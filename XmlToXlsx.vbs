'�ű��Ὣ�趨Ŀ¼������xml��ʽ�ļ�ת��Ϊxlsx�ļ�
Dim sourceDir
'��Ҫת����xml�ļ�����Ŀ¼
'���ʹ������·���������±����Ϊѡ�����ΪANSI
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