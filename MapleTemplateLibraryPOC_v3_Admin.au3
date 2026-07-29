#RequireAdmin
#AutoIt3Wrapper_Res_requestedExecutionLevel=requireAdministrator
#AutoIt3Wrapper_UseX64=y

#include "ImageSearchDLL_UDF_Embedded.au3"
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <FileConstants.au3>
#include <Misc.au3>

Opt("MustDeclareVars", 1)
Opt("TrayAutoPause", 0)
Opt("MouseCoordMode", 1)
Opt("PixelCoordMode", 1)

; ============================================================================
; Maple Template Library POC v3
;
; Read-only computer-vision proof of concept:
;   1. Load every PNG from data\player and data\target
;   2. Detect player identity and target variants
;   3. Deduplicate overlapping target results
;   4. Find the nearest target to the center of the SuperKiwi nameplate
;   5. Report horizontal, vertical, and Euclidean pixel distance
;
; No global hotkeys are registered.
; Images can be imported or captured without editing this script.
; This script DOES NOT click or send keyboard input.
; ============================================================================

Global Const $SEARCH_SCREEN = -1

Global Const $DATA_DIRECTORY = @ScriptDir & "\data"
Global Const $PLAYER_TEMPLATE_DIRECTORY = $DATA_DIRECTORY & "\player"
Global Const $TARGET_TEMPLATE_DIRECTORY = $DATA_DIRECTORY & "\target"

Global $g_aPlayerTemplates[1]
Global $g_iPlayerTemplateCount = 0

Global $g_aTargetTemplates[1]
Global $g_iTargetTemplateCount = 0

Global Const $PLAYER_TOLERANCE = 25
Global Const $TARGET_TOLERANCE = 25
Global Const $PLAYER_MAX_RESULTS = 1
Global Const $TARGET_MAX_RESULTS_PER_TEMPLATE = 20
Global Const $MAX_UNIQUE_TARGETS = 50

; These templates were captured from the live client, so exact scale is the
; safest first POC. Expand this later only if display scaling changes.
Global Const $MIN_SCALE = 1.00
Global Const $MAX_SCALE = 1.00
Global Const $SCALE_STEP = 0.10

Global Const $CONTINUOUS_INTERVAL = 300
Global Const $AUTO_DETECT_INTERVAL = 2000
Global Const $DUPLICATE_CENTER_RADIUS = 20

; Reject small launcher/helper windows owned by the same process.
Global Const $MIN_GAME_CLIENT_WIDTH = 640
Global Const $MIN_GAME_CLIENT_HEIGHT = 400

Global Const $PLAYER_OVERLAY_COLOR = 0x00BFFF
Global Const $TARGET_OVERLAY_COLOR = 0x00FF00
Global Const $NEAREST_OVERLAY_COLOR = 0xFF8C00
Global Const $OVERLAY_BORDER = 3
Global Const $MAX_OVERLAY_WINDOWS = 220

Global Const $PANEL_WIDTH = 570
Global Const $PANEL_HEIGHT = 650

Global $g_aTargetProcessNames[2] = ["MapleSaga.exe", "MapleStory.exe"]

Global $g_hTargetWindow = 0
Global $g_sTargetWindowTitle = ""
Global $g_iTargetWindowPID = 0
Global $g_sTargetProcessName = ""

Global $g_sDebugDirectory = @ScriptDir & "\debug"
Global $g_sLogPath = $g_sDebugDirectory & "\MapleTemplateLibraryPOC_v3.log"

Global $g_bImageSearchStarted = False
Global $g_bContinuous = False
Global $g_bSearchBusy = False

Global $g_hContinuousTimer = TimerInit()
Global $g_hAutoDetectTimer = TimerInit()

Global $g_aOverlayHandles[$MAX_OVERLAY_WINDOWS]
Global $g_iOverlayCount = 0

; GUI
Global $g_hControlGui = 0
Global $g_idWindowValue = 0
Global $g_idTemplateValue = 0
Global $g_idPlayerValue = 0
Global $g_idTargetValue = 0
Global $g_idDistanceValue = 0
Global $g_idStatusValue = 0

Global $g_idDetectButton = 0
Global $g_idDelayedBindButton = 0
Global $g_idSearchButton = 0
Global $g_idContinuousButton = 0
Global $g_idCaptureButton = 0
Global $g_idClearButton = 0
Global $g_idOpenDebugButton = 0
Global $g_idActivateButton = 0
Global $g_idReloadDataButton = 0
Global $g_idOpenDataButton = 0
Global $g_idImportPlayerButton = 0
Global $g_idImportTargetButton = 0
Global $g_idCapturePlayerButton = 0
Global $g_idCaptureTargetButton = 0
Global $g_idExitButton = 0

DirCreate($g_sDebugDirectory)
DirCreate($DATA_DIRECTORY)
DirCreate($PLAYER_TEMPLATE_DIRECTORY)
DirCreate($TARGET_TEMPLATE_DIRECTORY)
OnAutoItExitRegister("_OnExit")

_Log("============================================================")
_Log("Maple Template Library POC v3 starting")
_Log("Script directory: " & @ScriptDir)
_Log("AutoIt architecture: " & (@AutoItX64 ? "x64" : "x86"))
_Log("Administrator token: " & (IsAdmin() ? "yes" : "no"))
_Log("Desktop size: " & @DesktopWidth & "x" & @DesktopHeight)
_Log("No keyboard hotkeys are registered")

If Not _ImageSearch_Startup() Then
    Local $iStartupError = @error
    Local $iStartupExtended = @extended

    MsgBox(16, "ImageSearch startup failed", _
            "ImageSearchDLL could not start." & @CRLF & @CRLF & _
            "@error: " & $iStartupError & @CRLF & _
            "@extended: " & $iStartupExtended & @CRLF & @CRLF & _
            "The embedded UDF may require the Microsoft Visual C++ " & _
            "2015-2022 Redistributable.")

    Exit 1
EndIf

$g_bImageSearchStarted = True
_Log("ImageSearchDLL startup succeeded")

_CreateControlPanel()
_ReloadTemplateLibrary(False)
_AutoDetectGameClient(False)

GUISetState(@SW_SHOW, $g_hControlGui)

While True
    Local $iMessage = GUIGetMsg()

    Switch $iMessage
        Case $GUI_EVENT_CLOSE, $g_idExitButton
            ExitLoop

        Case $g_idDetectButton
            _AutoDetectGameClient(True)

        Case $g_idDelayedBindButton
            _BindForegroundWindowAfterDelay()

        Case $g_idSearchButton
            _RunDistanceSearch(True)

        Case $g_idContinuousButton
            _ToggleContinuousSearch()

        Case $g_idCaptureButton
            _SaveTargetWindowScreenshot("manual")

        Case $g_idClearButton
            _ClearHighlights()
            _SetStatus("Highlights cleared.")

        Case $g_idOpenDebugButton
            ShellExecute($g_sDebugDirectory)

        Case $g_idActivateButton
            _ActivateTargetWindow()

        Case $g_idReloadDataButton
            _ReloadTemplateLibrary(True)

        Case $g_idOpenDataButton
            ShellExecute($DATA_DIRECTORY)

        Case $g_idImportPlayerButton
            _ImportTemplateImages($PLAYER_TEMPLATE_DIRECTORY, "player")

        Case $g_idImportTargetButton
            _ImportTemplateImages($TARGET_TEMPLATE_DIRECTORY, "target")

        Case $g_idCapturePlayerButton
            _CaptureTemplateSnippet($PLAYER_TEMPLATE_DIRECTORY, "player")

        Case $g_idCaptureTargetButton
            _CaptureTemplateSnippet($TARGET_TEMPLATE_DIRECTORY, "target")
    EndSwitch

    If $g_bContinuous And TimerDiff($g_hContinuousTimer) >= $CONTINUOUS_INTERVAL Then
        $g_hContinuousTimer = TimerInit()
        _RunDistanceSearch(False)
    EndIf

    If TimerDiff($g_hAutoDetectTimer) >= $AUTO_DETECT_INTERVAL Then
        $g_hAutoDetectTimer = TimerInit()
        _MaintainBestGameWindow()
    EndIf

    Sleep(20)
