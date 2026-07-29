MAPLE TEMPLATE LIBRARY POC v3
=============================

INSTALL
-------
Extract the complete ZIP directly into:

C:\Users\Jake Lam\code\maple-automation

Keep your existing file at the project root:

ImageSearchDLL_UDF_Embedded.au3

Run:

Run-Maple-Template-Library-POC-v3-Admin.cmd


/DATA LAYOUT
------------
Every searchable image now lives under the single /data tree:

data\
  player\
    SuperKiwi_plain.png
    SuperKiwi_selected.png
    SuperKiwi_text.png

  target\
    stump1.png
    stump2.png
    stump3.png
    stump4.png
    stump5.png

The filenames are no longer hard-coded.

- Every PNG directly inside data\player is treated as a player/username
  identity template.
- Every PNG directly inside data\target is treated as a target template.
- Click "Reload /data" after manually adding or removing files.
- Restarting the POC also reloads both folders.


IMPORTING IMAGES
----------------
"Import Player Images"
- Select one or many PNG files.
- Copies them into data\player.
- Duplicate filenames receive _2, _3, and so on.
- Reloads the library automatically.
- Runs an immediate search when the game is already bound.

"Import Target Images"
- Performs the same workflow for data\target.


CAPTURING SNIPPETS
------------------
"Capture Player Snippet" or "Capture Target Snippet":

1. The control panel hides.
2. Drag a rectangle over the bound MapleSaga game client.
3. Release the left mouse button.
4. Enter a filename.
5. The PNG is saved into the selected /data category.
6. The library reloads and immediately tests the templates.

Press Esc or right-click before completing the rectangle to cancel.
The capture waits up to 20 seconds for the selection to begin.


SEARCH BEHAVIOR
---------------
- Searches every player PNG until the first player match.
- Searches every target PNG and collects all target matches.
- Deduplicates overlapping detections across alternate target images.
- Chooses the nearest target by center-to-center screen distance.
- Continues target searching even when the player is temporarily missing.

Overlay colors:
- Blue: player
- Orange: nearest target
- Green: other targets

This script remains read-only:
- no keyboard hotkeys
- no clicks sent to MapleSaga
- no movement or combat automation


PERFORMANCE
-----------
Search cost grows roughly with the number of images in /data.

The current bundle contains:
- 3 player templates
- 5 target templates

Continuous search uses a 300 ms interval. The search cannot overlap itself,
so a large template library may update more slowly but will not launch
concurrent searches.


DEBUG
-----
Log and captures:

C:\Users\Jake Lam\code\maple-automation\debug

Main log:

MapleTemplateLibraryPOC_v3.log
