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
Global $min = 2.4
Global $max = 2.5
Global $buffing = False

AdlibRegister("VIPBuff", 120000)

; Make sure the window is in the top left of screen
; resolution 1280x780

;creating gui
GUICreate("Hello World", 415, 200)
GUICtrlCreateLabel("Left Boundary", 20, 20)
GUICtrlCreateLabel("Right Boundary", 200, 20)
GUICtrlCreateLabel("Time Interval (ms)", 20, 70)
GUICtrlCreateLabel("Pause script first because lag", 20, 0)

$LBInputVal = GUICtrlCreateInput("350", 20, 40, 100, 20) ; will not accept drag&drop files
$RBInputVal = GUICtrlCreateInput("650", 200, 40, 100, 20) ; will not accept drag&drop files
$timerInputVal = GUICtrlCreateInput("12000", 20, 90, 80, 20) ; will not accept drag&drop files
$randMovement = GUICtrlCreateCheckbox("Random Movement", 20, 120, 120, 20)
$vipBuff = GUICtrlCreateCheckbox("VIP Buff(first put @Buffme in chat)", 20, 145, 200, 20)

GUISetState(@SW_SHOW)

Func VIPBuff()
	If isChecked($vipBuff) = True AND $g_bPaused = False Then
		$buffing = True
		Sleep(Random($min, $max) * 300)
		Send("{f10}")
		Sleep(Random($min, $max) * 400)
		Send("{enter}")
		Sleep(Random($min, $max) * 200)
		Send("{up}")
		Sleep(Random($min, $max) * 200)
		Send("{enter}")
		Sleep(Random($min, $max) * 200)
		Send("{enter}")
		Sleep(Random($min, $max) * 200)
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
$x1 = 0 ;char x position ingame
$y1 = 0
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

	  ;if character is too far left, send them to the right
	  If $x1 < $leftBound Then
		 moveRight($timerVal)
	  ;if character is too far left, send them to the right
	  ElseIf $x1 > $rightBound Then
		 moveLeft($timerVal)
	  ElseIf isChecked($randMovement) Then
		 $rand = Random(0, 10, 1)

		 If $rand <= 4 Then
			moveRandomRight($timerVal)
		 ElseIf $rand > 4 and $rand <= 8 Then
			moveRandomLeft($timerVal)
		 Else
 			stand($timerVal)
		 EndIf
	  EndIf

   EndIf
WEnd

; Utility functions

Func imageSearchName()
   ;search for name.png (must take a screenshot of img)
   For $i = 5 To 1 Step -1
      $search1 = _ImageSearch("name.png", 1, $x1, $y1, 110)
      ToolTip('Searching for name.png', 0, 0)
      If $search1 = 1 Then
         ToolTip($x1&@CRLF&$y1, 0, 0)
      EndIf
	  If $x1 < $leftBound or $x1 > $rightBound Then ExitLoop
      Sleep(Random($min, $max) * 25)
   Next
EndFunc   ;==>Example

;move char to left
Func moveLeft($timerVal)
   If $x1 > $rightBound Then
	     For $i = 8 To 1 Step -1
			imageSearchName()
			If $x1 < $leftBound Then ExitLoop
			For $i = 3 To 1 Step -1
				Send("{Left down}")
				Sleep(Random($min, $max) * 5)
			Next
			$res = Random($min, $max) * ($timerVal / 10)
			Sleep($res)
			Send("{Left up}")
			Sleep(Random($min, $max) * 35)
			Send("{Right down}")
			Sleep(Random($min, $max) * 35)
			Send("{Right Up}")
			Sleep(Random($min, $max) * 35)
		 Next
   EndIf
EndFunc   ;==>Example

;move char to the right
Func moveRight($timerVal)
   If $x1 < $leftBound Then
	     For $i = 8 To 1 Step -1
			imageSearchName()
			If $x1 > $rightBound Then ExitLoop
			For $i = 3 To 1 Step -1
				Send("{Right down}")
				Sleep(Random($min, $max) * 5)
			Next
			$res = Random($min, $max) * ($timerVal / 10)
			Sleep($res)
			Send("{Right up}")
			Sleep(Random($min, $max) * 35)
			Send("{Left down}")
			Sleep(Random($min, $max) * 35)
			Send("{Left Up}")
			Sleep(Random($min, $max) * 35)
		 Next
   EndIf
EndFunc   ;==>Example

;move char to left
Func moveRandomLeft($timerVal)

	For $i = 8 To 1 Step -1
		If $i = 5 or $i = 2 Then
		imageSearchName()
		EndIf
			If $x1 < $leftBound Then ExitLoop
		For $i = 3 To 1 Step -1
			Send("{Left down}")
			Sleep(Random($min, $max) * 5)
		Next
		$res = Random($min, $max) * ($timerVal / 10)
		Sleep($res)
		Send("{Left up}")
		Sleep(Random($min, $max) * 35)
		Send("{Right down}")
		Sleep(Random($min, $max) * 35)
		Send("{Right Up}")
		Sleep(Random($min, $max) * 35)
	Next
EndFunc   ;==>Example

;move char to the right
Func moveRandomRight($timerVal)

	For $i = 8 To 1 Step -1
		If $i = 5 or $i = 2 Then
		imageSearchName()
		EndIf
			If $x1 > $rightBound Then ExitLoop
		For $i = 3 To 1 Step -1
			Send("{Right down}")
			Sleep(Random($min, $max) * 5)
		Next
		$res = Random($min, $max) * ($timerVal / 10)
		Sleep($res)
		Send("{Right up}")
		Sleep(Random($min, $max) * 35)
		Send("{Left down}")
		Sleep(Random($min, $max) * 35)
		Send("{Left Up}")
		Sleep(Random($min, $max) * 35)
	Next
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