WEnd

Exit

; ============================================================================
; GUI
; ============================================================================

Func _CreateControlPanel()
    $g_hControlGui = GUICreate( _
            "Maple Template Library POC v3", _
            $PANEL_WIDTH, _
            $PANEL_HEIGHT, _
            -1, _
            -1, _
            $WS_OVERLAPPEDWINDOW, _
            $WS_EX_TOPMOST)

    GUICtrlCreateLabel( _
            "PLAYER-TO-TARGET TEMPLATE POC v3", _
            18, 14, 534, 24, $SS_CENTER)
    GUICtrlSetFont(-1, 11, 700)

    GUICtrlCreateLabel("Bound window:", 18, 51, 105, 18)
    $g_idWindowValue = GUICtrlCreateLabel("Not detected", 126, 49, 426, 36)
    GUICtrlSetFont($g_idWindowValue, 9, 600)

    GUICtrlCreateLabel("Data library:", 18, 89, 105, 18)
    $g_idTemplateValue = GUICtrlCreateLabel("Checking...", 126, 87, 426, 42)

    GUICtrlCreateLabel("Player:", 18, 135, 105, 18)
    $g_idPlayerValue = GUICtrlCreateLabel("Not detected", 126, 133, 426, 22)

    GUICtrlCreateLabel("Targets:", 18, 162, 105, 18)
    $g_idTargetValue = GUICtrlCreateLabel("Not detected", 126, 160, 426, 22)

    GUICtrlCreateLabel("Nearest:", 18, 189, 105, 18)
    $g_idDistanceValue = GUICtrlCreateLabel( _
            "No distance yet", _
            126, 187, 426, 48, _
            BitOR($SS_LEFT, $SS_SUNKEN))
    GUICtrlSetFont($g_idDistanceValue, 9, 700)

    GUICtrlCreateLabel("Status:", 18, 243, 105, 18)
    $g_idStatusValue = GUICtrlCreateLabel( _
            "Ready. Images are loaded from data\player and data\target.", _
            18, 264, 534, 70, _
            BitOR($SS_LEFT, $SS_SUNKEN))

    $g_idDetectButton = GUICtrlCreateButton( _
            "Detect Game Client", 18, 350, 260, 34)

    $g_idDelayedBindButton = GUICtrlCreateButton( _
            "Bind Active in 3 Seconds", 292, 350, 260, 34)

    $g_idSearchButton = GUICtrlCreateButton( _
            "Search + Measure Once", 18, 392, 260, 34)

    $g_idContinuousButton = GUICtrlCreateButton( _
            "Start Continuous", 292, 392, 260, 34)

    $g_idReloadDataButton = GUICtrlCreateButton( _
            "Reload /data", 18, 434, 170, 34)

    $g_idOpenDataButton = GUICtrlCreateButton( _
            "Open /data", 200, 434, 170, 34)

    $g_idOpenDebugButton = GUICtrlCreateButton( _
            "Open Debug", 382, 434, 170, 34)

    $g_idImportPlayerButton = GUICtrlCreateButton( _
            "Import Player Images", 18, 476, 260, 34)

    $g_idImportTargetButton = GUICtrlCreateButton( _
            "Import Target Images", 292, 476, 260, 34)

    $g_idCapturePlayerButton = GUICtrlCreateButton( _
            "Capture Player Snippet", 18, 518, 260, 34)

    $g_idCaptureTargetButton = GUICtrlCreateButton( _
            "Capture Target Snippet", 292, 518, 260, 34)

    $g_idCaptureButton = GUICtrlCreateButton( _
            "Capture Bound Window", 18, 560, 170, 32)

    $g_idClearButton = GUICtrlCreateButton( _
            "Clear Highlights", 200, 560, 170, 32)

    $g_idActivateButton = GUICtrlCreateButton( _
            "Activate Game", 382, 560, 170, 32)

    $g_idExitButton = GUICtrlCreateButton( _
            "Exit", 452, 608, 100, 28)

    GUICtrlSetTip($g_idDetectButton, _
            "Finds the largest visible MapleSaga.exe or MapleStory.exe window.")

    GUICtrlSetTip($g_idDelayedBindButton, _
            "Hides this panel. Activate the desired game window before the countdown ends.")

    GUICtrlSetTip($g_idSearchButton, _
            "Searches every PNG in data\player and data\target.")

    GUICtrlSetTip($g_idContinuousButton, _
            "Repeats the search approximately every " & $CONTINUOUS_INTERVAL & " ms.")

    GUICtrlSetTip($g_idReloadDataButton, _
            "Rescans the data folders without restarting the script.")

    GUICtrlSetTip($g_idImportPlayerButton, _
            "Select one or many PNG files and copy them into data\player.")

    GUICtrlSetTip($g_idImportTargetButton, _
            "Select one or many PNG files and copy them into data\target.")

    GUICtrlSetTip($g_idCapturePlayerButton, _
            "Drag a rectangle over the bound game window and save it into data\player.")

    GUICtrlSetTip($g_idCaptureTargetButton, _
            "Drag a rectangle over the bound game window and save it into data\target.")

    GUICtrlSetTip($g_idCaptureButton, _
            "Saves the complete bound game client to the debug folder.")
EndFunc

Func _SetStatus($sMessage)
    If $g_idStatusValue <> 0 Then
        GUICtrlSetData($g_idStatusValue, $sMessage)
    EndIf
EndFunc

Func _UpdateTemplateDisplay()
    GUICtrlSetData( _
            $g_idTemplateValue, _
            "data\player: " & $g_iPlayerTemplateCount & _
            " PNG(s) | data\target: " & $g_iTargetTemplateCount & _
            " PNG(s)" & @CRLF & _
            "Tolerance: player " & $PLAYER_TOLERANCE & _
            " | target " & $TARGET_TOLERANCE)
EndFunc

Func _UpdateWindowDisplay()
    If $g_hTargetWindow = 0 Or Not WinExists($g_hTargetWindow) Then
        GUICtrlSetData($g_idWindowValue, "Not detected")
        Return
    EndIf

    Local $aClientSize = WinGetClientSize($g_hTargetWindow)
    Local $sSize = ""

    If IsArray($aClientSize) Then
        $sSize = " | " & $aClientSize[0] & "x" & $aClientSize[1]
    EndIf

    Local $sIdentity = $g_sTargetWindowTitle

    If StringStripWS($sIdentity, 8) = "" Then
        $sIdentity = $g_sTargetProcessName
    ElseIf $g_sTargetProcessName <> "" Then
        $sIdentity &= " [" & $g_sTargetProcessName & "]"
    EndIf

    GUICtrlSetData( _
            $g_idWindowValue, _
            $sIdentity & " | PID " & $g_iTargetWindowPID & $sSize)
EndFunc

Func _ResetDetectionDisplay()
    GUICtrlSetData($g_idPlayerValue, "Not detected")
    GUICtrlSetData($g_idTargetValue, "Not detected")
    GUICtrlSetData($g_idDistanceValue, "No distance yet")
EndFunc

Func _SetContinuousUi()
    If $g_bContinuous Then
        GUICtrlSetData($g_idContinuousButton, "Stop Continuous")
    Else
        GUICtrlSetData($g_idContinuousButton, "Start Continuous")
    EndIf
EndFunc


; ============================================================================
; /data template library, import, and snippet capture
; ============================================================================

