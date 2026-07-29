#RequireAdmin
#AutoIt3Wrapper_Res_requestedExecutionLevel=requireAdministrator
#AutoIt3Wrapper_UseX64=y

#include "ImageSearchDLL_UDF_Embedded.au3"
#include <AutoItConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <FileConstants.au3>
#include <EditConstants.au3>
#include <ComboConstants.au3>
#include <GDIPlus.au3>
#include <Misc.au3>

Opt("MustDeclareVars", 1)
Opt("TrayAutoPause", 0)
Opt("MouseCoordMode", 1)
Opt("PixelCoordMode", 1)
Opt("SendKeyDelay", 10)
Opt("SendKeyDownDelay", 25)

; ============================================================================
; Maple Automation MVP v0.2.0
;
; Combined vertical slice:
;   1. Bind MapleSaga.exe / MapleStory.exe.
;   2. Load player and target PNG templates from data\player and data\target.
;   3. Detect the player, all targets, and the nearest target.
;   4. Optionally move horizontally toward the nearest target.
;   5. Optionally tap a movement skill while moving.
;   6. Read the permanent bottom EXP HUD with Tesseract.
;   7. Track session EXP, events, last gain, and XP/hour.
;   8. OCR HP/MP values and send configured potion keys below thresholds.
;
; Safety:
;   F6 toggles runtime start/pause.
;   F8 is an emergency stop and releases movement keys.
;   Automatic input is sent only while the bound game window is active.
;   HP/MP autopot is disabled by default and uses stable OCR confirmation.
;   Every OCR result and every potion decision is written to the debug log.
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
Global Const $MIN_SCALE = 1.00
Global Const $MAX_SCALE = 1.00
Global Const $SCALE_STEP = 0.10
Global Const $CONTINUOUS_INTERVAL = 300
Global Const $AUTO_DETECT_INTERVAL = 2000
Global Const $DUPLICATE_CENTER_RADIUS = 20
Global Const $MIN_GAME_CLIENT_WIDTH = 640
Global Const $MIN_GAME_CLIENT_HEIGHT = 400

Global Const $PLAYER_OVERLAY_COLOR = 0x00BFFF
Global Const $TARGET_OVERLAY_COLOR = 0x00FF00
Global Const $NEAREST_OVERLAY_COLOR = 0xFF8C00
Global Const $OVERLAY_BORDER = 3
Global Const $MAX_OVERLAY_WINDOWS = 220

Global Const $PANEL_WIDTH = 620
Global Const $PANEL_HEIGHT = 1180

Global Const $APP_COLOR_BACKGROUND = 0x1F1F1F
Global Const $APP_COLOR_PANEL = 0x2A2A2A
Global Const $APP_COLOR_TEXT = 0xF2F2F2
Global Const $APP_COLOR_MUTED = 0xB0B0B0
Global Const $APP_COLOR_ACCENT = 0x1EB5B5

Global Const $APP_OCR_INTERVAL = 1000
Global Const $APP_HUD_STABLE_READS = 2
Global Const $APP_HUD_SCALE = 6
Global Const $APP_HUD_X1_RATIO = 0.339
Global Const $APP_HUD_X2_RATIO = 0.427
Global Const $APP_HUD_Y1_RATIO = 0.948
Global Const $APP_HUD_Y2_RATIO = 0.977
Global Const $APP_MISS_LOG_INTERVAL_MS = 5000
Global Const $APP_VISION_STALE_MS = 900
Global Const $APP_STATS_REFRESH_MS = 250

; Bottom HP/MP HUD text crop, calibrated against the 1280x720 client HUD.
Global Const $APP_VITALS_INTERVAL = 800
Global Const $APP_VITALS_STABLE_READS = 2
Global Const $APP_VITALS_SEVERE_MARGIN = 10
Global Const $APP_VITALS_MAX_CHANGE_READS = 4
Global Const $APP_VITALS_MAX_CHANGE_PERCENT = 20
Global Const $APP_VITALS_SCALE = 4
Global Const $APP_VITALS_X1_RATIO = 0.167
Global Const $APP_VITALS_X2_RATIO = 0.329
Global Const $APP_VITALS_Y1_RATIO = 0.948
Global Const $APP_VITALS_Y2_RATIO = 0.979

Global $g_aTargetProcessNames[2] = ["MapleSaga.exe", "MapleStory.exe"]

Global $g_hTargetWindow = 0
Global $g_sTargetWindowTitle = ""
Global $g_iTargetWindowPID = 0
Global $g_sTargetProcessName = ""

Global $g_sDebugDirectory = @ScriptDir & "\debug"
Global $g_sOcrTempDirectory = $g_sDebugDirectory & "\ocr_temp"
Global $g_sLogPath = $g_sDebugDirectory & "\MapleAutomationMVP.log"
Global $g_sLatestHudRawPath = $g_sOcrTempDirectory & "\latest_exp_hud_raw.png"
Global $g_sLatestHudScaledPath = $g_sOcrTempDirectory & "\latest_exp_hud_scaled.png"
Global $g_sLatestVitalsRawPath = $g_sOcrTempDirectory & "\latest_vitals_hud_raw.png"
Global $g_sLatestVitalsScaledPath = $g_sOcrTempDirectory & "\latest_vitals_hud_scaled.png"

Global $g_bImageSearchStarted = False
Global $g_bGdiPlusStarted = False
Global $g_bContinuous = False
Global $g_bOcrMonitoring = False
Global $g_bSearchBusy = False

Global $g_hContinuousTimer = TimerInit()
Global $g_hAutoDetectTimer = TimerInit()
Global $g_hOcrTimer = TimerInit()
Global $g_hVitalsTimer = TimerInit()
Global $g_hStatsRefreshTimer = TimerInit()
Global $g_hSkillTimer = TimerInit()
Global $g_hVisionSuccessTimer = TimerInit()
Global $g_hMissLogTimer = TimerInit()
Global $g_hHpPotionTimer = TimerInit()
Global $g_hMpPotionTimer = TimerInit()

Global $g_aOverlayHandles[$MAX_OVERLAY_WINDOWS]
Global $g_iOverlayCount = 0

; Latest accepted vision snapshot.
Global $g_bVisionPlayerFound = False
Global $g_bVisionTargetFound = False
Global $g_nVisionDeltaX = 0
Global $g_nVisionDeltaY = 0
Global $g_nVisionDistance = 0
Global $g_iVisionTargetCount = 0
Global $g_sVisionTargetTemplate = ""

; Movement state.
Global $g_sHeldMovementKey = ""
Global $g_sLastInput = "None"

; EXP session state.
Global $g_sTesseractPath = ""
Global $g_hSessionStart = TimerInit()
Global $g_nSessionExp = 0
Global $g_iExpEvents = 0
Global $g_nLastGain = 0
Global $g_sLastRead = ""
Global $g_iLastAcceptedHudExp = -1
Global $g_iHudCandidateExp = -1
Global $g_iHudCandidateReads = 0
Global $g_sLastHudOcr = ""

; HP/MP OCR and autopot state.
Global $g_iCurrentHp = -1
Global $g_iMaximumHp = -1
Global $g_nCurrentHpPercent = -1
Global $g_iCurrentMp = -1
Global $g_iMaximumMp = -1
Global $g_nCurrentMpPercent = -1
Global $g_sLastVitalsOcr = ""
Global $g_sLastAutopotDecision = "Waiting for runtime start"

Global $g_iHpCandidateCurrent = -1
Global $g_iHpCandidateMaximum = -1
Global $g_nHpCandidatePercent = -1
Global $g_iHpCandidateReads = 0
Global $g_iMpCandidateCurrent = -1
Global $g_iMpCandidateMaximum = -1
Global $g_nMpCandidatePercent = -1
Global $g_iMpCandidateReads = 0
Global $g_iAcceptedHpMaximum = -1
Global $g_iAcceptedMpMaximum = -1
Global $g_bHpPotionHasFired = False
Global $g_bMpPotionHasFired = False

