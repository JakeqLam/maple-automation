#include <ImageSearch2015.au3>

#include <Misc.au3>
#include <AutoItConstants.au3>
;WinActivate("YunaMS")
#RequireAdmin
HotKeySet("{/}", "Terminate")
HotKeySet("-", "Terminate")
HotKeySet("+{/}", "Terminate")
HotKeySet("{`}", "TogglePause")
Global $g_bPaused = False
Global $res = 0

$atking = False

; Make sure the window is in the top left of screen
;resolution 1280x780

Func Terminate()
    Exit 0
EndFunc


Func TogglePause()
    $g_bPaused = Not $g_bPaused
    While $g_bPaused
        Sleep(100)
        ToolTip('Script is "Paused"', 0, 0)
    WEnd
    ToolTip("")
EndFunc   ;==>TogglePause

$x1 = 0
$y1 = 0
$search1 = 0;


While (1)
   $min = 2.4
$max = 2.5

if ($atking == False) Then

For $i = 5 To 1 Step -1
   $search1 = _ImageSearch("name.png", 1, $x1, $y1, 130)
   ToolTip('searching for image"', 0, 0)
   If $search1 = 1 Then
	  ToolTip($x1&@CRLF&$y1, 0, 0)
   EndIf

Sleep(Random($min, $max) * 100)
Next

If $x1 < 300 Then
Send("{Right down}")
 $res = Random($min, $max) * 3000
   Sleep($res)
Send("{Right up}")
EndIf

If $x1 > 1000 Then
Send("{Left down}")
 $res = Random($min, $max) * 3000
   Sleep($res)
Send("{Left up}")
EndIf


For $i = 5 To 1 Step -1
   $search1 = _ImageSearch("name.png", 1, $x1, $y1, 130)

   If $search1 = 1 Then
	  ToolTip($x1&@CRLF&$y1, 0, 0)
   EndIf

Sleep(Random($min, $max) * 100)
Next


if $x1 >= 300 and $x1 <= 1000 then

If Random(0, 1, 1) Then
   Send("{Right down}")
 $res = Random($min, $max) * 1500
   Sleep($res)
Send("{Right up}")
   Else
   Send("{Left down}")
 $res = Random($min, $max) * 1500
   Sleep($res)
Send("{Left up}")
EndIf

EndIf


EndIf


WEnd