Func _ReloadTemplateLibrary($bNotify)
    DirCreate($DATA_DIRECTORY)
    DirCreate($PLAYER_TEMPLATE_DIRECTORY)
    DirCreate($TARGET_TEMPLATE_DIRECTORY)

    _LoadPngTemplates( _
            $PLAYER_TEMPLATE_DIRECTORY, _
            $g_aPlayerTemplates, _
            $g_iPlayerTemplateCount)

    _LoadPngTemplates( _
            $TARGET_TEMPLATE_DIRECTORY, _
            $g_aTargetTemplates, _
            $g_iTargetTemplateCount)

    _UpdateTemplateDisplay()

    _Log( _
            "Template library reloaded: players=" & _
            $g_iPlayerTemplateCount & _
            "; targets=" & $g_iTargetTemplateCount)

    If $bNotify Then
        _SetStatus( _
                "Reloaded /data: " & _
                $g_iPlayerTemplateCount & " player image(s), " & _
                $g_iTargetTemplateCount & " target image(s).")
    EndIf
EndFunc

Func _LoadPngTemplates( _
        $sDirectory, _
        ByRef $aTemplates, _
        ByRef $iTemplateCount)

    $iTemplateCount = 0
    ReDim $aTemplates[1]

    Local $hSearch = FileFindFirstFile($sDirectory & "\*.png")

    If $hSearch = -1 Then Return 0

    While True
        Local $sFileName = FileFindNextFile($hSearch)

        If @error Then ExitLoop
        If $sFileName = "" Then ContinueLoop

        If $iTemplateCount >= UBound($aTemplates) Then
            ReDim $aTemplates[$iTemplateCount + 1]
        EndIf

        $aTemplates[$iTemplateCount] = $sDirectory & "\" & $sFileName
        $iTemplateCount += 1
    WEnd

    FileClose($hSearch)

    If $iTemplateCount > 0 Then
        ReDim $aTemplates[$iTemplateCount]
    EndIf

    Return $iTemplateCount
EndFunc

Func _ImportTemplateImages($sDestinationDirectory, $sCategory)
    _DisableContinuousSearch("Importing template images.")

    Local $sSelected = FileOpenDialog( _
            "Import " & $sCategory & " PNG images", _
            @MyDocumentsDir, _
            "PNG images (*.png)", _
            BitOR($FD_FILEMUSTEXIST, $FD_MULTISELECT))

    If @error Or $sSelected = "" Then
        _SetStatus("Image import cancelled.")
        Return
    EndIf

    DirCreate($sDestinationDirectory)

    Local $aSelection = StringSplit($sSelected, "|")
    Local $iCopied = 0
    Local $iFailed = 0

    If $aSelection[0] = 1 Then
        If _CopyTemplateFile($aSelection[1], $sDestinationDirectory) Then
            $iCopied += 1
        Else
            $iFailed += 1
        EndIf
    Else
        Local $sSourceDirectory = $aSelection[1]
        Local $i

        For $i = 2 To $aSelection[0]
            Local $sSourcePath = _
                    $sSourceDirectory & "\" & $aSelection[$i]

            If _CopyTemplateFile($sSourcePath, $sDestinationDirectory) Then
                $iCopied += 1
            Else
                $iFailed += 1
            EndIf
        Next
    EndIf

    _ReloadTemplateLibrary(False)

    _Log( _
            "Imported " & $sCategory & " images: copied=" & _
            $iCopied & "; failed=" & $iFailed)

    _SetStatus( _
            "Imported " & $iCopied & " " & $sCategory & _
            " image(s). Failed: " & $iFailed & _
            ". The /data library was reloaded.")

    _RunImmediateLibraryTest()
EndFunc

Func _CopyTemplateFile($sSourcePath, $sDestinationDirectory)
    If Not FileExists($sSourcePath) Then Return False

    Local $sDestinationPath = _
            _UniqueDestinationPath( _
                $sDestinationDirectory, _
                _FileNameOnly($sSourcePath))

    Return FileCopy($sSourcePath, $sDestinationPath, 0) = 1
EndFunc

Func _UniqueDestinationPath($sDirectory, $sFileName)
    Local $sBaseName = $sFileName
    Local $sExtension = ""
    Local $iDot = StringInStr($sFileName, ".", 0, -1)

    If $iDot > 0 Then
        $sBaseName = StringLeft($sFileName, $iDot - 1)
        $sExtension = StringTrimLeft($sFileName, $iDot - 1)
    EndIf

    Local $sCandidate = $sDirectory & "\" & $sBaseName & $sExtension
    Local $iSuffix = 2

    While FileExists($sCandidate)
        $sCandidate = _
                $sDirectory & "\" & $sBaseName & "_" & _
                $iSuffix & $sExtension
        $iSuffix += 1
    WEnd

    Return $sCandidate
EndFunc

Func _CaptureTemplateSnippet($sDestinationDirectory, $sCategory)
    _DisableContinuousSearch("Capturing a template snippet.")
    _ClearHighlights()

    Local $iClientLeft = 0
    Local $iClientTop = 0
    Local $iClientRight = 0
    Local $iClientBottom = 0

    If Not _GetTargetWindowRect( _
            $iClientLeft, _
            $iClientTop, _
            $iClientRight, _
            $iClientBottom) Then

        _SetStatus("Cannot capture: no usable game window is bound.")
        Return
    EndIf

    _SetStatus( _
            "Capture mode: drag a rectangle over the game. " & _
            "Press Esc or right-click to cancel.")

    GUISetState(@SW_HIDE, $g_hControlGui)
    WinActivate($g_hTargetWindow)
    Sleep(250)

    Local $iLeft = 0
    Local $iTop = 0
    Local $iRight = 0
    Local $iBottom = 0

    Local $bSelected = _SelectCaptureRectangle( _
            $iClientLeft, _
            $iClientTop, _
            $iClientRight, _
            $iClientBottom, _
            $iLeft, _
            $iTop, _
            $iRight, _
            $iBottom)

    GUISetState(@SW_SHOW, $g_hControlGui)
    _PositionPanelNextToTarget()

    If Not $bSelected Then
        _SetStatus("Snippet capture cancelled.")
        Return
    EndIf

    Local $sDefaultName = _
            $sCategory & "_" & _TimestampWithMilliseconds()

    Local $sName = InputBox( _
            "Save " & $sCategory & " template", _
            "Template filename (PNG):", _
            $sDefaultName)

    If @error Then
        _SetStatus("Snippet capture cancelled before saving.")
        Return
    EndIf

    $sName = _SanitizeTemplateName($sName)

    If $sName = "" Then
        _SetStatus("Snippet was not saved: filename was empty.")
        Return
    EndIf

    DirCreate($sDestinationDirectory)

    Local $sDestinationPath = _
            _UniqueDestinationPath( _
                $sDestinationDirectory, _
                $sName & ".png")

    Local $bSaved = _ImageSearch_ScreenCapture_SaveImage( _
            $sDestinationPath, _
            $iLeft, _
            $iTop, _
            $iRight, _
            $iBottom, _
            $SEARCH_SCREEN)

    Local $iCaptureError = @error
    Local $iCaptureExtended = @extended

    If Not $bSaved Then
        _Log( _
                "Snippet capture failed: error=" & $iCaptureError & _
                "; extended=" & $iCaptureExtended)

        _SetStatus("Snippet capture failed. Check the debug log.")
        Return
    EndIf

    _Log( _
            "Snippet saved: category=" & $sCategory & _
            "; path=" & $sDestinationPath & _
            "; region=" & $iLeft & "," & $iTop & _
            " to " & $iRight & "," & $iBottom)

    _ReloadTemplateLibrary(False)

    _SetStatus( _
            "Saved " & $sCategory & " snippet: " & _
            $sDestinationPath & _
            ". The /data library was reloaded.")

    _RunImmediateLibraryTest()
EndFunc