; GUI handles and controls.
Global $g_hControlGui = 0
Global $g_idWindowValue = 0
Global $g_idTemplateValue = 0
Global $g_idPlayerValue = 0
Global $g_idTargetValue = 0
Global $g_idDistanceValue = 0
Global $g_idAutomationStatusValue = 0
Global $g_idLastInputValue = 0
Global $g_idTesseractValue = 0
Global $g_idSessionTimeValue = 0
Global $g_idXpHourValue = 0
Global $g_idTotalValue = 0
Global $g_idEventsValue = 0
Global $g_idLastGainValue = 0
Global $g_idLastReadValue = 0
Global $g_idStatusValue = 0

Global $g_idAutoMoveCheckbox = 0
Global $g_idUseSkillCheckbox = 0
Global $g_idLeftKeyCombo = 0
Global $g_idRightKeyCombo = 0
Global $g_idSkillKeyCombo = 0
Global $g_idSkillIntervalInput = 0
Global $g_idStopDistanceInput = 0
Global $g_idTapLeftButton = 0
Global $g_idTapRightButton = 0
Global $g_idTestSkillButton = 0
Global $g_idResetSessionButton = 0

Global $g_idHpAutopotCheckbox = 0
Global $g_idMpAutopotCheckbox = 0
Global $g_idHpThresholdInput = 0
Global $g_idMpThresholdInput = 0
Global $g_idHpPotionKeyCombo = 0
Global $g_idMpPotionKeyCombo = 0
Global $g_idPotionCooldownInput = 0
Global $g_idHpCurrentValue = 0
Global $g_idMpCurrentValue = 0
Global $g_idVitalsStatusValue = 0
Global $g_idAutopotDecisionValue = 0

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
Global $g_idEmergencyButton = 0

DirCreate($g_sDebugDirectory)
DirCreate($g_sOcrTempDirectory)
DirCreate($DATA_DIRECTORY)
DirCreate($PLAYER_TEMPLATE_DIRECTORY)
DirCreate($TARGET_TEMPLATE_DIRECTORY)
OnAutoItExitRegister("_OnExit")
HotKeySet("{F6}", "_HotkeyToggleRuntime")
HotKeySet("{F8}", "_HotkeyEmergencyStop")

_Log("============================================================")
_Log("Maple Automation MVP v0.2.0 starting")
_Log("Script directory: " & @ScriptDir)
_Log("AutoIt architecture: " & (@AutoItX64 ? "x64" : "x86"))
_Log("Administrator token: " & (IsAdmin() ? "yes" : "no"))
_Log("Desktop size: " & @DesktopWidth & "x" & @DesktopHeight)
_Log("Hotkeys: F6 start/pause; F8 emergency stop")

If Not _ImageSearch_Startup() Then
    Local $iStartupError = @error
    Local $iStartupExtended = @extended
    MsgBox(16, "ImageSearch startup failed", _
            "ImageSearchDLL could not start." & @CRLF & @CRLF & _
            "@error: " & $iStartupError & @CRLF & _
            "@extended: " & $iStartupExtended & @CRLF & @CRLF & _
            "Confirm ImageSearchDLL_UDF_Embedded.au3 is beside this script.")
    Exit 1
EndIf
$g_bImageSearchStarted = True
_Log("ImageSearchDLL startup succeeded")

_GDIPlus_Startup()
$g_bGdiPlusStarted = True
_Log("GDI+ startup succeeded")

$g_sTesseractPath = _FindTesseractPath()
If $g_sTesseractPath <> "" Then
    _Log("Tesseract path: " & $g_sTesseractPath)
Else
    _Log("Tesseract path: not found; movement vision remains available")
EndIf

