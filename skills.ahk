#Requires AutoHotkey v2.0

F10:: {
    if WinExist("ahk_exe DreamMS.exe") {
        Send "d" ; soul arrow
        Sleep 1000
        Send "shift" ; booster
       
    }
}