Func _SelectCaptureRectangle( _
        $iClientLeft, _
        $iClientTop, _
        $iClientRight, _
        $iClientBottom, _
        ByRef $iSelectedLeft, _
        ByRef $iSelectedTop, _
        ByRef $iSelectedRight, _
        ByRef $iSelectedBottom)

    Local $iClientWidth = $iClientRight - $iClientLeft + 1
    Local $iClientHeight = $iClientBottom - $iClientTop + 1

    Local $hCaptureSurface = GUICreate( _
            "", _
            $iClientWidth, _
            $iClientHeight, _
            $iClientLeft, _
            $iClientTop, _
            $WS_POPUP, _
            BitOR($WS_EX_TOPMOST, $WS_EX_TOOLWINDOW))

    GUISetBkColor(0x000000, $hCaptureSurface)
    WinSetTrans($hCaptureSurface, "", 1)
    GUISetState(@SW_SHOW, $hCaptureSurface)

    Local $aBars[4]
    _CreateCaptureBars($aBars)

    TrayTip( _
            "Template snippet capture", _
            "Drag with the left mouse button. Esc or right-click cancels.", _
            10)

    While _IsPressed("01")
        Sleep(20)
    WEnd

    Local $hWaitTimer = TimerInit()
    Local $aStart = 0
    Local $bStarted = False

    While TimerDiff($hWaitTimer) < 20000
        If _IsPressed("1B") Or _IsPressed("02") Then ExitLoop

        If _IsPressed("01") Then
            $aStart = MouseGetPos()

            If IsArray($aStart) And _
                    $aStart[0] >= $iClientLeft And _
                    $aStart[0] <= $iClientRight And _
                    $aStart[1] >= $iClientTop And _
                    $aStart[1] <= $iClientBottom Then

                $bStarted = True
                ExitLoop
            EndIf
        EndIf

        Sleep(15)
    WEnd

    If Not $bStarted Then
        _DeleteCaptureBars($aBars)
        GUIDelete($hCaptureSurface)
        TrayTip("", "", 0)
        Return False
    EndIf

    Local $iStartX = $aStart[0]
    Local $iStartY = $aStart[1]
    Local $iCurrentX = $iStartX
    Local $iCurrentY = $iStartY

    While _IsPressed("01")
        If _IsPressed("1B") Or _IsPressed("02") Then
            _DeleteCaptureBars($aBars)
            GUIDelete($hCaptureSurface)
            TrayTip("", "", 0)
            Return False
        EndIf

        Local $aMouse = MouseGetPos()

        If IsArray($aMouse) Then
            $iCurrentX = _ClampValue( _
                    $aMouse[0], _
                    $iClientLeft, _
                    $iClientRight)

            $iCurrentY = _ClampValue( _
                    $aMouse[1], _
                    $iClientTop, _
                    $iClientBottom)

            _UpdateCaptureBars( _
                    $aBars, _
                    $iStartX, _
                    $iStartY, _
                    $iCurrentX, _
                    $iCurrentY)
        EndIf

        Sleep(15)
    WEnd

    $iSelectedLeft = $iStartX
    $iSelectedRight = $iCurrentX
    $iSelectedTop = $iStartY
    $iSelectedBottom = $iCurrentY

    If $iSelectedLeft > $iSelectedRight Then
        Local $iSwapX = $iSelectedLeft
        $iSelectedLeft = $iSelectedRight
        $iSelectedRight = $iSwapX
    EndIf

    If $iSelectedTop > $iSelectedBottom Then
        Local $iSwapY = $iSelectedTop
        $iSelectedTop = $iSelectedBottom
        $iSelectedBottom = $iSwapY
    EndIf

    _DeleteCaptureBars($aBars)
    GUIDelete($hCaptureSurface)
    TrayTip("", "", 0)
    Sleep(120)

    If ($iSelectedRight - $iSelectedLeft + 1) < 3 Then Return False
    If ($iSelectedBottom - $iSelectedTop + 1) < 3 Then Return False

    Return True
EndFunc

Func _CreateCaptureBars(ByRef $aBars)
    Local $i

    For $i = 0 To 3
        $aBars[$i] = GUICreate( _
                "", _
                1, _
                1, _
                0, _
                0, _
                $WS_POPUP, _
                BitOR( _
                    $WS_EX_TOPMOST, _
                    $WS_EX_TOOLWINDOW, _
                    $WS_EX_TRANSPARENT))

        GUISetBkColor(0xFF3030, $aBars[$i])
        GUISetState(@SW_SHOWNOACTIVATE, $aBars[$i])
    Next
EndFunc

Func _UpdateCaptureBars( _
        ByRef $aBars, _
        $iStartX, _
        $iStartY, _
        $iCurrentX, _
        $iCurrentY)

    Local $iLeft = $iStartX
    Local $iRight = $iCurrentX
    Local $iTop = $iStartY
    Local $iBottom = $iCurrentY

    If $iLeft > $iRight Then
        Local $iSwapX = $iLeft
        $iLeft = $iRight
        $iRight = $iSwapX
    EndIf

    If $iTop > $iBottom Then
        Local $iSwapY = $iTop
        $iTop = $iBottom
        $iBottom = $iSwapY
    EndIf

    Local $iWidth = $iRight - $iLeft + 1
    Local $iHeight = $iBottom - $iTop + 1
    Local $iBorder = 2

    WinMove($aBars[0], "", $iLeft, $iTop, $iWidth, $iBorder)
    WinMove($aBars[1], "", $iLeft, $iBottom - $iBorder + 1, $iWidth, $iBorder)
    WinMove($aBars[2], "", $iLeft, $iTop, $iBorder, $iHeight)
    WinMove($aBars[3], "", $iRight - $iBorder + 1, $iTop, $iBorder, $iHeight)
EndFunc

Func _DeleteCaptureBars(ByRef $aBars)
    Local $i

    For $i = 0 To UBound($aBars) - 1
        If $aBars[$i] <> 0 Then
            GUIDelete($aBars[$i])
            $aBars[$i] = 0
        EndIf
    Next
EndFunc

Func _ClampValue($iValue, $iMinimum, $iMaximum)
    If $iValue < $iMinimum Then Return $iMinimum
    If $iValue > $iMaximum Then Return $iMaximum

    Return $iValue
EndFunc

Func _SanitizeTemplateName($sName)
    $sName = StringStripWS($sName, 3)

    If StringLower(StringRight($sName, 4)) = ".png" Then
        $sName = StringTrimRight($sName, 4)
    EndIf

    $sName = StringRegExpReplace($sName, '[<>:"/\\|?*]', "_")
    $sName = StringRegExpReplace($sName, "\s+", "_")
    $sName = StringStripWS($sName, 3)

    Return $sName
EndFunc

Func _RunImmediateLibraryTest()
    If $g_hTargetWindow = 0 Or Not WinExists($g_hTargetWindow) Then Return
    If $g_iPlayerTemplateCount <= 0 Then Return
    If $g_iTargetTemplateCount <= 0 Then Return

    Sleep(150)
    _RunDistanceSearch(False)
EndFunc

; ============================================================================
; Window detection and binding
; ============================================================================

Func _AutoDetectGameClient($bNotify)
    Local $hDetectedWindow = _FindLargestVisibleTargetProcessWindow()

    If $hDetectedWindow = 0 Then
        If $bNotify Then
            _Log("Automatic game-client detection found no qualifying window")
            _SetStatus( _
                    "No visible MapleSaga.exe or MapleStory.exe client of at least " & _
                    $MIN_GAME_CLIENT_WIDTH & "x" & $MIN_GAME_CLIENT_HEIGHT & _
                    " was found.")
        EndIf

        Return False
    EndIf

    If $hDetectedWindow = $g_hTargetWindow Then
        _RefreshBoundWindowMetadata()

        If $bNotify Then
            _SetStatus("The best game client is already bound.")
        EndIf

        Return True
    EndIf

    Return _BindTargetWindow($hDetectedWindow, "automatic process detection")
EndFunc

Func _MaintainBestGameWindow()
    Local $hBestWindow = _FindLargestVisibleTargetProcessWindow()

    If $hBestWindow = 0 Then
        If $g_hTargetWindow <> 0 And Not WinExists($g_hTargetWindow) Then
            $g_hTargetWindow = 0
            $g_sTargetWindowTitle = ""
            $g_iTargetWindowPID = 0
            $g_sTargetProcessName = ""
            _UpdateWindowDisplay()
            _DisableContinuousSearch("The game window closed.")
        EndIf

        Return
    EndIf

    If $g_hTargetWindow = 0 Or Not WinExists($g_hTargetWindow) Then
        _BindTargetWindow($hBestWindow, "automatic maintenance")
        Return
    EndIf

    If $hBestWindow <> $g_hTargetWindow Then
        Local $iBestArea = _GetClientArea($hBestWindow)
        Local $iCurrentArea = _GetClientArea($g_hTargetWindow)

        If $iBestArea > $iCurrentArea Then
            _BindTargetWindow($hBestWindow, "larger game window detected")
            Return
        EndIf
    EndIf

    _RefreshBoundWindowMetadata()
