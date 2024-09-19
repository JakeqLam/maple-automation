#SingleInstance, Force
#NoEnv
#MaxThreadsPerHotkey 10
#IfWinExist 
#Persistent

SetWinDelay, 0
SetBatchLines -1

Menu, Tray, Icon, omes.ico
potion:= 0

;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><> UI DRAW

ui_buttonon_bitmap := Create_buttonon_png()
ui_buttonoff_bitmap := Create_buttonoff_png()
ui_bitmap := Create_uiautopot_png()

Gui, Add, picture, x0 y0 w415 h177, % "HBITMAP:*" . ui_bitmap

;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><> Version

Gui font, c505050 s9, Nova Square
Gui, Add, Text, x308 y140 BackgroundTrans, Omes V.0.3.0    

;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><> Autopot

Gui font, cC0C0C0 s9, Nova Square

Gui, Add, Text, x189 y13 BackgroundTrans, Autopot
Gui, Add, Picture, x32 y41 vbuttonautopot gbuttonautopot_switch, % "HBITMAP:*" . ui_buttonoff_bitmap 
Gui, Add, Picture, x32 y131 vbuttonontop gbuttonontop_switch, % "HBITMAP:*" . ui_buttonoff_bitmap 

Gui, Add, DDL, x275 y56 w50 vhp_value, NA|1|2|3|4|5|6|7|8|9|0|q|w|e|r|t|a|s|d|f|g|z|x|c|v
Gui, Add, DDL, x275 y96 w50 vmp_value, NA|1|2|3|4|5|6|7|8|9|0|q|w|e|r|t|a|s|d|f|g|z|x|c|v

Gui, Add, Text, x50 y40 BackgroundTrans, Autopot (F8)    				  ;text length +25		
Gui, Add, Text, x50 y130 BackgroundTrans, Always ontop                    ; x y w (width will restrict how far the text will go before entering) 

Gui, Add, Text, x249 y62 BackgroundTrans, HP 
Gui, Add, Text, x335 y62 BackgroundTrans, HP Key
Gui, Add, Text, x249 y102 BackgroundTrans, MP 
Gui, Add, Text, x335 y102 BackgroundTrans, MP Key

hBitmap := Create_buttonon_png1()
sliderhp := new CustomSlider(" x50 y65 w195 h10 c0x444444 c0x8bb53e", 0, hBitmap)   ;number berfore bitmap is width of screen box
slidermp := new CustomSlider(" x50 y105 w195 h10 c0x444444 c0x8bb53e", 0, hBitmap)   ;number berfore bitmap is width of screen box
sliderhp.pos := 50 ; set new pos
slidermp.pos := 50 ; set new pos

guicontrol, choose, hp_value, NA
guicontrol, choose, mp_value, NA

Gui, Show, x1500 y500 h177 w415, omes.autopot
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><<><><><><><><><><><><><><><><><>><><> Menu start

SetTimer, menu_open, % (togglemenucheck:=!togglemenucheck) ? 100 : "Off"
menu_open:

	GuiControlGet, hp_key, , hp_value,
	GuiControlGet, mp_key, , mp_value,

	if (potion = 1)
	{
		hpvalue := % sliderhp.pos * 1.66 + 614
		mpvalue := % slidermp.pos * 1.66 + 614

		PixelSearch,,, 616, 745, %hpvalue%, 751, 0x726F75, 2, Fast RGB
		if (!ErrorLevel and hp_key != "NA")
		{
			Sendinput {%hp_key%}
			sleep 10ms
		} 
		
		PixelSearch,,, 613, 761, %mpvalue%, 769, 0x79767d, 2, Fast RGB
		if (!ErrorLevel and mp_key != "NA")
		{
			Sendinput {%mp_key%}
			sleep 10ms
		} 
	}
return

F8::
buttonautopot_switch:
toggleautopot:=!toggleautopot

	if (!toggleautopot)
	{
		GuiControl,, buttonautopot,  % "HBITMAP:*" . ui_buttonoff_bitmap
		potion = 0
	}
	else
	{
		GuiControl,, buttonautopot, % "HBITMAP:*" . ui_buttonon_bitmap
		potion = 1
	}
return

buttonontop_switch:
toggleontop:=!toggleontop				
	if (!toggleontop)
	{

		Gui, -AlwaysOnTop
		GuiControl,, buttonontop, % "HBITMAP:*" . ui_buttonoff_bitmap
	}
	else
	{
		GuiControl,, buttonontop, % "HBITMAP:*" . ui_buttonon_bitmap
		Gui, +AlwaysOnTop
	}
return


GuiClose:
ExitApp






; based on http://www.autohotkey.com/board/topic/81144-progress-bar-slider/?p=516891
class CustomSlider
{
	__New(Options := "", val := "", hBitmap_thumb := "", ShowTooltip := false) {
		if !RegExMatch(Options, "i)\bBackground\w+\b") {                                      ;i)turns off case-sensitivity
			if RegExMatch(Options, "i)\bc\K\w+", bkColor)
				bkOpt := "Background" bkColor
		}
		Gui, Add, Progress, h1 %Options% %bkOpt% hwndHPROG Disabled -E0x200  , % val

		Gui, Add, Text, xp yp-10 h24 wp BackgroundTrans HWNDhpgTrigger,  ;determins slider position

		if RegExMatch(Options, "i)\bRange\K([\d-]+)-([\d-]+)", rng)
			this.rng_radio := Abs(rng2 - rng1)/100
		else
			this.rng_radio := 1

		GuiControlGet, pg, Pos, %HPROG%
		x := pgW * (val/this.rng_radio/100) + pgX

		;Gui, Add, Pic, xp yp w15 h29 HWNDhBtn  ;creates the ui for the slider and input ??? gui adds the slider
		Gui, Add, Pic, yp x%x% w8 h-20 HWNDhBtn, % "HBITMAP:*" hBitmap_thumb  ;creates the ui for the slider and input ??? gui adds the slider

		this.hProg := HPROG
		this.hBtn := hBtn
		this.pgVal := val
		this.ShowTooltip := ShowTooltip
		; this.hRightText := hRightText