_CreateControlPanel()
_ReloadTemplateLibrary(False)
_ResetExpSession()
_AutoDetectGameClient(False)
_UpdateSessionStats()
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
            _UpdateMovementControl()
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
        Case $g_idTapLeftButton
            _TapConfiguredMovementKey(True)
        Case $g_idTapRightButton
            _TapConfiguredMovementKey(False)
        Case $g_idTestSkillButton
            _TapConfiguredSkill(True)
        Case $g_idResetSessionButton
            _ResetExpSession()
        Case $g_idEmergencyButton
            _EmergencyStop("Emergency Stop button")
    EndSwitch

    If $g_bContinuous And TimerDiff($g_hContinuousTimer) >= $CONTINUOUS_INTERVAL Then
        $g_hContinuousTimer = TimerInit()
        _RunDistanceSearch(False)
    EndIf

    If $g_bContinuous Then
        _UpdateMovementControl()
    Else
        _ReleaseMovementKey()
    EndIf

    If $g_bOcrMonitoring And TimerDiff($g_hOcrTimer) >= $APP_OCR_INTERVAL Then
        $g_hOcrTimer = TimerInit()
        _ScanExperienceOnce()
    EndIf

    If $g_bOcrMonitoring And TimerDiff($g_hVitalsTimer) >= $APP_VITALS_INTERVAL Then
        $g_hVitalsTimer = TimerInit()
        _ScanVitalsOnce()
    EndIf

    If TimerDiff($g_hStatsRefreshTimer) >= $APP_STATS_REFRESH_MS Then
        $g_hStatsRefreshTimer = TimerInit()
        _UpdateSessionStats()
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
            "Maple Automation MVP v0.2.0", _
            $PANEL_WIDTH, _
            $PANEL_HEIGHT, _
            -1, _
            -1, _
            $WS_OVERLAPPEDWINDOW, _
            $WS_EX_TOPMOST)

    GUISetBkColor($APP_COLOR_BACKGROUND, $g_hControlGui)

    Local $idTitle = GUICtrlCreateLabel("MAPLE AUTOMATION MVP", 18, 12, 584, 26, $SS_CENTER)
    GUICtrlSetFont($idTitle, 13, 700)
    GUICtrlSetColor($idTitle, $APP_COLOR_TEXT)

    Local $idSubtitle = GUICtrlCreateLabel( _
            "Vision + EXP telemetry + OCR HP/MP autopot", _
            18, 38, 584, 18, $SS_CENTER)
    GUICtrlSetColor($idSubtitle, $APP_COLOR_MUTED)

    _CreateSectionLabel("BINDING + VISION", 18, 66)
    _CreateCaption("Window", 18, 94)
    $g_idWindowValue = _CreateValueLabel("Not detected", 116, 91, 486, 36)

    _CreateCaption("Templates", 18, 132)
    $g_idTemplateValue = _CreateValueLabel("Checking...", 116, 129, 486, 36)

    _CreateCaption("Player", 18, 170)
    $g_idPlayerValue = _CreateValueLabel("Not detected", 116, 167, 486, 24)

    _CreateCaption("Targets", 18, 199)
    $g_idTargetValue = _CreateValueLabel("Not detected", 116, 196, 486, 24)

    _CreateCaption("Nearest", 18, 228)
    $g_idDistanceValue = _CreateValueLabel("No distance yet", 116, 225, 486, 46)

    _CreateSectionLabel("MOVEMENT", 18, 284)
    $g_idAutoMoveCheckbox = GUICtrlCreateCheckbox( _
            "Enable automatic horizontal movement", 18, 312, 286, 22)
    GUICtrlSetState($g_idAutoMoveCheckbox, $GUI_UNCHECKED)
    GUICtrlSetColor($g_idAutoMoveCheckbox, $APP_COLOR_TEXT)

    $g_idUseSkillCheckbox = GUICtrlCreateCheckbox( _
            "Tap movement skill while moving", 318, 312, 284, 22)
    GUICtrlSetState($g_idUseSkillCheckbox, $GUI_CHECKED)
    GUICtrlSetColor($g_idUseSkillCheckbox, $APP_COLOR_TEXT)

    _CreateCaption("Move left", 18, 346)
    $g_idLeftKeyCombo = GUICtrlCreateCombo("Left Arrow", 116, 342, 170, 24, $CBS_DROPDOWNLIST)
    GUICtrlSetData($g_idLeftKeyCombo, "Left Arrow|A", "Left Arrow")

    _CreateCaption("Move right", 318, 346)
    $g_idRightKeyCombo = GUICtrlCreateCombo("Right Arrow", 416, 342, 186, 24, $CBS_DROPDOWNLIST)
    GUICtrlSetData($g_idRightKeyCombo, "Right Arrow|D", "Right Arrow")

    _CreateCaption("Skill key", 18, 380)
    $g_idSkillKeyCombo = GUICtrlCreateCombo("Alt", 116, 376, 170, 24, $CBS_DROPDOWNLIST)
    GUICtrlSetData($g_idSkillKeyCombo, "None|Alt|Ctrl|Space|Z|X|C", "Alt")

    _CreateCaption("Interval ms", 318, 380)
    $g_idSkillIntervalInput = GUICtrlCreateInput("1000", 416, 376, 80, 24)

    _CreateCaption("Stop px", 510, 380)
    $g_idStopDistanceInput = GUICtrlCreateInput("80", 562, 376, 40, 24)

    $g_idTapLeftButton = GUICtrlCreateButton("Tap Left", 18, 414, 170, 30)
    $g_idTapRightButton = GUICtrlCreateButton("Tap Right", 202, 414, 170, 30)
    $g_idTestSkillButton = GUICtrlCreateButton("Test Skill", 386, 414, 216, 30)

    _CreateCaption("Automation", 18, 458)
    $g_idAutomationStatusValue = _CreateValueLabel("Paused", 116, 455, 486, 28)
    _CreateCaption("Last input", 18, 490)
    $g_idLastInputValue = _CreateValueLabel("None", 116, 487, 486, 28)

    _CreateSectionLabel("HP / MP AUTOPOT", 18, 530)

    $g_idHpAutopotCheckbox = GUICtrlCreateCheckbox("Enable HP autopot", 18, 558, 168, 24)
    GUICtrlSetState($g_idHpAutopotCheckbox, $GUI_UNCHECKED)
    GUICtrlSetColor($g_idHpAutopotCheckbox, $APP_COLOR_TEXT)
    _CreateCaption("Threshold %", 196, 562)
    $g_idHpThresholdInput = GUICtrlCreateInput("40", 278, 558, 46, 24)
    _CreateCaption("Key", 340, 562)
    $g_idHpPotionKeyCombo = GUICtrlCreateCombo("F1", 382, 558, 74, 24, $CBS_DROPDOWNLIST)
    GUICtrlSetData($g_idHpPotionKeyCombo, "F1|F2|F3|F4|F5|F7|F9|F10|F11|F12", "F1")
    $g_idHpCurrentValue = _CreateValueLabel("HP: waiting", 470, 556, 132, 28)

    $g_idMpAutopotCheckbox = GUICtrlCreateCheckbox("Enable MP autopot", 18, 594, 168, 24)
    GUICtrlSetState($g_idMpAutopotCheckbox, $GUI_UNCHECKED)
    GUICtrlSetColor($g_idMpAutopotCheckbox, $APP_COLOR_TEXT)
    _CreateCaption("Threshold %", 196, 598)
    $g_idMpThresholdInput = GUICtrlCreateInput("30", 278, 594, 46, 24)
    _CreateCaption("Key", 340, 598)
    $g_idMpPotionKeyCombo = GUICtrlCreateCombo("F2", 382, 594, 74, 24, $CBS_DROPDOWNLIST)
    GUICtrlSetData($g_idMpPotionKeyCombo, "F1|F2|F3|F4|F5|F7|F9|F10|F11|F12", "F2")
    $g_idMpCurrentValue = _CreateValueLabel("MP: waiting", 470, 592, 132, 28)

    _CreateCaption("Vitals OCR", 18, 634)
    $g_idVitalsStatusValue = _CreateValueLabel("Waiting for F6", 116, 630, 486, 28)

    _CreateCaption("Cooldown", 18, 670)
    $g_idPotionCooldownInput = GUICtrlCreateInput("800", 116, 666, 72, 24)
    Local $idCooldownSuffix = GUICtrlCreateLabel("ms per potion", 196, 670, 100, 20)
    GUICtrlSetColor($idCooldownSuffix, $APP_COLOR_MUTED)

    _CreateCaption("Decision", 318, 670)
    $g_idAutopotDecisionValue = _CreateValueLabel("Autopot disabled by default", 416, 666, 186, 42)

    GUICtrlSetTip($g_idHpAutopotCheckbox, _
            "Uses OCR values from the permanent bottom HP HUD. Disabled by default.")
    GUICtrlSetTip($g_idMpAutopotCheckbox, _
            "Uses OCR values from the permanent bottom MP HUD. Disabled by default.")
    GUICtrlSetTip($g_idPotionCooldownInput, _
            "Minimum time between repeated sends for each potion channel.")

    _CreateSectionLabel("EXP SESSION", 18, 726)
    _CreateCaption("Tesseract", 18, 754)
    $g_idTesseractValue = _CreateValueLabel("Checking...", 116, 751, 486, 28)

    _CreateMiniStat("Session time", 18, 790, 178, $g_idSessionTimeValue)
    _CreateMiniStat("XP / hr", 212, 790, 178, $g_idXpHourValue)
    _CreateMiniStat("Total XP", 406, 790, 196, $g_idTotalValue)
    _CreateMiniStat("Events", 18, 842, 178, $g_idEventsValue)
    _CreateMiniStat("Last gain", 212, 842, 178, $g_idLastGainValue)
    _CreateMiniStat("Last HUD read", 406, 842, 196, $g_idLastReadValue)

    $g_idResetSessionButton = GUICtrlCreateButton("Reset EXP Session", 406, 892, 196, 28)

    _CreateSectionLabel("TOOLS", 18, 934)
    $g_idDetectButton = GUICtrlCreateButton("Detect Client", 18, 960, 136, 28)
    $g_idSearchButton = GUICtrlCreateButton("Search Once", 166, 960, 136, 28)
    $g_idReloadDataButton = GUICtrlCreateButton("Reload /data", 314, 960, 136, 28)
    $g_idOpenDebugButton = GUICtrlCreateButton("Open Debug", 462, 960, 140, 28)

    $g_idCapturePlayerButton = GUICtrlCreateButton("Capture Player", 18, 996, 136, 28)
    $g_idCaptureTargetButton = GUICtrlCreateButton("Capture Target", 166, 996, 136, 28)
    $g_idOpenDataButton = GUICtrlCreateButton("Open /data", 314, 996, 136, 28)
    $g_idCaptureButton = GUICtrlCreateButton("Capture Client", 462, 996, 140, 28)

    $g_idDelayedBindButton = GUICtrlCreateButton("Bind Active", 18, 1032, 106, 26)
    $g_idImportPlayerButton = GUICtrlCreateButton("Import Player", 132, 1032, 106, 26)
    $g_idImportTargetButton = GUICtrlCreateButton("Import Target", 246, 1032, 106, 26)
    $g_idClearButton = GUICtrlCreateButton("Clear Marks", 360, 1032, 106, 26)
    $g_idActivateButton = GUICtrlCreateButton("Activate", 474, 1032, 62, 26)
    $g_idExitButton = GUICtrlCreateButton("Exit", 544, 1032, 58, 26)

    $g_idStatusValue = GUICtrlCreateEdit( _
            "", 18, 1068, 584, 42, BitOR($ES_READONLY, $ES_MULTILINE))
    GUICtrlSetBkColor($g_idStatusValue, $APP_COLOR_PANEL)
    GUICtrlSetColor($g_idStatusValue, $APP_COLOR_TEXT)

    $g_idContinuousButton = GUICtrlCreateButton( _
            "F6 Start", 18, 1122, 282, 30)
    $g_idEmergencyButton = GUICtrlCreateButton( _
            "F8 EMERGENCY STOP", 314, 1122, 288, 30)
    GUICtrlSetTip($g_idEmergencyButton, _
            "Press F8 at any time to stop and release movement and potion keys.")

    GUICtrlSetTip($g_idContinuousButton, _
            "F6 starts or pauses vision, movement, EXP OCR, and HP/MP OCR.")
    GUICtrlSetTip($g_idAutoMoveCheckbox, _
            "Automatic input is sent only while the bound game window is active.")
    GUICtrlSetTip($g_idStopDistanceInput, _
            "Horizontal center distance at which movement keys are released.")

    _SetStatus("Ready. F6 starts the combined runtime; F8 releases everything immediately.")
EndFunc

Func _CreateSectionLabel($sText, $iX, $iY)
    Local $id = GUICtrlCreateLabel($sText, $iX, $iY, 584, 20)
    GUICtrlSetFont($id, 10, 700)
    GUICtrlSetColor($id, $APP_COLOR_ACCENT)
EndFunc

Func _CreateCaption($sText, $iX, $iY)
    Local $id = GUICtrlCreateLabel($sText, $iX, $iY, 92, 20)
    GUICtrlSetColor($id, $APP_COLOR_MUTED)