EndFunc

Func _FindLargestVisibleTargetProcessWindow()
    Local $aWindows = WinList()

    If @error Or Not IsArray($aWindows) Then Return 0

    Local $hBestWindow = 0
    Local $iBestArea = 0
    Local $i

    For $i = 1 To $aWindows[0][0]
        Local $hCandidate = $aWindows[$i][1]

        If $hCandidate = 0 Or $hCandidate = $g_hControlGui Then ContinueLoop

        Local $iState = WinGetState($hCandidate)

        If @error Then ContinueLoop
        If Not BitAND($iState, 2) Then ContinueLoop
        If BitAND($iState, 16) Then ContinueLoop

        Local $iCandidatePID = WinGetProcess($hCandidate)

        If @error Or $iCandidatePID <= 0 Then ContinueLoop
        If _GetTargetProcessNameByPID($iCandidatePID) = "" Then ContinueLoop

        Local $aClientSize = WinGetClientSize($hCandidate)

        If @error Or Not IsArray($aClientSize) Then ContinueLoop
        If $aClientSize[0] < $MIN_GAME_CLIENT_WIDTH Then ContinueLoop
        If $aClientSize[1] < $MIN_GAME_CLIENT_HEIGHT Then ContinueLoop

        Local $iArea = $aClientSize[0] * $aClientSize[1]

        If $iArea > $iBestArea Then
            $iBestArea = $iArea
            $hBestWindow = $hCandidate
        EndIf
    Next

    Return $hBestWindow
EndFunc

Func _GetTargetProcessNameByPID($iPID)
    If $iPID <= 0 Then Return ""

    Local $iProcessIndex

    For $iProcessIndex = 0 To UBound($g_aTargetProcessNames) - 1
        Local $aProcesses = ProcessList($g_aTargetProcessNames[$iProcessIndex])

        If @error Or Not IsArray($aProcesses) Then ContinueLoop

        Local $iPidIndex

        For $iPidIndex = 1 To $aProcesses[0][0]
            If Int($aProcesses[$iPidIndex][1]) = Int($iPID) Then
                Return $g_aTargetProcessNames[$iProcessIndex]
            EndIf
        Next
    Next

    Return ""
EndFunc

Func _BindForegroundWindowAfterDelay()
    _DisableContinuousSearch("Binding a new target window.")

    _SetStatus( _
            "Panel hidden for 3 seconds. Activate the game window now.")

    GUISetState(@SW_HIDE, $g_hControlGui)
    TrayTip("Bind active window", _
            "Activate MapleSaga now. Binding occurs in 3 seconds.", 3)

    Sleep(3000)

    Local $hActiveWindow = WinGetHandle("[ACTIVE]")
    Local $bBound = False

    If Not @error And $hActiveWindow <> 0 And $hActiveWindow <> $g_hControlGui Then
        $bBound = _BindTargetWindow($hActiveWindow, "delayed active-window binding")
    EndIf

    GUISetState(@SW_SHOW, $g_hControlGui)

    If Not $bBound Then
        _Log("Delayed active-window binding failed")
        _SetStatus("Binding failed. Try automatic detection or repeat the countdown.")
    EndIf
EndFunc

Func _BindTargetWindow($hWindow, $sSource)
    If $hWindow = 0 Or Not WinExists($hWindow) Then Return False

    Local $iState = WinGetState($hWindow)

    If @error Or Not BitAND($iState, 2) Or BitAND($iState, 16) Then
        Return False
    EndIf

    Local $aClientSize = WinGetClientSize($hWindow)

    If @error Or Not IsArray($aClientSize) Then Return False
    If $aClientSize[0] < 1 Or $aClientSize[1] < 1 Then Return False

    $g_hTargetWindow = $hWindow
    $g_sTargetWindowTitle = WinGetTitle($g_hTargetWindow)
    $g_iTargetWindowPID = WinGetProcess($g_hTargetWindow)
    $g_sTargetProcessName = _GetTargetProcessNameByPID($g_iTargetWindowPID)

    If $g_sTargetProcessName = "" Then
        $g_sTargetProcessName = "PID " & $g_iTargetWindowPID
    EndIf

    _ClearHighlights()
    _ResetDetectionDisplay()
    _UpdateWindowDisplay()
    _PositionPanelNextToTarget()

    Local $iLeft = 0
    Local $iTop = 0
    Local $iRight = 0
    Local $iBottom = 0

    If _GetTargetWindowRect($iLeft, $iTop, $iRight, $iBottom) Then
        _Log("Target window bound via " & $sSource & ":")
        _Log("  Title: " & $g_sTargetWindowTitle)
        _Log("  Process: " & $g_sTargetProcessName)
        _Log("  PID: " & $g_iTargetWindowPID)
        _Log("  Client region: " & $iLeft & "," & $iTop & _
                " to " & $iRight & "," & $iBottom)
        _Log("  Client size: " & ($iRight - $iLeft + 1) & _
                "x" & ($iBottom - $iTop + 1))
    EndIf

    _SetStatus("Bound to " & $g_sTargetProcessName & ". Ready to measure.")
    Return True
EndFunc

Func _RefreshBoundWindowMetadata()
    If $g_hTargetWindow = 0 Or Not WinExists($g_hTargetWindow) Then Return

    $g_sTargetWindowTitle = WinGetTitle($g_hTargetWindow)
    $g_iTargetWindowPID = WinGetProcess($g_hTargetWindow)
    $g_sTargetProcessName = _GetTargetProcessNameByPID($g_iTargetWindowPID)

    If $g_sTargetProcessName = "" Then
        $g_sTargetProcessName = "PID " & $g_iTargetWindowPID
    EndIf

    _UpdateWindowDisplay()
EndFunc

Func _ActivateTargetWindow()
    If $g_hTargetWindow = 0 Or Not WinExists($g_hTargetWindow) Then
        _SetStatus("No valid game window is bound.")
        Return
    EndIf

    WinActivate($g_hTargetWindow)

    If WinWaitActive($g_hTargetWindow, "", 2) Then
        _SetStatus("Activated " & $g_sTargetProcessName & ".")
    Else
        _SetStatus("Windows did not activate the bound window.")
    EndIf
EndFunc

Func _PositionPanelNextToTarget()
    If $g_hControlGui = 0 Then Return
    If $g_hTargetWindow = 0 Or Not WinExists($g_hTargetWindow) Then Return

    Local $aWindowPos = WinGetPos($g_hTargetWindow)

    If @error Or Not IsArray($aWindowPos) Then Return

    Local $iPanelX = @DesktopWidth - $PANEL_WIDTH - 15
    Local $iPanelY = 15

    Local $iRightCandidate = $aWindowPos[0] + $aWindowPos[2] + 10
    Local $iLeftCandidate = $aWindowPos[0] - $PANEL_WIDTH - 10

    If $iRightCandidate + $PANEL_WIDTH <= @DesktopWidth Then
        $iPanelX = $iRightCandidate
        $iPanelY = $aWindowPos[1]
    ElseIf $iLeftCandidate >= 0 Then
        $iPanelX = $iLeftCandidate
        $iPanelY = $aWindowPos[1]
    EndIf

    If $iPanelY < 0 Then $iPanelY = 0
    If $iPanelY + $PANEL_HEIGHT > @DesktopHeight Then
        $iPanelY = @DesktopHeight - $PANEL_HEIGHT
    EndIf

    WinMove($g_hControlGui, "", $iPanelX, $iPanelY)