		fn := this.OnClick.Bind(this)
		GuiControl, +g, %hBtn%, %fn%
		GuiControl, +g, %hpgTrigger%, %fn%
	}

	OnClick() {
		GuiControl, Focus, % this.hBtn

		hSlider := this.hProg

		pre_CoordModeMouse := A_CoordModeMouse
		CoordMode, Mouse, Relative

		MouseGetPos,,,, ClickedhWnd, 2

		GuiControlGet, SliderLine, %A_Gui%:Pos, % hSlider

		GuiControlGet, sliderVal, %A_Gui%:, %hSlider%
		V := sliderVal

		if this.ShowTooltip
			ToolTip, %sliderVal%

		ControlGet, Style, Style,,, ahk_id %hSlider%
		ControlGetPos, X, Y, W, H,, ahk_id %hSlider%

		VarSetCapacity(R, 8)
		SendMessage, 0x0407,, &R,, ahk_id %hSlider%
		R1 := NumGet(R, 0, "Int")
		R2 := NumGet(R, 4, "Int")
		
		LastV := (ClickedhWnd = this.hBtn) ? "" : sliderVal

		while (GetKeyState("LButton"))
		{
			Sleep, 10
			MouseGetPos, XM, YM
			V := (V:=(Style&0x4 ? 1-(YM-Y)/H : (XM-X)/W))>=1 ? R2 : V<=0 ? R1 : Round(V*(R2-R1)+R1)
			if (LastV="") {
				LastV := V
			} else if (V != LastV) {
				LastV := V
				if this.ShowTooltip
					ToolTip % V
				this.pos(SliderLineW, SliderLineX) := V
			}
		}

		if this.ShowTooltip
			ToolTip
		CoordMode, Mouse, %pre_CoordModeMouse%
	}

	pos[pgW := "", pgX := ""] {
		set {
			GuiControl,, % this.hProg, % value

			if !pgW
				GuiControlGet, pg, Pos, % this.hProg

			x := pgW * (value/this.rng_radio/100) + pgX
			; GuiControl, MoveDraw, % this.hBtn, x%x%
			GuiControl, Move, % this.hBtn, x%x%
			DllCall("InvalidateRect", "ptr", this.hBtn, "ptr", 0, "int", 0)

			this.pgVal := value
			; GuiControl,, % this.hRightText, % value
		}
		get {
			return this.pgVal
		}
	}
}


