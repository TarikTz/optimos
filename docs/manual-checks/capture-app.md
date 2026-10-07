# OptimosApp manual checks

Run these on a real Mac after `App/scripts/run.sh`. Items marked (2 displays) need a second monitor.
Tick each item; note the macOS version and displays used at the top.

macOS / displays used:

Known limitations (see spec): window capture is a crop (overlapping windows included, no shadow); selection stays within one display; hotkeys are not rebindable yet.

This checklist has NOT been run yet; tick items only after doing them.

Setup: copy `App/Config/Local.xcconfig.example` to `App/Config/Local.xcconfig` and set your team id so
Screen Recording permission survives rebuilds (a free Apple ID "Apple Development" certificate is enough).
If Screen Recording already shows OptimosApp as allowed but the app keeps asking (this happens after rebuilds
of an ad-hoc signed build): run `tccutil reset ScreenCapture app.optimos.OptimosApp`, relaunch the app, and
grant access again. On macOS 15 and later the system may periodically ask you to re-confirm screen recording
for apps like this; if a capture seems to hang, look for that prompt. Install the tools: `brew install xcodegen webp oxipng pngquant libjpeg-turbo`.

## Permission and menu
1. [ ] First launch with no Screen Recording permission: press `⌃⌥⌘3`. A toast asks you to allow Screen Recording and restart; the system prompt appears; nothing crashes.
2. [ ] Grant permission in System Settings, quit and relaunch. The menu shows "Screen Recording: allowed".
3. [ ] The menu-bar icon is visible, there is no Dock icon, and the menu lists the two capture actions with their shortcuts, a "Saving to: …" line, "Save Location…", "Show Last Screenshot in Finder" (disabled before the first save), the permission line and Quit.

## Capture
4. [ ] `⌃⌥⌘3`: the screen under the mouse is captured instantly. Paste into Preview or a browser: the image is correct and the toast shows `Copied · X → Y`.
5. [ ] Pasting into Slack (or a GitHub comment) works.
6. [ ] Paste a capture into apps that may only read TIFF: Preview "New from Clipboard", TextEdit, and Pages or Keynote. Expected: PNG-capable apps paste the image; TIFF-only apps may not (the app writes PNG pasteboard data only) — record which.
7. [ ] `⌃⌥⌘4`: the screen dims with a crosshair. Drag a rectangle: its size is shown. On release the selection STAYS and a toolbar with Copy, Save and Cancel icons appears next to it; press `Enter`: it is copied and the toast shows `Copied · X → Y`. The overlay is NOT in the pasted image.
8. [ ] In the overlay press Space: the window under the cursor gets an accent border; click it: that window is selected and the toolbar appears (it does not copy by itself). Press `Enter`: the window is copied (it includes anything overlapping it, no shadow). Space again (before selecting) returns to area mode.
9. [ ] In window mode, press the mouse on one window, drag, and release over a different window. Expected: the window under the cursor at release is selected (the highlight follows the cursor while dragging), not the one under the cursor at press time.
10. [ ] In window mode, click on the empty desktop (no window). Expected: nothing is selected and no toolbar appears, and Esc still closes the overlay.
11. [ ] Hold the Space key down in the overlay. Expected: the mode toggles exactly once (no flicker from key auto-repeat); release and press again to toggle back.
12. [ ] In area mode start dragging a rectangle, press Space mid-drag, then release the mouse. Expected: nothing is selected, the clipboard is unchanged, and the overlay stays open (Esc still closes it).
13. [ ] Retina: a pasted 100 × 100 point selection is 200 × 200 pixels.
14. [ ] (2 displays) Put the second display to the LEFT of the primary, then ABOVE it. Capture on each display: the pasted area matches what was selected. Window mode works on the second display.
15. [ ] Big capture: capture a full 5K/6K display or a very detailed screen. Note the time from hotkey to toast. Pressing the hotkey again during that time does nothing and does not crash.
16. [ ] Drag a large area on a 5K/6K display (or the largest you have). Expected: dragging stays smooth; record any lag.
17. [ ] Select an area and click **Save** (or press `⌘S`). Expected: a file appears in the save folder (the default folder `~/Pictures/Optimos`) named `Optimos YYYY-MM-DD at HH.MM.SS.png` and the toast reads `Saved to Optimos · <file> · X → Y` (the toast shows the folder's name: `Optimos` for the default, the chosen folder's own name for a custom one); two saves in the same second get different names.

