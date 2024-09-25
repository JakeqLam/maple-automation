#SingleInstance, Force
#NoEnv
#MaxThreadsPerHotkey 10
#IfWinExist 
#Persistent

SetWinDelay, 0
SetBatchLines -1

Menu, Tray, Icon, omes.ico

;<><><><><><><><><><><><><><><><><><><><><><><><> Draw UI BUTTONS

MaxRange1 := 100 
typeface := "Nova Square"

ui_bitmap                       := Create_uiupdate_png()
ui_buttonon_bitmap              := Create_buttonon_png()
ui_buttonoff_bitmap             := Create_buttonoff_png()

ui_buttontoggle_bitmap          := Create_buttontoggle_png()
ui_buttontoggle_down_bitmap     := Create_buttontoggledown_png()

ui_buttonkillswitch_bitmap      := Create_buttonkillswitch_png()
ui_buttonkillswitch_down_bitmap := Create_buttonkillswitchdown_png()

ui_button_autopot_bitmap        := Create_buttonautopot_png()
ui_button_autopot_down_bitmap   := Create_buttonautopotdown_png()

Gui, Add, Picture, x0 y0 w415 h477 vgui_ui, % "HBITMAP:*" . ui_bitmap
Gui, Add, Picture, x40 y365 h25 w155 vgui_button_toggle gbuttontoggle_down, % "HBITMAP:*" . ui_buttontoggle_bitmap
Gui, Add, Picture, x220 y365 h25 w155 vgui_button_close gbuttonkill_down, % "HBITMAP:*" . ui_buttonkillswitch_bitmap
Gui, Add, Picture, x40 y395 h25 w155 vgui_button_autopot gbuttonautopot_down, % "HBITMAP:*" . ui_button_autopot_bitmap

;<><><><><><><><><><><><><><><><><><><><><><><><> Draw Font/text <><><><> Headers

Gui font, cC0C0C0 s9, Nova Square
Gui, Add, Text, x180 y13  BackgroundTrans, Navigation
Gui, Add, Text, x177 y225 BackgroundTrans, Movement
Gui, Add, Text, x192 y340 BackgroundTrans, Misc

;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><> Draw Font/text Navigation tab

Gui, Add, Picture, x32 y36 vbuttonnav gbuttonnav_switch,  % "HBITMAP:*" . ui_buttonoff_bitmap         ; Start Navigation Y of text - 1
Gui, Add, Picture, x32 y166 vbuttonrune gbuttonrune_toggle,   % "HBITMAP:*" . ui_buttonoff_bitmap                        ;auto rune completion
Gui, Add, Picture, x32 y191 vbuttondc gbutton_dc,     % "HBITMAP:*" . ui_buttonoff_bitmap             ;chat dc

Gui, Add, Text, x50 y35 BackgroundTrans, Start Navigation (F6) 
Gui, Add, Text, x50 y55 BackgroundTrans, Map name
Gui, Add, Text, x50 y105 BackgroundTrans, Custom Map 

slidermapL := new CustomSlider(" x50 y125 w195 h9 c0x444444 c0x8bb53e", 50)   ;number berfore bitmap is width of screen box
slidermapR := new CustomSlider_reverse(" x50 y145 w195 h9 c0x444444 c0x8bb53e", 50)   ;number berfore bitmap is width of screen box
slidermapL.pos := 20 ; set new pos
slidermapR.pos := 20 ; set new pos

Gui, Add, Text, x250 y122 BackgroundTrans, Map Left 
Gui, Add, Text, x250 y142 BackgroundTrans, Map Right 

Gui, Add, Text, x50 y165 BackgroundTrans, AutoRune Completion 
Gui, Add, Text, x240 y165 BackgroundTrans, Interact Key 
Gui, Add, DDL,  x320 y161 w50 vDDLinteract, 1|2|3|4|5|6|7|8|9|0|q|w|e|r|t|y|u|i|o|p|a|s|d|f|g|h|j|k|l|z|x|c|v|b|n|m|Space

Gui, Add, Text, x50 y190 BackgroundTrans, Chat Disconnect (Safeguard) 

;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><> MAPS

DDLContent =                                                              ;list made
(Join|
custom map (small)
custom map (large)
)
Gui, Font, cC0C0C0 s9, Nova Square
Gui, Add, DDL, x50 y76 w250 vDDLselection, %DDLContent%                     ;creates the ui of ddl
GuiControlGet, Btn, Pos
GuiControlGet, DDL, Pos                                  ;DDL is dropdown list