; ##################################################################################
; # This #Include file was generated by Image2Include.ahk, you must not change it! #
; ##################################################################################
Create_uiautopot_png(NewHandle = False) {
Static hBitmap := 0
Ptr := A_PtrSize ? "Ptr" : "UInt"
UPtr := A_PtrSize ? "UPtr" : "UInt"
If (NewHandle)
   hBitmap := 0
If (hBitmap)
   Return hBitmap
VarSetCapacity(B64, 10440 << !!A_IsUnicode)
B64 := "iVBORw0KGgoAAAANSUhEUgAAAZ8AAACxCAIAAACUUScxAAAACXBIWXMAABcSAAAXEgFnn9JSAAAOBWlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNi4wLWMwMDYgNzkuMTY0NjQ4LCAyMDIxLzAxLzEyLTE1OjUyOjI5ICAgICAgICAiPiA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPiA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtbG5zOnBob3Rvc2hvcD0iaHR0cDovL25zLmFkb2JlLmNvbS9waG90b3Nob3AvMS4wLyIgeG1sbnM6ZGM9Imh0dHA6Ly9wdXJsLm9yZy9kYy9lbGVtZW50cy8xLjEvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RFdnQ9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZUV2ZW50IyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtbG5zOnRpZmY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vdGlmZi8xLjAvIiB4bWxuczpleGlmPSJodHRwOi8vbnMuYWRvYmUuY29tL2V4aWYvMS4wLyIgeG1wOkNyZWF0b3JUb29sPSJBZG9iZSBQaG90b3Nob3AgMjIuMiAoV2luZG93cykiIHhtcDpDcmVhdGVEYXRlPSIyMDIxLTA3LTMwVDA5OjA2OjQ4LTA3OjAwIiB4bXA6TWV0YWRhdGFEYXRlPSIyMDIxLTA4LTExVDE1OjEwOjEyLTA3OjAwIiB4bXA6TW9kaWZ5RGF0ZT0iMjAyMS0wOC0xMVQxNToxMDoxMi0wNzowMCIgcGhvdG9zaG9wOkNvbG9yTW9kZT0iMyIgZGM6Zm9ybWF0PSJpbWFnZS9wbmciIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6MjE3YTA0OTMtMjQ3Zi1iMzQ1LTk0NzYtZDc4MzIxNGVjY2RkIiB4bXBNTTpEb2N1bWVudElEPSJhZG9iZTpkb2NpZDpwaG90b3Nob3A6YzVhZjM2YmYtM2JiNS05YTRmLWJlOGUtZTg2ZTk0MmQxM2E0IiB4bXBNTTpPcmlnaW5hbERvY3VtZW50SUQ9InhtcC5kaWQ6ZGRhN2Q2MDUtMWI2Ny04ODQ1LTg4NTYtMjNkYzQ2NjVmNmQ0IiB0aWZmOk9yaWVudGF0aW9uPSIxIiB0aWZmOlhSZXNvbHV0aW9uPSIxNTAwMDAwLzEwMDAwIiB0aWZmOllSZXNvbHV0aW9uPSIxNTAwMDAwLzEwMDAwIiB0aWZmOlJlc29sdXRpb25Vbml0PSIyIiBleGlmOkNvbG9yU3BhY2U9IjY1NTM1IiBleGlmOlBpeGVsWERpbWVuc2lvbj0iNDE1IiBleGlmOlBpeGVsWURpbWVuc2lvbj0iNDYxIj4gPHBob3Rvc2hvcDpUZXh0TGF5ZXJzPiA8cmRmOkJhZz4gPHJkZjpsaSBwaG90b3Nob3A6TGF5ZXJOYW1lPSJBdXRvUG90IiBwaG90b3Nob3A6TGF5ZXJUZXh0PSJBdXRvUG90Ii8+IDxyZGY6bGkgcGhvdG9zaG9wOkxheWVyTmFtZT0iQXV0b1BvdCAoRjgpIiBwaG90b3Nob3A6TGF5ZXJUZXh0PSJBdXRvUG90IChGOCkiLz4gPHJkZjpsaSBwaG90b3Nob3A6TGF5ZXJOYW1lPSJBbHdheXMgb250b3AiIHBob3Rvc2hvcDpMYXllclRleHQ9IkFsd2F5cyBvbnRvcCIvPiA8cmRmOmxpIHBob3Rvc2hvcDpMYXllck5hbWU9IlRvZ2dsZSBTa2lsbCBVSSIgcGhvdG9zaG9wOkxheWVyVGV4dD0iVG9nZ2xlIFNraWxsIFVJIi8+IDxyZGY6bGkgcGhvdG9zaG9wOkxheWVyTmFtZT0iVG9nZ2xlIEtpbGxzd2l0Y2giIHBob3Rvc2hvcDpMYXllclRleHQ9IlRvZ2dsZSBLaWxsc3dpdGNoIi8+IDxyZGY6bGkgcGhvdG9zaG9wOkxheWVyTmFtZT0iQXV0b3BvdCIgcGhvdG9zaG9wOkxheWVyVGV4dD0iQXV0b3BvdCIvPiA8cmRmOmxpIHBob3Rvc2hvcDpMYXllck5hbWU9IlgiIHBob3Rvc2hvcDpMYXllclRleHQ9IlgiLz4gPC9yZGY6QmFnPiA8L3Bob3Rvc2hvcDpUZXh0TGF5ZXJzPiA8cGhvdG9zaG9wOkRvY3VtZW50QW5jZXN0b3JzPiA8cmRmOkJhZz4gPHJkZjpsaT5hZG9iZTpkb2NpZDpwaG90b3Nob3A6M2UwMTFlYTctNzE2My03ZjQ3LThhNjEtNzMxYzE4ODNlMTgxPC9yZGY6bGk+IDxyZGY6bGk+YWRvYmU6ZG9jaWQ6cGhvdG9zaG9wOjhiYjgxNjBmLTllZjgtZGI0MS1iNGE2LTNkZGQxMWYxOTVlMzwvcmRmOmxpPiA8cmRmOmxpPmFkb2JlOmRvY2lkOnBob3Rvc2hvcDo5MjA3OGUyNS02ZDI3LWE0NDAtYTZlMS03MWE1OTlmZDQ0YTk8L3JkZjpsaT4gPC9yZGY6QmFnPiA8L3Bob3Rvc2hvcDpEb2N1bWVudEFuY2VzdG9ycz4gPHhtcE1NOkhpc3Rvcnk+IDxyZGY6U2VxPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0iY3JlYXRlZCIgc3RFdnQ6aW5zdGFuY2VJRD0ieG1wLmlpZDpkZGE3ZDYwNS0xYjY3LTg4NDUtODg1Ni0yM2RjNDY2NWY2ZDQiIHN0RXZ0OndoZW49IjIwMjEtMDctMzBUMDk6MDY6NDgtMDc6MDAiIHN0RXZ0OnNvZnR3YXJlQWdlbnQ9IkFkb2JlIFBob3Rvc2hvcCAyMi4yIChXaW5kb3dzKSIvPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0ic2F2ZWQiIHN0RXZ0Omluc3RhbmNlSUQ9InhtcC5paWQ6ZDBlZDk4YjEtYzk1Zi1lNzQ0LWFiYmMtMGRkYWNmYTkyZDE0IiBzdEV2dDp3aGVuPSIyMDIxLTA3LTMwVDEwOjE5OjA4LTA3OjAwIiBzdEV2dDpzb2Z0d2FyZUFnZW50PSJBZG9iZSBQaG90b3Nob3AgMjIuMiAoV2luZG93cykiIHN0RXZ0OmNoYW5nZWQ9Ii8iLz4gPHJkZjpsaSBzdEV2dDphY3Rpb249InNhdmVkIiBzdEV2dDppbnN0YW5jZUlEPSJ4bXAuaWlkOjBlNGU3NDc1LWYwZTAtYTQ0MS1iOTliLTcyODI5ZDI0ZTgwYSIgc3RFdnQ6d2hlbj0iMjAyMS0wOC0xMVQxNToxMDoxMi0wNzowMCIgc3RFdnQ6c29mdHdhcmVBZ2VudD0iQWRvYmUgUGhvdG9zaG9wIDIyLjIgKFdpbmRvd3MpIiBzdEV2dDpjaGFuZ2VkPSIvIi8+IDxyZGY6bGkgc3RFdnQ6YWN0aW9uPSJjb252ZXJ0ZWQiIHN0RXZ0OnBhcmFtZXRlcnM9ImZyb20gYXBwbGljYXRpb24vdm5kLmFkb2JlLnBob3Rvc2hvcCB0byBpbWFnZS9wbmciLz4gPHJkZjpsaSBzdEV2dDphY3Rpb249ImRlcml2ZWQiIHN0RXZ0OnBhcmFtZXRlcnM9ImNvbnZlcnRlZCBmcm9tIGFwcGxpY2F0aW9uL3ZuZC5hZG9iZS5waG90b3Nob3AgdG8gaW1hZ2UvcG5nIi8+IDxyZGY6bGkgc3RFdnQ6YWN0aW9uPSJzYXZlZCIgc3RFdnQ6aW5zdGFuY2VJRD0ieG1wLmlpZDoyMTdhMDQ5My0yNDdmLWIzNDUtOTQ3Ni1kNzgzMjE0ZWNjZGQiIHN0RXZ0OndoZW49IjIwMjEtMDgtMTFUMTU6MTA6MTItMDc6MDAiIHN0RXZ0OnNvZnR3YXJlQWdlbnQ9IkFkb2JlIFBob3Rvc2hvcCAyMi4yIChXaW5kb3dzKSIgc3RFdnQ6Y2hhbmdlZD0iLyIvPiA8L3JkZjpTZXE+IDwveG1wTU06SGlzdG9yeT4gPHhtcE1NOkRlcml2ZWRGcm9tIHN0UmVmOmluc3RhbmNlSUQ9InhtcC5paWQ6MGU0ZTc0NzUtZjBlMC1hNDQxLWI5OWItNzI4MjlkMjRlODBhIiBzdFJlZjpkb2N1bWVudElEPSJhZG9iZTpkb2NpZDpwaG90b3Nob3A6OGJiODE2MGYtOWVmOC1kYjQxLWI0YTYtM2RkZDExZjE5NWUzIiBzdFJlZjpvcmlnaW5hbERvY3VtZW50SUQ9InhtcC5kaWQ6ZGRhN2Q2MDUtMWI2Ny04ODQ1LTg4NTYtMjNkYzQ2NjVmNmQ0Ii8+IDwvcmRmOkRlc2Ny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"
If !DllCall("Crypt32.dll\CryptStringToBinary" (A_IsUnicode ? "W" : "A"), Ptr, &B64, "UInt", 0, "UInt", 0x01, Ptr, 0, "UIntP", DecLen, Ptr, 0, Ptr, 0)
   Return False
VarSetCapacity(Dec, DecLen, 0)
If !DllCall("Crypt32.dll\CryptStringToBinary" (A_IsUnicode ? "W" : "A"), Ptr, &B64, "UInt", 0, "UInt", 0x01, Ptr, &Dec, "UIntP", DecLen, Ptr, 0, Ptr, 0)
   Return False
; Bitmap creation adopted from "How to convert Image data (JPEG/PNG/GIF) to hBITMAP?" by SKAN
; -> http://www.autohotkey.com/board/topic/21213-how-to-convert-image-data-jpegpnggif-to-hbitmap/?p=139257
hData := DllCall("Kernel32.dll\GlobalAlloc", "UInt", 2, UPtr, DecLen, UPtr)
pData := DllCall("Kernel32.dll\GlobalLock", Ptr, hData, UPtr)
DllCall("Kernel32.dll\RtlMoveMemory", Ptr, pData, Ptr, &Dec, UPtr, DecLen)
DllCall("Kernel32.dll\GlobalUnlock", Ptr, hData)
DllCall("Ole32.dll\CreateStreamOnHGlobal", Ptr, hData, "Int", True, Ptr "P", pStream)
hGdip := DllCall("Kernel32.dll\LoadLibrary", "Str", "Gdiplus.dll", UPtr)
VarSetCapacity(SI, 16, 0), NumPut(1, SI, 0, "UChar")
DllCall("Gdiplus.dll\GdiplusStartup", Ptr "P", pToken, Ptr, &SI, Ptr, 0)
DllCall("Gdiplus.dll\GdipCreateBitmapFromStream",  Ptr, pStream, Ptr "P", pBitmap)
DllCall("Gdiplus.dll\GdipCreateHBITMAPFromBitmap", Ptr, pBitmap, Ptr "P", hBitmap, "UInt", 0)
DllCall("Gdiplus.dll\GdipDisposeImage", Ptr, pBitmap)
DllCall("Gdiplus.dll\GdiplusShutdown", Ptr, pToken)
DllCall("Kernel32.dll\FreeLibrary", Ptr, hGdip)
PtrSize := A_PtrSize ? A_PtrSize : 4
DllCall(NumGet(NumGet(pStream + 0, 0, UPtr) + (PtrSize * 2), 0, UPtr), Ptr, pStream)
Return hBitmap
}




