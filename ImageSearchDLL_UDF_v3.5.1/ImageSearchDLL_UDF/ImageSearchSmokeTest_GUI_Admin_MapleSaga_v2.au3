#RequireAdmin
#AutoIt3Wrapper_Res_requestedExecutionLevel=requireAdministrator
#AutoIt3Wrapper_UseX64=y

#include "ImageSearchDLL_UDF_Embedded.au3"
#include <FileConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>

Opt("MustDeclareVars", 1)
Opt("TrayAutoPause", 0)
Opt("MouseCoordMode", 1)
Opt("PixelCoordMode", 1)

; ============================================================================
; ImageSearchDLL v3.5.1 GUI debugger
;
; No global keyboard hotkeys are registered.
;
; Features:
;   - Automatically detects the largest visible MapleSaga.exe/MapleStory.exe window
;   - Fallback: hide this panel and bind whichever window is active after 3 sec
;   - Searches only the bound window's visible client area
;   - Draws click-through highlight rectangles around matches
;   - Saves client-area screenshots and failure captures
;   - Logs window geometry, search timing, coordinates, and errors
;
; This script DOES NOT click or send keyboard input.
; ============================================================================

Global Const $SEARCH_SCREEN = -1       ; Entire virtual desktop/all monitors
Global Const $TOLERANCE = 20           ; 0 = exact; higher = more permissive
Global Const $MAX_RESULTS = 10
Global Const $MIN_SCALE = 0.90
Global Const $MAX_SCALE = 1.10
Global Const $SCALE_STEP = 0.05

Global Const $CONTINUOUS_INTERVAL = 750
Global Const $AUTO_DETECT_INTERVAL = 2000

Global Const $OVERLAY_COLOR = 0x00FF00
Global Const $OVERLAY_BORDER = 4
Global Const $MAX_OVERLAY_WINDOWS = $MAX_RESULTS * 4

Global Const $PANEL_WIDTH = 470
Global Const $PANEL_HEIGHT = 410

; Supported game executables. Private-server clients may have blank/custom titles.
Global $g_aTargetProcessNames[2] = ["MapleSaga.exe", "MapleStory.exe"]

Global $g_sTargetPath = ""
Global $g_hTargetWindow = 0
Global $g_sTargetWindowTitle = ""
Global $g_iTargetWindowPID = 0
Global $g_sTargetProcessName = ""

Global $g_sDebugDirectory = @ScriptDir & "\debug"
Global $g_sLogPath = $g_sDebugDirectory & "\ImageSearchSmokeTest.log"
Global $g_sSettingsPath = @ScriptDir & "\ImageSearchSmokeTest.ini"

Global $g_bImageSearchStarted = False
Global $g_bContinuous = False
Global $g_bSearchBusy = False

Global $g_hContinuousTimer = TimerInit()
Global $g_hAutoDetectTimer = TimerInit()

Global $g_aOverlayHandles[$MAX_OVERLAY_WINDOWS]
Global $g_iOverlayCount = 0

; Control panel
Global $g_hControlGui = 0
Global $g_idWindowValue = 0
Global $g_idTargetValue = 0
Global $g_idStatusValue = 0
Global $g_idSettingsValue = 0

Global $g_idDetectButton = 0
Global $g_idDelayedBindButton = 0
Global $g_idChooseTargetButton = 0
Global $g_idSearchButton = 0
Global $g_idContinuousButton = 0
Global $g_idCaptureButton = 0
Global $g_idClearButton = 0
Global $g_idOpenDebugButton = 0
Global $g_idActivateButton = 0
Global $g_idExitButton = 0

DirCreate($g_sDebugDirectory)
OnAutoItExitRegister("_OnExit")

_Log("============================================================")
_Log("ImageSearch GUI debugger starting")
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
_LoadSavedTarget()
_AutoDetectMapleStory(False)

GUISetState(@SW_SHOW, $g_hControlGui)

