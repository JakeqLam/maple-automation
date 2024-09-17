#Requires AutoHotkey v2.0

F12:: {
    loop 100 {    
        if WinExist("ahk_exe DreamMS.exe") {
            Send "1"      
            Sleep 1500
        }
    }
}

F2:: {
    reload
}