EndFunc

Func _GetTargetWindowRect( _
        ByRef $iLeft, _
        ByRef $iTop, _
        ByRef $iRight, _
        ByRef $iBottom)

    If $g_hTargetWindow = 0 Or Not WinExists($g_hTargetWindow) Then
        Return False
    EndIf

    Local $iWindowState = WinGetState($g_hTargetWindow)

    If @error Or BitAND($iWindowState, 16) Then Return False

    Local $aClientSize = WinGetClientSize($g_hTargetWindow)

    If @error Or Not IsArray($aClientSize) Then Return False
    If $aClientSize[0] < 1 Or $aClientSize[1] < 1 Then Return False

    Local $tClientOrigin = DllStructCreate("long X;long Y")
    DllStructSetData($tClientOrigin, "X", 0)
    DllStructSetData($tClientOrigin, "Y", 0)

    Local $aClientToScreen = DllCall( _
            "user32.dll", _
            "bool", _
            "ClientToScreen", _
            "hwnd", _
            $g_hTargetWindow, _
            "struct*", _
            $tClientOrigin)

    If @error Or Not IsArray($aClientToScreen) Or Not $aClientToScreen[0] Then
        Return False
    EndIf

    $iLeft = DllStructGetData($tClientOrigin, "X")
    $iTop = DllStructGetData($tClientOrigin, "Y")
    $iRight = $iLeft + $aClientSize[0] - 1
    $iBottom = $iTop + $aClientSize[1] - 1

    Return True
EndFunc

Func _GetClientArea($hWindow)
    If $hWindow = 0 Or Not WinExists($hWindow) Then Return 0

    Local $aClientSize = WinGetClientSize($hWindow)

    If @error Or Not IsArray($aClientSize) Then Return 0

    Return $aClientSize[0] * $aClientSize[1]
EndFunc

; ============================================================================
; Distance search
; ============================================================================

Func _ToggleContinuousSearch()
    If $g_bContinuous Then
        _DisableContinuousSearch("Stopped by user.")
        _SetStatus("Continuous distance search stopped.")
        Return
    EndIf

    If Not _ValidateReadyToSearch() Then Return

    $g_bContinuous = True
    $g_hContinuousTimer = TimerInit()

    _Log("Continuous distance search enabled")
    _SetContinuousUi()
    _RunDistanceSearch(False)
EndFunc

Func _DisableContinuousSearch($sReason)
    If Not $g_bContinuous Then Return

    $g_bContinuous = False
    _SetContinuousUi()
    _Log("Continuous distance search disabled: " & $sReason)
EndFunc

Func _ValidateReadyToSearch()
    _UpdateTemplateDisplay()

    If $g_iPlayerTemplateCount <= 0 Then
        _SetStatus( _
                "No player PNGs found. Add images to: " & _
                $PLAYER_TEMPLATE_DIRECTORY)
        Return False
    EndIf

    If $g_iTargetTemplateCount <= 0 Then
        _SetStatus( _
                "No target PNGs found. Add images to: " & _
                $TARGET_TEMPLATE_DIRECTORY)
        Return False
    EndIf

    Local $iLeft = 0
    Local $iTop = 0
    Local $iRight = 0
    Local $iBottom = 0

    If Not _GetTargetWindowRect($iLeft, $iTop, $iRight, $iBottom) Then
        _SetStatus("No usable visible game window is bound.")
        Return False
    EndIf

    Return True
EndFunc

