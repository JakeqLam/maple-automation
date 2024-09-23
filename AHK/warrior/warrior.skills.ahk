#SingleInstance, Force
#NoEnv
#MaxThreadsPerHotkey 10
#IfWinExist 
#Persistent

SetWinDelay, 0
SetBatchLines -1

Menu, Tray, Icon, omes.ico

infinite := 100000*100000
skillglobalcd = 0
buff_cd = 0

;<><><><><><><><><><><><><><><><><><><><><><><><> Draw UI


typeface := "Nova Square"

ui_bitmap := Create_uiskill_png()
ui_buttonon_bitmap := Create_buttonon_png()
ui_buttonoff_bitmap := Create_buttonoff_png()

Gui, Add, picture, x0 y0 w415 h410, % "HBITMAP:*" . ui_bitmap
Gui, Add, picture, x32 y33 vbuttonskill, % "HBITMAP:*" . ui_buttonoff_bitmap

ui_buttonoff := ui_buttonoff_bitmap
ui_buttonon := ui_buttonon_bitmap


;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><> version font

Gui font, c505050 s9, Nova Square
Gui, Add, Text, x310 y360 BackgroundTrans, Omes V.0.3.0                                     ;Version number

;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><> Draw Font/text Skills

Gui font, cC0C0C0 s10, Nova Square

Gui, Add, Text, x50 y32 BackgroundTrans, Skill Spam (F10)
Gui, Add, Text, x189 y13 BackgroundTrans, Skills

Gui, Add, Text, x50 y340 BackgroundTrans, Always ontop
Gui, Add, Picture, x32 y341 vbuttonontop gbuttonontop_switch,  % "HBITMAP:*" . ui_buttonoff_bitmap 
Gui, Add, Text, x50 y360 BackgroundTrans, AutoRune Completion
Gui, Add, Picture, x32 y361 vbuttonrune gbuttonrune_switch,  % "HBITMAP:*" . ui_buttonoff_bitmap 


gui_text         := 5
ycoord           := 5
ycoord_input     := 25
number_of_skills := 14


Gui, Add, Text, x50  y55 BackgroundTrans, Skill                       ; left side
Gui, Add, Text, x250 y55 BackgroundTrans, Skill                      ; right side
Gui, Add, Text, x110 y55 BackgroundTrans, CD                       ; left side
Gui, Add, Text, x310 y55 BackgroundTrans, CD

Gui, Add, Text, x50  y255 BackgroundTrans, Skill                       ; left side
Gui, Add, Text, x250 y255 BackgroundTrans, Skill                      ; right side
Gui, Add, Text, x110 y255 BackgroundTrans, CD                       ; left side
Gui, Add, Text, x310 y255 BackgroundTrans, CD

Gui font, cC0C0C0 s10, Nova Square
Gui, Add, Text, x50 y230 BackgroundTrans, Buffs/Long CD

Gui font, cBlack s9, Nova Square

;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><> Left side
Gui, Add, DDL,  x50   y75  w50 vDDLskill_1, NA|1|2|3|4|5|6|7|8|9|0|-|=|q|w|e|r|t|y|u|i|o|p|a|s|d|f|g|h|j|k|l|z|x|c|v|b|n|m|Space
Gui, Add, edit, x110  y75  w50 r1 vskillcd_1, 1

Gui, Add, DDL,  x50   y105 w50 vDDLskill_2, NA|1|2|3|4|5|6|7|8|9|0|-|=|q|w|e|r|t|y|u|i|o|p|a|s|d|f|g|h|j|k|l|z|x|c|v|b|n|m|Space
Gui, Add, edit, x110  y105 w50 r1 vskillcd_2, 2

Gui, Add, DDL,  x50   y135 w50 vDDLskill_3, NA|1|2|3|4|5|6|7|8|9|0|-|=|q|w|e|r|t|y|u|i|o|p|a|s|d|f|g|h|j|k|l|z|x|c|v|b|n|m|Space
Gui, Add, edit, x110  y135 w50 r1 vskillcd_3, 3

Gui, Add, DDL,  x50   y165 w50 vDDLskill_4, NA|1|2|3|4|5|6|7|8|9|0|-|=|q|w|e|r|t|y|u|i|o|p|a|s|d|f|g|h|j|k|l|z|x|c|v|b|n|m|Space
Gui, Add, edit, x110  y165 w50 r1 vskillcd_4, 4