While True
    Local $iMessage = GUIGetMsg()

    Switch $iMessage
        Case $GUI_EVENT_CLOSE, $g_idExitButton
            ExitLoop

        Case $g_idDetectButton
            _AutoDetectMapleStory(True)

        Case $g_idDelayedBindButton
            _BindForegroundWindowAfterDelay()

        Case $g_idChooseTargetButton
            _ChooseTarget()

        Case $g_idSearchButton
            _RunSearch(True)

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
    EndSwitch

    If $g_bContinuous And TimerDiff($g_hContinuousTimer) >= $CONTINUOUS_INTERVAL Then
        $g_hContinuousTimer = TimerInit()
        _RunSearch(False)
    EndIf

    If TimerDiff($g_hAutoDetectTimer) >= $AUTO_DETECT_INTERVAL Then
        $g_hAutoDetectTimer = TimerInit()

        If $g_hTargetWindow = 0 Or Not WinExists($g_hTargetWindow) Then
            _AutoDetectMapleStory(False)
        Else
            _RefreshBoundWindowMetadata()
        EndIf
    EndIf

    Sleep(20)
WEnd

Exit

; ============================================================================
; Control panel
; ============================================================================

Func _CreateControlPanel()
    $g_hControlGui = GUICreate( _
            "Maple ImageSearch Debugger", _
            $PANEL_WIDTH, _
            $PANEL_HEIGHT, _
            -1, _
            -1, _
            $WS_OVERLAPPEDWINDOW, _
            $WS_EX_TOPMOST)

    GUICtrlCreateLabel("MAPLE IMAGESEARCH DEBUGGER", 18, 14, 430, 22, $SS_CENTER)
    GUICtrlSetFont(-1, 11, 700)

    GUICtrlCreateLabel("Bound window:", 18, 48, 90, 18)
    $g_idWindowValue = GUICtrlCreateLabel("Not detected", 110, 46, 340, 36)
    GUICtrlSetFont($g_idWindowValue, 9, 600)

    GUICtrlCreateLabel("Target image:", 18, 89, 90, 18)
    $g_idTargetValue = GUICtrlCreateLabel("None selected", 110, 87, 340, 36)

    GUICtrlCreateLabel("Search settings:", 18, 130, 90, 18)
    $g_idSettingsValue = GUICtrlCreateLabel( _
            "Tolerance " & $TOLERANCE & _
            " | Scale " & $MIN_SCALE & "-" & $MAX_SCALE & _
            " | Max " & $MAX_RESULTS, _
            110, _
            128, _
            340, _
            20)

    GUICtrlCreateLabel("Status:", 18, 157, 90, 18)
    $g_idStatusValue = GUICtrlCreateLabel( _
            "Ready. Detect the game client and choose a target image.", _
            18, _
            177, _
            432, _
            54, _
            BitOR($SS_LEFT, $SS_SUNKEN))

    $g_idDetectButton = GUICtrlCreateButton( _
            "Detect Game Client", 18, 243, 205, 32)

    $g_idDelayedBindButton = GUICtrlCreateButton( _
            "Bind Active in 3 Seconds", 241, 243, 205, 32)

    $g_idChooseTargetButton = GUICtrlCreateButton( _
            "Choose Target Image", 18, 282, 205, 32)

    $g_idSearchButton = GUICtrlCreateButton( _
            "Search Once", 241, 282, 205, 32)

    $g_idContinuousButton = GUICtrlCreateButton( _
            "Start Continuous", 18, 321, 205, 32)

    $g_idCaptureButton = GUICtrlCreateButton( _
            "Capture Bound Window", 241, 321, 205, 32)

    $g_idClearButton = GUICtrlCreateButton( _
            "Clear Highlights", 18, 360, 132, 30)

    $g_idOpenDebugButton = GUICtrlCreateButton( _
            "Open Debug Folder", 159, 360, 132, 30)

    $g_idActivateButton = GUICtrlCreateButton( _
            "Activate Game", 300, 360, 92, 30)

    $g_idExitButton = GUICtrlCreateButton( _
            "Exit", 401, 360, 45, 30)

    GUICtrlSetTip($g_idDetectButton, _
            "Finds the largest visible window owned by MapleSaga.exe or MapleStory.exe.")

    GUICtrlSetTip($g_idDelayedBindButton, _
            "Hides this panel. Activate the desired window before the countdown ends.")

    GUICtrlSetTip($g_idContinuousButton, _
            "Repeatedly searches the visible client area every " & _
            $CONTINUOUS_INTERVAL & " ms.")

    GUICtrlSetTip($g_idCaptureButton, _
            "Saves only the bound window's visible client area.")

    GUICtrlSetTip($g_idActivateButton, _
            "Brings the currently bound window to the foreground.")
