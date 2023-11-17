'脚本会将设定目录下所有xml格式文件转换为xlsx文件
Dim sourceDir
'需要转换的xml文件所在目录
'如果使用中文路径报错，记事本另存为选择编码为ANSI
sourceDir = "C:\Users\Administrator\Desktop"

Dim fso
Set fso = CreateObject("Scripting.FileSystemObject") 

Dim folder
Set folder = fso.GetFolder(sourceDir)

Dim oExcel
Set oExcel = CreateObject("Excel.Application")

For Each file In folder.Files
  If LCase(fso.GetExtensionName(file.Path)) = "xml" Then
    
    Dim xlsxPath 
    xlsxPath = Replace(file.Path, ".xml", ".xlsx")
    
    If Not fso.FileExists(xlsxPath) Then
    
      Dim xmlBook
      Set xmlBook = oExcel.Workbooks.Open(file.Path)

      xmlBook.SaveAs xlsxPath, 51

      xmlBook.Close False
    
    End If
    
  End If
Next

oExcel.Quit
'WScript.Sleep 500
WScript.Echo "Conversion completed."

Set obj = createobject("wscript.shell")
obj.run "cmd /c %cd% && cscript //nologo test.vbs"