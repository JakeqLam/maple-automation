#Requires AutoHotkey v2.0

F10:: {
    loop 100 {
        if WinExist("ahk_exe DreamMS.exe") {
            Send "d" ; soul arrow
            Sleep 200000
        }
    }
}
F2:: {
    reload
}