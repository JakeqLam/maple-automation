#include <ImageSearch2015.au3> ;must include imageSearchDLLx64, x32
#include <Misc.au3>
#include <AutoItConstants.au3>
#include <GUIConstantsEx.au3>

#RequireAdmin
HotKeySet("{/}", "Terminate")
HotKeySet("-", "Terminate")
HotKeySet("+{/}", "Terminate")
HotKeySet("{`}", "TogglePause")

Global $g_bPaused = False
Global $res = 0
Global $min = 1
Global $max = 1.2
Global $buffing = False

AdlibRegister("VIPBuff", 153000)

; Make sure the window is in the top left of screen
; resolution 1280x780

;creating gui
GUICreate("Hello World", 415, 200)
GUICtrlCreateLabel("Left Boundary", 20, 20)
GUICtrlCreateLabel("Right Boundary", 200, 20)
GUICtrlCreateLabel("Time Interval (ms)", 20, 70)
GUICtrlCreateLabel("Pause script first because lag", 20, 0)

$LBInputVal = GUICtrlCreateInput("675", 20, 40, 100, 20) ; will not accept drag&drop files
$RBInputVal = GUICtrlCreateInput("900", 200, 40, 100, 20) ; will not accept drag&drop files
$timerInputVal = GUICtrlCreateInput("6", 20, 90, 80, 20) ; will not accept drag&drop files
$randMovement = GUICtrlCreateCheckbox("Random Movement", 20, 120, 120, 20)
$vipBuff = GUICtrlCreateCheckbox("VIP Buff", 20, 145, 200, 20)

GUISetState(@SW_SHOW)

Func VIPBuff()
	If isChecked($vipBuff) = True AND $g_bPaused = False Then
		$buffing = True
		Sleep(Random($min, $max) * 500)
		Send("{f8}")
		Sleep(Random($min, $max) * 750)
		Send("{f10}")
		Sleep(Random($min, $max) * 300)
		Send("{enter}")
		Sleep(Random($min, $max) * 150)
		Send("{@}")
		Sleep(Random($min, $max) * 5)
		Send("{B}")
		Sleep(Random($min, $max) * 5)
		Send("{u}")
		Sleep(Random($min, $max) * 5)
		Send("{f}")
		Sleep(Random($min, $max) * 5)
		Send("{f}")
		Sleep(Random($min, $max) * 5)
		Send("{m}")
		Sleep(Random($min, $max) * 5)
		Send("{e}")
		Sleep(Random($min, $max) * 5)
		Send("{enter}")
		Sleep(Random($min, $max) * 150)
		Send("{enter}")
		Sleep(Random($min, $max) * 500)
		Send("{f8}")
		Sleep(Random($min, $max) * 750)
		Send("{f10}")
		Sleep(Random($min, $max) * 300)
		$buffing = False
   EndIf
EndFunc   ;==>TogglePause


Func Terminate()
    Exit 0
EndFunc

Func TogglePause()
   $g_bPaused = Not $g_bPaused
   While $g_bPaused
        Sleep(100)
        ToolTip('Script is "Paused"', 0, 0)
   WEnd
   $buffing = False
	Send("{Right up}")
	Sleep(Random($min, $max) * 35)
	Send("{Left up}")
	Sleep(Random($min, $max) * 35)
   ToolTip("")
EndFunc   ;==>TogglePause

;Global variables
Global $x1 = 0 ;char x position ingame
Global $y1 = 0
$leftBound = 0
$rightBound = 0
$timerVal = 0
$search1 = 0; ;imagesearch result

;grab values from gui
;$leftBound = GUICtrlRead()


While (1)

   $leftBound = GUICtrlRead($LBInputVal) ;left side of the screen
   $rightBound = GUICtrlRead($RBInputVal)  ;right side of the screen
   $timerVal = GUICtrlRead($timerInputVal) ;movement time

	imageSearchName()

   if ($buffing == False) Then

	  Send("{Left up}")
      Sleep(Random($min, $max) * 25)
	  Send("{Right up}")
	  Sleep(Random($min, $max) * 25)
	  ;if character is too far left, send them to the right
	  If $x1 < $leftBound Then
		 moveRight($timerVal, false)
	  ;if character is too far left, send them to the right
	  ElseIf $x1 > $rightBound Then
		 moveLeft($timerVal, false)
	  ElseIf isChecked($randMovement) Then
		 $rand = Random(0, 8, 1)

		 If $rand <= 4 Then
			moveRight($timerVal, true)
		 ElseIf $rand > 4 and $rand <= 8 Then
			moveLeft($timerVal, true)
		 Else
;~  			stand($timerVal)
		 EndIf
	  EndIf

   EndIf
WEnd

; Utility functions

Func imageSearchName()
   ;search for name.png (must take a screenshot of img)
   For $i = 3 To 1 Step -1
      $search1 = _ImageSearch("name.png", 1, $x1, $y1, 110)

;~       ToolTip('Searching for name.png', 0, 0)
      If $search1 = 1 Then
         ToolTip($x1&@CRLF&$y1, 0, 0)
		 return 1
	  EndIf

      Sleep(Random($min, $max) * 25)

	  $search2 = _ImageSearch("name2.png", 1, $x1, $y1, 110)

	  If $search2 = 1 Then
         ToolTip($x1&@CRLF&$y1, 0, 0)
		 return 1
	  EndIf

	  If $x1 < $leftBound or $x1 > $rightBound Then return 1
      Sleep(Random($min, $max) * 25)
   Next
EndFunc   ;==>Example

;move char to left
Func moveLeft($timerVal, $random)
   If $x1 > $rightBound  or ($random = true and $x1 > $leftBound) Then
	For $i = $timerVal To 1 Step -1
		imageSearchName()
		Sleep(Random($min, $max) * 100)
		If ($x1 < $leftBound or $x1 > $rightBound) and $random = true Then ExitLoop
		If $x1 < $leftBound Then ExitLoop
		Send("{Left down}")
		$res = Random($min, $max) * 500
		Sleep($res)
	Next
		Send("{Left up}")
   EndIf
EndFunc   ;==>Example
z
;move char to the right
Func moveRight($timerVal, $random)
   If $x1 < $leftBound or ($random = true and $x1 < $rightBound) Then
	For $i = $timerVal To 1 Step -1
		imageSearchName()
		Sleep(Random($min, $max) * 100)
		If ($x1 < $leftBound or $x1 > $rightBound) and $random = true Then ExitLoop
		If $x1 > $rightBound Then ExitLoop
		Send("{Right down}")
		$res = Random($min, $max) * 500
		Sleep($res)
	Next
		Send("{Right up}")
   EndIf
EndFunc   ;==>Example

Func stand($timerVal)
	 For $i = 3 To 1 Step -1
		If $i = 3 or $i = 2 Then
		imageSearchName()
		EndIf
			If $x1 < $leftBound or $x1 > $rightBound Then ExitLoop
		$res = Random($min, $max) * ($timerVal / 10)
		Sleep($res)
	 Next
EndFunc

Func isChecked($idControlID)
   Return BitAND(GUICtrlRead($idControlID), $GUI_CHECKED) = $GUI_CHECKED
EndFunc