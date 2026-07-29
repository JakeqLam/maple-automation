MAPLE AUTOMATION MVP v0.2.0

This build extends the verified combined movement + EXP OCR POC with OCR-based HP/MP reading and guarded autopot decisions.

FEATURES
- Binds MapleSaga.exe or MapleStory.exe.
- Detects player and targets from data\player and data\target.
- Optional horizontal movement and movement-skill taps.
- Reads the permanent bottom EXP HUD and tracks session XP.
- Reads HP and MP numeric ratios from the permanent bottom HUD.
- Computes HP/MP percentages from OCR values.
- Optional HP and MP potion sends below configurable thresholds.
- Separate per-potion cooldown enforcement.
- F6 starts/pauses the combined runtime.
- F8 immediately stops automation and forces movement/potion keys up.
- Logs every vitals OCR result and every autopot decision.

SAFETY DEFAULTS
- Automatic movement is OFF.
- HP autopot is OFF.
- MP autopot is OFF.
- Potion inputs are sent only while the bound game window is active.
- Normal threshold decisions require stable OCR confirmation.
- A reading at least 10 percentage points below threshold is treated as severe and may act after one valid OCR read.
- Large OCR changes to maximum HP/MP require additional confirmation.

DEFAULT AUTOPOT SETTINGS
- HP threshold: 40%, key F1
- MP threshold: 30%, key F2
- Cooldown: 800 ms per potion channel

INSTALL
1. Extract into C:\Users\Jake Lam\code\maple-automation.
2. Keep ImageSearchDLL_UDF_Embedded.au3 beside the main script.
3. Keep Tesseract installed at C:\Program Files\Tesseract-OCR\tesseract.exe.
4. Run Run-Maple-Automation-MVP-v0.2.0-Admin.cmd.

FIRST TEST
1. Start MapleSaga at 1280x720.
2. Launch the MVP and confirm the client is bound.
3. Leave HP/MP autopot unchecked and press F6.
4. Confirm the GUI reports values matching the bottom HUD.
5. Open debug\MapleAutomationMVP.log and verify VITALS OCR and AUTOPOT decision lines.
6. Configure thresholds/keys, enable one channel at a time, and test with F8 ready.

DEBUG OUTPUT
- debug\MapleAutomationMVP.log
- debug\ocr_temp\latest_vitals_hud_raw.png
- debug\ocr_temp\latest_vitals_hud_scaled.png
- debug\ocr_temp\vitals_ocr_result.txt
- Existing EXP and vision debug files remain available.
