#Requires AutoHotkey v2.0

F11:: {
    loop 100 {        
        if WinExist("ahk_exe DreamMS.exe") {
            Send "x"
            Sleep 40000
        }
    }
}
F2:: {
    reload
}
