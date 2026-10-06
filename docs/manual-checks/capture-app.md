# OptimosApp manual checks

Run these on a real Mac after `App/scripts/run.sh`. Items marked (2 displays) need a second monitor.
Tick each item; note the macOS version and displays used at the top.

macOS / displays used:

Known limitations (see spec): window capture is a crop (overlapping windows included, no shadow); selection stays within one display; hotkeys are not rebindable yet.

Setup: copy `App/Config/Local.xcconfig.example` to `App/Config/Local.xcconfig` and set your team id so
Screen Recording permission survives rebuilds. Install the tools: `brew install xcodegen webp oxipng pngquant libjpeg-turbo`.

## Permission and menu
1. [ ] First launch with no Screen Recording permission: press `⌃⌥⌘3`. A toast asks you to allow Screen Recording and restart; the system prompt appears; nothing crashes.
2. [ ] Grant permission in System Settings, quit and relaunch. The menu shows "Screen Recording: allowed".
3. [ ] The menu-bar icon is visible, there is no Dock icon, and the menu lists the three capture actions with their shortcuts and Quit.

## Capture
4. [ ] `⌃⌥⌘3`: the screen under the mouse is captured instantly. Paste into Preview or a browser: the image is correct and the toast shows `Copied · X → Y`.
5. [ ] Pasting into Slack (or a GitHub comment) works.
6. [ ] Paste a capture into apps that may only read TIFF: Preview "New from Clipboard", TextEdit, and Pages or Keynote. Expected: PNG-capable apps paste the image; TIFF-only apps may not (the app writes PNG pasteboard data only) — record which.
7. [ ] `⌃⌥⌘4`: the screen dims with a crosshair. Drag a rectangle: its size is shown; release copies it. The overlay is NOT in the pasted image.
8. [ ] In the overlay press Space: the window under the cursor gets an accent border; click it: that window is copied (it includes anything overlapping it, no shadow). Space again returns to area mode.
9. [ ] In window mode, press the mouse on one window, drag, and release over another window. Expected: a single window is captured, or nothing; record which window (known: may capture the window under the cursor at press time).
10. [ ] In window mode, click on the empty desktop (no window). Expected: nothing happens, and Esc still closes the overlay.
11. [ ] Hold the Space key down in the overlay. Expected: the mode does not flicker repeatedly (known: auto-repeat flips area/window mode); record what you see.
12. [ ] Retina: a pasted 100 × 100 point selection is 200 × 200 pixels.
13. [ ] (2 displays) Put the second display to the LEFT of the primary, then ABOVE it. Capture on each display: the pasted area matches what was selected. Window mode works on the second display.
14. [ ] Big capture: capture a full 5K/6K display or a very detailed screen. Note the time from hotkey to toast. Pressing the hotkey again during that time does nothing and does not crash.
15. [ ] Drag a large area on a 5K/6K display (or the largest you have). Expected: dragging stays smooth; record any lag.
16. [ ] `⌃⌥⌘5`: select an area; a file appears in `~/Pictures/Optimos/` named `Optimos YYYY-MM-DD at HH.MM.SS.png` and the toast shows the name. Two captures in the same second get different names.

## Focus and dismissal
17. [ ] Dismissing the overlay: Esc, right-click, pressing `⌃⌥⌘4` again, and Cmd-Tab each close it with nothing copied. The overlay can never get stuck.
18. [ ] Open the overlay and press Esc immediately, WITHOUT clicking first. Expected: the overlay closes.
19. [ ] While the overlay is open, switch Space (Ctrl-arrow or Mission Control) and Cmd-Tab to another app. Expected: the overlay closes, and the app does NOT yank you back to the old Space or app afterwards.
20. [ ] After a capture or an Esc cancel, keep typing without clicking anywhere. Expected: keystrokes go to the app you were using before (focus returns to it).

## Edge cases
21. [ ] A full-screen app (Safari or Xcode in full screen): the overlay appears over it and captures correctly.
22. [ ] A second Space: the overlay appears on the current Space.
23. [ ] Another app already owns `⌃⌥⌘4` (for example set it in System Settings > Keyboard): the menu shows a warning line for that shortcut and the other shortcuts still work.
24. [ ] Missing tool: rename oxipng with `mv "$(brew --prefix)/bin/oxipng" "$(brew --prefix)/bin/oxipng.off"`, then capture. Expected: the unoptimized screenshot is still copied and the toast says `not optimized`. Restore it immediately, before continuing: `mv "$(brew --prefix)/bin/oxipng.off" "$(brew --prefix)/bin/oxipng"`, then run `which oxipng` (expected: prints the path).
25. [ ] Quit from the menu: the app exits and the hotkeys stop working.