Gui, Add, DDL,  x50   y195 w50 vDDLskill_5, NA|1|2|3|4|5|6|7|8|9|0|-|=|q|w|e|r|t|y|u|i|o|p|a|s|d|f|g|h|j|k|l|z|x|c|v|b|n|m|Space
Gui, Add, edit, x110  y195 w50 r1 vskillcd_5, 5

Gui, Add, DDL,  x50   y277 w50 vDDLskill_11, NA|1|2|3|4|5|6|7|8|9|0|-|=|q|w|e|r|t|y|u|i|o|p|a|s|d|f|g|h|j|k|l|z|x|c|v|b|n|m|Space
Gui, Add, edit, x110  y277 w50 r1 vskillcd_11, 1

Gui, Add, DDL,  x50   y307 w50 vDDLskill_12, NA|1|2|3|4|5|6|7|8|9|0|-|=|q|w|e|r|t|y|u|i|o|p|a|s|d|f|g|h|j|k|l|z|x|c|v|b|n|m|Space
Gui, Add, edit, x110  y307 w50 r1 vskillcd_12, 2

;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><> Left side
Gui, Add, DDL,  x250  y75  w50 vDDLskill_6, NA|1|2|3|4|5|6|7|8|9|0|-|=|q|w|e|r|t|y|u|i|o|p|a|s|d|f|g|h|j|k|l|z|x|c|v|b|n|m|Space
Gui, Add, edit, x310  y75  w50 r1 vskillcd_6, 6

Gui, Add, DDL,  x250  y105 w50 vDDLskill_7, NA|1|2|3|4|5|6|7|8|9|0|-|=|q|w|e|r|t|y|u|i|o|p|a|s|d|f|g|h|j|k|l|z|x|c|v|b|n|m|Space
Gui, Add, edit, x310  y105 w50 r1 vskillcd_7, 7

Gui, Add, DDL,  x250  y135 w50 vDDLskill_8, NA|1|2|3|4|5|6|7|8|9|0|-|=|q|w|e|r|t|y|u|i|o|p|a|s|d|f|g|h|j|k|l|z|x|c|v|b|n|m|Space
Gui, Add, edit, x310  y135 w50 r1 vskillcd_8, 8

Gui, Add, DDL,  x250  y165 w50 vDDLskill_9, NA|1|2|3|4|5|6|7|8|9|0|-|=|q|w|e|r|t|y|u|i|o|p|a|s|d|f|g|h|j|k|l|z|x|c|v|b|n|m|Space
Gui, Add, edit, x310  y165 w50 r1 vskillcd_9, 9

Gui, Add, DDL,  x250  y195 w50 vDDLskill_10, NA|1|2|3|4|5|6|7|8|9|0|-|=|q|w|e|r|t|y|u|i|o|p|a|s|d|f|g|h|j|k|l|z|x|c|v|b|n|m|Space
Gui, Add, edit, x310  y195 w50 r1 vskillcd_10, 10

Gui, Add, DDL,  x250  y277 w50 vDDLskill_13, NA|1|2|3|4|5|6|7|8|9|0|-|=|q|w|e|r|t|y|u|i|o|p|a|s|d|f|g|h|j|k|l|z|x|c|v|b|n|m|Space
Gui, Add, edit, x310  y277 w50 r1 vskillcd_13, 3

Gui, Add, DDL,  x250  y307 w50 vDDLskill_14, NA|1|2|3|4|5|6|7|8|9|0|-|=|q|w|e|r|t|y|u|i|o|p|a|s|d|f|g|h|j|k|l|z|x|c|v|b|n|m|Space
Gui, Add, edit, x310  y307 w50 r1 vskillcd_14, 4

Loop 14                                                        ; loops and goes up in number depending on times looped
{
	GuiControl, choose, DDLskill_%A_Index%, NA
}

Gui, +Caption +LastFound -AlwaysOnTop +OwnDialogs
Gui, Show, x1500 y700 w415 h410

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

	
;<><><><><><><><><><><><><><><><><><><><><><><><> Start Timer checks

*F10::
	
rune_execute = 0