Func _RunDistanceSearch($bCaptureOnMiss)
    If $g_bSearchBusy Then Return

    If Not _ValidateReadyToSearch() Then
        _DisableContinuousSearch("Search prerequisites are invalid.")
        Return
    EndIf

    $g_bSearchBusy = True
    _ClearHighlights()

    Local $iSearchLeft = 0
    Local $iSearchTop = 0
    Local $iSearchRight = 0
    Local $iSearchBottom = 0

    If Not _GetTargetWindowRect( _
            $iSearchLeft, _
            $iSearchTop, _
            $iSearchRight, _
            $iSearchBottom) Then

        _DisableContinuousSearch("The game window is unavailable.")
        _SetStatus("Game window unavailable or minimized.")
        $g_bSearchBusy = False
        Return
    EndIf

    Local $hTimer = TimerInit()

    ; ------------------------------------------------------------------------
    ; Search every player visual state.
    ; Do NOT abort if the player is missing; target diagnostics must still run.
    ; ------------------------------------------------------------------------
    Local $bPlayerFound = False
    Local $iPlayerX = 0
    Local $iPlayerY = 0
    Local $iPlayerWidth = 0
    Local $iPlayerHeight = 0
    Local $iPlayerTemplateIndex = -1
    Local $iPlayerIndex

    For $iPlayerIndex = 0 To $g_iPlayerTemplateCount - 1
        Local $aPlayerResults = _ImageSearch( _
                $g_aPlayerTemplates[$iPlayerIndex], _
                $iSearchLeft, _
                $iSearchTop, _
                $iSearchRight, _
                $iSearchBottom, _
                $SEARCH_SCREEN, _
                $PLAYER_TOLERANCE, _
                $PLAYER_MAX_RESULTS, _
                0, _
                $MIN_SCALE, _
                $MAX_SCALE, _
                $SCALE_STEP, _
                0, _
                0)

        Local $iPlayerError = @error
        Local $iPlayerExtended = @extended

        If $iPlayerError <> 0 Then
            _Log( _
                    "PLAYER TEMPLATE ERROR " & _
                    _FileNameOnly($g_aPlayerTemplates[$iPlayerIndex]) & _
                    ": error=" & $iPlayerError & _
                    "; extended=" & $iPlayerExtended)
            ContinueLoop
        EndIf

        If Not _HasSearchMatches($aPlayerResults) Then ContinueLoop

        $bPlayerFound = True
        $iPlayerTemplateIndex = $iPlayerIndex
        $iPlayerX = Int($aPlayerResults[1][0])
        $iPlayerY = Int($aPlayerResults[1][1])
        $iPlayerWidth = Int($aPlayerResults[1][2])
        $iPlayerHeight = Int($aPlayerResults[1][3])
        ExitLoop
    Next

    Local $nPlayerCenterX = 0
    Local $nPlayerCenterY = 0

    If $bPlayerFound Then
        $nPlayerCenterX = $iPlayerX + ($iPlayerWidth / 2)
        $nPlayerCenterY = $iPlayerY + ($iPlayerHeight / 2)

        _DrawHighlight( _
                $iPlayerX, _
                $iPlayerY, _
                $iPlayerWidth, _
                $iPlayerHeight, _
                $PLAYER_OVERLAY_COLOR)

        GUICtrlSetData( _
                $g_idPlayerValue, _
                "Found by " & _
                _FileNameOnly($g_aPlayerTemplates[$iPlayerTemplateIndex]) & _
                " at client " & _
                ($iPlayerX - $iSearchLeft) & "," & _
                ($iPlayerY - $iSearchTop) & _
                " | " & $iPlayerWidth & "x" & $iPlayerHeight)

        _Log( _
                "PLAYER FOUND template=" & _
                _FileNameOnly($g_aPlayerTemplates[$iPlayerTemplateIndex]) & _
                " x=" & $iPlayerX & _
                " y=" & $iPlayerY)
    Else
        GUICtrlSetData($g_idPlayerValue, "Not detected across " & $g_iPlayerTemplateCount & " template(s)")
        _Log("PLAYER MISS across all " & $g_iPlayerTemplateCount & " templates")
    EndIf

    ; ------------------------------------------------------------------------
    ; Search every PNG in data\target regardless of player result.
    ; ------------------------------------------------------------------------
    Local $aTargetMatches[$MAX_UNIQUE_TARGETS][5]
    Local $iTargetCount = 0
    Local $iTemplateIndex

    For $iTemplateIndex = 0 To $g_iTargetTemplateCount - 1
        Local $aTargetResults = _ImageSearch( _
                $g_aTargetTemplates[$iTemplateIndex], _
                $iSearchLeft, _
                $iSearchTop, _
                $iSearchRight, _
                $iSearchBottom, _
                $SEARCH_SCREEN, _
                $TARGET_TOLERANCE, _
                $TARGET_MAX_RESULTS_PER_TEMPLATE, _
                0, _
                $MIN_SCALE, _
                $MAX_SCALE, _
                $SCALE_STEP, _
                0, _
                0)

        Local $iTargetSearchError = @error
        Local $iTargetSearchExtended = @extended

        If $iTargetSearchError <> 0 Then
            _Log( _
                    "TARGET TEMPLATE ERROR " & _
                    _FileNameOnly($g_aTargetTemplates[$iTemplateIndex]) & _
                    ": error=" & $iTargetSearchError & _
                    "; extended=" & $iTargetSearchExtended)
            ContinueLoop
        EndIf

        If Not _HasSearchMatches($aTargetResults) Then
            ContinueLoop
        EndIf

        Local $iTemplateMatchCount = Int($aTargetResults[0][0])
        Local $iAvailableMatches = UBound($aTargetResults, 1) - 1

        If $iTemplateMatchCount > $iAvailableMatches Then
            $iTemplateMatchCount = $iAvailableMatches
        EndIf

        _Log( _
                "TARGET TEMPLATE HIT " & _
                _FileNameOnly($g_aTargetTemplates[$iTemplateIndex]) & _
                " matches=" & $iTemplateMatchCount)

        Local $iMatchIndex

        For $iMatchIndex = 1 To $iTemplateMatchCount
            _AddUniqueTargetMatch( _
                    $aTargetMatches, _
                    $iTargetCount, _
                    Int($aTargetResults[$iMatchIndex][0]), _
                    Int($aTargetResults[$iMatchIndex][1]), _
                    Int($aTargetResults[$iMatchIndex][2]), _
                    Int($aTargetResults[$iMatchIndex][3]), _
                    $iTemplateIndex)
        Next
    Next

    Local $nElapsed = Round(TimerDiff($hTimer), 2)

    If $iTargetCount <= 0 Then
        GUICtrlSetData($g_idTargetValue, "0 detected")

        If $bPlayerFound Then
            GUICtrlSetData($g_idDistanceValue, "Player found; no target matched")
            _SetStatus( _
                    "Player found, but no target template matched in " & _
                    $nElapsed & " ms.")
            _Log("PLAYER FOUND but TARGET MISS after " & $nElapsed & " ms")
        Else
            GUICtrlSetData($g_idDistanceValue, "Neither player nor target matched")
            _SetStatus( _
                    "No player state and no target template matched in " & _
                    $nElapsed & " ms.")
            _Log("PLAYER MISS and TARGET MISS after " & $nElapsed & " ms")
        EndIf

        If $bCaptureOnMiss Then
            _SaveFailureScreenshot("player-and-or-target-not-found")
        EndIf

        $g_bSearchBusy = False
        Return
    EndIf

    GUICtrlSetData( _
            $g_idTargetValue, _
            $iTargetCount & " unique target(s) detected")

    ; If targets were found without a player, highlight all of them and report
    ; the successful target stage instead of hiding it behind the player miss.
    If Not $bPlayerFound Then
        Local $iFoundTargetIndex

        For $iFoundTargetIndex = 0 To $iTargetCount - 1
            _DrawHighlight( _
                    $aTargetMatches[$iFoundTargetIndex][0], _
                    $aTargetMatches[$iFoundTargetIndex][1], _
                    $aTargetMatches[$iFoundTargetIndex][2], _
                    $aTargetMatches[$iFoundTargetIndex][3], _
                    $TARGET_OVERLAY_COLOR)
        Next

        GUICtrlSetData( _
                $g_idDistanceValue, _
                "Targets found; distance unavailable until player is found")

        _SetStatus( _
                "Found " & $iTargetCount & _
                " target(s) in " & $nElapsed & _
                " ms, but no player nameplate state matched.")

        _Log( _
                "TARGETS FOUND WITHOUT PLAYER: count=" & _
                $iTargetCount & _
                "; elapsedMs=" & $nElapsed)

        If $bCaptureOnMiss Then
            _SaveFailureScreenshot("player-not-found-targets-found")
        EndIf

        $g_bSearchBusy = False
        Return
    EndIf

    ; ------------------------------------------------------------------------
    ; Player and targets both found: select nearest center.
    ; ------------------------------------------------------------------------
    Local $iNearestIndex = -1
    Local $nNearestDistance = 999999999
    Local $nNearestDeltaX = 0
    Local $nNearestDeltaY = 0
    Local $iTargetIndex

    For $iTargetIndex = 0 To $iTargetCount - 1
        Local $nTargetCenterX = _
                $aTargetMatches[$iTargetIndex][0] + _
                ($aTargetMatches[$iTargetIndex][2] / 2)

        Local $nTargetCenterY = _
                $aTargetMatches[$iTargetIndex][1] + _
                ($aTargetMatches[$iTargetIndex][3] / 2)

        Local $nDeltaX = $nTargetCenterX - $nPlayerCenterX
        Local $nDeltaY = $nTargetCenterY - $nPlayerCenterY
        Local $nDistance = Sqrt(($nDeltaX ^ 2) + ($nDeltaY ^ 2))

        _Log( _
                "TARGET " & ($iTargetIndex + 1) & _
                " template=" & _
                _FileNameOnly( _
                    $g_aTargetTemplates[$aTargetMatches[$iTargetIndex][4]]) & _
                " x=" & $aTargetMatches[$iTargetIndex][0] & _
                " y=" & $aTargetMatches[$iTargetIndex][1] & _
                " dx=" & Round($nDeltaX, 2) & _
                " dy=" & Round($nDeltaY, 2) & _
                " distance=" & Round($nDistance, 2))

        If $nDistance < $nNearestDistance Then
            $nNearestDistance = $nDistance
            $iNearestIndex = $iTargetIndex
            $nNearestDeltaX = $nDeltaX
            $nNearestDeltaY = $nDeltaY
        EndIf
    Next

    For $iTargetIndex = 0 To $iTargetCount - 1
        If $iTargetIndex = $iNearestIndex Then ContinueLoop

        _DrawHighlight( _
                $aTargetMatches[$iTargetIndex][0], _
                $aTargetMatches[$iTargetIndex][1], _
                $aTargetMatches[$iTargetIndex][2], _
                $aTargetMatches[$iTargetIndex][3], _
                $TARGET_OVERLAY_COLOR)
    Next

    _DrawHighlight( _
            $aTargetMatches[$iNearestIndex][0], _
            $aTargetMatches[$iNearestIndex][1], _
            $aTargetMatches[$iNearestIndex][2], _
            $aTargetMatches[$iNearestIndex][3], _
            $NEAREST_OVERLAY_COLOR)

    Local $sHorizontalDirection = "same X"

    If $nNearestDeltaX > 0 Then
        $sHorizontalDirection = "right"
    ElseIf $nNearestDeltaX < 0 Then
        $sHorizontalDirection = "left"
    EndIf

    Local $sVerticalDirection = "same Y"

    If $nNearestDeltaY > 0 Then
        $sVerticalDirection = "below"
    ElseIf $nNearestDeltaY < 0 Then
        $sVerticalDirection = "above"
    EndIf

    $nElapsed = Round(TimerDiff($hTimer), 2)

    GUICtrlSetData( _
            $g_idDistanceValue, _
            "Distance: " & StringFormat("%.1f", $nNearestDistance) & _
            " px | DX: " & StringFormat("%.1f", $nNearestDeltaX) & _
            " | DY: " & StringFormat("%.1f", $nNearestDeltaY) & @CRLF & _
            "Nearest target is " & $sHorizontalDirection & _
            " and " & $sVerticalDirection & ".")

    _SetStatus( _
            "Measured player to nearest target in " & $nElapsed & _
            " ms. Blue = player, orange = nearest target, green = other targets.")

    _Log( _
            "DISTANCE RESULT: targets=" & $iTargetCount & _
            "; nearestIndex=" & $iNearestIndex & _
            "; dx=" & Round($nNearestDeltaX, 2) & _
            "; dy=" & Round($nNearestDeltaY, 2) & _
            "; distance=" & Round($nNearestDistance, 2) & _
            "; elapsedMs=" & $nElapsed)

    $g_bSearchBusy = False
