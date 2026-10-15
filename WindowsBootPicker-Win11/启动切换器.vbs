Option Explicit

Dim shell, fileSystem, scriptPath, command
Set shell = CreateObject("WScript.Shell")
Set fileSystem = CreateObject("Scripting.FileSystemObject")
scriptPath = fileSystem.BuildPath(fileSystem.GetParentFolderName(WScript.ScriptFullName), "WindowsBootPicker.ps1")
command = """" & shell.ExpandEnvironmentStrings("%SystemRoot%") & "\System32\WindowsPowerShell\v1.0\powershell.exe"" -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -STA -File """ & scriptPath & """"
shell.Run command, 0, False
