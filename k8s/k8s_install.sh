echo "此脚本用来快捷搭建k8s集群，极大程度降低工作量，能在10分钟内完成任意版本的k8s集群部署"
echo "默认master节点名为：master，worker节点为：worker1，worker2....当前执行脚本的主机默认为：master"
ip_addr=$(ip a | grep inet | grep -v '127' | grep -v 'inet6' | awk '{print $2}' | grep '/24' | awk -F '/' '{print $1}')
cd /home
while true; do
	echo "请选择要执行的操作："
	echo "1.初始化环境(master worker)"
	echo "2.安装kubelet kubeadm kubectl(master worker)"
	echo "3.初始化kubernetes(master)"
	echo "4.配置Flannel网络(master)"
	echo "5.锁定k8s版本（避免无意升级出现错误）"
	echo "6.解锁k8s版本"
	echo "7.退出"
	read -p "请输入选项数字： " choice
	case $choice in
	1)
		echo "正在执行初始化环境"
		echo "请输入集群 IP 地址（以空格分隔）,第一个ip地址为master节点"
		read -a ips
		master="${ips[0]}"
		workers=("${ips[@]:1}")
		echo "$master master" >>/etc/hosts
		for ((i = 0; i < ${#workers[@]}; i++)); do
			echo "${workers[$i]} worker$((i + 1))" >>/etc/hosts
		done
		echo "已更新 /etc/hosts 文件。"
		cat /etc/hosts
		sleep 2
		echo "修改主机名"
		hostname=$(grep "$ip_addr" /etc/hosts | awk '{print $2}')
		hostnamectl set-hostname $hostname
		echo "主机名设定为"
		hostname
		sleep 2
		echo "仓库换源"
		yum install -y yum-utils device-mapper-persistent-data lvm2 wget tar curl epel-release
		mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
		wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
		yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
		sed -i 's+download.docker.com+mirrors.aliyun.com/docker-ce+' /etc/yum.repos.d/docker-ce.repo
		cat >/etc/yum.repos.d/kubernetes.repo <<EOF
		[kubernetes]
		name=Kubernetes
		baseurl=http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
		enabled=1
		gpgcheck=0
		repo_gpgcheck=0
		gpgkey=http://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg 
		http://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
		EOF
		
		yum clean all
		yum makecache
		
		echo "修改iptables"
		cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
		br_netfilter
		EOF
		
		cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
		net.bridge.bridge-nf-call-ip6tables = 1
		net.bridge.bridge-nf-call-iptables = 1
		net.ipv4.ip_forward=1 # better than modify /etc/sysctl.conf
		EOF
		
		sudo sysctl --system
		
		echo "关闭 Linux 的 swap 分区，提升 Kubernetes 的性能"
		swapoff -a
		sed -ri '/\sswap\s/s/^#?/#/' /etc/fstab
		
		
		echo "-----------------------------"
		echo "执行完第一步后，请重启设备：reboot"
		echo "-----------------------------"
		echo "3秒后将会重启设备"
		sleep 3
		reboot
		;;
	2)
		echo "正在执行安装kubelet kubeadm kubectl"
		yum list kubectl --showduplicates | sort -r
		echo "k8s 1.24以后，dockershim 代码正式的从 k8s 移除，脚本还没考虑到这个情况，因此暂时不要安装1.24以后的k8s"
		echo "安装的k8s版本尽量限制在(1.14.10--1.23.3)"
		read -p "请输入需要安装的k8s版本号（省略掉-以及后面的数字，如：1.23.3）: " k8s_version
		set -e
		yum install -y kubelet-$k8s_version kubeadm-$k8s_version kubectl-$k8s_version
		yum install -y docker-ce-18.09.0-3.el7 docker-ce-cli-18.09.0-3.el7 containerd.io
		set +e
		echo "修改docker配置文件"
		sudo mkdir -p /etc/docker && touch /etc/docker/daemon.json
		cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "registry-mirrors": ["https://hub-mirror.c.163.com"],
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
		sudo systemctl enable docker
		sudo systemctl daemon-reload
		sudo systemctl restart docker
		systemctl enable kubelet.service
		firewall-cmd --zone=public --add-port=6443/tcp --permanent
		firewall-cmd --reload
		;;
	3)
		echo "k8s初始化"
		ip_addr=$(ip a | grep inet | grep -v '127' | grep -v 'inet6' | awk '{print $2}' | grep '/24' | awk -F '/' '{print $1}')
		k8s_version=$(kubectl version --client --short | awk -Fv '/Client Version: /{print $2}')
		repo=registry.cn-hangzhou.aliyuncs.com/google_containers
		for name in $(kubeadm config images list --kubernetes-version v$k8s_version); do
			src_name=${name#k8s.gcr.io/}
			src_name=${src_name#coredns/}
			docker pull $repo/$src_name
			docker tag $repo/$src_name $name
			docker rmi $repo/$src_name
		done
		kubeadm init --pod-network-cidr=10.10.0.0/16 --apiserver-advertise-address=$ip_addr --kubernetes-version=$k8s_version >init.log 2>&1
		wait
		awk '/kubeadm join '$ip_addr'/ {print; getline; print}' init.log >join.txt
		echo "----------------------------"
		echo "                            "
		cat join.txt
		echo "                            "
		echo "----------------------------"
		mkdir -p $HOME/.kube
		sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
		sudo chown $(id -u):$(id -g) $HOME/.kube/config
		;;
	4)
		echo "配置Flannel网络"
		wget http://www.lunrry.top:99/p/Ydnp233Q0S/kube-flannel.yml
		kubectl apply -f kube-flannel.yml
		kubectl get node
		;;
	5)
		echo "锁定k8s版本，避免无意升级出现错误"
		yum install -y yum-versionlock
		yum versionlock add kubeadm kubelet kubectl
		yum versionlock list
		;;
	6)
		echo "解除k8s版本锁定"
		yum versionlock delete kubeadm kubelet kubectl
		yum versionlock list
		;;
	7)
		echo "退出脚本"
		exit 0
		;;
	esac
done
