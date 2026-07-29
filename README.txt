MAPLE AUTOMATION MVP v0.1.1
============================

PURPOSE
-------
This is the first combined build of the two successful proofs of concept:

1. Maple Template Library POC v3
   - player template library
   - target template library
   - nearest-target detection and distance measurement
   - import and snippet-capture tools

2. Maple OCR Session Stats POC v1.4
   - permanent bottom EXP HUD capture
   - 6x GDI+ upscale
   - Tesseract single-line OCR
   - stable-read confirmation
   - session EXP, event count, last gain, and XP/hour

The combined MVP also adds optional horizontal movement toward the nearest detected
target and optional movement-skill taps.

INSTALL
-------
Extract this bundle into your existing folder, normally:

    C:\Users\Jake Lam\code\maple-automation

Keep your known-working dependency beside the script:

    ImageSearchDLL_UDF_Embedded.au3

Tesseract should remain installed at the working default path:

    C:\Program Files\Tesseract-OCR\tesseract.exe

RUN
---
Launch:

    Run-Maple-Automation-MVP-v0.1.1-Admin.cmd

The launcher runs Au3Check first when available, then starts the script.

SAFE FIRST TEST
---------------
1. Start MapleSaga at the same 1280x720 client size used for template capture.
2. Open the MVP and confirm Window, Player, Targets, and Nearest are detected.
3. Leave automatic movement unchecked.
4. Use Tap Left, Tap Right, and Test Skill to validate the configured keys.
5. Check Enable automatic horizontal movement.
6. Click F6 Start, then activate the game window.
7. Press F8 immediately if movement is unexpected.

HOTKEYS
-------
F6  Start or pause the combined runtime.
F8  Emergency stop and release Left, Right, A, and D.

MOVEMENT RULES
--------------
- Input is sent only while the bound Maple game window is active.
- The nearest target is selected by Euclidean center distance.
- Movement uses only the horizontal delta for this MVP.
- The movement key is released inside Stop Distance.
- The configured skill key is tapped at Skill Interval while moving.
- Lost/stale vision releases movement automatically.

DEBUG OUTPUT
------------
    debug\MapleAutomationMVP.log
    debug\ocr_temp\latest_exp_hud_raw.png
    debug\ocr_temp\latest_exp_hud_scaled.png
    debug\ocr_temp\hud_ocr_result.txt

DATA LIBRARY
------------
    data\player\*.png
    data\target\*.png

The bundle carries forward the uploaded SuperKiwi and stump templates.

KNOWN MVP LIMITS
----------------
- No vertical platform routing, obstacle handling, or attack logic yet.
- Target identity is currently the nearest matching target template.
- Templates remain exact-scale first; display scaling changes may require new captures.
- EXP rollover safely rebases at level-up but does not yet calculate the rollover gain.
- HP/MP OCR and autopot are intentionally deferred until their HUD regions are
  calibrated and verified with the same discipline used for EXP.

V0.1.1 HOTFIX
--------------
Removed duplicate UTF-8 BOM bytes that prevented AutoIt from parsing #RequireAdmin on line 1.
