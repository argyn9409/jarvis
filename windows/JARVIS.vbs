Set sh = CreateObject("WScript.Shell")
p = sh.ExpandEnvironmentStrings("%USERPROFILE%\lab\jarvis-run.ps1")
sh.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & p & """", 0, False