; ##################################################################################
; # This #Include file was generated by Image2Include.ahk, you must not change it! #
; ##################################################################################
Create_buttonon_png(NewHandle = False) {
Static hBitmap := 0
Ptr := A_PtrSize ? "Ptr" : "UInt"
UPtr := A_PtrSize ? "UPtr" : "UInt"
If (NewHandle)
   hBitmap := 0
If (hBitmap)
   Return hBitmap
VarSetCapacity(B64, 3824 << !!A_IsUnicode)
B64 := "iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAIAAAD9iXMrAAAACXBIWXMAABcSAAAXEgFnn9JSAAAKJmlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNi4wLWMwMDYgNzkuMTY0NjQ4LCAyMDIxLzAxLzEyLTE1OjUyOjI5ICAgICAgICAiPiA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPiA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtbG5zOnBob3Rvc2hvcD0iaHR0cDovL25zLmFkb2JlLmNvbS9waG90b3Nob3AvMS4wLyIgeG1sbnM6ZGM9Imh0dHA6Ly9wdXJsLm9yZy9kYy9lbGVtZW50cy8xLjEvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RFdnQ9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZUV2ZW50IyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtbG5zOnRpZmY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vdGlmZi8xLjAvIiB4bWxuczpleGlmPSJodHRwOi8vbnMuYWRvYmUuY29tL2V4aWYvMS4wLyIgeG1wOkNyZWF0b3JUb29sPSJBZG9iZSBQaG90b3Nob3AgMjIuMiAoV2luZG93cykiIHhtcDpDcmVhdGVEYXRlPSIyMDIxLTA3LTMwVDA5OjA2OjQ4LTA3OjAwIiB4bXA6TWV0YWRhdGFEYXRlPSIyMDIxLTA3LTMwVDEwOjE4OjU5LTA3OjAwIiB4bXA6TW9kaWZ5RGF0ZT0iMjAyMS0wNy0zMFQxMDoxODo1OS0wNzowMCIgcGhvdG9zaG9wOkNvbG9yTW9kZT0iMyIgZGM6Zm9ybWF0PSJpbWFnZS9wbmciIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6OWE4ZWJlZjAtZTE0ZC0xMDRjLWE4OTctZDhmNDA1MjQwYWE5IiB4bXBNTTpEb2N1bWVudElEPSJhZG9iZTpkb2NpZDpwaG90b3Nob3A6ZmI4NTU0MDItZjQwOS1lMTRmLTg4OWItMGU5YWZkYzM3OWYzIiB4bXBNTTpPcmlnaW5hbERvY3VtZW50SUQ9InhtcC5kaWQ6ZGRhN2Q2MDUtMWI2Ny04ODQ1LTg4NTYtMjNkYzQ2NjVmNmQ0IiB0aWZmOk9yaWVudGF0aW9uPSIxIiB0aWZmOlhSZXNvbHV0aW9uPSIxNTAwMDAwLzEwMDAwIiB0aWZmOllSZXNvbHV0aW9uPSIxNTAwMDAwLzEwMDAwIiB0aWZmOlJlc29sdXRpb25Vbml0PSIyIiBleGlmOkNvbG9yU3BhY2U9IjY1NTM1IiBleGlmOlBpeGVsWERpbWVuc2lvbj0iNDE1IiBleGlmOlBpeGVsWURpbWVuc2lvbj0iMjI1Ij4gPHBob3Rvc2hvcDpUZXh0TGF5ZXJzPiA8cmRmOkJhZz4gPHJkZjpsaSBwaG90b3Nob3A6TGF5ZXJOYW1lPSJYIiBwaG90b3Nob3A6TGF5ZXJUZXh0PSJYIi8+IDwvcmRmOkJhZz4gPC9waG90b3Nob3A6VGV4dExheWVycz4gPHhtcE1NOkhpc3Rvcnk+IDxyZGY6U2VxPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0iY3JlYXRlZCIgc3RFdnQ6aW5zdGFuY2VJRD0ieG1wLmlpZDpkZGE3ZDYwNS0xYjY3LTg4NDUtODg1Ni0yM2RjNDY2NWY2ZDQiIHN0RXZ0OndoZW49IjIwMjEtMDctMzBUMDk6MDY6NDgtMDc6MDAiIHN0RXZ0OnNvZnR3YXJlQWdlbnQ9IkFkb2JlIFBob3Rvc2hvcCAyMi4yIChXaW5kb3dzKSIvPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0ic2F2ZWQiIHN0RXZ0Omluc3RhbmNlSUQ9InhtcC5paWQ6MDNjOTFmZmYtZDIxNi0yNjQ1LWEwZDQtOGZlNjU1MDhkOTMzIiBzdEV2dDp3aGVuPSIyMDIxLTA3LTMwVDEwOjE4OjU5LTA3OjAwIiBzdEV2dDpzb2Z0d2FyZUFnZW50PSJBZG9iZSBQaG90b3Nob3AgMjIuMiAoV2luZG93cykiIHN0RXZ0OmNoYW5nZWQ9Ii8iLz4gPHJkZjpsaSBzdEV2dDphY3Rpb249ImNvbnZlcnRlZCIgc3RFdnQ6cGFyYW1ldGVycz0iZnJvbSBhcHBsaWNhdGlvbi92bmQuYWRvYmUucGhvdG9zaG9wIHRvIGltYWdlL3BuZyIvPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0iZGVyaXZlZCIgc3RFdnQ6cGFyYW1ldGVycz0iY29udmVydGVkIGZyb20gYXBwbGljYXRpb24vdm5kLmFkb2JlLnBob3Rvc2hvcCB0byBpbWFnZS9wbmciLz4gPHJkZjpsaSBzdEV2dDphY3Rpb249InNhdmVkIiBzdEV2dDppbnN0YW5jZUlEPSJ4bXAuaWlkOjlhOGViZWYwLWUxNGQtMTA0Yy1hODk3LWQ4ZjQwNTI0MGFhOSIgc3RFdnQ6d2hlbj0iMjAyMS0wNy0zMFQxMDoxODo1OS0wNzowMCIgc3RFdnQ6c29mdHdhcmVBZ2VudD0iQWRvYmUgUGhvdG9zaG9wIDIyLjIgKFdpbmRvd3MpIiBzdEV2dDpjaGFuZ2VkPSIvIi8+IDwvcmRmOlNlcT4gPC94bXBNTTpIaXN0b3J5PiA8eG1wTU06RGVyaXZlZEZyb20gc3RSZWY6aW5zdGFuY2VJRD0ieG1wLmlpZDowM2M5MWZmZi1kMjE2LTI2NDUtYTBkNC04ZmU2NTUwOGQ5MzMiIHN0UmVmOmRvY3VtZW50SUQ9ImFkb2JlOmRvY2lkOnBob3Rvc2hvcDo5MjA3OGUyNS02ZDI3LWE0NDAtYTZlMS03MWE1OTlmZDQ0YTkiIHN0UmVmOm9yaWdpbmFsRG9jdW1lbnRJRD0ieG1wLmRpZDpkZGE3ZDYwNS0xYjY3LTg4NDUtODg1Ni0yM2RjNDY2NWY2ZDQiLz4gPC9yZGY6RGVzY3JpcHRpb24+IDwvcmRmOlJERj4gPC94OnhtcG1ldGE+IDw/eHBhY2tldCBlbmQ9InIiPz5g8KCWAAAAsklEQVQokW2QQUrEQBBFXyeVtSCCCB7FM3kR7zmCiwG3mv7PRTIkZvKhF9316tfvau8fb48vZTiqgQBt4Po519Pr9PDc7qidZBinmn+FM87FDmD+sRqiig1oaNtIUMBYkQguL9nb4HozlsGszK19pVwPPVZi+q4sbiQusFZi7w0gB6+tIZ2yJwfu8HtBKiHZorfN859qF+c2736VUuN0WtqtEIaJul56n8dznyVJ4/ur/wGrMILkPh7JcAAAAABJRU5ErkJggg=="
If !DllCall("Crypt32.dll\CryptStringToBinary" (A_IsUnicode ? "W" : "A"), Ptr, &B64, "UInt", 0, "UInt", 0x01, Ptr, 0, "UIntP", DecLen, Ptr, 0, Ptr, 0)
   Return False
VarSetCapacity(Dec, DecLen, 0)
If !DllCall("Crypt32.dll\CryptStringToBinary" (A_IsUnicode ? "W" : "A"), Ptr, &B64, "UInt", 0, "UInt", 0x01, Ptr, &Dec, "UIntP", DecLen, Ptr, 0, Ptr, 0)
   Return False
; Bitmap creation adopted from "How to convert Image data (JPEG/PNG/GIF) to hBITMAP?" by SKAN
; -> http://www.autohotkey.com/board/topic/21213-how-to-convert-image-data-jpegpnggif-to-hbitmap/?p=139257
hData := DllCall("Kernel32.dll\GlobalAlloc", "UInt", 2, UPtr, DecLen, UPtr)
pData := DllCall("Kernel32.dll\GlobalLock", Ptr, hData, UPtr)
DllCall("Kernel32.dll\RtlMoveMemory", Ptr, pData, Ptr, &Dec, UPtr, DecLen)
DllCall("Kernel32.dll\GlobalUnlock", Ptr, hData)
DllCall("Ole32.dll\CreateStreamOnHGlobal", Ptr, hData, "Int", True, Ptr "P", pStream)
hGdip := DllCall("Kernel32.dll\LoadLibrary", "Str", "Gdiplus.dll", UPtr)
VarSetCapacity(SI, 16, 0), NumPut(1, SI, 0, "UChar")
DllCall("Gdiplus.dll\GdiplusStartup", Ptr "P", pToken, Ptr, &SI, Ptr, 0)
DllCall("Gdiplus.dll\GdipCreateBitmapFromStream",  Ptr, pStream, Ptr "P", pBitmap)
DllCall("Gdiplus.dll\GdipCreateHBITMAPFromBitmap", Ptr, pBitmap, Ptr "P", hBitmap, "UInt", 0)
DllCall("Gdiplus.dll\GdipDisposeImage", Ptr, pBitmap)
DllCall("Gdiplus.dll\GdiplusShutdown", Ptr, pToken)
DllCall("Kernel32.dll\FreeLibrary", Ptr, hGdip)
PtrSize := A_PtrSize ? A_PtrSize : 4
DllCall(NumGet(NumGet(pStream + 0, 0, UPtr) + (PtrSize * 2), 0, UPtr), Ptr, pStream)
Return hBitmap
}





