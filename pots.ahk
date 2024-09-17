#Requires AutoHotkey v2.0

F11:: {
    if WinExist("ahk_exe DreamMS.exe") {
        Send "x"
        Sleep 5000
        Send "x"
       
    }
}