EndFunc

Func _CreateValueLabel($sText, $iX, $iY, $iW, $iH)
    Local $id = GUICtrlCreateLabel($sText, $iX, $iY, $iW, $iH, BitOR($SS_LEFT, $SS_SUNKEN))
    GUICtrlSetBkColor($id, $APP_COLOR_PANEL)
    GUICtrlSetColor($id, $APP_COLOR_TEXT)
    GUICtrlSetFont($id, 9, 600)
    Return $id
EndFunc

Func _CreateMiniStat($sCaption, $iX, $iY, $iW, ByRef $idValue)
    Local $idCaption = GUICtrlCreateLabel($sCaption, $iX, $iY, $iW, 18)
    GUICtrlSetColor($idCaption, $APP_COLOR_MUTED)
    $idValue = _CreateValueLabel("-", $iX, $iY + 18, $iW, 28)
EndFunc

Func _SetStatus($sMessage)
    If $g_idStatusValue <> 0 Then GUICtrlSetData($g_idStatusValue, $sMessage)
EndFunc

Func _SetAutomationStatus($sMessage)
    If $g_idAutomationStatusValue <> 0 Then GUICtrlSetData($g_idAutomationStatusValue, $sMessage)
EndFunc

Func _UpdateTemplateDisplay()
    GUICtrlSetData($g_idTemplateValue, _
            "player: " & $g_iPlayerTemplateCount & _
            " PNG(s) | target: " & $g_iTargetTemplateCount & _
            " PNG(s) | tolerance " & $PLAYER_TOLERANCE & "/" & $TARGET_TOLERANCE)
EndFunc

Func _UpdateWindowDisplay()
    If $g_hTargetWindow = 0 Or Not WinExists($g_hTargetWindow) Then
        GUICtrlSetData($g_idWindowValue, "Not detected")
        Return
    EndIf

    Local $aClientSize = WinGetClientSize($g_hTargetWindow)
    Local $sSize = ""
    If IsArray($aClientSize) Then $sSize = " | " & $aClientSize[0] & "x" & $aClientSize[1]

    Local $sIdentity = $g_sTargetWindowTitle
    If StringStripWS($sIdentity, 8) = "" Then
        $sIdentity = $g_sTargetProcessName
    ElseIf $g_sTargetProcessName <> "" Then
        $sIdentity &= " [" & $g_sTargetProcessName & "]"
    EndIf

    GUICtrlSetData($g_idWindowValue, _
            $sIdentity & " | PID " & $g_iTargetWindowPID & $sSize)
EndFunc

Func _ResetDetectionDisplay()
    _ResetVisionSnapshot()
    GUICtrlSetData($g_idPlayerValue, "Not detected")
    GUICtrlSetData($g_idTargetValue, "Not detected")
    GUICtrlSetData($g_idDistanceValue, "No distance yet")
EndFunc

Func _SetContinuousUi()
    If $g_bContinuous Then
        GUICtrlSetData($g_idContinuousButton, "F6 Pause")
    Else
        GUICtrlSetData($g_idContinuousButton, "F6 Start")
    EndIf
EndFunc

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
            _ResetVisionSnapshot()
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

    _ReleaseMovementKey()
    _ClearHighlights()
    _ResetDetectionDisplay()
    $g_iLastAcceptedHudExp = -1
    $g_iHudCandidateExp = -1
    $g_iHudCandidateReads = 0
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
    _ResetVisionSnapshot()

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

        $g_bVisionPlayerFound = True

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

    $g_iVisionTargetCount = $iTargetCount

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

    $g_bVisionTargetFound = True
    $g_nVisionDeltaX = $nNearestDeltaX
    $g_nVisionDeltaY = $nNearestDeltaY
    $g_nVisionDistance = $nNearestDistance
    $g_sVisionTargetTemplate = _FileNameOnly( _
            $g_aTargetTemplates[$aTargetMatches[$iNearestIndex][4]])
    $g_hVisionSuccessTimer = TimerInit()

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

; ============================================================================
; Combined runtime and movement
; ============================================================================

Func _ToggleContinuousSearch()
    If $g_bContinuous Then
        _DisableContinuousSearch("Paused by user.")
        _SetStatus("Combined runtime paused. EXP session totals were retained.")
        Return
    EndIf

    If Not _ValidateReadyToSearch() Then Return

    $g_bContinuous = True
    $g_bOcrMonitoring = ($g_sTesseractPath <> "")
    $g_hContinuousTimer = TimerInit()
    $g_hOcrTimer = TimerInit()
    $g_hVitalsTimer = TimerInit()
    $g_hSkillTimer = TimerInit()

    ; Establish a fresh baseline so EXP earned while paused is not counted.
    $g_iLastAcceptedHudExp = -1
    $g_iHudCandidateExp = -1
    $g_iHudCandidateReads = 0
    _ResetVitalsCandidates()

    _SetContinuousUi()
    _SetAutomationStatus("Starting vision...")
    _Log("Combined runtime enabled; OCR=" & ($g_bOcrMonitoring ? "on" : "off"))

    _RunDistanceSearch(False)
    _ActivateTargetWindow()
EndFunc

Func _DisableContinuousSearch($sReason)
    If Not $g_bContinuous And Not $g_bOcrMonitoring Then
        _ReleaseMovementKey()
        Return
    EndIf

    $g_bContinuous = False
    $g_bOcrMonitoring = False
    _ReleaseMovementKey()
    _ReleaseAllConfiguredPotionKeys()
    _SetContinuousUi()
    _SetAutomationStatus("Paused")
    _Log("Combined runtime disabled: " & $sReason)
EndFunc

Func _HotkeyToggleRuntime()
    _ToggleContinuousSearch()
EndFunc

Func _HotkeyEmergencyStop()
    _EmergencyStop("F8 emergency stop")
EndFunc

Func _EmergencyStop($sReason)
    $g_bContinuous = False
    $g_bOcrMonitoring = False
    _ReleaseMovementKey()
    _ReleaseAllConfiguredMovementKeys()
    _ReleaseAllConfiguredPotionKeys()
    _SetContinuousUi()
    _SetAutomationStatus("EMERGENCY STOPPED")
    _SetStatus($sReason & ". Movement and potion keys released.")
    _Log("EMERGENCY STOP: " & $sReason)
EndFunc

Func _ResetVisionSnapshot()
    $g_bVisionPlayerFound = False
    $g_bVisionTargetFound = False
    $g_nVisionDeltaX = 0
    $g_nVisionDeltaY = 0
    $g_nVisionDistance = 0
    $g_iVisionTargetCount = 0
    $g_sVisionTargetTemplate = ""
EndFunc

Func _UpdateMovementControl()
    If Not $g_bContinuous Then
        _ReleaseMovementKey()
        Return
    EndIf

    If GUICtrlRead($g_idAutoMoveCheckbox) <> $GUI_CHECKED Then
        _ReleaseMovementKey()
        _SetAutomationStatus("Vision active; automatic movement disabled")
        Return
    EndIf

    If Not $g_bVisionPlayerFound Or Not $g_bVisionTargetFound Then
        _ReleaseMovementKey()
        _SetAutomationStatus("Waiting for player + target")
        Return
    EndIf

    If TimerDiff($g_hVisionSuccessTimer) > $APP_VISION_STALE_MS Then
        _ReleaseMovementKey()
        _SetAutomationStatus("Vision stale; movement released")
        Return
    EndIf

    If $g_hTargetWindow = 0 Or Not WinExists($g_hTargetWindow) Then
        _ReleaseMovementKey()
        _SetAutomationStatus("Game window unavailable")
        Return
    EndIf

    ; Do not type into another application if the user changes focus.
    If Not WinActive($g_hTargetWindow) Then
        _ReleaseMovementKey()
        _SetAutomationStatus("Game not active; movement safely paused")
        Return
    EndIf

    Local $iStopDistance = Int(Number(GUICtrlRead($g_idStopDistanceInput)))
    $iStopDistance = _ClampValue($iStopDistance, 10, 500)

    If Abs($g_nVisionDeltaX) <= $iStopDistance Then
        _ReleaseMovementKey()
        _SetAutomationStatus( _
                "Target inside stop distance: " & Round(Abs($g_nVisionDeltaX), 1) & " px")
        Return
    EndIf

    Local $sDirection = "right"
    Local $sKeyLabel = GUICtrlRead($g_idRightKeyCombo)
    If $g_nVisionDeltaX < 0 Then
        $sDirection = "left"
        $sKeyLabel = GUICtrlRead($g_idLeftKeyCombo)
    EndIf

    _HoldMovementKey($sKeyLabel)
    _SetAutomationStatus( _
            "Moving " & $sDirection & " toward nearest target | DX " & _
            Round($g_nVisionDeltaX, 1) & " px")

    If GUICtrlRead($g_idUseSkillCheckbox) = $GUI_CHECKED Then
        Local $iInterval = Int(Number(GUICtrlRead($g_idSkillIntervalInput)))
        $iInterval = _ClampValue($iInterval, 100, 10000)
        If TimerDiff($g_hSkillTimer) >= $iInterval Then
            $g_hSkillTimer = TimerInit()
            _TapConfiguredSkill(False)
        EndIf
    EndIf