; ##################################################################################
; # This #Include file was generated by Image2Include.ahk, you must not change it! #
; ##################################################################################
Create_buttonon_png1(NewHandle = False) {
Static hBitmap := 0
Ptr := A_PtrSize ? "Ptr" : "UInt"
UPtr := A_PtrSize ? "UPtr" : "UInt"
If (NewHandle)
   hBitmap := 0
If (hBitmap)
   Return hBitmap
VarSetCapacity(B64, 3824 << !!A_IsUnicode)
B64 := "iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAIAAAD9iXMrAAAACXBIWXMAABcSAAAXEgFnn9JSAAAKJmlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNi4wLWMwMDYgNzkuMTY0NjQ4LCAyMDIxLzAxLzEyLTE1OjUyOjI5ICAgICAgICAiPiA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPiA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtbG5zOnBob3Rvc2hvcD0iaHR0cDovL25zLmFkb2JlLmNvbS9waG90b3Nob3AvMS4wLyIgeG1sbnM6ZGM9Imh0dHA6Ly9wdXJsLm9yZy9kYy9lbGVtZW50cy8xLjEvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RFdnQ9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZUV2ZW50IyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtbG5zOnRpZmY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vdGlmZi8xLjAvIiB4bWxuczpleGlmPSJodHRwOi8vbnMuYWRvYmUuY29tL2V4aWYvMS4wLyIgeG1wOkNyZWF0b3JUb29sPSJBZG9iZSBQaG90b3Nob3AgMjIuMiAoV2luZG93cykiIHhtcDpDcmVhdGVEYXRlPSIyMDIxLTA3LTMwVDA5OjA2OjQ4LTA3OjAwIiB4bXA6TWV0YWRhdGFEYXRlPSIyMDIxLTA3LTMwVDEwOjE4OjU5LTA3OjAwIiB4bXA6TW9kaWZ5RGF0ZT0iMjAyMS0wNy0zMFQxMDoxODo1OS0wNzowMCIgcGhvdG9zaG9wOkNvbG9yTW9kZT0iMyIgZGM6Zm9ybWF0PSJpbWFnZS9wbmciIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6OWE4ZWJlZjAtZTE0ZC0xMDRjLWE4OTctZDhmNDA1MjQwYWE5IiB4bXBNTTpEb2N1bWVudElEPSJhZG9iZTpkb2NpZDpwaG90b3Nob3A6ZmI4NTU0MDItZjQwOS1lMTRmLTg4OWItMGU5YWZkYzM3OWYzIiB4bXBNTTpPcmlnaW5hbERvY3VtZW50SUQ9InhtcC5kaWQ6ZGRhN2Q2MDUtMWI2Ny04ODQ1LTg4NTYtMjNkYzQ2NjVmNmQ0IiB0aWZmOk9yaWVudGF0aW9uPSIxIiB0aWZmOlhSZXNvbHV0aW9uPSIxNTAwMDAwLzEwMDAwIiB0aWZmOllSZXNvbHV0aW9uPSIxNTAwMDAwLzEwMDAwIiB0aWZmOlJlc29sdXRpb25Vbml0PSIyIiBleGlmOkNvbG9yU3BhY2U9IjY1NTM1IiBleGlmOlBpeGVsWERpbWVuc2lvbj0iNDE1IiBleGlmOlBpeGVsWURpbWVuc2lvbj0iMjI1Ij4gPHBob3Rvc2hvcDpUZXh0TGF5ZXJzPiA8cmRmOkJhZz4gPHJkZjpsaSBwaG90b3Nob3A6TGF5ZXJOYW1lPSJYIiBwaG90b3Nob3A6TGF5ZXJUZXh0PSJYIi8+IDwvcmRmOkJhZz4gPC9waG90b3Nob3A6VGV4dExheWVycz4gPHhtcE1NOkhpc3Rvcnk+IDxyZGY6U2VxPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0iY3JlYXRlZCIgc3RFdnQ6aW5zdGFuY2VJRD0ieG1wLmlpZDpkZGE3ZDYwNS0xYjY3LTg4NDUtODg1Ni0yM2RjNDY2NWY2ZDQiIHN0RXZ0OndoZW49IjIwMjEtMDctMzBUMDk6MDY6NDgtMDc6MDAiIHN0RXZ0OnNvZnR3YXJlQWdlbnQ9IkFkb2JlIFBob3Rvc2hvcCAyMi4yIChXaW5kb3dzKSIvPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0ic2F2ZWQiIHN0RXZ0Omluc3RhbmNlSUQ9InhtcC5paWQ6MDNjOTFmZmYtZDIxNi0yNjQ1LWEwZDQtOGZlNjU1MDhkOTMzIiBzdEV2dDp3aGVuPSIyMDIxLTA3LTMwVDEwOjE4OjU5LTA3OjAwIiBzdEV2dDpzb2Z0d2FyZUFnZW50PSJBZG9iZSBQaG90b3Nob3AgMjIuMiAoV2luZG93cykiIHN0RXZ0OmNoYW5nZWQ9Ii8iLz4gPHJkZjpsaSBzdEV2dDphY3Rpb249ImNvbnZlcnRlZCIgc3RFdnQ6cGFyYW1ldGVycz0iZnJvbSBhcHBsaWNhdGlvbi92bmQuYWRvYmUucGhvdG9zaG9wIHRvIGltYWdlL3BuZyIvPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0iZGVyaXZlZCIgc3RFdnQ6cGFyYW1ldGVycz0iY29udmVydGVkIGZyb20gYXBwbGljYXRpb24vdm5kLmFkb2JlLnBob3Rvc2hvcCB0byBpbWFnZS9wbmciLz4gPHJkZjpsaSBzdEV2dDphY3Rpb249InNhdmVkIiBzdEV2dDppbnN0YW5jZUlEPSJ4bXAuaWlkOjlhOGViZWYwLWUxNGQtMTA0Yy1hODk3LWQ4ZjQwNTI0MGFhOSIgc3RFdnQ6d2hlbj0iMjAyMS0wNy0zMFQxMDoxODo1OS0wNzowMCIgc3RFdnQ6c29mdHdhcmVBZ2VudD0iQWRvYmUgUGhvdG9zaG9wIDIyLjIgKFdpbmRvd3MpIiBzdEV2dDpjaGFuZ2VkPSIvIi8+IDwvcmRmOlNlcT4gPC94bXBNTTpIaXN0b3J5PiA8eG1wTU06RGVyaXZlZEZyb20gc3RSZWY6aW5zdGFuY2VJRD0ieG1wLmlpZDowM2M5MWZmZi1kMjE2LTI2NDUtYTBkNC04ZmU2NTUwOGQ5MzMiIHN0UmVmOmRvY3VtZW50SUQ9ImFkb2JlOmRvY2lkOnBob3Rvc2hvcDo5MjA3OGUyNS02ZDI3LWE0NDAtYTZlMS03MWE1OTlmZDQ0YTkiIHN0UmVmOm9yaWdpbmFsRG9jdW1lbnRJRD0ieG1wLmRpZDpkZGE3ZDYwNS0xYjY3LTg4NDUtODg1Ni0yM2RjNDY2NWY2ZDQiLz4gPC9yZGY6RGVzY3JpcHRpb24+IDwvcmRmOlJERj4gPC94OnhtcG1ldGE+IDw/eHBhY2tldCBlbmQ9InIiPz5g8KCWAAAAsklEQVQokW2QQUrEQBBFXyeVtSCCCB7FM3kR7zmCiwG3mv7PRTIkZvKhF9316tfvau8fb48vZTiqgQBt4Po519Pr9PDc7qidZBinmn+FM87FDmD+sRqiig1oaNtIUMBYkQguL9nb4HozlsGszK19pVwPPVZi+q4sbiQusFZi7w0gB6+tIZ2yJwfu8HtBKiHZorfN859qF+c2736VUuN0WtqtEIaJul56n8dznyVJ4/ur/wGrMILkPh7JcAAAAABJRU5ErkJggg=="
If !DllCall("Crypt32.dll\CryptStringToBinary" (A_IsUnicode ? "W" : "A"), Ptr, &B64, "UInt", 0, "UInt", 0x01, Ptr, 0, "UIntP", DecLen, Ptr, 0, Ptr, 0)
   Return False
VarSetCapacity(Dec, DecLen, 0)
If !DllCall("Crypt32.dll\CryptStringToBinary" (A_IsUnicode ? "W" : "A"), Ptr, &B64, "UInt", 0, "UInt", 0x01, Ptr, &Dec, "UIntP", DecLen, Ptr, 0, Ptr, 0)
   Return False
; Bitmap creation adopted from "How to convert Image data (JPEG/PNG/GIF) to hBITMAP?" by SKAN
; -> http://www.autohotkey.com/board/topic/21213-how-to-convert-image-data-jpegpnggif-to-hbitmap/?p=139257
hData := DllCall("Kernel32.dll\GlobalAlloc", "UInt", 2, UPtr, DecLen, UPtr)
pData := DllCall("Kernel32.dll\GlobalLock", Ptr, hData, UPtr)
DllCall("Kernel32.dll\RtlMoveMemory", Ptr, pData, Ptr, &Dec, UPtr, DecLen)
DllCall("Kernel32.dll\GlobalUnlock", Ptr, hData)
DllCall("Ole32.dll\CreateStreamOnHGlobal", Ptr, hData, "Int", True, Ptr "P", pStream)
hGdip := DllCall("Kernel32.dll\LoadLibrary", "Str", "Gdiplus.dll", UPtr)
VarSetCapacity(SI, 16, 0), NumPut(1, SI, 0, "UChar")
DllCall("Gdiplus.dll\GdiplusStartup", Ptr "P", pToken, Ptr, &SI, Ptr, 0)
DllCall("Gdiplus.dll\GdipCreateBitmapFromStream",  Ptr, pStream, Ptr "P", pBitmap)
DllCall("Gdiplus.dll\GdipCreateHBITMAPFromBitmap", Ptr, pBitmap, Ptr "P", hBitmap, "UInt", 0)
DllCall("Gdiplus.dll\GdipDisposeImage", Ptr, pBitmap)
DllCall("Gdiplus.dll\GdiplusShutdown", Ptr, pToken)
DllCall("Kernel32.dll\FreeLibrary", Ptr, hGdip)
PtrSize := A_PtrSize ? A_PtrSize : 4
DllCall(NumGet(NumGet(pStream + 0, 0, UPtr) + (PtrSize * 2), 0, UPtr), Ptr, pStream)
Return hBitmap
}