Y := DDLY + ((BtnH - DDLH) // 2)                         ;BTN is ? H is height, can be used as btnX btnY BtnW BtnH
GuiControl, Move, DDL, y%Y%

;GuiControlGet, Outputvar, ,DDLselection,                ;Looks for the output variable of the DDL
;msgbox %Outputvar%                                      ;prints out the varible

GuiControl, MoveDraw, DDL ; needed to ensure that the control will shown properly after the first Gui, Show, ...
GuiControl, choose, DDLselection, small map navigation (side borders)

;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><> version font

Gui font, c505050 s9, Nova Square
Gui, Add, Text, x308 y438 BackgroundTrans, Omes V.0.3.0                                      ;Version number

;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><> toggle always ontop
Gui font, cC0C0C0 s9, Nova Square
Gui, Add, Text, x50 y432 BackgroundTrans, Always ontop
Gui, Add, Picture, x32 y433 vbuttonontop gbuttonontop_switch,  % "HBITMAP:*" . ui_buttonoff_bitmap 

;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><> Draw Font/text Skills

Gui font, cC0C0C0 s9, Nova Square

Gui, Add, Picture, x32 y251 vbuttonmovement gbuttonmovement_switch, % "HBITMAP:*" . ui_buttonoff_bitmap
Gui, Add, Text, x50 y250 BackgroundTrans, Enable Movement (F7)
Gui, Add, Text, x50 y270 BackgroundTrans, Movement type
Gui, Add, Text, x200 y270 BackgroundTrans, Movement Key
Gui, Add, Text, x311 y270 BackgroundTrans, Delay (MS)

Gui, Add, DDL, x50 y290 w145 vDDLmovement, Single_Jump|Double_Jump_Fast|Double_Jump_Slow|Teleport
Gui, Add, DDL, x200 y290 w100 vDDLmovement_key, Space|q|w|e|r|t|a|s|d|f|g|z|x|c|v

Gui font, cBlack s9, Nova Square
Gui, Add, edit, x320 y290 w50 r1 vMovement_delay, 300

GuiControl, choose, DDLmovement, Single_Jump

OnMessage(WM_MOUSEWHEEL:=0x20A, "wheel")
OnMessage(WM_MOUSEMOVE:=0x200, "drag")
return


drag(wParam, lParam)
{
   static yp,lastControl,change
   sensitivity:=7 ; In pixels, about how far should the mouse move before adjusting the value?
   amt:=1         ; How much to increase the value
   mode:=1        ; 1 = up/down, 2=left/right
   
   ; some safety checks
   if (!GetKeyState("Lbutton", "P"))
      return
   GuiControlGet, controlType, Focus
   if (!instr(controlType, "Edit"))
      return
   GuiControlGet, value,, %A_GuiControl%
   if value is not number
      return
 
   if (mode=1)
      MouseGetPos,, y
   else if (mode=2)
   {
      MouseGetPos, y
      y*=-1 ; need to swap it so dragging to the right adds, not subtracts.
   }
   else
      return
      
   if (lastControl!=A_GuiControl) ; set the position to the current mouse position
      yp:=y
   change:=abs(y-yp)              ; check to see if the value is ready to be changed, has it met the sensitivity?
   
   mult:=((wParam=5) ? 0.01 : (wParam=9) ? 0.1 : 1)
   value+=((y<yp && change>=sensitivity) ? amt*mult : (y>yp && change>=sensitivity) ? -amt*mult : 0)
 
   GuiControl,, %A_GuiControl%, % RegExReplace(value, "(\.[1-9]+)0+$", "$1")
   
   if (change>=sensitivity)
      yp:=y
   lastControl:=A_GuiControl
}
 
wheel(wParam, lParam)
{
   amt:=1 ; How much to increase the value
   GuiControlGet, controlType, Focus
   if (!instr(controlType, "Edit"))
      return
      
   GuiControlGet, value,, %A_GuiControl%
   if value is not number
      return
   
   mult:=((wParam & 0xffff=4) ? 0.01 : (wParam & 0xffff=8) ? 0.1 : 1)
   value+=((StrLen(wParam)>7) ? -amt*mult : amt*mult)
   GuiControl,, %A_GuiControl%, % RegExReplace(value, "(\.[1-9]+)0+$", "$1")
}
return

;<><><><><><><><><><><><><><><><><><><><><><><><> Character inputs / loop variables


navigation := 0
menu := 0
autorune := 0

;<><><><><><><><><><><><><><><><><><><><><><><><> Start loop

*F5:: 


;<><><><><><><><><><><><><><><><><><><><><><><><> Character inputs / loop variables
;mapsearch_x1 := 10
;mapsearch_y1 := 84
;mapsearch_x2 := 185
;mapsearch_y2 := 152
pathing_upper := 0
pathing_lower := 0
arrow_red_id    := "0xE4601F|0xDD3A15|0xE32915|0xD34E16|0xCE5715|0xE70A15|0xBD7751|0xD93815|0xAD7A4A|0x0ADA3E|0xA83846|0xCC7139|0xB87A3D|0xD7633E|0xB17C36|0xE18815|0xB86811"
arrow_green_id  := "0x02E043|0x4DCC7D|0x04f115|0x02D162|0x43c665|0x16ef43|0x4BC487|0x43C743|0x51CB85|0x51CB85|0x64CB4D|0x0ADA3E|0x36BB74|0x00DD66|0x3EFF3B"
scan_x := 450
arrowvalue := 0
rune_execute := 0
looping_arrows = 0

togglemenu:=!togglemenu				
	if (!togglemenu)
	{
		menu = 0
		Gui, Hide
	}
	else
	{
		Gui, Show, x800 y0 w415 h477
		menu = 1
	}
	
;<><><><><><><><><><><><><><><><><><><><><><><><> Start Timer checks

SetTimer, menu_open, % (togglemenucheck:=!togglemenucheck) ? 100 : "Off"
menu_open:

	if (!togglemenucheck)
	{
		Gui, Hide
		return
	}
	
	else if (menu = 1)
	{
		GuiControlGet, Delayvar, , Movement_delay,
		GuiControlGet, Movementvar, ,DDLmovement,
		GuiControlGet, Outputvar, ,DDLselection,
		GuiControlGet, interactkeyvar, ,DDLinteract,
		
		movement_class = %Movementvar%

		Random, 10ms, 9,14
		Random, 100ms, 98, 124
		Random, 200ms, 202, 210
		Random, 300ms, 297, 305
		Random, 400ms, 411, 435
		Random, 500ms, 497, 521
		Random, 800ms, 801, 814


;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><<><><><><><><><><><><><><><><><>><><> dc check

		if (dc = 1)
		{
			pixelsearch ,,, 8, 761, 103, 779, 0xe8e6e3, 4, Fast Rgb
			if !ErrorLevel
			{
				click 956, 762
				sleep 100ms
				click 949, 720
				sleep 100ms
				click 650, 526
			}
		}
	
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><<><><><><><><><><><><><><><><><>><><> Movement
		if (movement = 1) 
		{
			if (Movementvar = "Single_Jump")
			{
				%movement_class%()
				Sleep %Delayvar%
				Sleep 10ms
			}
			if (Movementvar = "Double_Jump_Fast")
			{
				%movement_class%()
				Sleep %Delayvar%
				Sleep 10ms
			}
			if (Movementvar = "Double_Jump_Slow")
			{
				%movement_class%()
				Sleep %Delayvar%
				Sleep 10ms
			}
			if (Movementvar = "Teleport")
			{
				%movement_class%()
				Sleep %Delayvar%
				Sleep 10ms
			}
		}
		
		
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><<><><><><><><><><><><><><><><><>><><> small map nagivation with side borders
		if (navigation = 1) 
		{
			if (navigation = 1 and Outputvar = "custom map (small)")
			{
				custom_map_left = % slidermapL.pos + 12
				y_value := slidermapR.pos
				custom_map_right := 180 - y_value
			
				PixelSearch,,, %custom_map_right%, 80, 151, 140, 0xFFDD44, 2, Fast RGB     ;right side
				if !ErrorLevel
				{
					MsgBox "going left"
					Sendinput {Blind}{Right up}
					Sendinput {Left down}
				}

				PixelSearch,,, 12, 80, %custom_map_left%, 140, 0xFFDD44, 2, Fast RGB        ;left side
				if !ErrorLevel
				{
					MsgBox "going right"
					Sendinput {Blind}{Left up}
					Sendinput {Right down}
				}
			}	
			if (navigation = 1 and Outputvar = "custom map (large)")
			{
				custom_map_left_long = % slidermapL.pos + 8
				y_value := slidermapR.pos
				custom_map_right_long := 288 - y_value
			
				PixelSearch,,, %custom_map_right_long%, 136, 226, 157, 0xFFDD44, 2, Fast RGB     ;right side
				if !ErrorLevel
				{
					Sendinput {Blind}{Right up}
					Sendinput {Left down}
				}
		
				PixelSearch,,, 8, 136, %custom_map_left_long%, 157, 0xFFDD44, 2, Fast RGB        ;left side
				if !ErrorLevel
				{
					Sendinput {Blind}{Left up}
					Sendinput {Right down}
				}
			}
		}
	}	
return


;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><> functions

Single_Jump()
{
	Sendinput {Alt down}
	Sleep 100ms
	Sendinput {Blind}{Alt up}
}

Double_Jump_Fast()
{
	Sendinput {Alt down}
	Sleep 100ms
	Sendinput {Blind}{Alt up}
	Sendinput {Alt down}
	Sleep 100ms
	Sendinput {Blind}{Alt up}
}

Double_Jump_Slow()
{
	Sendinput {Alt down}
	Sleep 300ms
	Sendinput {Blind}{Alt up}
	Sendinput {Alt down}
	Sleep 300ms
	Sendinput {Blind}{Alt up}
}

Teleport()
{
	GuiControlGet, Movementvar_key, ,DDLmovement_key,
	Sendinput {%Movementvar_key%}
}

;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><> keybindings

*F11::

return


*F6::
buttonnav_switch:
togglenavigation:=!togglenavigation

	if (!togglenavigation)
	{
		Sendinput {Blind}{Left up}
		Sendinput {Blind}{Right up}
		Sendinput {Blind}{Up up}
		Sendinput {Blind}{Down up}
		GuiControl,, buttonnav,  % "HBITMAP:*" . ui_buttonoff_bitmap
		navigation = 0
		looping_arrows = 0
	}
	else
	{
		GuiControl,, buttonnav, % "HBITMAP:*" . ui_buttonon_bitmap
		navigation = 1
	}
return

buttonrune_toggle:
togglerune:=!togglerune

	if (!togglerune)
	{
		Sendinput {Blind}{Left up}
		Sendinput {Blind}{Right up}
		Sendinput {Blind}{Up up}
		Sendinput {Blind}{Down up}
		GuiControl,, buttonrune,  % "HBITMAP:*" . ui_buttonoff_bitmap
		autorune = 0
	}
	else
	{
		GuiControl,, buttonrune, % "HBITMAP:*" . ui_buttonon_bitmap
		autorune = 1
	}
return

*F7::
buttonmovement_switch:
togglemovement:=!togglemovement

	if (!togglemovement){
		GuiControl,, buttonmovement,  % "HBITMAP:*" . ui_buttonoff_bitmap
		movement = 0
		Reload
	} else {
		GuiControl,, buttonmovement, % "HBITMAP:*" . ui_buttonon_bitmap
		;randNum := 0
		Loop {
			if (togglemovement) {
				;Random, randNum, 1000, 6000
					
				;shift in place
						;randNum := 0
		Loop {
			if (togglemovement) {
				
				;Random, randNum, 1000, 6000
				Sleep, 7000
				SendInput {Left Down}
				Sleep, %Delayvar% 
				;Sleep, randNum
				SendInput {Left Up}
				Sleep, 1000 
		
				SendInput {Right Down}
				Sleep, %Delayvar%
				;Sleep, randNum
				SendInput {Right Up}
				Sleep, 1000 
					
			}
		}
					
			}
		}
		movement = 1
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


button_dc:
toggledc:=!toggledc			
	if (!toggledc)
	{
		GuiControl,, buttondc, % "HBITMAP:*" . ui_buttonoff_bitmap
		dc = 0
	}
	else
	{
		GuiControl,, buttondc, % "HBITMAP:*" . ui_buttonon_bitmap
		dc = 1 
	}
return

;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><> Button toggle down images

buttontoggle_down:
GuiControl,,gui_button_toggle, % "HBITMAP:*" . ui_buttontoggle_down_bitmap
	Loop
	{
		LM:=GetKeyState("LButton")
		if(LM=False)
		{
			break
		}
	}
GuiControl,,gui_button_toggle, % "HBITMAP:*" . ui_buttontoggle_bitmap

;Process, Exist, omes.skills.exe
Process, Exist, omes.skills.ahk
	if !ErrorLevel
	{
		;Run, omes.skills.exe
		Run, omes.skills.ahk
	}
	else if ErrorLevel = 1
	{
		msgbox Omes.skills.exe not found!
	}
return

;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><> Button toggle autopot ui

buttonautopot_down:
GuiControl,,gui_button_autopot, % "HBITMAP:*" . ui_button_autopot_down_bitmap
	Loop
	{
		LM:=GetKeyState("LButton")
		if(LM=False)
		{
			break
		}
	}
GuiControl,,gui_button_autopot, % "HBITMAP:*" . ui_button_autopot_bitmap

;Process, Exist, omes.skills.exe
Process, Exist, omes.autopot.ahk
	if !ErrorLevel
	{
		;Run, omes.skills.exe
		Run, omes.autopot.ahk
	}
	else if ErrorLevel = 1
	{
		msgbox Omes.autopot.exe not found!
	}
return


;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><> buttonkillswitch

;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><> buttonkillswitch

buttonkill_down:

		LM:=GetKeyState("LButton")
		Sendinput {Blind}{Alt up}
		Sendinput {Blind}{Space up}
		Sendinput {Blind}{Control up}
		Sendinput {Blind}{Up up}
		Sendinput {Blind}{Down up}
		Sendinput {Blind}{Left up}
		Sendinput {Blind}{Right up}
		
		GuiControl,, buttonautopot,  % "HBITMAP:*" . ui_buttonoff_bitmap
		potion = 0
		
		GuiControl,, buttonmovement,  % "HBITMAP:*" . ui_buttonoff_bitmap
		movement = 0
		
		GuiControl,, buttonnav,  % "HBITMAP:*" . ui_buttonoff_bitmap
		navigation = 0
		

GuiControl,,gui_button_close, % "HBITMAP:*" . ui_buttonkillswitch_down_bitmap
	Loop
	{
		LM:=GetKeyState("LButton")
		if(LM=False)
		{
			break
		}
	}
GuiControl,,gui_button_close, % "HBITMAP:*" . ui_buttonkillswitch_bitmap

return
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>


guiclose:
ExitApp
return


; script commands
^r::Reload
^p::Pause
^z::ExitApp, [ ExitCode]
































class CustomSlider_reverse
{
	__New(Options := "", val := "", hBitmap_thumb := "", ShowTooltip := false) {
		if !RegExMatch(Options, "i)\bBackground\w+\b") {                                      ;i)turns off case-sensitivity
			if RegExMatch(Options, "i)\bc\K\w+", bkColor)
				bkOpt := "Background" bkColor
		}
		Gui, Add, Progress, h1 %Options% %bkOpt% hwndHPROG Disabled +E0x00400000, % val       ;-E0x200  Left to right    +E0x00400000 triggers backwards progress

		Gui, Add, Text, xp yp-10 h24 wp BackgroundTrans HWNDhpgTrigger,  ;determins slider position

		if RegExMatch(Options, "i)\bRange\K([\d-]+)-([\d-]+)", rng)
			this.rng_radio := Abs(rng2 - rng1)/100
		else
			this.rng_radio := 1

		GuiControlGet, pg, Pos, %HPROG%
		x := pgW * (val/this.rng_radio/100) + pgX

		Gui, Add, Pic, x%x% yp w8 h-20 HWNDhBtn, % "HBITMAP:" hBitmap_thumb  ;creates the ui for the slider and input ??? gui adds the slider0
		this.hProg := HPROG
		this.hBtn := hBtn
		this.pgVal := val
		this.ShowTooltip := ShowTooltip
		; this.hRightText := hRightText

		fn := this.OnClick_reverse.Bind(this)
		GuiControl, +g, %hBtn%, %fn%
		GuiControl, +g, %hpgTrigger%, %fn%
	}

	OnClick_reverse() {
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
		R1 := NumGet(R, 4, "Int")
		R2 := NumGet(R, 0, "Int")
		
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
Create_buttonautopot_png(NewHandle = False) {
Static hBitmap := 0
Ptr := A_PtrSize ? "Ptr" : "UInt"
UPtr := A_PtrSize ? "UPtr" : "UInt"
If (NewHandle)
   hBitmap := 0
If (hBitmap)
   Return hBitmap
VarSetCapacity(B64, 6016 << !!A_IsUnicode)
B64 := "iVBORw0KGgoAAAANSUhEUgAAAJsAAAAZCAIAAACpe8sIAAAACXBIWXMAABcSAAAXEgFnn9JSAAANc2lUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNi4wLWMwMDYgNzkuMTY0NjQ4LCAyMDIxLzAxLzEyLTE1OjUyOjI5ICAgICAgICAiPiA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPiA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtbG5zOnBob3Rvc2hvcD0iaHR0cDovL25zLmFkb2JlLmNvbS9waG90b3Nob3AvMS4wLyIgeG1sbnM6ZGM9Imh0dHA6Ly9wdXJsLm9yZy9kYy9lbGVtZW50cy8xLjEvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RFdnQ9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZUV2ZW50IyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtbG5zOnRpZmY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vdGlmZi8xLjAvIiB4bWxuczpleGlmPSJodHRwOi8vbnMuYWRvYmUuY29tL2V4aWYvMS4wLyIgeG1wOkNyZWF0b3JUb29sPSJBZG9iZSBQaG90b3Nob3AgMjIuMiAoV2luZG93cykiIHhtcDpDcmVhdGVEYXRlPSIyMDIxLTA3LTMwVDA5OjA2OjQ4LTA3OjAwIiB4bXA6TWV0YWRhdGFEYXRlPSIyMDIxLTA4LTExVDE1OjUyOjM2LTA3OjAwIiB4bXA6TW9kaWZ5RGF0ZT0iMjAyMS0wOC0xMVQxNTo1MjozNi0wNzowMCIgcGhvdG9zaG9wOkNvbG9yTW9kZT0iMyIgZGM6Zm9ybWF0PSJpbWFnZS9wbmciIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6ZjJiMDE3MzQtYWNmNy0xYzQzLWFjYmQtMDAwNWU0NzQxNzRmIiB4bXBNTTpEb2N1bWVudElEPSJhZG9iZTpkb2NpZDpwaG90b3Nob3A6NzE1ZjQwZDUtYmIzZC1hNDQwLTk2ZGUtMzk5NWJhYWUxMWZiIiB4bXBNTTpPcmlnaW5hbERvY3VtZW50SUQ9InhtcC5kaWQ6ZGRhN2Q2MDUtMWI2Ny04ODQ1LTg4NTYtMjNkYzQ2NjVmNmQ0IiB0aWZmOk9yaWVudGF0aW9uPSIxIiB0aWZmOlhSZXNvbHV0aW9uPSIxNTAwMDAwLzEwMDAwIiB0aWZmOllSZXNvbHV0aW9uPSIxNTAwMDAwLzEwMDAwIiB0aWZmOlJlc29sdXRpb25Vbml0PSIyIiBleGlmOkNvbG9yU3BhY2U9IjY1NTM1IiBleGlmOlBpeGVsWERpbWVuc2lvbj0iNDE1IiBleGlmOlBpeGVsWURpbWVuc2lvbj0iNTUwIj4gPHBob3Rvc2hvcDpUZXh0TGF5ZXJzPiA8cmRmOkJhZz4gPHJkZjpsaSBwaG90b3Nob3A6TGF5ZXJOYW1lPSJUb2dnbGUgU2tpbGwgVUkiIHBob3Rvc2hvcDpMYXllclRleHQ9IlRvZ2dsZSBTa2lsbCBVSSIvPiA8cmRmOmxpIHBob3Rvc2hvcDpMYXllck5hbWU9IlRvZ2dsZSBBdXRvcG90IiBwaG90b3Nob3A6TGF5ZXJUZXh0PSJUb2dnbGUgQXV0b3BvdCIvPiA8cmRmOmxpIHBob3Rvc2hvcDpMYXllck5hbWU9IlRvZ2dsZSBLaWxsc3dpdGNoIiBwaG90b3Nob3A6TGF5ZXJUZXh0PSJUb2dnbGUgS2lsbHN3aXRjaCIvPiA8cmRmOmxpIHBob3Rvc2hvcDpMYXllck5hbWU9IkF1dG9wb3QiIHBob3Rvc2hvcDpMYXllclRleHQ9IkF1dG9wb3QiLz4gPHJkZjpsaSBwaG90b3Nob3A6TGF5ZXJOYW1lPSJYIiBwaG90b3Nob3A6TGF5ZXJUZXh0PSJYIi8+IDwvcmRmOkJhZz4gPC9waG90b3Nob3A6VGV4dExheWVycz4gPHBob3Rvc2hvcDpEb2N1bWVudEFuY2VzdG9ycz4gPHJkZjpCYWc+IDxyZGY6bGk+YWRvYmU6ZG9jaWQ6cGhvdG9zaG9wOjNlMDExZWE3LTcxNjMtN2Y0Ny04YTYxLTczMWMxODgzZTE4MTwvcmRmOmxpPiA8cmRmOmxpPmFkb2JlOmRvY2lkOnBob3Rvc2hvcDo4YmI4MTYwZi05ZWY4LWRiNDEtYjRhNi0zZGRkMTFmMTk1ZTM8L3JkZjpsaT4gPHJkZjpsaT5hZG9iZTpkb2NpZDpwaG90b3Nob3A6OTIwNzhlMjUtNmQyNy1hNDQwLWE2ZTEtNzFhNTk5ZmQ0NGE5PC9yZGY6bGk+IDwvcmRmOkJhZz4gPC9waG90b3Nob3A6RG9jdW1lbnRBbmNlc3RvcnM+IDx4bXBNTTpIaXN0b3J5PiA8cmRmOlNlcT4gPHJkZjpsaSBzdEV2dDphY3Rpb249ImNyZWF0ZWQiIHN0RXZ0Omluc3RhbmNlSUQ9InhtcC5paWQ6ZGRhN2Q2MDUtMWI2Ny04ODQ1LTg4NTYtMjNkYzQ2NjVmNmQ0IiBzdEV2dDp3aGVuPSIyMDIxLTA3LTMwVDA5OjA2OjQ4LTA3OjAwIiBzdEV2dDpzb2Z0d2FyZUFnZW50PSJBZG9iZSBQaG90b3Nob3AgMjIuMiAoV2luZG93cykiLz4gPHJkZjpsaSBzdEV2dDphY3Rpb249InNhdmVkIiBzdEV2dDppbnN0YW5jZUlEPSJ4bXAuaWlkOmQwZWQ5OGIxLWM5NWYtZTc0NC1hYmJjLTBkZGFjZmE5MmQxNCIgc3RFdnQ6d2hlbj0iMjAyMS0wNy0zMFQxMDoxOTowOC0wNzowMCIgc3RFdnQ6c29mdHdhcmVBZ2VudD0iQWRvYmUgUGhvdG9zaG9wIDIyLjIgKFdpbmRvd3MpIiBzdEV2dDpjaGFuZ2VkPSIvIi8+IDxyZGY6bGkgc3RFdnQ6YWN0aW9uPSJzYXZlZCIgc3RFdnQ6aW5zdGFuY2VJRD0ieG1wLmlpZDo3Y2QzNjI4Ny0yODA4LWEwNGEtYTRmNC0zYTE3ODBmMzJhZmMiIHN0RXZ0OndoZW49IjIwMjEtMDgtMTFUMTU6NTI6MzYtMDc6MDAiIHN0RXZ0OnNvZnR3YXJlQWdlbnQ9IkFkb2JlIFBob3Rvc2hvcCAyMi4yIChXaW5kb3dzKSIgc3RFdnQ6Y2hhbmdlZD0iLyIvPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0iY29udmVydGVkIiBzdEV2dDpwYXJhbWV0ZXJzPSJmcm9tIGFwcGxpY2F0aW9uL3ZuZC5hZG9iZS5waG90b3Nob3AgdG8gaW1hZ2UvcG5nIi8+IDxyZGY6bGkgc3RFdnQ6YWN0aW9uPSJkZXJpdmVkIiBzdEV2dDpwYXJhbWV0ZXJzPSJjb252ZXJ0ZWQgZnJvbSBhcHBsaWNhdGlvbi92bmQuYWRvYmUucGhvdG9zaG9wIHRvIGltYWdlL3BuZyIvPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0ic2F2ZWQiIHN0RXZ0Omluc3RhbmNlSUQ9InhtcC5paWQ6ZjJiMDE3MzQtYWNmNy0xYzQzLWFjYmQtMDAwNWU0NzQxNzRmIiBzdEV2dDp3aGVuPSIyMDIxLTA4LTExVDE1OjUyOjM2LTA3OjAwIiBzdEV2dDpzb2Z0d2FyZUFnZW50PSJBZG9iZSBQaG90b3Nob3AgMjIuMiAoV2luZG93cykiIHN0RXZ0OmNoYW5nZWQ9Ii8iLz4gPC9yZGY6U2VxPiA8L3htcE1NOkhpc3Rvcnk+IDx4bXBNTTpEZXJpdmVkRnJvbSBzdFJlZjppbnN0YW5jZUlEPSJ4bXAuaWlkOjdjZDM2Mjg3LTI4MDgtYTA0YS1hNGY0LTNhMTc4MGYzMmFmYyIgc3RSZWY6ZG9jdW1lbnRJRD0iYWRvYmU6ZG9jaWQ6cGhvdG9zaG9wOjhiYjgxNjBmLTllZjgtZGI0MS1iNGE2LTNkZGQxMWYxOTVlMyIgc3RSZWY6b3JpZ2luYWxEb2N1bWVudElEPSJ4bXAuZGlkOmRkYTdkNjA1LTFiNjctODg0NS04ODU2LTIzZGM0NjY1ZjZkNCIvPiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/PiRZdoEAAAPSSURBVGiB7Zk/TPJOGMef95d3KH9isCYChkGIjmqicaDFsQRWdFFkZNTBzY3oAi4mbsQN6+aO8UZKFxOispicApNGE0hjIrLdOxzp25/8EX601J/pZ7o+ef58rw+9u3AAFj+LXwCwvLxstgwLfSiVSr/pSFEUU5VY6IDL5QKAf8yWYaEzVkd/GlZHfxrtfZQQYq4OC734bXQBv9/v9Xq1lufn52q1OkpOjuNkWf5vGu7v7xuNRh9nlmV9Pt/d3d0oClWGlTo6hneU47i5uTmGYTweT61WA4BcLjdiwmQyOfhrCofDm5ubtDTDMIlE4ujoqM9Pamdn5+HhQZeODitVFwxfdUVRBACe55PJZCqV0ivt4IKDwWCxWDw9PaWP6XQ6GAxWKpX+yXV8IWPe0Qz/RjthWXZ7e5tlWQBoNBqiKDYajaWlpUgkYrPZAABjfH5+3stTm6prVCfNZlMdt1otOuB5fmVl5eTkBADi8TgA5PP53d1dj8fjcrl8Pl8mkwmHwxzHUX9Zlq+urnoV7TTG4/GFhQUASKVSauwYaJ91icFoq0Sj0UAggBBCCAUCgWg0SgiJRCIAgBCSZVkQhMXFxV6e2lRdo/qU1j7Ozs6yLEuN8/Pz1IgQUhSlUqnk83lCSCwWwxgjhDDGsVisT9FOY7lcLpfL1Hh9fW3EW+060zGddWl+tYqiKIVCAQAEQaB2m82GMabGra0tp9NJnTs9tanUqEQi0Wq13t7euk5EEAQaTsEYa1ur2uv1eqFQEAShXq/f3NwAAMMw1WpVkiRCiCAIn4pqpXYaJUlyOp0AQI1jw4RVV1/sdvv+/v7k5GQ6ne61OyKEzs7O6Pjg4GCM6kzgf/8PA8/zHx8fmUxmYmIiEAiYLcd8TNhHAYBhGDpmGAY0SyghhJ6DVGNXT22qUql0fHxMCNnb25uZmelfmvx7se1M3pnf4XAQQhwOh9bYVWpX4xje7aepjW/VVa93JElaXV2ly6CiKJIkAUCxWFxfXw+FQtoQrScA0IOGNhWNog61Wm2oHaurDMr7+zsdIITi8Tg9CSOEVIdQKESlqkW1+rVKxn+p1b4ffX19NbTM1NRUvV4f0FkUxWw2+6k9h4eHGONcLjdUqs7SX4Z/6aAqGba00UxPT/+9HzWaQSa2sbFht9vtdjsAPD09UePa2prf7wcAr9d7e3s7YKo+pb8M17EH42ynyjc6GdFeNpvNbDb7+PhIjW63mw4uLy8vLi5ME6cBY1wsFs1W0ZP2qvvy8mK2EotRcbvdpVLpG32jFrpgdfSn0T4ZqduVhYXF9+IPUvxQUVNewgEAAAAASUVORK5CYII="
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
Create_buttonautopotdown_png(NewHandle = False) {
Static hBitmap := 0
Ptr := A_PtrSize ? "Ptr" : "UInt"
UPtr := A_PtrSize ? "UPtr" : "UInt"
If (NewHandle)
   hBitmap := 0
If (hBitmap)
   Return hBitmap
VarSetCapacity(B64, 5972 << !!A_IsUnicode)
B64 := "iVBORw0KGgoAAAANSUhEUgAAAJsAAAAZCAIAAACpe8sIAAAACXBIWXMAABcSAAAXEgFnn9JSAAANc2lUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNi4wLWMwMDYgNzkuMTY0NjQ4LCAyMDIxLzAxLzEyLTE1OjUyOjI5ICAgICAgICAiPiA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPiA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtbG5zOnBob3Rvc2hvcD0iaHR0cDovL25zLmFkb2JlLmNvbS9waG90b3Nob3AvMS4wLyIgeG1sbnM6ZGM9Imh0dHA6Ly9wdXJsLm9yZy9kYy9lbGVtZW50cy8xLjEvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RFdnQ9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZUV2ZW50IyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtbG5zOnRpZmY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vdGlmZi8xLjAvIiB4bWxuczpleGlmPSJodHRwOi8vbnMuYWRvYmUuY29tL2V4aWYvMS4wLyIgeG1wOkNyZWF0b3JUb29sPSJBZG9iZSBQaG90b3Nob3AgMjIuMiAoV2luZG93cykiIHhtcDpDcmVhdGVEYXRlPSIyMDIxLTA3LTMwVDA5OjA2OjQ4LTA3OjAwIiB4bXA6TWV0YWRhdGFEYXRlPSIyMDIxLTA4LTExVDE1OjUyOjUwLTA3OjAwIiB4bXA6TW9kaWZ5RGF0ZT0iMjAyMS0wOC0xMVQxNTo1Mjo1MC0wNzowMCIgcGhvdG9zaG9wOkNvbG9yTW9kZT0iMyIgZGM6Zm9ybWF0PSJpbWFnZS9wbmciIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6MTgwNTllOTMtMGVlNS00ZDQ1LTg1NTctZGQxMDllZWY2YWYzIiB4bXBNTTpEb2N1bWVudElEPSJhZG9iZTpkb2NpZDpwaG90b3Nob3A6YzRhOTAxMDItZDU0OS00MTRjLTkxYzAtYmQ0MzRlYzRkMmQwIiB4bXBNTTpPcmlnaW5hbERvY3VtZW50SUQ9InhtcC5kaWQ6ZGRhN2Q2MDUtMWI2Ny04ODQ1LTg4NTYtMjNkYzQ2NjVmNmQ0IiB0aWZmOk9yaWVudGF0aW9uPSIxIiB0aWZmOlhSZXNvbHV0aW9uPSIxNTAwMDAwLzEwMDAwIiB0aWZmOllSZXNvbHV0aW9uPSIxNTAwMDAwLzEwMDAwIiB0aWZmOlJlc29sdXRpb25Vbml0PSIyIiBleGlmOkNvbG9yU3BhY2U9IjY1NTM1IiBleGlmOlBpeGVsWERpbWVuc2lvbj0iNDE1IiBleGlmOlBpeGVsWURpbWVuc2lvbj0iNTUwIj4gPHBob3Rvc2hvcDpUZXh0TGF5ZXJzPiA8cmRmOkJhZz4gPHJkZjpsaSBwaG90b3Nob3A6TGF5ZXJOYW1lPSJUb2dnbGUgU2tpbGwgVUkiIHBob3Rvc2hvcDpMYXllclRleHQ9IlRvZ2dsZSBTa2lsbCBVSSIvPiA8cmRmOmxpIHBob3Rvc2hvcDpMYXllck5hbWU9IlRvZ2dsZSBBdXRvcG90IiBwaG90b3Nob3A6TGF5ZXJUZXh0PSJUb2dnbGUgQXV0b3BvdCIvPiA8cmRmOmxpIHBob3Rvc2hvcDpMYXllck5hbWU9IlRvZ2dsZSBLaWxsc3dpdGNoIiBwaG90b3Nob3A6TGF5ZXJUZXh0PSJUb2dnbGUgS2lsbHN3aXRjaCIvPiA8cmRmOmxpIHBob3Rvc2hvcDpMYXllck5hbWU9IkF1dG9wb3QiIHBob3Rvc2hvcDpMYXllclRleHQ9IkF1dG9wb3QiLz4gPHJkZjpsaSBwaG90b3Nob3A6TGF5ZXJOYW1lPSJYIiBwaG90b3Nob3A6TGF5ZXJUZXh0PSJYIi8+IDwvcmRmOkJhZz4gPC9waG90b3Nob3A6VGV4dExheWVycz4gPHBob3Rvc2hvcDpEb2N1bWVudEFuY2VzdG9ycz4gPHJkZjpCYWc+IDxyZGY6bGk+YWRvYmU6ZG9jaWQ6cGhvdG9zaG9wOjNlMDExZWE3LTcxNjMtN2Y0Ny04YTYxLTczMWMxODgzZTE4MTwvcmRmOmxpPiA8cmRmOmxpPmFkb2JlOmRvY2lkOnBob3Rvc2hvcDo4YmI4MTYwZi05ZWY4LWRiNDEtYjRhNi0zZGRkMTFmMTk1ZTM8L3JkZjpsaT4gPHJkZjpsaT5hZG9iZTpkb2NpZDpwaG90b3Nob3A6OTIwNzhlMjUtNmQyNy1hNDQwLWE2ZTEtNzFhNTk5ZmQ0NGE5PC9yZGY6bGk+IDwvcmRmOkJhZz4gPC9waG90b3Nob3A6RG9jdW1lbnRBbmNlc3RvcnM+IDx4bXBNTTpIaXN0b3J5PiA8cmRmOlNlcT4gPHJkZjpsaSBzdEV2dDphY3Rpb249ImNyZWF0ZWQiIHN0RXZ0Omluc3RhbmNlSUQ9InhtcC5paWQ6ZGRhN2Q2MDUtMWI2Ny04ODQ1LTg4NTYtMjNkYzQ2NjVmNmQ0IiBzdEV2dDp3aGVuPSIyMDIxLTA3LTMwVDA5OjA2OjQ4LTA3OjAwIiBzdEV2dDpzb2Z0d2FyZUFnZW50PSJBZG9iZSBQaG90b3Nob3AgMjIuMiAoV2luZG93cykiLz4gPHJkZjpsaSBzdEV2dDphY3Rpb249InNhdmVkIiBzdEV2dDppbnN0YW5jZUlEPSJ4bXAuaWlkOmQwZWQ5OGIxLWM5NWYtZTc0NC1hYmJjLTBkZGFjZmE5MmQxNCIgc3RFdnQ6d2hlbj0iMjAyMS0wNy0zMFQxMDoxOTowOC0wNzowMCIgc3RFdnQ6c29mdHdhcmVBZ2VudD0iQWRvYmUgUGhvdG9zaG9wIDIyLjIgKFdpbmRvd3MpIiBzdEV2dDpjaGFuZ2VkPSIvIi8+IDxyZGY6bGkgc3RFdnQ6YWN0aW9uPSJzYXZlZCIgc3RFdnQ6aW5zdGFuY2VJRD0ieG1wLmlpZDo3NGNlMGE5NC01OWNjLTY3NGEtYjNhNC0yOTg2ZDRjMGIyYjYiIHN0RXZ0OndoZW49IjIwMjEtMDgtMTFUMTU6NTI6NTAtMDc6MDAiIHN0RXZ0OnNvZnR3YXJlQWdlbnQ9IkFkb2JlIFBob3Rvc2hvcCAyMi4yIChXaW5kb3dzKSIgc3RFdnQ6Y2hhbmdlZD0iLyIvPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0iY29udmVydGVkIiBzdEV2dDpwYXJhbWV0ZXJzPSJmcm9tIGFwcGxpY2F0aW9uL3ZuZC5hZG9iZS5waG90b3Nob3AgdG8gaW1hZ2UvcG5nIi8+IDxyZGY6bGkgc3RFdnQ6YWN0aW9uPSJkZXJpdmVkIiBzdEV2dDpwYXJhbWV0ZXJzPSJjb252ZXJ0ZWQgZnJvbSBhcHBsaWNhdGlvbi92bmQuYWRvYmUucGhvdG9zaG9wIHRvIGltYWdlL3BuZyIvPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0ic2F2ZWQiIHN0RXZ0Omluc3RhbmNlSUQ9InhtcC5paWQ6MTgwNTllOTMtMGVlNS00ZDQ1LTg1NTctZGQxMDllZWY2YWYzIiBzdEV2dDp3aGVuPSIyMDIxLTA4LTExVDE1OjUyOjUwLTA3OjAwIiBzdEV2dDpzb2Z0d2FyZUFnZW50PSJBZG9iZSBQaG90b3Nob3AgMjIuMiAoV2luZG93cykiIHN0RXZ0OmNoYW5nZWQ9Ii8iLz4gPC9yZGY6U2VxPiA8L3htcE1NOkhpc3Rvcnk+IDx4bXBNTTpEZXJpdmVkRnJvbSBzdFJlZjppbnN0YW5jZUlEPSJ4bXAuaWlkOjc0Y2UwYTk0LTU5Y2MtNjc0YS1iM2E0LTI5ODZkNGMwYjJiNiIgc3RSZWY6ZG9jdW1lbnRJRD0iYWRvYmU6ZG9jaWQ6cGhvdG9zaG9wOjhiYjgxNjBmLTllZjgtZGI0MS1iNGE2LTNkZGQxMWYxOTVlMyIgc3RSZWY6b3JpZ2luYWxEb2N1bWVudElEPSJ4bXAuZGlkOmRkYTdkNjA1LTFiNjctODg0NS04ODU2LTIzZGM0NjY1ZjZkNCIvPiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/PjOqqOsAAAOxSURBVGiB7ZnfS/peGMef75fYZjSwSQWTumiCDElEdyOJF+VVXnQjddE/4f/Sf1HRRUjQTUQgQY1DEJaBCaVH6aKEtIbenO/FsX2GM8uPm+sre12dPTw/3uc8ena2AbhMFv8AQDQadVqGizUghKboaHl52VkpLqNTLpcB4F+nZbhYjNvRScPt6KTRvY8SQpzV4WIVU3YXEARhdnbWaGk0Gq+vr6PklCTp4eHh7zTUajVN0wY4ezweQRAwxqMo1BlW6ujY3tFgMOj3+1mWFQShXq8DwOnp6SgJJUna2NjY3d39oX8oFFpbW6OlWZadmZnZ398f8JNKp9MYY0s6OqxUS7C9oxcXF/A5t4ODA7vLmZFl+ebm5uzsjF7u7OwEg0GqaiKxvaNmPB5PMpnkeR4Ams3m+fm5pml+vz8WizEMAwAYY7rifT2NqfpGmWm32+axJEmBQODk5AQA4vE4AFxfX6fTaZ/Px/P83Nzc0dFRKBSSZZn6393dFQqFr4qajfF4nD7lZzIZPXYMdM+6xH70KpFIRBRFhBBCSBTFSCRCCInFYgCAELq9vVUURRTFrzyNqfpGmesaJ6hfzs/P8zxPjX6/n9oRQq1Wq1arqapKCEkkEhhjhBDGOJFIDChqNj4+PtJHfoRQuVy2fkG/mOlYz7p6lWazWSqV4PMFJCGEYRiMMTWur69zHEedzZ7GVHrU6upqp9PRNK3vRBRFURRFv8QY9+ShvL+/l0qlaDT69vZWrVZp/ufnZyqAYZieokapZmOpVOI4DgCocWw4sOtaC8uym5ubPM/v7e29vLz09VFVNZ/P0/HW1tYY1TnA//4Nw8rKSqfTOTw85DjO5/M5Lcd5HLiP0j2qZwCf25rH4xnsaUwFAPf398fHx4SQTCbj9XoH1/1WRo8DALAsSwhhWdZY1Cz1K/3jWVu9Foxz1221WnRQLBZlWc5ms9RYLBYBoFAoJJPJcDhsDDF6wue3BWMqGkUd6vX6UHesvjIo+nn46uoqlUqlUik61h3C4TCVqhc16jcq0aWOje730aWlJVvLTE9Pf3x8/NA5m83mcrme9mxvb1er1Xw+P1Qqc+lvw7910JUMW9punp6e/nwftZufTExRFJZl6f7WaDSoMRAILCwsAIDP56Ov04Zdox7/b8Mt7ME426nzi05GtJftdjuXy+mnVq/XSweXl5eqqjqlzUi1WjVu0b+N7q67uLjotBKXUalUKgihX/QfdbEEt6OTRvdkVKlUnNXh4uLSn/8AWGZmJsWQVt0AAAAASUVORK5CYII="
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





;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><> UI
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><> UI
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><> UI
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><> UI





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
; ##################################################################################
; # This #Include file was generated by Image2Include.ahk, you must not change it! #
; ##################################################################################

Create_uiupdate_png(NewHandle = False) {
Static hBitmap := 0
Ptr := A_PtrSize ? "Ptr" : "UInt"
UPtr := A_PtrSize ? "UPtr" : "UInt"
If (NewHandle)
   hBitmap := 0
If (hBitmap)
   Return hBitmap
VarSetCapacity(B64, 19644 << !!A_IsUnicode)
B64 := "iVBORw0KGgoAAAANSUhEUgAAAZ8AAAHdCAIAAABNEOOkAAAACXBIWXMAABcSAAAXEgFnn9JSAAANc2lUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNi4wLWMwMDYgNzkuMTY0NjQ4LCAyMDIxLzAxLzEyLTE1OjUyOjI5ICAgICAgICAiPiA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPiA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtbG5zOnBob3Rvc2hvcD0iaHR0cDovL25zLmFkb2JlLmNvbS9waG90b3Nob3AvMS4wLyIgeG1sbnM6ZGM9Imh0dHA6Ly9wdXJsLm9yZy9kYy9lbGVtZW50cy8xLjEvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RFdnQ9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZUV2ZW50IyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtbG5zOnRpZmY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vdGlmZi8xLjAvIiB4bWxuczpleGlmPSJodHRwOi8vbnMuYWRvYmUuY29tL2V4aWYvMS4wLyIgeG1wOkNyZWF0b3JUb29sPSJBZG9iZSBQaG90b3Nob3AgMjIuMiAoV2luZG93cykiIHhtcDpDcmVhdGVEYXRlPSIyMDIxLTA3LTMwVDA5OjA2OjQ4LTA3OjAwIiB4bXA6TWV0YWRhdGFEYXRlPSIyMDIxLTA4LTExVDE2OjA1OjExLTA3OjAwIiB4bXA6TW9kaWZ5RGF0ZT0iMjAyMS0wOC0xMVQxNjowNToxMS0wNzowMCIgcGhvdG9zaG9wOkNvbG9yTW9kZT0iMyIgZGM6Zm9ybWF0PSJpbWFnZS9wbmciIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6Yjc3OTkxZGQtYjJjOS1kYTRkLThiZmEtMDZjZmQxOWZjYjMxIiB4bXBNTTpEb2N1bWVudElEPSJhZG9iZTpkb2NpZDpwaG90b3Nob3A6Y2RhZGQ2M2EtMGEwNy1kYTRkLWJiNTAtOWNhZDI2YjM4MmYzIiB4bXBNTTpPcmlnaW5hbERvY3VtZW50SUQ9InhtcC5kaWQ6ZGRhN2Q2MDUtMWI2Ny04ODQ1LTg4NTYtMjNkYzQ2NjVmNmQ0IiB0aWZmOk9yaWVudGF0aW9uPSIxIiB0aWZmOlhSZXNvbHV0aW9uPSIxNTAwMDAwLzEwMDAwIiB0aWZmOllSZXNvbHV0aW9uPSIxNTAwMDAwLzEwMDAwIiB0aWZmOlJlc29sdXRpb25Vbml0PSIyIiBleGlmOkNvbG9yU3BhY2U9IjY1NTM1IiBleGlmOlBpeGVsWERpbWVuc2lvbj0iNDE1IiBleGlmOlBpeGVsWURpbWVuc2lvbj0iNTUwIj4gPHBob3Rvc2hvcDpUZXh0TGF5ZXJzPiA8cmRmOkJhZz4gPHJkZjpsaSBwaG90b3Nob3A6TGF5ZXJOYW1lPSJUb2dnbGUgU2tpbGwgVUkiIHBob3Rvc2hvcDpMYXllclRleHQ9IlRvZ2dsZSBTa2lsbCBVSSIvPiA8cmRmOmxpIHBob3Rvc2hvcDpMYXllck5hbWU9IlRvZ2dsZSBBdXRvcG90IiBwaG90b3Nob3A6TGF5ZXJUZXh0PSJUb2dnbGUgQXV0b3BvdCIvPiA8cmRmOmxpIHBob3Rvc2hvcDpMYXllck5hbWU9IlRvZ2dsZSBLaWxsc3dpdGNoIiBwaG90b3Nob3A6TGF5ZXJUZXh0PSJUb2dnbGUgS2lsbHN3aXRjaCIvPiA8cmRmOmxpIHBob3Rvc2hvcDpMYXllck5hbWU9IkF1dG9wb3QiIHBob3Rvc2hvcDpMYXllclRleHQ9IkF1dG9wb3QiLz4gPHJkZjpsaSBwaG90b3Nob3A6TGF5ZXJOYW1lPSJYIiBwaG90b3Nob3A6TGF5ZXJUZXh0PSJYIi8+IDwvcmRmOkJhZz4gPC9waG90b3Nob3A6VGV4dExheWVycz4gPHBob3Rvc2hvcDpEb2N1bWVudEFuY2VzdG9ycz4gPHJkZjpCYWc+IDxyZGY6bGk+YWRvYmU6ZG9jaWQ6cGhvdG9zaG9wOjNlMDExZWE3LTcxNjMtN2Y0Ny04YTYxLTczMWMxODgzZTE4MTwvcmRmOmxpPiA8cmRmOmxpPmFkb2JlOmRvY2lkOnBob3Rvc2hvcDo4YmI4MTYwZi05ZWY4LWRiNDEtYjRhNi0zZGRkMTFmMTk1ZTM8L3JkZjpsaT4gPHJkZjpsaT5hZG9iZTpkb2NpZDpwaG90b3Nob3A6OTIwNzhlMjUtNmQyNy1hNDQwLWE2ZTEtNzFhNTk5ZmQ0NGE5PC9yZGY6bGk+IDwvcmRmOkJhZz4gPC9waG90b3Nob3A6RG9jdW1lbnRBbmNlc3RvcnM+IDx4bXBNTTpIaXN0b3J5PiA8cmRmOlNlcT4gPHJkZjpsaSBzdEV2dDphY3Rpb249ImNyZWF0ZWQiIHN0RXZ0Omluc3RhbmNlSUQ9InhtcC5paWQ6ZGRhN2Q2MDUtMWI2Ny04ODQ1LTg4NTYtMjNkYzQ2NjVmNmQ0IiBzdEV2dDp3aGVuPSIyMDIxLTA3LTMwVDA5OjA2OjQ4LTA3OjAwIiBzdEV2dDpzb2Z0d2FyZUFnZW50PSJBZG9iZSBQaG90b3Nob3AgMjIuMiAoV2luZG93cykiLz4gPHJkZjpsaSBzdEV2dDphY3Rpb249InNhdmVkIiBzdEV2dDppbnN0YW5jZUlEPSJ4bXAuaWlkOmQwZWQ5OGIxLWM5NWYtZTc0NC1hYmJjLTBkZGFjZmE5MmQxNCIgc3RFdnQ6d2hlbj0iMjAyMS0wNy0zMFQxMDoxOTowOC0wNzowMCIgc3RFdnQ6c29mdHdhcmVBZ2VudD0iQWRvYmUgUGhvdG9zaG9wIDIyLjIgKFdpbmRvd3MpIiBzdEV2dDpjaGFuZ2VkPSIvIi8+IDxyZGY6bGkgc3RFdnQ6YWN0aW9uPSJzYXZlZCIgc3RFdnQ6aW5zdGFuY2VJRD0ieG1wLmlpZDo2Nzk5NGNkZS04OWFhLTU5NDktYTUzYy00YmQ0YjhjM2ViNTUiIHN0RXZ0OndoZW49IjIwMjEtMDgtMTFUMTY6MDU6MTEtMDc6MDAiIHN0RXZ0OnNvZnR3YXJlQWdlbnQ9IkFkb2JlIFBob3Rvc2hvcCAyMi4yIChXaW5kb3dzKSIgc3RFdnQ6Y2hhbmdlZD0iLyIvPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0iY29udmVydGVkIiBzdEV2dDpwYXJhbWV0ZXJzPSJmcm9tIGFwcGxpY2F0aW9uL3ZuZC5hZG9iZS5waG90b3Nob3AgdG8gaW1hZ2UvcG5nIi8+IDxyZGY6bGkgc3RFdnQ6YWN0aW9uPSJkZXJpdmVkIiBzdEV2dDpwYXJhbWV0ZXJzPSJjb252ZXJ0ZWQgZnJvbSBhcHBsaWNhdGlvbi92bmQuYWRvYmUucGhvdG9zaG9wIHRvIGltYWdlL3BuZyIvPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0ic2F2ZWQiIHN0RXZ0Omluc3RhbmNlSUQ9InhtcC5paWQ6Yjc3OTkxZGQtYjJjOS1kYTRkLThiZmEtMDZjZmQxOWZjYjMxIiBzdEV2dDp3aGVuPSIyMDIxLTA4LTExVDE2OjA1OjExLTA3OjAwIiBzdEV2dDpzb2Z0d2FyZUFnZW50PSJBZG9iZSBQaG90b3Nob3AgMjIuMiAoV2luZG93cykiIHN0RXZ0OmNoYW5nZWQ9Ii8iLz4gPC9yZGY6U2VxPiA8L3htcE1NOkhpc3Rvcnk+IDx4bXBNTTpEZXJpdmVkRnJvbSBzdFJlZjppbnN0YW5jZUlEPSJ4bXAuaWlkOjY3OTk0Y2RlLTg5YWEtNTk0OS1hNTNjLTRiZDRiOGMzZWI1NSIgc3RSZWY6ZG9jdW1lbnRJRD0iYWRvYmU6ZG9jaWQ6cGhvdG9zaG9wOjhiYjgxNjBmLTllZjgtZGI0MS1iNGE2LTNkZGQxMWYxOTVlMyIgc3RSZWY6b3JpZ2luYWxEb2N1bWVudElEPSJ4bXAuZGlkOmRkYTdkNjA1LTFiNjctODg0NS04ODU2LTIzZGM0NjY1ZjZkNCIvPiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/Ptf6HZ8AACu+SURBVHic7Z07khxJDkSzaCOMsMqYjRkPwfsfZQ9BsxUpUKsVmt1d1ZUfIAIfdwSe0CSbVZkRgMMz8hdx++effzYNt227q77QXLNeUGl7nNRw2nil8k30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"
B64 .= "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"
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
Create_buttonkillswitch_png(NewHandle = False) {
Static hBitmap := 0
Ptr := A_PtrSize ? "Ptr" : "UInt"
UPtr := A_PtrSize ? "UPtr" : "UInt"
If (NewHandle)
   hBitmap := 0
If (hBitmap)
   Return hBitmap
VarSetCapacity(B64, 6220 << !!A_IsUnicode)
B64 := "iVBORw0KGgoAAAANSUhEUgAAAJsAAAAZCAIAAACpe8sIAAAACXBIWXMAABcSAAAXEgFnn9JSAAANH2lUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNi4wLWMwMDYgNzkuMTY0NjQ4LCAyMDIxLzAxLzEyLTE1OjUyOjI5ICAgICAgICAiPiA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPiA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtbG5zOnBob3Rvc2hvcD0iaHR0cDovL25zLmFkb2JlLmNvbS9waG90b3Nob3AvMS4wLyIgeG1sbnM6ZGM9Imh0dHA6Ly9wdXJsLm9yZy9kYy9lbGVtZW50cy8xLjEvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RFdnQ9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZUV2ZW50IyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtbG5zOnRpZmY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vdGlmZi8xLjAvIiB4bWxuczpleGlmPSJodHRwOi8vbnMuYWRvYmUuY29tL2V4aWYvMS4wLyIgeG1wOkNyZWF0b3JUb29sPSJBZG9iZSBQaG90b3Nob3AgMjIuMiAoV2luZG93cykiIHhtcDpDcmVhdGVEYXRlPSIyMDIxLTA3LTMwVDA5OjA2OjQ4LTA3OjAwIiB4bXA6TWV0YWRhdGFEYXRlPSIyMDIxLTA4LTAzVDIwOjA5OjI2LTA3OjAwIiB4bXA6TW9kaWZ5RGF0ZT0iMjAyMS0wOC0wM1QyMDowOToyNi0wNzowMCIgcGhvdG9zaG9wOkNvbG9yTW9kZT0iMyIgZGM6Zm9ybWF0PSJpbWFnZS9wbmciIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6NWE1ZDNmZDMtMTRmMi01MzQ0LTgxYTYtOTgzNzE0YzkzYmJjIiB4bXBNTTpEb2N1bWVudElEPSJhZG9iZTpkb2NpZDpwaG90b3Nob3A6NTA0OWM1MjQtZWUwZS1lZDQ1LWE4YzYtZDI0ODcwZjMwMGE3IiB4bXBNTTpPcmlnaW5hbERvY3VtZW50SUQ9InhtcC5kaWQ6ZGRhN2Q2MDUtMWI2Ny04ODQ1LTg4NTYtMjNkYzQ2NjVmNmQ0IiB0aWZmOk9yaWVudGF0aW9uPSIxIiB0aWZmOlhSZXNvbHV0aW9uPSIxNTAwMDAwLzEwMDAwIiB0aWZmOllSZXNvbHV0aW9uPSIxNTAwMDAwLzEwMDAwIiB0aWZmOlJlc29sdXRpb25Vbml0PSIyIiBleGlmOkNvbG9yU3BhY2U9IjY1NTM1IiBleGlmOlBpeGVsWERpbWVuc2lvbj0iNDE1IiBleGlmOlBpeGVsWURpbWVuc2lvbj0iNDYxIj4gPHBob3Rvc2hvcDpUZXh0TGF5ZXJzPiA8cmRmOkJhZz4gPHJkZjpsaSBwaG90b3Nob3A6TGF5ZXJOYW1lPSJUb2dnbGUgU2tpbGwgVUkiIHBob3Rvc2hvcDpMYXllclRleHQ9IlRvZ2dsZSBTa2lsbCBVSSIvPiA8cmRmOmxpIHBob3Rvc2hvcDpMYXllck5hbWU9IlRvZ2dsZSBLaWxsc3dpdGNoIiBwaG90b3Nob3A6TGF5ZXJUZXh0PSJUb2dnbGUgS2lsbHN3aXRjaCIvPiA8cmRmOmxpIHBob3Rvc2hvcDpMYXllck5hbWU9IkF1dG9wb3QiIHBob3Rvc2hvcDpMYXllclRleHQ9IkF1dG9wb3QiLz4gPHJkZjpsaSBwaG90b3Nob3A6TGF5ZXJOYW1lPSJYIiBwaG90b3Nob3A6TGF5ZXJUZXh0PSJYIi8+IDwvcmRmOkJhZz4gPC9waG90b3Nob3A6VGV4dExheWVycz4gPHBob3Rvc2hvcDpEb2N1bWVudEFuY2VzdG9ycz4gPHJkZjpCYWc+IDxyZGY6bGk+YWRvYmU6ZG9jaWQ6cGhvdG9zaG9wOjNlMDExZWE3LTcxNjMtN2Y0Ny04YTYxLTczMWMxODgzZTE4MTwvcmRmOmxpPiA8cmRmOmxpPmFkb2JlOmRvY2lkOnBob3Rvc2hvcDo4YmI4MTYwZi05ZWY4LWRiNDEtYjRhNi0zZGRkMTFmMTk1ZTM8L3JkZjpsaT4gPHJkZjpsaT5hZG9iZTpkb2NpZDpwaG90b3Nob3A6OTIwNzhlMjUtNmQyNy1hNDQwLWE2ZTEtNzFhNTk5ZmQ0NGE5PC9yZGY6bGk+IDwvcmRmOkJhZz4gPC9waG90b3Nob3A6RG9jdW1lbnRBbmNlc3RvcnM+IDx4bXBNTTpIaXN0b3J5PiA8cmRmOlNlcT4gPHJkZjpsaSBzdEV2dDphY3Rpb249ImNyZWF0ZWQiIHN0RXZ0Omluc3RhbmNlSUQ9InhtcC5paWQ6ZGRhN2Q2MDUtMWI2Ny04ODQ1LTg4NTYtMjNkYzQ2NjVmNmQ0IiBzdEV2dDp3aGVuPSIyMDIxLTA3LTMwVDA5OjA2OjQ4LTA3OjAwIiBzdEV2dDpzb2Z0d2FyZUFnZW50PSJBZG9iZSBQaG90b3Nob3AgMjIuMiAoV2luZG93cykiLz4gPHJkZjpsaSBzdEV2dDphY3Rpb249InNhdmVkIiBzdEV2dDppbnN0YW5jZUlEPSJ4bXAuaWlkOmQwZWQ5OGIxLWM5NWYtZTc0NC1hYmJjLTBkZGFjZmE5MmQxNCIgc3RFdnQ6d2hlbj0iMjAyMS0wNy0zMFQxMDoxOTowOC0wNzowMCIgc3RFdnQ6c29mdHdhcmVBZ2VudD0iQWRvYmUgUGhvdG9zaG9wIDIyLjIgKFdpbmRvd3MpIiBzdEV2dDpjaGFuZ2VkPSIvIi8+IDxyZGY6bGkgc3RFdnQ6YWN0aW9uPSJzYXZlZCIgc3RFdnQ6aW5zdGFuY2VJRD0ieG1wLmlpZDplMzQ5OGMyMC03ZGQ0LTczNGYtOGFiNi02MDI3ZGUwNzg2OGIiIHN0RXZ0OndoZW49IjIwMjEtMDgtMDNUMjA6MDk6MjYtMDc6MDAiIHN0RXZ0OnNvZnR3YXJlQWdlbnQ9IkFkb2JlIFBob3Rvc2hvcCAyMi4yIChXaW5kb3dzKSIgc3RFdnQ6Y2hhbmdlZD0iLyIvPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0iY29udmVydGVkIiBzdEV2dDpwYXJhbWV0ZXJzPSJmcm9tIGFwcGxpY2F0aW9uL3ZuZC5hZG9iZS5waG90b3Nob3AgdG8gaW1hZ2UvcG5nIi8+IDxyZGY6bGkgc3RFdnQ6YWN0aW9uPSJkZXJpdmVkIiBzdEV2dDpwYXJhbWV0ZXJzPSJjb252ZXJ0ZWQgZnJvbSBhcHBsaWNhdGlvbi92bmQuYWRvYmUucGhvdG9zaG9wIHRvIGltYWdlL3BuZyIvPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0ic2F2ZWQiIHN0RXZ0Omluc3RhbmNlSUQ9InhtcC5paWQ6NWE1ZDNmZDMtMTRmMi01MzQ0LTgxYTYtOTgzNzE0YzkzYmJjIiBzdEV2dDp3aGVuPSIyMDIxLTA4LTAzVDIwOjA5OjI2LTA3OjAwIiBzdEV2dDpzb2Z0d2FyZUFnZW50PSJBZG9iZSBQaG90b3Nob3AgMjIuMiAoV2luZG93cykiIHN0RXZ0OmNoYW5nZWQ9Ii8iLz4gPC9yZGY6U2VxPiA8L3htcE1NOkhpc3Rvcnk+IDx4bXBNTTpEZXJpdmVkRnJvbSBzdFJlZjppbnN0YW5jZUlEPSJ4bXAuaWlkOmUzNDk4YzIwLTdkZDQtNzM0Zi04YWI2LTYwMjdkZTA3ODY4YiIgc3RSZWY6ZG9jdW1lbnRJRD0iYWRvYmU6ZG9jaWQ6cGhvdG9zaG9wOjhiYjgxNjBmLTllZjgtZGI0MS1iNGE2LTNkZGQxMWYxOTVlMyIgc3RSZWY6b3JpZ2luYWxEb2N1bWVudElEPSJ4bXAuZGlkOmRkYTdkNjA1LTFiNjctODg0NS04ODU2LTIzZGM0NjY1ZjZkNCIvPiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/PkjWDmwAAAS+SURBVGiB7Zk/TPpaFMfPe/kNQoxIGyUQB0rC4CAmEB1AxxIYSBR1wmAcGB1kczEmLjBpXJSwCThpXIkdCx1JkMQBgjgYRRMbohHY+obru6+vlD9K+fHT9DPdHs/5nnN767mXFkDlZ/EXANjt9mGXoaIMuVzuFxrVarWhVqKiAOPj4wDw97DLUFEYdUV/GuqK/jQ+9lFBEIZbh4pS/BqEKEVRRqNRbHl8fKxUKv1oOp1OjuN6dCYIYmpq6vr6GgBsNhsAoDFBEDqdDlUi9vmUeCs2mw3pAABFUQDQYbJdHfpkIF3X6XTSNO3z+UKhEE3TNE33LxgKhXr339rampmZAQCCIDY3N+fn55F9fX09GAxKfD4rLmFpaWl7extf7u7uSp5mCV0d+mQgXTeZTAKAy+UKhUJ7e3tKyX6qSEEQBEHw+/3NZjMejyNjIpHQ6XRYB/l8QVzM5eXl7e2tJLyr2uC2uYF03VYIglhfXycIAgB4nk8mkzzPz87OejwejUYDAKVSKZVKtfMUS8lGyeJ2ux0Ox/HxMbZMT087HI6jo6N2IVi80WjE43Ge5ymK2tjYQM+ly+XC4YFAAABSqRRFUcvLy/l83uVyoW7k8/nMZnMqlQoEAlarFQAajUY6nc7n8yiLz+dDnhzHXV1dfemOtuWj6woDQKzs9XotFgvDMAzDWCwWr9crCILH4wEAhmE4jqNp2maztfMUS8lGtaYmSdLv99/c3IyOjmK72WwmCEL2X1MirtfrUWqTyWQ2m1vD0VKJHR4eHhiGAYBCocBxnM1mo2ma4zhk9Hg8OG+hUGAYplQq+f1+pe42nsgAVxTlwINarcayLMuy6P2UIAgajeb+/p5l2XQ6DQDo1st6iqVw1MTERLPZfH19lc1rt9ur1SpBEGtra9FoVDxn2TEW53meZdmTk5NEItE6iw7h5XKZZVkAqFQq5XJ5dHQUANLpNMuyxWKxWCxi50qlwrJspVIZGRnp8w5LZg2/resqi1ar3dnZ0ev1kUjk9vZW1iebzcZiMQAgSfLg4GBhYSGTyXRV5jjO7/efnp4CAMMwiURCkYIvLi4U0emFb/mGweVyNRqNaDQ6NjZmsVhkfer1Ohq8vLz0rlytViORSDAYPDs76/+IjiFJcmFhQSm1zvymfRQAcIcZGRmBfzcwjUYjCAI6B2GjrKdYKpfLHRwcCIIQDodNJlPn1EKbLVPWGA6HrVYrdsB/RdunRqPpXFurLApcWVlxu90d8ioCEhxs18WfdDKZzNzcHGpitVoNNcBsNruysiJ5eMWeAFAoFCRSKAo53N3doa2rlff3dzxuNptvb29oLD45Yx8szjBMIBBA51h0omFZ1u12Hx4eIp1arSaZBfz/yxXOJQnEjVdczCA+eX18H31+flZcmiTJ3jteMpmMxWKS5dnf3y+VSqenp5+Sak2NL8V2WeMXaJerq3+feVuZnJz87/voIOil3NXVVa1Wq9VqAeDh4QEZFxcX0asyo9GIfsN9duYSf3wptssav0C7XF39lV1OzJBPRmgt6/V6LBYrl8vIaDAY0CCdTp+fnw+tuO/JR9d9enoadiUq/WIwGHK53Lf89aLSAXVFfxofJyO8damoqPxZ/AOyiXnIrvm8lAAAAABJRU5ErkJggg=="
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
Create_buttonkillswitchdown_png(NewHandle = False) {
Static hBitmap := 0
Ptr := A_PtrSize ? "Ptr" : "UInt"
UPtr := A_PtrSize ? "UPtr" : "UInt"
If (NewHandle)
   hBitmap := 0
If (hBitmap)
   Return hBitmap
VarSetCapacity(B64, 6132 << !!A_IsUnicode)
B64 := "iVBORw0KGgoAAAANSUhEUgAAAJsAAAAZCAIAAACpe8sIAAAACXBIWXMAABcSAAAXEgFnn9JSAAANH2lUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNi4wLWMwMDYgNzkuMTY0NjQ4LCAyMDIxLzAxLzEyLTE1OjUyOjI5ICAgICAgICAiPiA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPiA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtbG5zOnBob3Rvc2hvcD0iaHR0cDovL25zLmFkb2JlLmNvbS9waG90b3Nob3AvMS4wLyIgeG1sbnM6ZGM9Imh0dHA6Ly9wdXJsLm9yZy9kYy9lbGVtZW50cy8xLjEvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RFdnQ9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZUV2ZW50IyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtbG5zOnRpZmY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vdGlmZi8xLjAvIiB4bWxuczpleGlmPSJodHRwOi8vbnMuYWRvYmUuY29tL2V4aWYvMS4wLyIgeG1wOkNyZWF0b3JUb29sPSJBZG9iZSBQaG90b3Nob3AgMjIuMiAoV2luZG93cykiIHhtcDpDcmVhdGVEYXRlPSIyMDIxLTA3LTMwVDA5OjA2OjQ4LTA3OjAwIiB4bXA6TWV0YWRhdGFEYXRlPSIyMDIxLTA4LTAzVDIwOjA5OjQxLTA3OjAwIiB4bXA6TW9kaWZ5RGF0ZT0iMjAyMS0wOC0wM1QyMDowOTo0MS0wNzowMCIgcGhvdG9zaG9wOkNvbG9yTW9kZT0iMyIgZGM6Zm9ybWF0PSJpbWFnZS9wbmciIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6YzQxOGQ3ZWUtZDA2YS0xNTRmLThhNzAtMjBjNWE0OGRmMjU5IiB4bXBNTTpEb2N1bWVudElEPSJhZG9iZTpkb2NpZDpwaG90b3Nob3A6MmFmY2Q0ZmUtY2U0OS0zYjQzLTkyY2EtMWVjNTA3NmRkNzRmIiB4bXBNTTpPcmlnaW5hbERvY3VtZW50SUQ9InhtcC5kaWQ6ZGRhN2Q2MDUtMWI2Ny04ODQ1LTg4NTYtMjNkYzQ2NjVmNmQ0IiB0aWZmOk9yaWVudGF0aW9uPSIxIiB0aWZmOlhSZXNvbHV0aW9uPSIxNTAwMDAwLzEwMDAwIiB0aWZmOllSZXNvbHV0aW9uPSIxNTAwMDAwLzEwMDAwIiB0aWZmOlJlc29sdXRpb25Vbml0PSIyIiBleGlmOkNvbG9yU3BhY2U9IjY1NTM1IiBleGlmOlBpeGVsWERpbWVuc2lvbj0iNDE1IiBleGlmOlBpeGVsWURpbWVuc2lvbj0iNDYxIj4gPHBob3Rvc2hvcDpUZXh0TGF5ZXJzPiA8cmRmOkJhZz4gPHJkZjpsaSBwaG90b3Nob3A6TGF5ZXJOYW1lPSJUb2dnbGUgU2tpbGwgVUkiIHBob3Rvc2hvcDpMYXllclRleHQ9IlRvZ2dsZSBTa2lsbCBVSSIvPiA8cmRmOmxpIHBob3Rvc2hvcDpMYXllck5hbWU9IlRvZ2dsZSBLaWxsc3dpdGNoIiBwaG90b3Nob3A6TGF5ZXJUZXh0PSJUb2dnbGUgS2lsbHN3aXRjaCIvPiA8cmRmOmxpIHBob3Rvc2hvcDpMYXllck5hbWU9IkF1dG9wb3QiIHBob3Rvc2hvcDpMYXllclRleHQ9IkF1dG9wb3QiLz4gPHJkZjpsaSBwaG90b3Nob3A6TGF5ZXJOYW1lPSJYIiBwaG90b3Nob3A6TGF5ZXJUZXh0PSJYIi8+IDwvcmRmOkJhZz4gPC9waG90b3Nob3A6VGV4dExheWVycz4gPHBob3Rvc2hvcDpEb2N1bWVudEFuY2VzdG9ycz4gPHJkZjpCYWc+IDxyZGY6bGk+YWRvYmU6ZG9jaWQ6cGhvdG9zaG9wOjNlMDExZWE3LTcxNjMtN2Y0Ny04YTYxLTczMWMxODgzZTE4MTwvcmRmOmxpPiA8cmRmOmxpPmFkb2JlOmRvY2lkOnBob3Rvc2hvcDo4YmI4MTYwZi05ZWY4LWRiNDEtYjRhNi0zZGRkMTFmMTk1ZTM8L3JkZjpsaT4gPHJkZjpsaT5hZG9iZTpkb2NpZDpwaG90b3Nob3A6OTIwNzhlMjUtNmQyNy1hNDQwLWE2ZTEtNzFhNTk5ZmQ0NGE5PC9yZGY6bGk+IDwvcmRmOkJhZz4gPC9waG90b3Nob3A6RG9jdW1lbnRBbmNlc3RvcnM+IDx4bXBNTTpIaXN0b3J5PiA8cmRmOlNlcT4gPHJkZjpsaSBzdEV2dDphY3Rpb249ImNyZWF0ZWQiIHN0RXZ0Omluc3RhbmNlSUQ9InhtcC5paWQ6ZGRhN2Q2MDUtMWI2Ny04ODQ1LTg4NTYtMjNkYzQ2NjVmNmQ0IiBzdEV2dDp3aGVuPSIyMDIxLTA3LTMwVDA5OjA2OjQ4LTA3OjAwIiBzdEV2dDpzb2Z0d2FyZUFnZW50PSJBZG9iZSBQaG90b3Nob3AgMjIuMiAoV2luZG93cykiLz4gPHJkZjpsaSBzdEV2dDphY3Rpb249InNhdmVkIiBzdEV2dDppbnN0YW5jZUlEPSJ4bXAuaWlkOmQwZWQ5OGIxLWM5NWYtZTc0NC1hYmJjLTBkZGFjZmE5MmQxNCIgc3RFdnQ6d2hlbj0iMjAyMS0wNy0zMFQxMDoxOTowOC0wNzowMCIgc3RFdnQ6c29mdHdhcmVBZ2VudD0iQWRvYmUgUGhvdG9zaG9wIDIyLjIgKFdpbmRvd3MpIiBzdEV2dDpjaGFuZ2VkPSIvIi8+IDxyZGY6bGkgc3RFdnQ6YWN0aW9uPSJzYXZlZCIgc3RFdnQ6aW5zdGFuY2VJRD0ieG1wLmlpZDo1ODBhZmVkMy1kNWI3LTExNDEtYTE0Ni02NDNmNGUwMDFmYzkiIHN0RXZ0OndoZW49IjIwMjEtMDgtMDNUMjA6MDk6NDEtMDc6MDAiIHN0RXZ0OnNvZnR3YXJlQWdlbnQ9IkFkb2JlIFBob3Rvc2hvcCAyMi4yIChXaW5kb3dzKSIgc3RFdnQ6Y2hhbmdlZD0iLyIvPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0iY29udmVydGVkIiBzdEV2dDpwYXJhbWV0ZXJzPSJmcm9tIGFwcGxpY2F0aW9uL3ZuZC5hZG9iZS5waG90b3Nob3AgdG8gaW1hZ2UvcG5nIi8+IDxyZGY6bGkgc3RFdnQ6YWN0aW9uPSJkZXJpdmVkIiBzdEV2dDpwYXJhbWV0ZXJzPSJjb252ZXJ0ZWQgZnJvbSBhcHBsaWNhdGlvbi92bmQuYWRvYmUucGhvdG9zaG9wIHRvIGltYWdlL3BuZyIvPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0ic2F2ZWQiIHN0RXZ0Omluc3RhbmNlSUQ9InhtcC5paWQ6YzQxOGQ3ZWUtZDA2YS0xNTRmLThhNzAtMjBjNWE0OGRmMjU5IiBzdEV2dDp3aGVuPSIyMDIxLTA4LTAzVDIwOjA5OjQxLTA3OjAwIiBzdEV2dDpzb2Z0d2FyZUFnZW50PSJBZG9iZSBQaG90b3Nob3AgMjIuMiAoV2luZG93cykiIHN0RXZ0OmNoYW5nZWQ9Ii8iLz4gPC9yZGY6U2VxPiA8L3htcE1NOkhpc3Rvcnk+IDx4bXBNTTpEZXJpdmVkRnJvbSBzdFJlZjppbnN0YW5jZUlEPSJ4bXAuaWlkOjU4MGFmZWQzLWQ1YjctMTE0MS1hMTQ2LTY0M2Y0ZTAwMWZjOSIgc3RSZWY6ZG9jdW1lbnRJRD0iYWRvYmU6ZG9jaWQ6cGhvdG9zaG9wOjhiYjgxNjBmLTllZjgtZGI0MS1iNGE2LTNkZGQxMWYxOTVlMyIgc3RSZWY6b3JpZ2luYWxEb2N1bWVudElEPSJ4bXAuZGlkOmRkYTdkNjA1LTFiNjctODg0NS04ODU2LTIzZGM0NjY1ZjZkNCIvPiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/PggA0IcAAAR9SURBVGiB7ZnfS/puFMfP58sH54SVTbCa0EVbSYThj4GTzMCkC7sIQuii67r2X+l/6EqkKwkiipBEKN1NaQYmUYkImZCRuZt9L57ad1+nZjmTYq+rZ4f3eZ+z53HPNgeg8bv4AwBOp3PQbWioA8/zf9FocnJysK1o9E6hUACAfwbdhobKaCv629BW9Lfxdh8VRXGwfWioRV+uUZIk6f9DkmSPnjRNdy/GcdxisaCxxWKRxjiOS53INZ8yVyL5AABJkp1P9kNBj/RlRa1Wq8Ph4DguGAw6HA6Hw9GjIU3TwWCwe/3KysrExAQA4Di+vLw8NTWF4j6fz+/3N2k+a96E0+lcW1uTDjc2NkZGRjroPxT0yN9+mCaTSXifqWg02o8SXeJ2uwVBOD4+RofxeBzHcXVL8DxfLpfV9eyFvqyoEhzHfT4fQRAAUKvV4vF4vV63WCwul0un0wFAsVhEv4OWSrlVy6yWzM7OWq3WWCwmRSiKYhhmf3+/XYpkLgjCwcFBvV4nSdLv96PfJU3TUrrH4wGAZDJJkqTH44lGozRNo92I4ziz2ZxMJj0eD9qQBUFIp9PFYhFV4TgOKS8vLzOZzNemtB1vu67YHyRnu91OURTP8zzPUxRlt9tFUXS5XADA83w2m2VZlqKodkq5VcssZd2hoSGv13tzc4NhmBQ3m80EQUgayVNpThAEKm00GsfHx5XpaKnkgsfHR57nAaBQKORyOYqiWJbNZrMo6HK5pFqFQoHn+WKx6PV6e59k+VnDNzzrSs61Wi2fz8P7n46iKOp0umKxiIJLS0t6vR6JlUq5lZQ1Pz8vCEK9Xm/Z/PT0dKlUIghicXGR47idnR1lSy3NHx4e8vl8tVqtVCqdU5rSK5UKSimXy5VKhWEYALi4uACA4eFhubhcLqMT1Ol0qs/8N+266oJh2OrqKkEQkUhEPu9yzs/Pj46OAMBgMGxubjIMgyaxM9lsdmFhwWazAUAqlUokEqo0nE6nVfHphh/5D4PNZhMEYXd3V6/Xm0ymlppGo4EGLy8v3TtXq9VIJLK9vX14eMiyrAq9AgCAwWBAl+w38E33UbTHNg3gfdtBz58dlHIrALi6utrb2xNFMRQKGY3GznWbDkFx75SPQ6HQ2NiYUonjOOqnc2/KMUp0u91Op7OzuHfQUvZ3131+fkaDXC43MzMTDodRMJfLAUAmk/H5fHNzc/IUuRLevyfIrVAWEpRKpXZ7qXSNAoAgCK+vr2j89PSk1EjmZ2dngUAgEAigMQDk8/lSqbS1tYV8arVa01nI0+W1mhLj8biyGXmiWrx9H0Xv2upiMBi63/HC4XAsFmtanvX19fv7+0Qi8SkrZWnpUB5vGfwC7Wp9qO+xrpLb29v/vo/2g27aZVkWwzAMwwCgWq2iIMMwo6OjAGAyma6vr7u06lBaOpTHWwa/QLtaH+rVXU6JAT8ZobVsNBqxWEx6ajUajWhwenqaSqUG1dsPZcDfXk5OTpRBdAPT+Bo/8u1FowPaiv423nbdu7u7wfahoaHRmn8BZ+ucCkYNZ00AAAAASUVORK5CYII="
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
Create_buttontoggle_png(NewHandle = False) {
Static hBitmap := 0
Ptr := A_PtrSize ? "Ptr" : "UInt"
UPtr := A_PtrSize ? "UPtr" : "UInt"
If (NewHandle)
   hBitmap := 0
If (hBitmap)
   Return hBitmap
VarSetCapacity(B64, 5728 << !!A_IsUnicode)
B64 := "iVBORw0KGgoAAAANSUhEUgAAAJsAAAAZCAIAAACpe8sIAAAACXBIWXMAABcSAAAXEgFnn9JSAAAMb2lUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNi4wLWMwMDYgNzkuMTY0NjQ4LCAyMDIxLzAxLzEyLTE1OjUyOjI5ICAgICAgICAiPiA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPiA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtbG5zOnBob3Rvc2hvcD0iaHR0cDovL25zLmFkb2JlLmNvbS9waG90b3Nob3AvMS4wLyIgeG1sbnM6ZGM9Imh0dHA6Ly9wdXJsLm9yZy9kYy9lbGVtZW50cy8xLjEvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RFdnQ9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZUV2ZW50IyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtbG5zOnRpZmY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vdGlmZi8xLjAvIiB4bWxuczpleGlmPSJodHRwOi8vbnMuYWRvYmUuY29tL2V4aWYvMS4wLyIgeG1wOkNyZWF0b3JUb29sPSJBZG9iZSBQaG90b3Nob3AgMjIuMiAoV2luZG93cykiIHhtcDpDcmVhdGVEYXRlPSIyMDIxLTA3LTMwVDA5OjA2OjQ4LTA3OjAwIiB4bXA6TWV0YWRhdGFEYXRlPSIyMDIxLTA4LTAxVDIxOjIwOjQ4LTA3OjAwIiB4bXA6TW9kaWZ5RGF0ZT0iMjAyMS0wOC0wMVQyMToyMDo0OC0wNzowMCIgcGhvdG9zaG9wOkNvbG9yTW9kZT0iMyIgZGM6Zm9ybWF0PSJpbWFnZS9wbmciIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6Yjg4Y2FiNDgtYWI2Zi1lMzQyLWE4NTMtYTczMDVjMjg4YzdjIiB4bXBNTTpEb2N1bWVudElEPSJhZG9iZTpkb2NpZDpwaG90b3Nob3A6ZjVmYjc1NDUtMjU5YS1iYjQ4LTg5MzItMGNhNDdlNzY1ODVjIiB4bXBNTTpPcmlnaW5hbERvY3VtZW50SUQ9InhtcC5kaWQ6ZGRhN2Q2MDUtMWI2Ny04ODQ1LTg4NTYtMjNkYzQ2NjVmNmQ0IiB0aWZmOk9yaWVudGF0aW9uPSIxIiB0aWZmOlhSZXNvbHV0aW9uPSIxNTAwMDAwLzEwMDAwIiB0aWZmOllSZXNvbHV0aW9uPSIxNTAwMDAwLzEwMDAwIiB0aWZmOlJlc29sdXRpb25Vbml0PSIyIiBleGlmOkNvbG9yU3BhY2U9IjY1NTM1IiBleGlmOlBpeGVsWERpbWVuc2lvbj0iNDE1IiBleGlmOlBpeGVsWURpbWVuc2lvbj0iNjc1Ij4gPHBob3Rvc2hvcDpUZXh0TGF5ZXJzPiA8cmRmOkJhZz4gPHJkZjpsaSBwaG90b3Nob3A6TGF5ZXJOYW1lPSJUb2dnbGUgU2tpbGwgVUkiIHBob3Rvc2hvcDpMYXllclRleHQ9IlRvZ2dsZSBTa2lsbCBVSSIvPiA8cmRmOmxpIHBob3Rvc2hvcDpMYXllck5hbWU9IkNsb3NlIiBwaG90b3Nob3A6TGF5ZXJUZXh0PSJDbG9zZSIvPiA8cmRmOmxpIHBob3Rvc2hvcDpMYXllck5hbWU9IkF1dG9wb3QiIHBob3Rvc2hvcDpMYXllclRleHQ9IkF1dG9wb3QiLz4gPHJkZjpsaSBwaG90b3Nob3A6TGF5ZXJOYW1lPSJYIiBwaG90b3Nob3A6TGF5ZXJUZXh0PSJYIi8+IDwvcmRmOkJhZz4gPC9waG90b3Nob3A6VGV4dExheWVycz4gPHBob3Rvc2hvcDpEb2N1bWVudEFuY2VzdG9ycz4gPHJkZjpCYWc+IDxyZGY6bGk+YWRvYmU6ZG9jaWQ6cGhvdG9zaG9wOjkyMDc4ZTI1LTZkMjctYTQ0MC1hNmUxLTcxYTU5OWZkNDRhOTwvcmRmOmxpPiA8L3JkZjpCYWc+IDwvcGhvdG9zaG9wOkRvY3VtZW50QW5jZXN0b3JzPiA8eG1wTU06SGlzdG9yeT4gPHJkZjpTZXE+IDxyZGY6bGkgc3RFdnQ6YWN0aW9uPSJjcmVhdGVkIiBzdEV2dDppbnN0YW5jZUlEPSJ4bXAuaWlkOmRkYTdkNjA1LTFiNjctODg0NS04ODU2LTIzZGM0NjY1ZjZkNCIgc3RFdnQ6d2hlbj0iMjAyMS0wNy0zMFQwOTowNjo0OC0wNzowMCIgc3RFdnQ6c29mdHdhcmVBZ2VudD0iQWRvYmUgUGhvdG9zaG9wIDIyLjIgKFdpbmRvd3MpIi8+IDxyZGY6bGkgc3RFdnQ6YWN0aW9uPSJzYXZlZCIgc3RFdnQ6aW5zdGFuY2VJRD0ieG1wLmlpZDpkMGVkOThiMS1jOTVmLWU3NDQtYWJiYy0wZGRhY2ZhOTJkMTQiIHN0RXZ0OndoZW49IjIwMjEtMDctMzBUMTA6MTk6MDgtMDc6MDAiIHN0RXZ0OnNvZnR3YXJlQWdlbnQ9IkFkb2JlIFBob3Rvc2hvcCAyMi4yIChXaW5kb3dzKSIgc3RFdnQ6Y2hhbmdlZD0iLyIvPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0ic2F2ZWQiIHN0RXZ0Omluc3RhbmNlSUQ9InhtcC5paWQ6MmZmM2IxYmMtODQyMi05MjQ2LTk0OWQtZmIxMjIzYmU2NGI0IiBzdEV2dDp3aGVuPSIyMDIxLTA4LTAxVDIxOjIwOjQ4LTA3OjAwIiBzdEV2dDpzb2Z0d2FyZUFnZW50PSJBZG9iZSBQaG90b3Nob3AgMjIuMiAoV2luZG93cykiIHN0RXZ0OmNoYW5nZWQ9Ii8iLz4gPHJkZjpsaSBzdEV2dDphY3Rpb249ImNvbnZlcnRlZCIgc3RFdnQ6cGFyYW1ldGVycz0iZnJvbSBhcHBsaWNhdGlvbi92bmQuYWRvYmUucGhvdG9zaG9wIHRvIGltYWdlL3BuZyIvPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0iZGVyaXZlZCIgc3RFdnQ6cGFyYW1ldGVycz0iY29udmVydGVkIGZyb20gYXBwbGljYXRpb24vdm5kLmFkb2JlLnBob3Rvc2hvcCB0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"
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
Create_buttontoggledown_png(NewHandle = False) {
Static hBitmap := 0
Ptr := A_PtrSize ? "Ptr" : "UInt"
UPtr := A_PtrSize ? "UPtr" : "UInt"
If (NewHandle)
   hBitmap := 0
If (hBitmap)
   Return hBitmap
VarSetCapacity(B64, 5684 << !!A_IsUnicode)
B64 := "iVBORw0KGgoAAAANSUhEUgAAAJsAAAAZCAIAAACpe8sIAAAACXBIWXMAABcSAAAXEgFnn9JSAAAMb2lUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNi4wLWMwMDYgNzkuMTY0NjQ4LCAyMDIxLzAxLzEyLTE1OjUyOjI5ICAgICAgICAiPiA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPiA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtbG5zOnBob3Rvc2hvcD0iaHR0cDovL25zLmFkb2JlLmNvbS9waG90b3Nob3AvMS4wLyIgeG1sbnM6ZGM9Imh0dHA6Ly9wdXJsLm9yZy9kYy9lbGVtZW50cy8xLjEvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RFdnQ9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZUV2ZW50IyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtbG5zOnRpZmY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vdGlmZi8xLjAvIiB4bWxuczpleGlmPSJodHRwOi8vbnMuYWRvYmUuY29tL2V4aWYvMS4wLyIgeG1wOkNyZWF0b3JUb29sPSJBZG9iZSBQaG90b3Nob3AgMjIuMiAoV2luZG93cykiIHhtcDpDcmVhdGVEYXRlPSIyMDIxLTA3LTMwVDA5OjA2OjQ4LTA3OjAwIiB4bXA6TWV0YWRhdGFEYXRlPSIyMDIxLTA4LTAxVDIxOjIxOjA4LTA3OjAwIiB4bXA6TW9kaWZ5RGF0ZT0iMjAyMS0wOC0wMVQyMToyMTowOC0wNzowMCIgcGhvdG9zaG9wOkNvbG9yTW9kZT0iMyIgZGM6Zm9ybWF0PSJpbWFnZS9wbmciIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6NDJmZGIzMjktNTg5NC02MzRmLWE4ZjEtNTg2NTBjYTE1MmIwIiB4bXBNTTpEb2N1bWVudElEPSJhZG9iZTpkb2NpZDpwaG90b3Nob3A6NjJmNTk3OTgtMDU5MS01YTRjLWJkNjItZTFjN2EwNDdkNDRhIiB4bXBNTTpPcmlnaW5hbERvY3VtZW50SUQ9InhtcC5kaWQ6ZGRhN2Q2MDUtMWI2Ny04ODQ1LTg4NTYtMjNkYzQ2NjVmNmQ0IiB0aWZmOk9yaWVudGF0aW9uPSIxIiB0aWZmOlhSZXNvbHV0aW9uPSIxNTAwMDAwLzEwMDAwIiB0aWZmOllSZXNvbHV0aW9uPSIxNTAwMDAwLzEwMDAwIiB0aWZmOlJlc29sdXRpb25Vbml0PSIyIiBleGlmOkNvbG9yU3BhY2U9IjY1NTM1IiBleGlmOlBpeGVsWERpbWVuc2lvbj0iNDE1IiBleGlmOlBpeGVsWURpbWVuc2lvbj0iNjc1Ij4gPHBob3Rvc2hvcDpUZXh0TGF5ZXJzPiA8cmRmOkJhZz4gPHJkZjpsaSBwaG90b3Nob3A6TGF5ZXJOYW1lPSJUb2dnbGUgU2tpbGwgVUkiIHBob3Rvc2hvcDpMYXllclRleHQ9IlRvZ2dsZSBTa2lsbCBVSSIvPiA8cmRmOmxpIHBob3Rvc2hvcDpMYXllck5hbWU9IkNsb3NlIiBwaG90b3Nob3A6TGF5ZXJUZXh0PSJDbG9zZSIvPiA8cmRmOmxpIHBob3Rvc2hvcDpMYXllck5hbWU9IkF1dG9wb3QiIHBob3Rvc2hvcDpMYXllclRleHQ9IkF1dG9wb3QiLz4gPHJkZjpsaSBwaG90b3Nob3A6TGF5ZXJOYW1lPSJYIiBwaG90b3Nob3A6TGF5ZXJUZXh0PSJYIi8+IDwvcmRmOkJhZz4gPC9waG90b3Nob3A6VGV4dExheWVycz4gPHBob3Rvc2hvcDpEb2N1bWVudEFuY2VzdG9ycz4gPHJkZjpCYWc+IDxyZGY6bGk+YWRvYmU6ZG9jaWQ6cGhvdG9zaG9wOjkyMDc4ZTI1LTZkMjctYTQ0MC1hNmUxLTcxYTU5OWZkNDRhOTwvcmRmOmxpPiA8L3JkZjpCYWc+IDwvcGhvdG9zaG9wOkRvY3VtZW50QW5jZXN0b3JzPiA8eG1wTU06SGlzdG9yeT4gPHJkZjpTZXE+IDxyZGY6bGkgc3RFdnQ6YWN0aW9uPSJjcmVhdGVkIiBzdEV2dDppbnN0YW5jZUlEPSJ4bXAuaWlkOmRkYTdkNjA1LTFiNjctODg0NS04ODU2LTIzZGM0NjY1ZjZkNCIgc3RFdnQ6d2hlbj0iMjAyMS0wNy0zMFQwOTowNjo0OC0wNzowMCIgc3RFdnQ6c29mdHdhcmVBZ2VudD0iQWRvYmUgUGhvdG9zaG9wIDIyLjIgKFdpbmRvd3MpIi8+IDxyZGY6bGkgc3RFdnQ6YWN0aW9uPSJzYXZlZCIgc3RFdnQ6aW5zdGFuY2VJRD0ieG1wLmlpZDpkMGVkOThiMS1jOTVmLWU3NDQtYWJiYy0wZGRhY2ZhOTJkMTQiIHN0RXZ0OndoZW49IjIwMjEtMDctMzBUMTA6MTk6MDgtMDc6MDAiIHN0RXZ0OnNvZnR3YXJlQWdlbnQ9IkFkb2JlIFBob3Rvc2hvcCAyMi4yIChXaW5kb3dzKSIgc3RFdnQ6Y2hhbmdlZD0iLyIvPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0ic2F2ZWQiIHN0RXZ0Omluc3RhbmNlSUQ9InhtcC5paWQ6MGYwYTRjZDQtYzRiYS0xMjRhLTk5NjgtNGYzOGE1Y2ZlZTEwIiBzdEV2dDp3aGVuPSIyMDIxLTA4LTAxVDIxOjIxOjA4LTA3OjAwIiBzdEV2dDpzb2Z0d2FyZUFnZW50PSJBZG9iZSBQaG90b3Nob3AgMjIuMiAoV2luZG93cykiIHN0RXZ0OmNoYW5nZWQ9Ii8iLz4gPHJkZjpsaSBzdEV2dDphY3Rpb249ImNvbnZlcnRlZCIgc3RFdnQ6cGFyYW1ldGVycz0iZnJvbSBhcHBsaWNhdGlvbi92bmQuYWRvYmUucGhvdG9zaG9wIHRvIGltYWdlL3BuZyIvPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0iZGVyaXZlZCIgc3RFdnQ6cGFyYW1ldGVycz0iY29udmVydGVkIGZyb20gYXBwbGljYXRpb24vdm5kLmFkb2JlLnBob3Rvc2hvcCB0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"
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