EndFunc

Func _HoldMovementKey($sKeyLabel)
    If $sKeyLabel = "" Then Return
    If $g_sHeldMovementKey = $sKeyLabel Then Return

    _ReleaseMovementKey()

    Local $sToken = _MovementHoldToken($sKeyLabel)
    If $sToken = "" Then Return

    Send("{" & $sToken & " down}")
    $g_sHeldMovementKey = $sKeyLabel
    $g_sLastInput = $sKeyLabel & " down"
    GUICtrlSetData($g_idLastInputValue, $g_sLastInput)
    _Log("INPUT HOLD: " & $g_sLastInput)
EndFunc

Func _ReleaseMovementKey()
    If $g_sHeldMovementKey = "" Then Return

    Local $sToken = _MovementHoldToken($g_sHeldMovementKey)
    If $sToken <> "" Then Send("{" & $sToken & " up}")

    $g_sLastInput = $g_sHeldMovementKey & " up"
    GUICtrlSetData($g_idLastInputValue, $g_sLastInput)
    _Log("INPUT RELEASE: " & $g_sLastInput)
    $g_sHeldMovementKey = ""
EndFunc

Func _ReleaseAllConfiguredMovementKeys()
    Send("{LEFT up}{RIGHT up}{A up}{D up}")
    $g_sHeldMovementKey = ""
EndFunc

Func _ReleaseAllConfiguredPotionKeys()
    ; Potion keys are sent as taps, but force every supported key up for F8/exit safety.
    Send("{F1 up}{F2 up}{F3 up}{F4 up}{F5 up}{F7 up}{F9 up}{F10 up}{F11 up}{F12 up}")
EndFunc

Func _PotionSendToken($sKeyLabel)
    Switch StringUpper(StringStripWS($sKeyLabel, 8))
        Case "F1", "F2", "F3", "F4", "F5", "F7", "F9", "F10", "F11", "F12"
            Return StringUpper(StringStripWS($sKeyLabel, 8))
    EndSwitch
    Return ""
EndFunc

Func _MovementHoldToken($sKeyLabel)
    Switch StringUpper(StringStripWS($sKeyLabel, 8))
        Case "LEFT ARROW"
            Return "LEFT"
        Case "RIGHT ARROW"
            Return "RIGHT"
        Case "A"
            Return "A"
        Case "D"
            Return "D"
    EndSwitch
    Return ""
EndFunc

Func _TapConfiguredMovementKey($bLeft)
    If Not _EnsureGameActiveForManualInput() Then Return

    Local $sLabel = GUICtrlRead($g_idRightKeyCombo)
    If $bLeft Then $sLabel = GUICtrlRead($g_idLeftKeyCombo)

    Local $sToken = _MovementHoldToken($sLabel)
    If $sToken = "" Then Return

    Send("{" & $sToken & "}")
    $g_sLastInput = "Tap " & $sLabel
    GUICtrlSetData($g_idLastInputValue, $g_sLastInput)
    _SetStatus("Sent " & $g_sLastInput & " to the active game window.")
    _Log("INPUT TAP: " & $g_sLastInput)
EndFunc

Func _TapConfiguredSkill($bManual)
    If $bManual And Not _EnsureGameActiveForManualInput() Then Return
    If Not $bManual And Not WinActive($g_hTargetWindow) Then Return

    Local $sLabel = GUICtrlRead($g_idSkillKeyCombo)
    Local $sSend = _SkillSendToken($sLabel)
    If $sSend = "" Then Return

    Send($sSend)
    $g_sLastInput = "Skill " & $sLabel
    GUICtrlSetData($g_idLastInputValue, $g_sLastInput)
    If $bManual Then _SetStatus("Sent test skill: " & $sLabel)
    _Log("INPUT SKILL: " & $sLabel)
EndFunc

Func _SkillSendToken($sKeyLabel)
    Switch StringUpper(StringStripWS($sKeyLabel, 8))
        Case "ALT"
            Return "{ALT}"
        Case "CTRL"
            Return "{CTRL}"
        Case "SPACE"
            Return "{SPACE}"
        Case "Z"
            Return "z"
        Case "X"
            Return "x"
        Case "C"
            Return "c"
    EndSwitch
    Return ""
EndFunc

Func _EnsureGameActiveForManualInput()
    If $g_hTargetWindow = 0 Or Not WinExists($g_hTargetWindow) Then
        _SetStatus("No valid game window is bound.")
        Return False
    EndIf

    WinActivate($g_hTargetWindow)
    If Not WinWaitActive($g_hTargetWindow, "", 2) Then
        _SetStatus("Could not activate the bound game window.")
        Return False
    EndIf
    Return True
EndFunc

; ============================================================================
; Bottom HP/MP HUD OCR and autopot
; ============================================================================

Func _ResetVitalsCandidates()
    $g_iHpCandidateCurrent = -1
    $g_iHpCandidateMaximum = -1
    $g_nHpCandidatePercent = -1
    $g_iHpCandidateReads = 0
    $g_iMpCandidateCurrent = -1
    $g_iMpCandidateMaximum = -1
    $g_nMpCandidatePercent = -1
    $g_iMpCandidateReads = 0
    $g_iAcceptedHpMaximum = -1
    $g_iAcceptedMpMaximum = -1
    $g_sLastAutopotDecision = "Waiting for stable HP/MP OCR"
    If $g_idAutopotDecisionValue <> 0 Then _SetAutopotDecision($g_sLastAutopotDecision)
EndFunc

Func _SetAutopotDecision($sDecision)
    $g_sLastAutopotDecision = $sDecision
    If $g_idAutopotDecisionValue <> 0 Then GUICtrlSetData($g_idAutopotDecisionValue, $sDecision)
EndFunc

