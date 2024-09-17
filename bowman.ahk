#Requires AutoHotkey v2.0

F12:: {
    if WinExist("ahk_exe DreamMS.exe") {
        Send "a"
        Sleep 1000
        Send "a"
       
    }
}