EndFunc

Func _SetStatus($sMessage)
    If $g_idStatusValue <> 0 Then
        GUICtrlSetData($g_idStatusValue, $sMessage)
    EndIf
EndFunc

Func _UpdateWindowDisplay()
    If $g_idWindowValue = 0 Then Return

    If $g_hTargetWindow = 0 Or Not WinExists($g_hTargetWindow) Then
        GUICtrlSetData($g_idWindowValue, "Not detected")
        Return
    EndIf

    Local $aClientSize = WinGetClientSize($g_hTargetWindow)
    Local $sSize = ""

    If IsArray($aClientSize) Then
        $sSize = " | " & $aClientSize[0] & "x" & $aClientSize[1]
    EndIf

    Local $sWindowIdentity = $g_sTargetWindowTitle

    If StringStripWS($sWindowIdentity, 8) = "" Then
        $sWindowIdentity = $g_sTargetProcessName
    ElseIf $g_sTargetProcessName <> "" Then
        $sWindowIdentity &= " [" & $g_sTargetProcessName & "]"
    EndIf

    GUICtrlSetData( _
            $g_idWindowValue, _
            $sWindowIdentity & " | PID " & $g_iTargetWindowPID & $sSize)
EndFunc

Func _UpdateTargetDisplay()
    If $g_idTargetValue = 0 Then Return

    If $g_sTargetPath = "" Then
        GUICtrlSetData($g_idTargetValue, "None selected")
    Else
        GUICtrlSetData($g_idTargetValue, $g_sTargetPath)
    EndIf
EndFunc

Func _SetContinuousUi()
    If $g_bContinuous Then
        GUICtrlSetData($g_idContinuousButton, "Stop Continuous")
        _SetStatus("Continuous search is running. Keep the game visible.")
    Else
        GUICtrlSetData($g_idContinuousButton, "Start Continuous")
    EndIf
EndFunc

; ============================================================================
; Target image
; ============================================================================

Func _LoadSavedTarget()
    Local $sSavedTarget = IniRead( _
            $g_sSettingsPath, _
            "General", _
            "TargetPath", _
            "")

    If $sSavedTarget <> "" And FileExists($sSavedTarget) Then
        $g_sTargetPath = $sSavedTarget
        _UpdateTargetDisplay()
        _Log("Restored target image: " & $g_sTargetPath)
        Return
    EndIf

    Local $sDefaultTarget = @ScriptDir & "\slime1.png"

    If FileExists($sDefaultTarget) Then
        $g_sTargetPath = $sDefaultTarget
        _UpdateTargetDisplay()
        _Log("Selected default target image: " & $g_sTargetPath)
    Else
        _UpdateTargetDisplay()
    EndIf
EndFunc

