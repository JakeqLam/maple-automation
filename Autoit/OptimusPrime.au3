#include <ImageSearch2015.au3> ;must include imageSearchDLLx64, x32
#include <Misc.au3>
#include <AutoItConstants.au3>
#include <GUIConstantsEx.au3>

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
; resolution 1280x780

;creating gui
GUICreate("Hello World", 415, 210)
GUICtrlCreateLabel("Left Boundary", 20, 20) 
GUICtrlCreateLabel("Right Boundary", 200, 20) 

$LBInputVal = GUICtrlCreateInput("300", 20, 40, 100, 20) ; will not accept drag&drop files
$RBInputVal = GUICtrlCreateInput("900", 200, 40, 100, 20) ; will not accept drag&drop files

GUISetState(@SW_SHOW)


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

$x1 = 0 ;char x position ingame
$y1 = 0
$leftBound = GUICtrlRead($LBInputVal) ;left side of the screen
$rightBound = GUICtrlRead($RBInputVal)  ;right side of the screen
$search1 = 0; ;imagesearch result

;grab values from gui
;$leftBound = GUICtrlRead()


While (1)
   $min = 2.4
$max = 2.5

if ($atking == False) Then

For $i = 5 To 1 Step -1
   $search1 = _ImageSearch("name.png", 1, $x1, $y1, 130)
   ToolTip('Searching for name.png', 0, 0)
   If $search1 = 1 Then
	  ToolTip($x1&@CRLF&$y1, 0, 0)
   EndIf

Sleep(Random($min, $max) * 100)
Next

; if character is too far left, send them to the right
If $x1 < $leftBound Then
   Send("{Right down}")
   $res = Random($min, $max) * 3000
   Sleep($res)
   Send("{Right up}")
EndIf

; if character is too far right, send them to the left
If $x1 > $rightBound Then
   Send("{Left down}")
   $res = Random($min, $max) * 3000
   Sleep($res)
   Send("{Left up}")
EndIf


;Randomize movement
For $i = 5 To 1 Step -1
   $search1 = _ImageSearch("name.png", 1, $x1, $y1, 130)

   If $search1 = 1 Then
	  ToolTip($x1&@CRLF&$y1, 0, 0)
   EndIf

Sleep(Random($min, $max) * 100)
Next


if $x1 >= $leftBound and $x1 <= $rightBound then
;(1)  randomly move right. (2) randomly move left. (0) randomly means stop
$Rand = Random(0, 2, 1)
   If $Rand = 1 Then
      Send("{Right down}")
      $res = Random($min, $max) * 1500
      Sleep($res)
      Send("{Right up}")
   ElseIf $Rand = 2 Then
      Send("{Left down}")
      $res = Random($min, $max) * 1500
      Sleep($res)
      Send("{Left up}")
   Else
      $res = Random($min, $max) * 1500
      Sleep($res)
   EndIf
EndIf


EndIf


WEnd