toggleskillspam:=!toggleskillspam

	if (!toggleskillspam)
	{
		GuiControl,, buttonskill, % "HBITMAP:*" . ui_buttonoff_bitmap
		skill_spam = 0
	}
	else
	{
		GuiControl,, buttonskill, % "HBITMAP:*" . ui_buttonon_bitmap
		skill_spam = 1
	
	
		Loop 10
		{
			GuiControlGet, varskillcd_%A_index%, ,skillcd_%A_index%, 
			cd_%A_index% = % varskillcd_%A_index% * 10
			skill_counter_%A_index% = % cd_%A_index%
			
		}
	}

SetTimer, menu_open, % (togglemenucheck:=!togglemenucheck) ? 100 : "Off"
menu_open:

		Loop % number_of_skills
		{
			GuiControlGet, varskillcd_%A_index%, ,skillcd_%A_index%, 
			GuiControlGet, varskill_%A_index%, ,DDLskill_%A_index%, 
			cd_%A_index% = % varskillcd_%A_index% * 10
		}
		

		Random, 10ms, 9,14
		Random, 100ms, 98, 124
		Random, 200ms, 202, 210
		Random, 300ms, 297, 305
		Random, 400ms, 411, 435
		Random, 500ms, 497, 521
		Random, 800ms, 801, 814
		Random, GlobalCD, 1000,1050
		
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><<><><><><><><><><><><><><><><><>><><> Skill
		
	if (autorune = 1)
	{
		PixelSearch, rune_x, rune_y, 15, 90, 190, 150, 0xdd66ff, 2, fast RGB  
		if !Errorlevel
		{
			rune_execute= 1
			
			rune_x1 = % rune_x - 3
			rune_y1 = % rune_y - 3 
			rune_x2 = % rune_x + 3
			rune_y2 = % rune_y + 3 
			
			PixelSearch,,, rune_x1, rune_y1, rune_x2, rune_y2, 0xFFDD44, 2, fast RGB  
			if !Errorlevel
			{
				continue_sleep:
				sleep 5000
				PixelSearch,,, rune_x1, rune_y1, rune_x2, rune_y2, 0xdd66ff, 2, fast RGB  
				if !Errorlevel
				{
					goto continue_sleep
				}
				if Errorlevel = 1
				{
					rune_execute = 0
					return
				}
			}
			
		}
	}
	
	if (skill_spam = 1 and rune_execute = 0)
	{
		if (skill_spam = 1 and varskill_1 != "NA" and buff_cd = 0)
		{		
			if (skill_counter_1 < cd_1)
			{
				skill_counter_1++
			}
			else if (skill_counter_1 >= cd_1)
			{
				Sendinput {%varskill_1% down}
				Sleep 100ms
				Sendinput {%varskill_1% up}
				skill_counter_1 = 0
			}
		}
		if (skill_spam = 1 and varskill_2 != "NA" and buff_cd = 0)
		{
			if (skill_counter_2 < cd_2)
			{
				skill_counter_2++
			}
			else if (skill_counter_2 >= cd_2)
			{
				Sendinput {%varskill_2% down}
				sleep 100ms
				Sendinput {%varskill_2% up}
				skill_counter_2 = 0
			}
		}
		if (skill_spam = 1 and varskill_3 != "NA" and buff_cd = 0)
		{
			if (skill_counter_3 < cd_3)
			{
				skill_counter_3++
			}
			else if (skill_counter_3 >= cd_3)
			{
				Sendinput {%varskill_3% down}
				Sleep 100ms
				Sendinput {%varskill_3% up}
				skill_counter_3 = 0
			}
		}
		
		if (skill_spam = 1 and varskill_4 != "NA" and buff_cd = 0)
		{
			if (skill_counter_4 < cd_4)
			{
				skill_counter_4++
			}
			else if (skill_counter_4 >= cd_4)
			{
				Sendinput {%varskill_4% down}
				sleep 100ms
				Sendinput {%varskill_4% up}
				skill_counter_4 = 0
			}
		}
		if (skill_spam = 1 and varskill_5 != "NA" and buff_cd = 0)
		{
			if (skill_counter_5 < cd_5)
			{
				skill_5ounter++
			}
			else if (skill_counter_5 >= cd_5)
			{
				Sendinput {%varskill_5% down}
				sleep 100ms
				Sendinput {%varskill_5% up}
				skill_counter_5 = 0
			}
		}
		if (skill_spam = 1 and varskill_6 != "NA" and buff_cd = 0)
		{
			if (skill_counter_6 < cd_6)
			{
				skill_counter_6++
			}
			else if (skill_counter_6 >= cd_6)
			{
				Sendinput {%varskill_6% down}
				sleep 100ms
				Sendinput {%varskill_6% up}
				skill_counter_6 = 0
			}
		} 
		if (skill_spam = 1 and varskill_7 != "NA") and buff_cd = 0
		{
			if (skill_counter_7 < cd_7)
			{
				skill_counter_7++
			}
			else if (skill_counter_7 >= cd_7)
			{
				Sendinput {%varskill_7% down}
				sleep 100ms
				Sendinput {%varskill_7% up}
				skill_counter_7 = 0
			}
		} 
		if (skill_spam = 1 and varskill_8 != "NA" and buff_cd = 0)
		{
			if (skill_counter_8 < cd_8)
			{
				skill_counter_8++
			}
			else if (skill_counter_8 >= cd_8)
			{
				Sendinput {%varskill_8% down}
				sleep 100ms
				Sendinput {%varskill_8% up}
				skill_counter_8 = 0
			}
		} 
		if (skill_spam = 1 and varskill_9 != "NA" and buff_cd = 0)
		{
			if (skill_counter_9 < cd_9)
			{
				skill_counter_9++
			}
			else if (skill_counter_9 >= cd_9)
			{
				Sendinput {%varskill_9% down}
				sleep 100ms
				Sendinput {%varskill_9% up}
				skill_counter_9 = 0
			}
		} 
		if (skill_spam = 1 and varskill_10 != "NA" and buff_cd = 0)
		{
			if (skill_counter_10 < cd_10)
			{
				skill_counter_10++
			}
			else if (skill_counter_10 >= cd_10)
			{
				Sendinput {%varskill_10% down}
				sleep 100ms
				Sendinput {%varskill_10% up}
				skill_counter_10 = 0
			}
		} 
		if (skill_spam = 1 and varskill_11 != "NA")
		{
			if (skill_counter_11 < cd_11)
			{
				skill_counter_11++
			}
			else if (skill_counter_11 >= cd_11)
			{
				buff_cd := 1
				sendallinputs_down()
				sleep GlobalCD
				Sendinput {%varskill_11% down}
				sleep 3000
				Sendinput {%varskill_11% up}
				sendallinputs_up()
				buff_cd := 0
				skill_counter_11 = 0
			}
		} 
		if (skill_spam = 1 and varskill_12 != "NA")
		{
			if (skill_counter_12 < cd_12)
			{
				skill_counter_12++
			}
			else if (skill_counter_12 >= cd_12)
			{
				buff_cd = 1
				sendallinputs_down()
				sleep GlobalCD
				Sendinput {%varskill_12% down}
				sleep 3000
				Sendinput {%varskill_12% up}
				sendallinputs_up()
				buff_cd = 0
				skill_counter_12 = 0
			}
		} 
		if (skill_spam = 1 and varskill_13 != "NA")
		{
			if (skill_counter_13 < cd_13)
			{
				skill_counter_13++
			}
			else if (skill_counter_13 >= cd_13)
			{
				buff_cd = 1
				sendallinputs_down()
				sleep GlobalCD
				Sendinput {%varskill_13% down}
				sleep 3000
				Sendinput {%varskill_13% up}
				sendallinputs_up()
				buff_cd = 0
				skill_counter_13 = 0
			}
		} 
		if (skill_spam = 1 and varskill_14 != "NA")
		{
			if (skill_counter_14 < cd_14)
			{
				skill_counter_14++
			}
			else if (skill_counter_14 >= cd_14)
			{
				buff_cd = 1
				sendallinputs_down()
				sleep GlobalCD
				Sendinput {%varskill_14% down}
				sleep 3000
				Sendinput {%varskill_14% up}
				sendallinputs_up()
				buff_cd = 0
				skill_counter_14 = 0
			}
		} 
		
		else if (skill_spam = 0)
		{
			Loop 1
			{
				skill_counter_%A_index% = 0 
			}
		}
	}