Func _ChooseTarget()
    Local $sInitialDirectory = @ScriptDir

    If $g_sTargetPath <> "" Then
        Local $iLastSlash = StringInStr($g_sTargetPath, "\", 0, -1)

        If $iLastSlash > 1 Then
            $sInitialDirectory = StringLeft($g_sTargetPath, $iLastSlash - 1)
        EndIf
    EndIf

    Local $sSelectedFile = FileOpenDialog( _
            "Choose the image to find inside the bound window", _
            $sInitialDirectory, _
            "Supported images (*.png;*.bmp;*.jpg;*.jpeg)", _
            $FD_FILEMUSTEXIST, _
            "", _
            $g_hControlGui)

    If @error Or $sSelectedFile = "" Then
        _Log("Target selection cancelled")
        _SetStatus("Target selection cancelled.")
        Return
    EndIf

    $g_sTargetPath = $sSelectedFile
    IniWrite($g_sSettingsPath, "General", "TargetPath", $g_sTargetPath)

    _ClearHighlights()
    _UpdateTargetDisplay()

    _Log("Target selected: " & $g_sTargetPath)
    _SetStatus("Target selected. Search once or start continuous search.")
EndFunc

; ============================================================================
; Window detection and binding
; ============================================================================

Func _AutoDetectMapleStory($bNotify)
    Local $hDetectedWindow = _FindLargestVisibleTargetProcessWindow()

    If $hDetectedWindow = 0 Then
        If $bNotify Then
            _Log("Automatic game-client detection found no visible supported process window")
            _SetStatus( _
                    "No visible MapleSaga.exe or MapleStory.exe window was found. " & _
                    "Use 'Bind Active in 3 Seconds' as a fallback.")
            TrayTip("Game client not found", _
                    "Use the delayed active-window binding button.", 4)
        EndIf

        Return False
    EndIf

    Return _BindTargetWindow($hDetectedWindow, "automatic detection")
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
        If Not BitAND($iState, 2) Then ContinueLoop ; Not visible
        If BitAND($iState, 16) Then ContinueLoop    ; Minimized

        Local $iCandidatePID = WinGetProcess($hCandidate)

        If @error Or $iCandidatePID <= 0 Then ContinueLoop
        If _GetSupportedProcessNameByPID($iCandidatePID) = "" Then ContinueLoop

        Local $aClientSize = WinGetClientSize($hCandidate)

        If @error Or Not IsArray($aClientSize) Then ContinueLoop

        Local $iArea = $aClientSize[0] * $aClientSize[1]

        If $iArea > $iBestArea Then
            $iBestArea = $iArea
            $hBestWindow = $hCandidate
        EndIf
    Next

    Return $hBestWindow
EndFunc

Func _GetSupportedProcessNameByPID($iPID)
    If $iPID <= 0 Then Return ""

    Local $iProcessNameIndex

    For $iProcessNameIndex = 0 To UBound($g_aTargetProcessNames) - 1
        Local $aProcesses = ProcessList($g_aTargetProcessNames[$iProcessNameIndex])

        If @error Or Not IsArray($aProcesses) Then ContinueLoop

        Local $iProcessIndex

        For $iProcessIndex = 1 To $aProcesses[0][0]
            If Int($aProcesses[$iProcessIndex][1]) = Int($iPID) Then
                Return $g_aTargetProcessNames[$iProcessNameIndex]
            EndIf
        Next
    Next

    Return ""
EndFunc

Func _BindForegroundWindowAfterDelay()
    _DisableContinuousSearch("Binding a new target window.")

    _SetStatus( _
            "Panel hidden for 3 seconds. Activate MapleSaga or the desired window now.")

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
    If $hWindow = 0 Or Not WinExists($hWindow) Then
        _Log("Binding failed: invalid window handle")
        Return False
    EndIf

    Local $iState = WinGetState($hWindow)

    If @error Or Not BitAND($iState, 2) Or BitAND($iState, 16) Then
        _Log("Binding failed: window is hidden or minimized")
        Return False
    EndIf

    Local $aClientSize = WinGetClientSize($hWindow)

    If @error Or Not IsArray($aClientSize) Then
        _Log("Binding failed: could not read client size")
        Return False
    EndIf

    If $aClientSize[0] < 1 Or $aClientSize[1] < 1 Then
        _Log("Binding failed: invalid client size")
        Return False
    EndIf

    $g_hTargetWindow = $hWindow
    $g_sTargetWindowTitle = WinGetTitle($g_hTargetWindow)
    $g_iTargetWindowPID = WinGetProcess($g_hTargetWindow)
    $g_sTargetProcessName = _GetSupportedProcessNameByPID($g_iTargetWindowPID)

    If $g_sTargetProcessName = "" Then
        $g_sTargetProcessName = "PID " & $g_iTargetWindowPID
    EndIf

    _ClearHighlights()
    _UpdateWindowDisplay()
    _PositionPanelNextToTarget()

    Local $iLeft = 0
    Local $iTop = 0
    Local $iRight = 0
    Local $iBottom = 0

    If _GetTargetWindowRect($iLeft, $iTop, $iRight, $iBottom) Then
        _Log("Target window bound via " & $sSource & ":")
        _Log("  Title: " & $g_sTargetWindowTitle)
        _Log("  Handle: " & $g_hTargetWindow)
        _Log("  PID: " & $g_iTargetWindowPID)
        _Log("  Process: " & $g_sTargetProcessName)
        _Log("  Client region: " & $iLeft & "," & $iTop & _
                " to " & $iRight & "," & $iBottom)
        _Log("  Client size: " & ($iRight - $iLeft + 1) & _
                "x" & ($iBottom - $iTop + 1))
    EndIf

    Local $sBoundIdentity = $g_sTargetWindowTitle

    If StringStripWS($sBoundIdentity, 8) = "" Then
        $sBoundIdentity = $g_sTargetProcessName
    EndIf

    _SetStatus("Bound to " & $sBoundIdentity & ". Ready to search.")
    Return True
EndFunc

Func _RefreshBoundWindowMetadata()
    If $g_hTargetWindow = 0 Or Not WinExists($g_hTargetWindow) Then
        $g_hTargetWindow = 0
        $g_sTargetWindowTitle = ""
        $g_iTargetWindowPID = 0
        $g_sTargetProcessName = ""
        _UpdateWindowDisplay()
        Return
    EndIf

    $g_sTargetWindowTitle = WinGetTitle($g_hTargetWindow)
    $g_iTargetWindowPID = WinGetProcess($g_hTargetWindow)
    $g_sTargetProcessName = _GetSupportedProcessNameByPID($g_iTargetWindowPID)

    If $g_sTargetProcessName = "" Then
        $g_sTargetProcessName = "PID " & $g_iTargetWindowPID
    EndIf

    _UpdateWindowDisplay()
EndFunc

Func _ActivateTargetWindow()
    If $g_hTargetWindow = 0 Or Not WinExists($g_hTargetWindow) Then
        _SetStatus("No valid window is bound.")
        Return
    EndIf

    WinActivate($g_hTargetWindow)

    If WinWaitActive($g_hTargetWindow, "", 2) Then
        _SetStatus("Activated " & $g_sTargetWindowTitle & ".")
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

    If @error Then Return False
    If BitAND($iWindowState, 16) Then Return False

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

; ============================================================================
; Search
; ============================================================================

Func _ToggleContinuousSearch()
    If $g_bContinuous Then
        _DisableContinuousSearch("Stopped by user.")
        _SetStatus("Continuous search stopped.")
        Return
    EndIf

    If Not _ValidateReadyToSearch() Then Return

    $g_bContinuous = True
    $g_hContinuousTimer = TimerInit()

    _Log("Continuous search enabled")
    _SetContinuousUi()
    _RunSearch(False)
EndFunc

Func _DisableContinuousSearch($sReason)
    If Not $g_bContinuous Then Return

    $g_bContinuous = False
    GUICtrlSetData($g_idContinuousButton, "Start Continuous")

    _Log("Continuous search disabled: " & $sReason)
EndFunc

Func _ValidateReadyToSearch()
    If $g_sTargetPath = "" Or Not FileExists($g_sTargetPath) Then
        _SetStatus("Choose a valid target image first.")
        _Log("Search rejected: no valid target image")
        Return False
    EndIf

    Local $iLeft = 0
    Local $iTop = 0
    Local $iRight = 0
    Local $iBottom = 0

    If Not _GetTargetWindowRect($iLeft, $iTop, $iRight, $iBottom) Then
        _SetStatus("No usable visible window is bound.")
        _Log("Search rejected: no usable target window")
        Return False
    EndIf

    Return True
EndFunc

Func _RunSearch($bCaptureOnMiss)
    If $g_bSearchBusy Then Return
    If Not _ValidateReadyToSearch() Then
        _DisableContinuousSearch("Search prerequisites are no longer valid.")
        Return
    EndIf

    $g_bSearchBusy = True

    Local $iSearchLeft = 0
    Local $iSearchTop = 0
    Local $iSearchRight = 0
    Local $iSearchBottom = 0

    If Not _GetTargetWindowRect( _
            $iSearchLeft, _
            $iSearchTop, _
            $iSearchRight, _
            $iSearchBottom) Then

        _DisableContinuousSearch("The target window is unavailable.")
        _SetStatus("Target window is unavailable or minimized.")
        $g_bSearchBusy = False
        Return
    EndIf

    _ClearHighlights()

    Local $sSearchWindowIdentity = $g_sTargetWindowTitle

    If StringStripWS($sSearchWindowIdentity, 8) = "" Then
        $sSearchWindowIdentity = $g_sTargetProcessName
    EndIf

    Local $hTimer = TimerInit()

    Local $aResults = _ImageSearch( _
            $g_sTargetPath, _
            $iSearchLeft, _
            $iSearchTop, _
            $iSearchRight, _
            $iSearchBottom, _
            $SEARCH_SCREEN, _
            $TOLERANCE, _
            $MAX_RESULTS, _
            0, _
            $MIN_SCALE, _
            $MAX_SCALE, _
            $SCALE_STEP, _
            0, _
            0)

    Local $iSearchError = @error
    Local $iSearchExtended = @extended
    Local $nElapsedMilliseconds = Round(TimerDiff($hTimer), 2)

    If $iSearchError <> 0 Then
        _Log("SEARCH ERROR after " & $nElapsedMilliseconds & _
                " ms: @error=" & $iSearchError & _
                ", @extended=" & $iSearchExtended)

        _SetStatus( _
                "Search error " & $iSearchError & _
                " (extended " & $iSearchExtended & ").")

        If $bCaptureOnMiss Then
            _SaveFailureScreenshot("search-error")
        EndIf

        $g_bSearchBusy = False
        Return
    EndIf

    If Not IsArray($aResults) Then
        _Log("MISS after " & $nElapsedMilliseconds & _
                " ms: result was not an array")
        _SetStatus("No match. Unexpected result format.")

        If $bCaptureOnMiss Then
            _SaveFailureScreenshot("not-an-array")
        EndIf

        $g_bSearchBusy = False
        Return
    EndIf

    If UBound($aResults, 0) <> 2 Then
        _Log("MISS after " & $nElapsedMilliseconds & _
                " ms: unexpected array dimensions")
        _SetStatus("No match. Unexpected result dimensions.")

        If $bCaptureOnMiss Then
            _SaveFailureScreenshot("unexpected-array")
        EndIf

        $g_bSearchBusy = False
        Return
    EndIf

    If UBound($aResults, 1) < 1 Or UBound($aResults, 2) < 1 Then
        _Log("MISS after " & $nElapsedMilliseconds & _
                " ms: empty result array")
        _SetStatus("No match. Empty result array.")

        If $bCaptureOnMiss Then
            _SaveFailureScreenshot("empty-result")
        EndIf

        $g_bSearchBusy = False
        Return
    EndIf

    Local $iMatchCount = Int($aResults[0][0])

    If $iMatchCount <= 0 Then
        _Log("MISS in '" & $g_sTargetWindowTitle & "' after " & _
                $nElapsedMilliseconds & " ms")

        _SetStatus( _
                "No match in " & $nElapsedMilliseconds & _
                " ms. A one-shot miss saves a debug capture.")

        If $bCaptureOnMiss Then
            _SaveFailureScreenshot("not-found")
        EndIf

        $g_bSearchBusy = False
        Return
    EndIf

    Local $iAvailableMatches = UBound($aResults, 1) - 1

    If $iMatchCount > $iAvailableMatches Then
        $iMatchCount = $iAvailableMatches
    EndIf

    If UBound($aResults, 2) < 4 Then
        _Log("SEARCH ERROR: result array did not include X/Y/width/height")
        _SetStatus("Search result did not include match dimensions.")
        $g_bSearchBusy = False
        Return
    EndIf

    _Log("FOUND " & $iMatchCount & " match(es) in '" & _
            $g_sTargetWindowTitle & "' after " & _
            $nElapsedMilliseconds & " ms")

    Local $i
    Local $sFirstMatch = ""

    For $i = 1 To $iMatchCount
        Local $iX = Int($aResults[$i][0])
        Local $iY = Int($aResults[$i][1])
        Local $iWidth = Int($aResults[$i][2])
        Local $iHeight = Int($aResults[$i][3])

        _Log("  Match " & $i & _
                ": X=" & $iX & _
                ", Y=" & $iY & _
                ", Width=" & $iWidth & _
                ", Height=" & $iHeight)

        If $i = 1 Then
            $sFirstMatch = " First: " & $iX & "," & $iY & _
                    " (" & $iWidth & "x" & $iHeight & ")."
        EndIf

        _DrawHighlight($iX, $iY, $iWidth, $iHeight)
    Next

    _SetStatus( _
            "Found " & $iMatchCount & " match(es) in " & _
            $nElapsedMilliseconds & " ms." & $sFirstMatch)

    $g_bSearchBusy = False
EndFunc

; ============================================================================
; Highlight overlays
; ============================================================================

Func _DrawHighlight($iX, $iY, $iWidth, $iHeight)
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
            $OVERLAY_BORDER)

    _CreateOverlayBar( _
            $iX - $OVERLAY_BORDER, _
            $iY + $iHeight, _
            $iWidth + ($OVERLAY_BORDER * 2), _
            $OVERLAY_BORDER)

    _CreateOverlayBar( _
            $iX - $OVERLAY_BORDER, _
            $iY, _
            $OVERLAY_BORDER, _
            $iHeight)

    _CreateOverlayBar( _
            $iX + $iWidth, _
            $iY, _
            $OVERLAY_BORDER, _
            $iHeight)