; ##################################################################################
; # This #Include file was generated by Image2Include.ahk, you must not change it! #
; ##################################################################################
Create_buttonoff_png(NewHandle = False) {
Static hBitmap := 0
Ptr := A_PtrSize ? "Ptr" : "UInt"
UPtr := A_PtrSize ? "UPtr" : "UInt"
If (NewHandle)
   hBitmap := 0
If (hBitmap)
   Return hBitmap
VarSetCapacity(B64, 3692 << !!A_IsUnicode)
B64 := "iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAIAAAD9iXMrAAAACXBIWXMAABcSAAAXEgFnn9JSAAAKJmlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNi4wLWMwMDYgNzkuMTY0NjQ4LCAyMDIxLzAxLzEyLTE1OjUyOjI5ICAgICAgICAiPiA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPiA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtbG5zOnBob3Rvc2hvcD0iaHR0cDovL25zLmFkb2JlLmNvbS9waG90b3Nob3AvMS4wLyIgeG1sbnM6ZGM9Imh0dHA6Ly9wdXJsLm9yZy9kYy9lbGVtZW50cy8xLjEvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RFdnQ9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZUV2ZW50IyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtbG5zOnRpZmY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vdGlmZi8xLjAvIiB4bWxuczpleGlmPSJodHRwOi8vbnMuYWRvYmUuY29tL2V4aWYvMS4wLyIgeG1wOkNyZWF0b3JUb29sPSJBZG9iZSBQaG90b3Nob3AgMjIuMiAoV2luZG93cykiIHhtcDpDcmVhdGVEYXRlPSIyMDIxLTA3LTMwVDA5OjA2OjQ4LTA3OjAwIiB4bXA6TWV0YWRhdGFEYXRlPSIyMDIxLTA3LTMwVDEwOjE5OjA2LTA3OjAwIiB4bXA6TW9kaWZ5RGF0ZT0iMjAyMS0wNy0zMFQxMDoxOTowNi0wNzowMCIgcGhvdG9zaG9wOkNvbG9yTW9kZT0iMyIgZGM6Zm9ybWF0PSJpbWFnZS9wbmciIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6MDQ2ZmQwNGUtYTExOC1mMjQzLWFmNGMtZDdjMzIzMzkzNjA0IiB4bXBNTTpEb2N1bWVudElEPSJhZG9iZTpkb2NpZDpwaG90b3Nob3A6MGQ3YWE4NGUtOWJjMS0wNDQzLTkzYzktZDk4ZjdkYTAzMzI0IiB4bXBNTTpPcmlnaW5hbERvY3VtZW50SUQ9InhtcC5kaWQ6ZGRhN2Q2MDUtMWI2Ny04ODQ1LTg4NTYtMjNkYzQ2NjVmNmQ0IiB0aWZmOk9yaWVudGF0aW9uPSIxIiB0aWZmOlhSZXNvbHV0aW9uPSIxNTAwMDAwLzEwMDAwIiB0aWZmOllSZXNvbHV0aW9uPSIxNTAwMDAwLzEwMDAwIiB0aWZmOlJlc29sdXRpb25Vbml0PSIyIiBleGlmOkNvbG9yU3BhY2U9IjY1NTM1IiBleGlmOlBpeGVsWERpbWVuc2lvbj0iNDE1IiBleGlmOlBpeGVsWURpbWVuc2lvbj0iMjI1Ij4gPHBob3Rvc2hvcDpUZXh0TGF5ZXJzPiA8cmRmOkJhZz4gPHJkZjpsaSBwaG90b3Nob3A6TGF5ZXJOYW1lPSJYIiBwaG90b3Nob3A6TGF5ZXJUZXh0PSJYIi8+IDwvcmRmOkJhZz4gPC9waG90b3Nob3A6VGV4dExheWVycz4gPHhtcE1NOkhpc3Rvcnk+IDxyZGY6U2VxPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0iY3JlYXRlZCIgc3RFdnQ6aW5zdGFuY2VJRD0ieG1wLmlpZDpkZGE3ZDYwNS0xYjY3LTg4NDUtODg1Ni0yM2RjNDY2NWY2ZDQiIHN0RXZ0OndoZW49IjIwMjEtMDctMzBUMDk6MDY6NDgtMDc6MDAiIHN0RXZ0OnNvZnR3YXJlQWdlbnQ9IkFkb2JlIFBob3Rvc2hvcCAyMi4yIChXaW5kb3dzKSIvPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0ic2F2ZWQiIHN0RXZ0Omluc3RhbmNlSUQ9InhtcC5paWQ6MDdjNDUzYjYtNWEwMi0zNjQwLWE0ZDktOWI1YTE1NjY4MzQ0IiBzdEV2dDp3aGVuPSIyMDIxLTA3LTMwVDEwOjE5OjA2LTA3OjAwIiBzdEV2dDpzb2Z0d2FyZUFnZW50PSJBZG9iZSBQaG90b3Nob3AgMjIuMiAoV2luZG93cykiIHN0RXZ0OmNoYW5nZWQ9Ii8iLz4gPHJkZjpsaSBzdEV2dDphY3Rpb249ImNvbnZlcnRlZCIgc3RFdnQ6cGFyYW1ldGVycz0iZnJvbSBhcHBsaWNhdGlvbi92bmQuYWRvYmUucGhvdG9zaG9wIHRvIGltYWdlL3BuZyIvPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0iZGVyaXZlZCIgc3RFdnQ6cGFyYW1ldGVycz0iY29udmVydGVkIGZyb20gYXBwbGljYXRpb24vdm5kLmFkb2JlLnBob3Rvc2hvcCB0byBpbWFnZS9wbmciLz4gPHJkZjpsaSBzdEV2dDphY3Rpb249InNhdmVkIiBzdEV2dDppbnN0YW5jZUlEPSJ4bXAuaWlkOjA0NmZkMDRlLWExMTgtZjI0My1hZjRjLWQ3YzMyMzM5MzYwNCIgc3RFdnQ6d2hlbj0iMjAyMS0wNy0zMFQxMDoxOTowNi0wNzowMCIgc3RFdnQ6c29mdHdhcmVBZ2VudD0iQWRvYmUgUGhvdG9zaG9wIDIyLjIgKFdpbmRvd3MpIiBzdEV2dDpjaGFuZ2VkPSIvIi8+IDwvcmRmOlNlcT4gPC94bXBNTTpIaXN0b3J5PiA8eG1wTU06RGVyaXZlZEZyb20gc3RSZWY6aW5zdGFuY2VJRD0ieG1wLmlpZDowN2M0NTNiNi01YTAyLTM2NDAtYTRkOS05YjVhMTU2NjgzNDQiIHN0UmVmOmRvY3VtZW50SUQ9ImFkb2JlOmRvY2lkOnBob3Rvc2hvcDo5MjA3OGUyNS02ZDI3LWE0NDAtYTZlMS03MWE1OTlmZDQ0YTkiIHN0UmVmOm9yaWdpbmFsRG9jdW1lbnRJRD0ieG1wLmRpZDpkZGE3ZDYwNS0xYjY3LTg4NDUtODg1Ni0yM2RjNDY2NWY2ZDQiLz4gPC9yZGY6RGVzY3JpcHRpb24+IDwvcmRmOlJERj4gPC94OnhtcG1ldGE+IDw/eHBhY2tldCBlbmQ9InIiPz4jd760AAAAT0lEQVQoke3RsRHAIAxDUUlHY7Zh/71wZ6Xg0nBJWCC/fqrEMUZE2MYWAQMAycxsvfeI2NE2IVVV3whAVemIVr97cdKZSmpzTtsP/96tfy9RrBmxhTtQuAAAAABJRU5ErkJggg=="
If !DllCall("Crypt32.dll\CryptStringToBinary" (A_IsUnicode ? "W" : "A"), Ptr, &B64, "UInt", 0, "UInt", 0x01, Ptr, 0, "UIntP", DecLen, Ptr, 0, Ptr, 0)
   Return False
VarSetCapacity(Dec, DecLen, 0)
If !DllCall("Crypt32.dll\CryptStringToBinary" (A_IsUnicode ? "W" : "A"), Ptr, &B64, "UInt", 0, "UInt", 0x01, Ptr, &Dec, "UIntP", DecLen, Ptr, 0, Ptr, 0)
   Return False
; Bitmap creation adopted from "How to convert Image data (JPEG/PNG/GIF) to hBITMAP?" by SKAN
; -> http://www.autohotkey.com/board/topic/21213-how-to-convert-image-data-jpegpnggif-to-hbitmap/?p=139257
hData := DllCall("Kernel32.dll\GlobalAlloc", "UInt", 2, UPtr, DecLen, UPtr)
pData := DllCall("Kernel32.dll\GlobalLock", Ptr, hData, UPtr)
DllCall("Kernel32.dll\RtlMoveMemory", Ptr, pData, Ptr, &Dec, UPtr, DecLen)
DllCall("Kernel32.dll\GlobalUnlock", Ptr, hData)
DllCall("Ole32.dll\CreateStreamOnHGlobal", Ptr, hData, "Int", True, Ptr "P", pStream)
hGdip := DllCall("Kernel32.dll\LoadLibrary", "Str", "Gdiplus.dll", UPtr)
VarSetCapacity(SI, 16, 0), NumPut(1, SI, 0, "UChar")
DllCall("Gdiplus.dll\GdiplusStartup", Ptr "P", pToken, Ptr, &SI, Ptr, 0)
DllCall("Gdiplus.dll\GdipCreateBitmapFromStream",  Ptr, pStream, Ptr "P", pBitmap)
DllCall("Gdiplus.dll\GdipCreateHBITMAPFromBitmap", Ptr, pBitmap, Ptr "P", hBitmap, "UInt", 0)
DllCall("Gdiplus.dll\GdipDisposeImage", Ptr, pBitmap)
DllCall("Gdiplus.dll\GdiplusShutdown", Ptr, pToken)
DllCall("Kernel32.dll\FreeLibrary", Ptr, hGdip)
PtrSize := A_PtrSize ? A_PtrSize : 4
DllCall(NumGet(NumGet(pStream + 0, 0, UPtr) + (PtrSize * 2), 0, UPtr), Ptr, pStream)
Return hBitmap
}