return





*F12::

MouseGetPos, xpos, ypos 
MsgBox, The cursor is at X%xpos% Y%ypos%.

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

buttonrune_switch:
togglerune:=!togglerune				
	if (!togglerune)
	{
		Gui, -AlwaysOnTop
		GuiControl,, buttonrune, % "HBITMAP:*" . ui_buttonoff_bitmap
		autorune = 0
	}
	else
	{
		GuiControl,, buttonrune, % "HBITMAP:*" . ui_buttonon_bitmap
		Gui, +AlwaysOnTop
		autorune = 1
	}
return


guiclose:
ExitApp
return


sendallinputs_down()
{
	Sendinput {left down}
	Sendinput {right down}
	Sendinput {up down}
	Sendinput {down down}
}

sendallinputs_up()
{
	Sendinput {blind}{left up}
	Sendinput {blind}{right up}
	Sendinput {blind}{up up}
	Sendinput {blind}{down up}
}


















; ##################################################################################
; # This #Include file was generated by Image2Include.ahk, you must not change it! #
; ##################################################################################
Create_uiskill_png(NewHandle = False) {
Static hBitmap := 0
Ptr := A_PtrSize ? "Ptr" : "UInt"
UPtr := A_PtrSize ? "UPtr" : "UInt"
If (NewHandle)
   hBitmap := 0
If (hBitmap)
   Return hBitmap
VarSetCapacity(B64, 21976 << !!A_IsUnicode)
B64 := "iVBORw0KGgoAAAANSUhEUgAAAZ8AAAGaCAIAAABfTdlwAAAACXBIWXMAABcSAAAXEgFnn9JSAAAL12lUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNi4wLWMwMDYgNzkuMTY0NjQ4LCAyMDIxLzAxLzEyLTE1OjUyOjI5ICAgICAgICAiPiA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPiA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtbG5zOnBob3Rvc2hvcD0iaHR0cDovL25zLmFkb2JlLmNvbS9waG90b3Nob3AvMS4wLyIgeG1sbnM6ZGM9Imh0dHA6Ly9wdXJsLm9yZy9kYy9lbGVtZW50cy8xLjEvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RFdnQ9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZUV2ZW50IyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtbG5zOnRpZmY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vdGlmZi8xLjAvIiB4bWxuczpleGlmPSJodHRwOi8vbnMuYWRvYmUuY29tL2V4aWYvMS4wLyIgeG1wOkNyZWF0b3JUb29sPSJBZG9iZSBQaG90b3Nob3AgMjIuMiAoV2luZG93cykiIHhtcDpDcmVhdGVEYXRlPSIyMDIxLTA3LTMwVDA5OjA2OjQ4LTA3OjAwIiB4bXA6TWV0YWRhdGFEYXRlPSIyMDIxLTA5LTE2VDEzOjEzOjU5LTA3OjAwIiB4bXA6TW9kaWZ5RGF0ZT0iMjAyMS0wOS0xNlQxMzoxMzo1OS0wNzowMCIgcGhvdG9zaG9wOkNvbG9yTW9kZT0iMyIgZGM6Zm9ybWF0PSJpbWFnZS9wbmciIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6MDA4OTZiZmQtOWZjZS0zYjQzLWFiNjgtYjRmMGEyNmVmNTIzIiB4bXBNTTpEb2N1bWVudElEPSJhZG9iZTpkb2NpZDpwaG90b3Nob3A6NWIxMjM1NGEtZmUzMC0yMTQ0LTlkYzEtMGYyOWMwZWJiMjU1IiB4bXBNTTpPcmlnaW5hbERvY3VtZW50SUQ9InhtcC5kaWQ6ZGRhN2Q2MDUtMWI2Ny04ODQ1LTg4NTYtMjNkYzQ2NjVmNmQ0IiB0aWZmOk9yaWVudGF0aW9uPSIxIiB0aWZmOlhSZXNvbHV0aW9uPSIxNTAwMDAwLzEwMDAwIiB0aWZmOllSZXNvbHV0aW9uPSIxNTAwMDAwLzEwMDAwIiB0aWZmOlJlc29sdXRpb25Vbml0PSIyIiBleGlmOkNvbG9yU3BhY2U9IjY1NTM1IiBleGlmOlBpeGVsWERpbWVuc2lvbj0iNDE1IiBleGlmOlBpeGVsWURpbWVuc2lvbj0iMzc1Ij4gPHBob3Rvc2hvcDpUZXh0TGF5ZXJzPiA8cmRmOkJhZz4gPHJkZjpsaSBwaG90b3Nob3A6TGF5ZXJOYW1lPSJBdXRvcG90IiBwaG90b3Nob3A6TGF5ZXJUZXh0PSJBdXRvcG90Ii8+IDxyZGY6bGkgcGhvdG9zaG9wOkxheWVyTmFtZT0iWCIgcGhvdG9zaG9wOkxheWVyVGV4dD0iWCIvPiA8L3JkZjpCYWc+IDwvcGhvdG9zaG9wOlRleHRMYXllcnM+IDxwaG90b3Nob3A6RG9jdW1lbnRBbmNlc3RvcnM+IDxyZGY6QmFnPiA8cmRmOmxpPmFkb2JlOmRvY2lkOnBob3Rvc2hvcDo5MjA3OGUyNS02ZDI3LWE0NDAtYTZlMS03MWE1OTlmZDQ0YTk8L3JkZjpsaT4gPC9yZGY6QmFnPiA8L3Bob3Rvc2hvcDpEb2N1bWVudEFuY2VzdG9ycz4gPHhtcE1NOkhpc3Rvcnk+IDxyZGY6U2VxPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0iY3JlYXRlZCIgc3RFdnQ6aW5zdGFuY2VJRD0ieG1wLmlpZDpkZGE3ZDYwNS0xYjY3LTg4NDUtODg1Ni0yM2RjNDY2NWY2ZDQiIHN0RXZ0OndoZW49IjIwMjEtMDctMzBUMDk6MDY6NDgtMDc6MDAiIHN0RXZ0OnNvZnR3YXJlQWdlbnQ9IkFkb2JlIFBob3Rvc2hvcCAyMi4yIChXaW5kb3dzKSIvPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0ic2F2ZWQiIHN0RXZ0Omluc3RhbmNlSUQ9InhtcC5paWQ6ZDBlZDk4YjEtYzk1Zi1lNzQ0LWFiYmMtMGRkYWNmYTkyZDE0IiBzdEV2dDp3aGVuPSIyMDIxLTA3LTMwVDEwOjE5OjA4LTA3OjAwIiBzdEV2dDpzb2Z0d2FyZUFnZW50PSJBZG9iZSBQaG90b3Nob3AgMjIuMiAoV2luZG93cykiIHN0RXZ0OmNoYW5nZWQ9Ii8iLz4gPHJkZjpsaSBzdEV2dDphY3Rpb249InNhdmVkIiBzdEV2dDppbnN0YW5jZUlEPSJ4bXAuaWlkOjY3MzEyNjBmLWFlMDAtZjk0Yy1hMTYyLTkwNGM1Y2Y5ZTFiMiIgc3RFdnQ6d2hlbj0iMjAyMS0wOS0xNlQxMzoxMzo1OS0wNzowMCIgc3RFdnQ6c29mdHdhcmVBZ2VudD0iQWRvYmUgUGhvdG9zaG9wIDIyLjIgKFdpbmRvd3MpIiBzdEV2dDpjaGFuZ2VkPSIvIi8+IDxyZGY6bGkgc3RFdnQ6YWN0aW9uPSJjb252ZXJ0ZWQiIHN0RXZ0OnBhcmFtZXRlcnM9ImZyb20gYXBwbGljYXRpb24vdm5kLmFkb2JlLnBob3Rvc2hvcCB0byBpbWFnZS9wbmciLz4gPHJkZjpsaSBzdEV2dDphY3Rpb249ImRlcml2ZWQiIHN0RXZ0OnBhcmFtZXRlcnM9ImNvbnZlcnRlZCBmcm9tIGFwcGxpY2F0aW9uL3ZuZC5hZG9iZS5waG90b3Nob3AgdG8gaW1hZ2UvcG5nIi8+IDxyZGY6bGkgc3RFdnQ6YWN0aW9uPSJzYXZlZCIgc3RFdnQ6aW5zdGFuY2VJRD0ieG1wLmlpZDowMDg5NmJmZC05ZmNlLTNiNDMtYWI2OC1iNGYwYTI2ZWY1MjMiIHN0RXZ0OndoZW49IjIwMjEtMDktMTZUMTM6MTM6NTktMDc6MDAiIHN0RXZ0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"
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