Func _ScanVitalsOnce()
    If $g_bSearchBusy Then
        _Log("VITALS DECISION: scan skipped because another capture/OCR operation is busy")
        Return
    EndIf
    $g_bSearchBusy = True

    Local $iHp = -1, $iHpMax = -1, $iMp = -1, $iMpMax = -1
    Local $sOcrOutput = ""

    If Not _TryReadCurrentVitals($iHp, $iHpMax, $iMp, $iMpMax, $sOcrOutput) Then
        $g_sLastVitalsOcr = $sOcrOutput
        _SetAutopotDecision("OCR miss; no potion decision")
        GUICtrlSetData($g_idVitalsStatusValue, "Unreadable; see debug images")
        _Log("VITALS OCR MISS: raw='" & $sOcrOutput & _
                "'; crop=" & $g_sLatestVitalsRawPath & _
                "; scaled=" & $g_sLatestVitalsScaledPath & _
                "; no potion keys sent")
        $g_bSearchBusy = False
        Return
    EndIf

    $g_sLastVitalsOcr = $sOcrOutput
    Local $nHpPercent = ($iHpMax > 0 ? ($iHp / $iHpMax) * 100.0 : -1)
    Local $nMpPercent = ($iMpMax > 0 ? ($iMp / $iMpMax) * 100.0 : -1)

    $g_iCurrentHp = $iHp
    $g_iMaximumHp = $iHpMax
    $g_nCurrentHpPercent = $nHpPercent
    $g_iCurrentMp = $iMp
    $g_iMaximumMp = $iMpMax
    $g_nCurrentMpPercent = $nMpPercent

    GUICtrlSetData($g_idHpCurrentValue, _FormatVitalRead("HP", $iHp, $iHpMax, $nHpPercent))
    GUICtrlSetData($g_idMpCurrentValue, _FormatVitalRead("MP", $iMp, $iMpMax, $nMpPercent))
    GUICtrlSetData($g_idVitalsStatusValue, _
            "HP " & StringFormat("%.1f", $nHpPercent) & "% | MP " & _
            StringFormat("%.1f", $nMpPercent) & "%")

    _Log("VITALS OCR: HP=" & $iHp & "/" & $iHpMax & _
            " (" & StringFormat("%.2f", $nHpPercent) & "%)" & _
            "; MP=" & $iMp & "/" & $iMpMax & _
            " (" & StringFormat("%.2f", $nMpPercent) & "%)" & _
            "; OCR='" & $sOcrOutput & "'")

    Local $sHpDecision = _ProcessVitalChannel( _
            "HP", $iHp, $iHpMax, $nHpPercent, _
            $g_idHpAutopotCheckbox, $g_idHpThresholdInput, $g_idHpPotionKeyCombo, _
            $g_iHpCandidateCurrent, $g_iHpCandidateMaximum, _
            $g_nHpCandidatePercent, $g_iHpCandidateReads, _
            $g_iAcceptedHpMaximum, $g_hHpPotionTimer, $g_bHpPotionHasFired)

    Local $sMpDecision = _ProcessVitalChannel( _
            "MP", $iMp, $iMpMax, $nMpPercent, _
            $g_idMpAutopotCheckbox, $g_idMpThresholdInput, $g_idMpPotionKeyCombo, _
            $g_iMpCandidateCurrent, $g_iMpCandidateMaximum, _
            $g_nMpCandidatePercent, $g_iMpCandidateReads, _
            $g_iAcceptedMpMaximum, $g_hMpPotionTimer, $g_bMpPotionHasFired)

    _SetAutopotDecision("HP: " & $sHpDecision & @CRLF & "MP: " & $sMpDecision)
    $g_bSearchBusy = False
EndFunc

Func _ProcessVitalChannel( _
        $sKind, $iCurrent, $iMaximum, $nPercent, _
        $idEnabledCheckbox, $idThresholdInput, $idKeyCombo, _
        ByRef $iCandidateCurrent, ByRef $iCandidateMaximum, _
        ByRef $nCandidatePercent, ByRef $iCandidateReads, _
        ByRef $iAcceptedMaximum, ByRef $hPotionTimer, ByRef $bPotionHasFired)

    Local $iThreshold = Int(Number(GUICtrlRead($idThresholdInput)))
    $iThreshold = _ClampValue($iThreshold, 1, 99)
    Local $iRequiredReads = $APP_VITALS_STABLE_READS
    If $nPercent <= ($iThreshold - $APP_VITALS_SEVERE_MARGIN) Then $iRequiredReads = 1

    ; Accept consecutive reads with the same maximum and a nearby percentage.
    If $iMaximum = $iCandidateMaximum And _
            $nCandidatePercent >= 0 And Abs($nPercent - $nCandidatePercent) <= 5.0 Then
        $iCandidateReads += 1
    Else
        $iCandidateReads = 1
    EndIf
    $iCandidateCurrent = $iCurrent
    $iCandidateMaximum = $iMaximum
    $nCandidatePercent = $nPercent

    If $iCandidateReads < $iRequiredReads Then
        Local $sPending = "stable read " & $iCandidateReads & "/" & $iRequiredReads
        _Log("AUTOPOT " & $sKind & ": " & $sPending & _
                "; current=" & $iCurrent & "/" & $iMaximum & _
                " (" & StringFormat("%.2f", $nPercent) & "%)" & _
                "; no key sent")
        Return $sPending
    EndIf

    If $iAcceptedMaximum > 0 Then
        Local $nMaxChange = Abs($iMaximum - $iAcceptedMaximum) / $iAcceptedMaximum * 100.0
        If $nMaxChange > $APP_VITALS_MAX_CHANGE_PERCENT And _
                $iCandidateReads < $APP_VITALS_MAX_CHANGE_READS Then
            Local $sMaxPending = "max changed; verify " & $iCandidateReads & "/" & _
                    $APP_VITALS_MAX_CHANGE_READS
            _Log("AUTOPOT " & $sKind & ": suspicious maximum change " & _
                    $iAcceptedMaximum & " -> " & $iMaximum & _
                    " (" & StringFormat("%.1f", $nMaxChange) & "%)" & _
                    "; " & $sMaxPending & "; no key sent")
            Return $sMaxPending
        EndIf
    EndIf
    $iAcceptedMaximum = $iMaximum

    If GUICtrlRead($idEnabledCheckbox) <> $GUI_CHECKED Then
        _Log("AUTOPOT " & $sKind & ": disabled; current=" & _
                StringFormat("%.2f", $nPercent) & "%" & _
                "; threshold=" & $iThreshold & "%; no key sent")
        Return "disabled"
    EndIf

    If $nPercent > $iThreshold Then
        _Log("AUTOPOT " & $sKind & ": " & _
                StringFormat("%.2f", $nPercent) & "% > threshold " & _
                $iThreshold & "%; no key sent")
        Return StringFormat("%.1f%% > %d%%", $nPercent, $iThreshold)
    EndIf

    If $g_hTargetWindow = 0 Or Not WinExists($g_hTargetWindow) Then
        _Log("AUTOPOT " & $sKind & ": threshold crossed but game window is unavailable; no key sent")
        Return "low; window unavailable"
    EndIf

    If Not WinActive($g_hTargetWindow) Then
        _Log("AUTOPOT " & $sKind & ": threshold crossed but game window is not active; no key sent")
        Return "low; game inactive"
    EndIf

    Local $iCooldown = Int(Number(GUICtrlRead($g_idPotionCooldownInput)))
    $iCooldown = _ClampValue($iCooldown, 250, 10000)
    Local $nElapsed = $iCooldown
    If $bPotionHasFired Then $nElapsed = TimerDiff($hPotionTimer)

    If $bPotionHasFired And $nElapsed < $iCooldown Then
        _Log("AUTOPOT " & $sKind & ": " & _
                StringFormat("%.2f", $nPercent) & "% <= " & $iThreshold & _
                "%; cooldown " & Int($nElapsed) & "/" & $iCooldown & _
                " ms; no key sent")
        Return "cooldown " & Int($nElapsed) & "/" & $iCooldown & " ms"
    EndIf

    Local $sKeyLabel = GUICtrlRead($idKeyCombo)
    Local $sToken = _PotionSendToken($sKeyLabel)
    If $sToken = "" Then
        _Log("AUTOPOT " & $sKind & ": threshold crossed but configured key is invalid; no key sent")
        Return "invalid key"
    EndIf

    Send("{" & $sToken & "}")
    $hPotionTimer = TimerInit()
    $bPotionHasFired = True
    $g_sLastInput = $sKind & " potion " & $sKeyLabel
    GUICtrlSetData($g_idLastInputValue, $g_sLastInput)

    _Log("AUTOPOT " & $sKind & " SEND: key=" & $sKeyLabel & _
            "; current=" & $iCurrent & "/" & $iMaximum & _
            " (" & StringFormat("%.2f", $nPercent) & "%)" & _
            "; threshold=" & $iThreshold & "%" & _
            "; cooldown=" & $iCooldown & " ms")
    Return "sent " & $sKeyLabel
EndFunc