EndFunc

Func _CreateOverlayBar($iX, $iY, $iWidth, $iHeight)
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

    GUISetBkColor($OVERLAY_COLOR, $hOverlay)
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
        _Log("Screenshot cancelled: no usable target window")
        _SetStatus("Screenshot not saved: no usable target window.")
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
        _Log("Target-window screenshot saved: " & $sScreenshotPath)
        _SetStatus("Screenshot saved: " & $sScreenshotPath)
        Return True
    EndIf

    _Log("Screenshot failed: @error=" & $iCaptureError & _
            ", @extended=" & $iCaptureExtended)

    _SetStatus( _
            "Screenshot failed: error " & $iCaptureError & _
            ", extended " & $iCaptureExtended & ".")

    Return False
EndFunc

Func _SaveFailureScreenshot($sReason)
    Local $iLeft = 0
    Local $iTop = 0
    Local $iRight = 0
    Local $iBottom = 0

    If Not _GetTargetWindowRect($iLeft, $iTop, $iRight, $iBottom) Then
        _Log("Failure screenshot skipped: target window unavailable")
        Return
    EndIf

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

    Local $iCaptureError = @error
    Local $iCaptureExtended = @extended

    If $bSaved Then
        _Log("Failure screenshot saved: " & $sScreenshotPath)
    Else
        _Log("Failure screenshot failed: @error=" & _
                $iCaptureError & ", @extended=" & $iCaptureExtended)
    EndIf
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

    _Log("ImageSearch GUI debugger stopped")
EndFunc