## Confirm toolbar
18. [ ] The toolbar appears below the selection at its right edge.
19. [ ] A selection near the bottom of the screen puts the toolbar ABOVE it.
20. [ ] A full-screen-size selection puts the toolbar inside its bottom-right corner.
21. [ ] Selections at the far left and far right keep the toolbar fully on screen.
22. [ ] (2 displays) The toolbar appears on the display where you selected.
23. [ ] Hovering each icon shows its tooltip, and clicking Copy, Save and Cancel each work.
24. [ ] `Enter` and `⌘C` copy, `⌘S` saves, `Esc` cancels. Before a selection exists, `Enter`, `⌘C` and `⌘S` do nothing; `Esc` closes the overlay.
25. [ ] With the toolbar showing, Space does nothing.
26. [ ] With the toolbar showing, dragging a new rectangle outside it discards the old selection and toolbar, and (2 displays) starting a selection on the other display removes the first display's toolbar.
27. [ ] With the toolbar showing, right-click, pressing `⌃⌥⌘4` again and Cmd-Tab each dismiss the overlay with nothing copied.
28. [ ] `Enter` and `Esc` work immediately after releasing the mouse WITHOUT clicking anywhere (the toolbar buttons must not take keyboard focus).
29. [ ] Click the toolbar's padding between or around the three icons (not on an icon). Expect the selection and the toolbar to survive, and in window mode the selection does not change to another window (Enter still copies the originally chosen region).
30. [ ] (2 displays) With a selection confirmed on one display, move the pointer onto the OTHER display and press `Enter`, `⌘C` or `⌘S`. Expect Enter, `⌘C` and `⌘S` to work wherever the pointer is while a selection is confirmed (same result as with the pointer on the selection's display), and Esc still cancels. Also start a new selection on the other display and confirm it works and its keys work.

## Save location
31. [ ] The menu shows `Saving to: ~/Pictures/Optimos`.
32. [ ] **Save Location…** opens a folder picker in front of other windows; choose another folder: the menu updates, the next Save writes there, and after quitting and relaunching the app the choice is still in place.
33. [ ] Cancelling the picker changes nothing.
34. [ ] **Show Last Screenshot in Finder** is disabled before the first save, reveals the file after a save, and is disabled again after you delete or move that file.
35. [ ] This applies to a custom folder only (the default `~/Pictures/Optimos` is auto-created). Create a NEW empty test folder for this check (never use a folder with your own files), choose it with Save Location…, then make it fail: delete that empty folder, or make it read-only with `chmod a-w <folder>`. Press Save: a toast says `Save failed: …` and tells you to choose another folder, and no file is written anywhere else. Restore afterwards: `mkdir` the folder again, or `chmod u+w <folder>`.
36. [ ] Choose a NEW empty test folder you created for this check (for example `~/Desktop/optimos-test-folder`), quit the app, rename that folder (for example to `optimos-test-folder-gone`), relaunch the app. Record what the menu's "Saving to:" line shows (expected: it still shows the remembered path, NOT the default). Capture an area and press Save: expected a toast `Save failed: …` telling you to choose another folder, and NO file written anywhere else (check `~/Pictures/Optimos` has no new file). Restore afterwards by renaming the folder back, or choose a different folder with Save Location….
37. [ ] With no custom folder chosen (or after choosing `~/Pictures/Optimos` again), press Save once: the folder `~/Pictures/Optimos` is created if it did not exist and the file is written there.
38. [ ] The Copy flow and the `⌃⌥⌘3` instant copy are unchanged.

## Focus and dismissal
39. [ ] Dismissing the overlay: Esc, right-click, pressing `⌃⌥⌘4` again, and Cmd-Tab each close it with nothing copied. The overlay can never get stuck.
40. [ ] Open the overlay and press Esc immediately, WITHOUT clicking first. Expected: the overlay closes.
41. [ ] While the overlay is open, switch Space (Ctrl-arrow or Mission Control) and Cmd-Tab to another app. Expected: the overlay closes, and the app does NOT yank you back to the old Space or app afterwards.
42. [ ] After a capture or an Esc cancel, keep typing without clicking anywhere. Expected: keystrokes go to the app you were using before (focus returns to it).

## Edge cases
43. [ ] A full-screen app (Safari or Xcode in full screen): the overlay appears over it and captures correctly.
44. [ ] A second Space: the overlay appears on the current Space.
45. [ ] Another app already owns `⌃⌥⌘4` (for example set it in System Settings > Keyboard): the menu shows a warning line for that shortcut and the other shortcuts still work.
46. [ ] Missing tool: rename oxipng with `mv "$(brew --prefix)/bin/oxipng" "$(brew --prefix)/bin/oxipng.off"`, then capture. Expected: the unoptimized screenshot is still copied and the toast says `not optimized`. Restore it immediately, before continuing: `mv "$(brew --prefix)/bin/oxipng.off" "$(brew --prefix)/bin/oxipng"`, then run `which oxipng` (expected: prints the path).
47. [ ] Trigger a long failure message with the save-failure case (item 35 or 36). Expected: the toast wraps to up to three lines and is fully visible, not cut off at the bottom.
48. [ ] Quit from the menu: the app exits and the hotkeys stop working.

## Annotations
49. [ ] Select an area. The toolbar shows five tools, six colours, three sizes, then Copy / Save / Cancel, and fits on screen (also for a selection near a screen edge).
50. [ ] Pick Rectangle (or press `R`) and drag inside the selection: a red rectangle appears. Same for Arrow (`A`): a line with an arrow head.
51. [ ] Pick Text (`T`), click in the selection and type. Expected: text appears with a caret; `Return` adds a new line and does NOT copy; the first `Esc` finishes the text; a second `Esc` closes the overlay.
52. [ ] Pick Pixelate (`P`) and drag over text. Expected: the area becomes large blocks and the text under it cannot be read; a rectangle drawn over it stays sharp.
53. [ ] Pick Select (`V`), click an annotation (the edge of a rectangle, the line of an arrow, the text, the inside of a pixelate area), drag it, press `Delete`. Expected: it is selected with a dashed outline, moves, and is removed.
54. [ ] `⌘Z` undoes the last step (add, move, delete, recolour) and `⇧⌘Z` redoes it. A whole drag-move is one step.
55. [ ] With an annotation selected, click another colour or size. Expected: that annotation changes; the next one you draw uses the new choice.
56. [ ] Press Copy, then paste into an app, and do the same with Save. Expected: the image contains the annotations exactly as shown, including pixelation, at full Retina sharpness.
57. [ ] With annotations drawn, press outside the selection. Expected: nothing happens (the work is kept). With no annotations, pressing outside still starts a new selection. `Esc`, right-click and Cmd-Tab still close the overlay.

## Save panel
58. [ ] Select an area and press Save (button or `⌘S`). Expected: a save panel opens in front, pre-filled with a timestamped name; choosing a folder saves there and the toast names it. Cancelling the panel saves nothing and shows no error.
59. [ ] Untick **Ask Where to Save Each Time** in the menu. Expected: Save now writes straight into the folder named on the "Autosaving to:" line with no panel. Tick it again and the panel returns.

## More annotation tools
60. [ ] The toolbar's top row shows ten tools: select, rectangle, circle, arrow, line, text, highlight, numbered marker, pixelate, blur (hover for names and keys V R O A L T H N P B). It still fits the screen and nothing overlaps.
61. [ ] Circle (`O`) draws an ellipse in the dragged box; Line (`L`) a plain line; both can be selected, moved, resized with handles, recoloured and deleted.
62. [ ] Highlight (`H`) with yellow tints a band while the text underneath stays readable. A highlight drawn over a pixelate or blur area stays on top of it.
63. [ ] Numbered marker (`N`): each click places the next number (1, 2, 3, ...) in the chosen colour and size; digits are readable on every colour including yellow and white. Markers move and delete but have no handles; undo removes the last one.
64. [ ] Blur (`B`) over text: the area becomes smooth and the text cannot be read, even at the largest size. Compare with Pixelate (`P`): both hide the text equally.
65. [ ] Copy and Save include every new tool exactly as shown, at full Retina resolution, and in the right place after the selection has been resized or moved.
66. [ ] There is no separate crop tool: resizing the selection with its handles crops. (This is by design.)