Func _TryReadCurrentVitals( _
        ByRef $iHp, ByRef $iHpMax, ByRef $iMp, ByRef $iMpMax, ByRef $sOcrOutput)
    $iHp = -1
    $iHpMax = -1
    $iMp = -1
    $iMpMax = -1
    $sOcrOutput = ""
    If $g_sTesseractPath = "" Then Return False

    Local $iLeft = 0, $iTop = 0, $iRight = 0, $iBottom = 0
    If Not _GetTargetWindowRect($iLeft, $iTop, $iRight, $iBottom) Then Return False

    Local $iClientWidth = $iRight - $iLeft + 1
    Local $iClientHeight = $iBottom - $iTop + 1
    Local $iVitalsLeft = $iLeft + Int($iClientWidth * $APP_VITALS_X1_RATIO)
    Local $iVitalsRight = $iLeft + Int($iClientWidth * $APP_VITALS_X2_RATIO)
    Local $iVitalsTop = $iTop + Int($iClientHeight * $APP_VITALS_Y1_RATIO)
    Local $iVitalsBottom = $iTop + Int($iClientHeight * $APP_VITALS_Y2_RATIO)

    Local $bSaved = _ImageSearch_ScreenCapture_SaveImage( _
            $g_sLatestVitalsRawPath, _
            $iVitalsLeft, $iVitalsTop, $iVitalsRight, $iVitalsBottom, $SEARCH_SCREEN)
    If Not $bSaved Or Not FileExists($g_sLatestVitalsRawPath) Then Return False

    If Not _CreateScaledOcrImage( _
            $g_sLatestVitalsRawPath, $g_sLatestVitalsScaledPath, $APP_VITALS_SCALE) Then Return False

    $sOcrOutput = _RunTesseractOnVitalsImage($g_sLatestVitalsScaledPath)
    If $sOcrOutput = "" Then Return False
    Return _ExtractVitalsValues($sOcrOutput, $iHp, $iHpMax, $iMp, $iMpMax)
EndFunc

Func _RunTesseractOnVitalsImage($sImagePath)
    Local $sOutputBase = $g_sOcrTempDirectory & "\vitals_ocr_result"
    Local $sOutputPath = $sOutputBase & ".txt"
    FileDelete($sOutputPath)

    Local $sCommand = '"' & $g_sTesseractPath & '" "' & $sImagePath & _
            '" "' & $sOutputBase & '" -l eng --psm 7'
    Local $iExitCode = RunWait($sCommand, @ScriptDir, @SW_HIDE)
    If $iExitCode <> 0 Or Not FileExists($sOutputPath) Then Return ""

    Local $sOutput = FileRead($sOutputPath)
    Return StringStripWS( _
            StringReplace(StringReplace($sOutput, @CR, " "), @LF, " "), 7)
EndFunc

Func _ExtractVitalsValues( _
        $sText, ByRef $iHp, ByRef $iHpMax, ByRef $iMp, ByRef $iMpMax)
    $iHp = -1
    $iHpMax = -1
    $iMp = -1
    $iMpMax = -1
    If $sText = "" Then Return False

    Local $sUpper = StringUpper($sText)
    Local $aHp = StringRegExp( _
            $sUpper, 'HP[^0-9]*([0-9]{1,6})[^0-9]+([0-9]{1,6})', 3)
    Local $aMp = StringRegExp( _
            $sUpper, 'MP[^0-9]*([0-9]{1,6})[^0-9]+([0-9]{1,6})', 3)

    If Not IsArray($aHp) Or UBound($aHp) < 2 Then Return False
    If Not IsArray($aMp) Or UBound($aMp) < 2 Then Return False

    $iHp = Int(Number($aHp[0]))
    $iHpMax = Int(Number($aHp[1]))
    $iMp = Int(Number($aMp[0]))
    $iMpMax = Int(Number($aMp[1]))

    If $iHp < 0 Or $iHpMax <= 0 Or $iHp > $iHpMax Then Return False
    If $iMp < 0 Or $iMpMax <= 0 Or $iMp > $iMpMax Then Return False
    Return True
EndFunc

Func _FormatVitalRead($sKind, $iCurrent, $iMaximum, $nPercent)
    Return $sKind & ": " & $iCurrent & "/" & $iMaximum & @CRLF & _
            StringFormat("%.1f%%", $nPercent)
EndFunc

; ============================================================================
; Bottom EXP HUD OCR and session statistics
; ============================================================================

Func _FindTesseractPath()
    Local $aCandidates[5] = [ _
            @ScriptDir & "\tesseract.exe", _
            @ScriptDir & "\Tesseract-OCR\tesseract.exe", _
            @ProgramFilesDir & "\Tesseract-OCR\tesseract.exe", _
            @ProgramFilesDir & " (x86)\Tesseract-OCR\tesseract.exe", _
            "C:\Program Files\Tesseract-OCR\tesseract.exe" _
    ]

    Local $i
    For $i = 0 To UBound($aCandidates) - 1
        If FileExists($aCandidates[$i]) Then Return $aCandidates[$i]
    Next
    Return ""
EndFunc

Func _ResetExpSession()
    $g_hSessionStart = TimerInit()
    $g_nSessionExp = 0
    $g_iExpEvents = 0
    $g_nLastGain = 0
    $g_sLastRead = ""
    $g_iLastAcceptedHudExp = -1
    $g_iHudCandidateExp = -1
    $g_iHudCandidateReads = 0
    $g_sLastHudOcr = ""
    $g_hMissLogTimer = TimerInit()
    _UpdateSessionStats()
    _SetStatus("EXP session reset.")
    _Log("EXP session reset")
EndFunc

Func _UpdateSessionStats()
    Local $iSessionSeconds = Int(TimerDiff($g_hSessionStart) / 1000)
    Local $nHours = $iSessionSeconds / 3600.0
    Local $nXpHour = 0
    If $nHours > 0 Then $nXpHour = $g_nSessionExp / $nHours

    GUICtrlSetData($g_idSessionTimeValue, _FormatSeconds($iSessionSeconds))
    GUICtrlSetData($g_idXpHourValue, _FormatCompact($nXpHour))
    GUICtrlSetData($g_idTotalValue, _FormatCompact($g_nSessionExp))
    GUICtrlSetData($g_idEventsValue, $g_iExpEvents)
    GUICtrlSetData($g_idLastGainValue, _FormatCompact($g_nLastGain))
    GUICtrlSetData($g_idLastReadValue, ($g_sLastRead <> "" ? $g_sLastRead : "-"))
    GUICtrlSetData($g_idTesseractValue, _
            ($g_sTesseractPath <> "" ? $g_sTesseractPath : "Not found; EXP + HP/MP OCR disabled"))
    _UpdateWindowDisplay()
EndFunc

Func _ScanExperienceOnce()
    If $g_bSearchBusy Then Return
    $g_bSearchBusy = True

    Local $iCurrentExp = 0
    Local $nCurrentPercent = -1
    Local $sOcrOutput = ""

    If _TryReadCurrentHudExp($iCurrentExp, $nCurrentPercent, $sOcrOutput) Then
        $g_sLastHudOcr = $sOcrOutput

        If $iCurrentExp <> $g_iHudCandidateExp Then
            $g_iHudCandidateExp = $iCurrentExp
            $g_iHudCandidateReads = 1
        Else
            $g_iHudCandidateReads += 1
        EndIf

        If $g_iHudCandidateReads >= $APP_HUD_STABLE_READS Then
            _AcceptStableHudExp($iCurrentExp, $nCurrentPercent, $sOcrOutput)
        EndIf
    Else
        $g_iHudCandidateExp = -1
        $g_iHudCandidateReads = 0

        If TimerDiff($g_hMissLogTimer) >= $APP_MISS_LOG_INTERVAL_MS Then
            $g_hMissLogTimer = TimerInit()
            _Log("Bottom EXP HUD OCR miss; raw='" & $sOcrOutput & _
                    "'; crop=" & $g_sLatestHudRawPath & _
                    "; scaled=" & $g_sLatestHudScaledPath)
        EndIf
    EndIf

    _UpdateSessionStats()
    $g_bSearchBusy = False
EndFunc

Func _AcceptStableHudExp($iCurrentExp, $nCurrentPercent, $sOcrOutput)
    $g_sLastRead = _FormatHudRead($iCurrentExp, $nCurrentPercent)
    GUICtrlSetData($g_idLastReadValue, $g_sLastRead)

    If $g_iLastAcceptedHudExp < 0 Then
        $g_iLastAcceptedHudExp = $iCurrentExp
        _Log("EXP HUD baseline: " & $g_sLastRead & "; OCR='" & $sOcrOutput & "'")
        Return
    EndIf

    If $iCurrentExp = $g_iLastAcceptedHudExp Then Return

    If $iCurrentExp > $g_iLastAcceptedHudExp Then
        Local $iPreviousExp = $g_iLastAcceptedHudExp
        Local $iGain = $iCurrentExp - $iPreviousExp
        $g_nLastGain = $iGain
        $g_nSessionExp += $iGain
        $g_iExpEvents += 1
        $g_iLastAcceptedHudExp = $iCurrentExp
        _Log("EXP HUD EVENT: previous=" & $iPreviousExp & _
                "; current=" & $iCurrentExp & _
                "; percent=" & $nCurrentPercent & _
                "; gain=" & $iGain & _
                "; OCR='" & $sOcrOutput & "'")
        Return
    EndIf

    _Log("EXP HUD decreased from " & $g_iLastAcceptedHudExp & _
            " to " & $iCurrentExp & _
            "; probable level-up or OCR correction; rebasing without gain." & _
            " OCR='" & $sOcrOutput & "'")
    $g_iLastAcceptedHudExp = $iCurrentExp