EndFunc

Func _HasSearchMatches(ByRef $aResults)
    If Not IsArray($aResults) Then Return False
    If UBound($aResults, 0) <> 2 Then Return False
    If UBound($aResults, 1) < 2 Then Return False
    If UBound($aResults, 2) < 4 Then Return False
    If Int($aResults[0][0]) <= 0 Then Return False

    Return True
EndFunc

Func _AddUniqueTargetMatch( _
        ByRef $aMatches, _
        ByRef $iCount, _
        $iX, _
        $iY, _
        $iWidth, _
        $iHeight, _
        $iTemplateIndex)

    If $iCount >= UBound($aMatches, 1) Then Return False

    Local $nCandidateCenterX = $iX + ($iWidth / 2)
    Local $nCandidateCenterY = $iY + ($iHeight / 2)
    Local $i

    For $i = 0 To $iCount - 1
        Local $nExistingCenterX = _
                $aMatches[$i][0] + ($aMatches[$i][2] / 2)

        Local $nExistingCenterY = _
                $aMatches[$i][1] + ($aMatches[$i][3] / 2)

        Local $nCenterDistance = Sqrt( _
                (($nCandidateCenterX - $nExistingCenterX) ^ 2) + _
                (($nCandidateCenterY - $nExistingCenterY) ^ 2))

        If $nCenterDistance <= $DUPLICATE_CENTER_RADIUS Then
            Return False
        EndIf
    Next

    $aMatches[$iCount][0] = $iX
    $aMatches[$iCount][1] = $iY
    $aMatches[$iCount][2] = $iWidth
    $aMatches[$iCount][3] = $iHeight
    $aMatches[$iCount][4] = $iTemplateIndex
    $iCount += 1

    Return True
EndFunc

; ============================================================================
; Highlight overlays
; ============================================================================

Func _DrawHighlight($iX, $iY, $iWidth, $iHeight, $iColor)
    If $iWidth < ($OVERLAY_BORDER * 2) Then
        $iWidth = $OVERLAY_BORDER * 2
    EndIf

    If $iHeight < ($OVERLAY_BORDER * 2) Then
        $iHeight = $OVERLAY_BORDER * 2
    EndIf

    _CreateOverlayBar( _
            $iX - $OVERLAY_BORDER, _
            $iY - $OVERLAY_BORDER, _
            $iWidth + ($OVERLAY_BORDER * 2), _
            $OVERLAY_BORDER, _
            $iColor)

    _CreateOverlayBar( _
            $iX - $OVERLAY_BORDER, _
            $iY + $iHeight, _
            $iWidth + ($OVERLAY_BORDER * 2), _
            $OVERLAY_BORDER, _
            $iColor)

    _CreateOverlayBar( _
            $iX - $OVERLAY_BORDER, _
            $iY, _
            $OVERLAY_BORDER, _
            $iHeight, _
            $iColor)

    _CreateOverlayBar( _
            $iX + $iWidth, _
            $iY, _
            $OVERLAY_BORDER, _
            $iHeight, _
            $iColor)
EndFunc

Func _CreateOverlayBar($iX, $iY, $iWidth, $iHeight, $iColor)
    If $g_iOverlayCount >= UBound($g_aOverlayHandles) Then Return

    If $iWidth < 1 Then $iWidth = 1
    If $iHeight < 1 Then $iHeight = 1

    Local $hOverlay = GUICreate( _
            "", _
            $iWidth, _
            $iHeight, _
            $iX, _
            $iY, _
            $WS_POPUP, _
            BitOR( _
                $WS_EX_TOPMOST, _
                $WS_EX_TOOLWINDOW, _
                $WS_EX_TRANSPARENT))

    If @error Or $hOverlay = 0 Then
        _Log("Failed to create highlight overlay")
        Return
    EndIf

    GUISetBkColor($iColor, $hOverlay)
    WinSetTrans($hOverlay, "", 235)
    GUISetState(@SW_SHOWNOACTIVATE, $hOverlay)

    $g_aOverlayHandles[$g_iOverlayCount] = $hOverlay
    $g_iOverlayCount += 1
EndFunc

Func _ClearHighlights()
    Local $i

    For $i = 0 To $g_iOverlayCount - 1
        If $g_aOverlayHandles[$i] <> 0 Then
            GUIDelete($g_aOverlayHandles[$i])
            $g_aOverlayHandles[$i] = 0
        EndIf
    Next

    $g_iOverlayCount = 0
EndFunc

; ============================================================================
; Screenshots and logging
; ============================================================================

Func _SaveTargetWindowScreenshot($sPrefix)
    Local $iLeft = 0
    Local $iTop = 0
    Local $iRight = 0
    Local $iBottom = 0

    If Not _GetTargetWindowRect($iLeft, $iTop, $iRight, $iBottom) Then
        _SetStatus("Screenshot not saved: no usable game window.")
        Return False
    EndIf

    Local $sScreenshotPath = _
            $g_sDebugDirectory & "\" & $sPrefix & "_" & _
            _TimestampWithMilliseconds() & ".png"

    Local $bSaved = _ImageSearch_ScreenCapture_SaveImage( _
            $sScreenshotPath, _
            $iLeft, _
            $iTop, _
            $iRight, _
            $iBottom, _
            $SEARCH_SCREEN)

    Local $iCaptureError = @error
    Local $iCaptureExtended = @extended

    If $bSaved Then
        _Log("Screenshot saved: " & $sScreenshotPath)
        _SetStatus("Screenshot saved: " & $sScreenshotPath)
        Return True
    EndIf

    _Log("Screenshot failed: error=" & $iCaptureError & _
            "; extended=" & $iCaptureExtended)

    _SetStatus("Screenshot failed. Check the debug log.")
    Return False
EndFunc

Func _SaveFailureScreenshot($sReason)
    Local $iLeft = 0
    Local $iTop = 0
    Local $iRight = 0
    Local $iBottom = 0

    If Not _GetTargetWindowRect($iLeft, $iTop, $iRight, $iBottom) Then Return

    Local $sScreenshotPath = _
            $g_sDebugDirectory & "\failure_" & _
            $sReason & "_" & _TimestampWithMilliseconds() & ".png"

    Local $bSaved = _ImageSearch_ScreenCapture_SaveImage( _
            $sScreenshotPath, _
            $iLeft, _
            $iTop, _
            $iRight, _
            $iBottom, _
            $SEARCH_SCREEN)

    If $bSaved Then
        _Log("Failure screenshot saved: " & $sScreenshotPath)
    Else
        _Log("Failure screenshot could not be saved")
    EndIf
EndFunc

Func _FileNameOnly($sPath)
    Local $iLastSlash = StringInStr($sPath, "\", 0, -1)

    If $iLastSlash <= 0 Then Return $sPath

    Return StringTrimLeft($sPath, $iLastSlash)
EndFunc

Func _Log($sMessage)
    Local $sLine = "[" & @HOUR & ":" & @MIN & ":" & @SEC & "] " & _
            $sMessage & @CRLF

    ConsoleWrite($sLine)
    FileWrite($g_sLogPath, $sLine)
EndFunc

Func _TimestampWithMilliseconds()
    Local $sMilliseconds = StringFormat("%03d", @MSEC)

    Return @YEAR & @MON & @MDAY & "_" & _
            @HOUR & @MIN & @SEC & "_" & $sMilliseconds
EndFunc

Func _OnExit()
    $g_bContinuous = False
    _ClearHighlights()

    If $g_bImageSearchStarted Then
        _ImageSearch_Shutdown()
    EndIf

    _Log("Maple Template Library POC v3 stopped")
EndFunc