EndFunc

Func _FormatHudRead($iExp, $nPercent)
    If $nPercent >= 0 Then
        Return "EXP " & $iExp & " (" & StringFormat("%.2f", $nPercent) & "%)"
    EndIf
    Return "EXP " & $iExp
EndFunc

Func _TryReadCurrentHudExp(ByRef $iCurrentExp, ByRef $nCurrentPercent, ByRef $sOcrOutput)
    $iCurrentExp = 0
    $nCurrentPercent = -1
    $sOcrOutput = ""
    If $g_sTesseractPath = "" Then Return False

    Local $iLeft = 0, $iTop = 0, $iRight = 0, $iBottom = 0
    If Not _GetTargetWindowRect($iLeft, $iTop, $iRight, $iBottom) Then Return False

    Local $iClientWidth = $iRight - $iLeft + 1
    Local $iClientHeight = $iBottom - $iTop + 1
    Local $iHudLeft = $iLeft + Int($iClientWidth * $APP_HUD_X1_RATIO)
    Local $iHudRight = $iLeft + Int($iClientWidth * $APP_HUD_X2_RATIO)
    Local $iHudTop = $iTop + Int($iClientHeight * $APP_HUD_Y1_RATIO)
    Local $iHudBottom = $iTop + Int($iClientHeight * $APP_HUD_Y2_RATIO)

    Local $bSaved = _ImageSearch_ScreenCapture_SaveImage( _
            $g_sLatestHudRawPath, $iHudLeft, $iHudTop, $iHudRight, $iHudBottom, $SEARCH_SCREEN)
    If Not $bSaved Or Not FileExists($g_sLatestHudRawPath) Then Return False

    If Not _CreateScaledOcrImage( _
            $g_sLatestHudRawPath, $g_sLatestHudScaledPath, $APP_HUD_SCALE) Then Return False

    $sOcrOutput = _RunTesseractOnHudImage($g_sLatestHudScaledPath)
    If $sOcrOutput = "" Then Return False
    Return _ExtractHudValues($sOcrOutput, $iCurrentExp, $nCurrentPercent)
EndFunc

Func _CreateScaledOcrImage($sSourcePath, $sDestinationPath, $iScale)
    If Not $g_bGdiPlusStarted Or Not FileExists($sSourcePath) Or $iScale < 1 Then Return False

    Local $hSourceImage = _GDIPlus_ImageLoadFromFile($sSourcePath)
    If $hSourceImage = 0 Then Return False

    Local $iSourceWidth = _GDIPlus_ImageGetWidth($hSourceImage)
    Local $iSourceHeight = _GDIPlus_ImageGetHeight($hSourceImage)
    If $iSourceWidth < 1 Or $iSourceHeight < 1 Then
        _GDIPlus_ImageDispose($hSourceImage)
        Return False
    EndIf

    Local $iOutputWidth = $iSourceWidth * $iScale
    Local $iOutputHeight = $iSourceHeight * $iScale
    Local $hOutputBitmap = _GDIPlus_BitmapCreateFromScan0($iOutputWidth, $iOutputHeight)
    If $hOutputBitmap = 0 Then
        _GDIPlus_ImageDispose($hSourceImage)
        Return False
    EndIf

    Local $hGraphics = _GDIPlus_ImageGetGraphicsContext($hOutputBitmap)
    If $hGraphics = 0 Then
        _GDIPlus_BitmapDispose($hOutputBitmap)
        _GDIPlus_ImageDispose($hSourceImage)
        Return False
    EndIf

    _GDIPlus_GraphicsSetInterpolationMode($hGraphics, $GDIP_INTERPOLATIONMODE_HIGHQUALITYBICUBIC)
    Local $bDrawn = _GDIPlus_GraphicsDrawImageRect( _
            $hGraphics, $hSourceImage, 0, 0, $iOutputWidth, $iOutputHeight)
    Local $bSaved = False
    If $bDrawn Then $bSaved = _GDIPlus_ImageSaveToFile($hOutputBitmap, $sDestinationPath)

    _GDIPlus_GraphicsDispose($hGraphics)
    _GDIPlus_BitmapDispose($hOutputBitmap)
    _GDIPlus_ImageDispose($hSourceImage)
    Return $bSaved And FileExists($sDestinationPath)
EndFunc

Func _RunTesseractOnHudImage($sImagePath)
    Local $sOutputBase = $g_sOcrTempDirectory & "\hud_ocr_result"
    Local $sOutputPath = $sOutputBase & ".txt"
    FileDelete($sOutputPath)

    Local $sCommand = '"' & $g_sTesseractPath & '" "' & $sImagePath & _
            '" "' & $sOutputBase & '" -l eng --psm 7'
    Local $iExitCode = RunWait($sCommand, @ScriptDir, @SW_HIDE)
    If $iExitCode <> 0 Or Not FileExists($sOutputPath) Then Return ""

    Local $sOutput = FileRead($sOutputPath)
    Return StringStripWS( _
            StringReplace(StringReplace($sOutput, @CR, " "), @LF, " "), 7)
EndFunc

Func _ExtractHudValues($sText, ByRef $iExp, ByRef $nPercent)
    $iExp = -1
    $nPercent = -1
    If $sText = "" Then Return False

    Local $sUpper = StringUpper($sText)
    ; Repair OCR spacing such as 27. 72% or 27 .72% before parsing.
    $sUpper = StringRegExpReplace($sUpper, '([0-9])\s*\.\s*([0-9])', '$1.$2')

    Local $aExpMatches = StringRegExp($sUpper, 'EXP[^0-9]*([0-9]{1,10})', 3)
    If @error Or Not IsArray($aExpMatches) Or UBound($aExpMatches) < 1 Then Return False

    Local $sDigits = $aExpMatches[0]
    If Not StringRegExp($sDigits, '^[0-9]+$') Then Return False
    $iExp = Int(Number($sDigits))

    Local $aPercentMatches = StringRegExp( _
            $sUpper, '([0-9]{1,3}\.[0-9]{1,2})[^0-9]*%', 3)
    If IsArray($aPercentMatches) And UBound($aPercentMatches) >= 1 Then
        Local $nParsedPercent = Number($aPercentMatches[0])
        If $nParsedPercent >= 0 And $nParsedPercent <= 100 Then $nPercent = $nParsedPercent
    EndIf

    Return $iExp >= 0
EndFunc

Func _FormatSeconds($iSeconds)
    Local $iHours = Int($iSeconds / 3600)
    Local $iMinutes = Int(Mod($iSeconds, 3600) / 60)
    Local $iRemainder = Int(Mod($iSeconds, 60))
    Return StringFormat("%02d:%02d:%02d", $iHours, $iMinutes, $iRemainder)
EndFunc

Func _FormatCompact($nValue)
    If $nValue >= 1000000 Then Return StringFormat("%.2fM", $nValue / 1000000.0)
    If $nValue >= 1000 Then Return StringFormat("%.1fK", $nValue / 1000.0)
    Return StringFormat("%.0f", $nValue)
EndFunc

Func _OnExit()
    $g_bContinuous = False
    $g_bOcrMonitoring = False
    _ReleaseMovementKey()
    _ReleaseAllConfiguredMovementKeys()
    _ReleaseAllConfiguredPotionKeys()
    _ClearHighlights()
    HotKeySet("{F6}")
    HotKeySet("{F8}")
    If $g_bGdiPlusStarted Then _GDIPlus_Shutdown()
    If $g_bImageSearchStarted Then _ImageSearch_Shutdown()
    _Log("Maple Automation MVP v0.2.0 stopped")
EndFunc
