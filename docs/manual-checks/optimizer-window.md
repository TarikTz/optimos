# Optimizer window — manual checks

Open **Optimize Images…** from the menu-bar menu. Use copies of real images, not your only originals.

## Basics
1. [ ] The window opens in front, shows the drop prompt and the bottom bar (`+`, Level, Format, Max size, Custom px, Undo, Again). Opening it again while it is open brings the same window forward.
2. [ ] Drop a few PNG and JPEG files. Expected: each row shows a spinner, then `old → new (−N%)`. The files on disk are smaller and open normally.
3. [ ] Drop the same files again. Expected: they are not added twice.
4. [ ] Drop a folder with images in subfolders plus a `.txt` file and a hidden image. Expected: only the visible supported images are added.
5. [ ] Drop a `.txt` or `.heic` file by itself. Expected: that row says "unsupported or unrecognised image format" in red; other rows are unaffected.
6. [ ] The `+` button opens a panel where files and folders can be chosen; chosen items are processed.

## Levels, format and size
7. [ ] Set Level to Smallest and press Again on a photo. Expected: the result is smaller than at Balanced, still looks acceptable, and is not re-compressed on top of the earlier result.
8. [ ] Level Lossless: pixels are identical (compare in Preview), the file may stay "Already optimal".
9. [ ] Format WebP, press Again. Expected: new `.webp` files appear next to the originals, the originals are untouched, and the rows show the new file name.
10. [ ] Convert two files with the same base name (`a.png`, `a.jpg`) to WebP. Expected: `a.webp` and `a 2.webp`; nothing is overwritten.
11. [ ] Max size 800 px: a big image is shrunk to a longest side of 800 px; an image smaller than 800 px keeps its size. Type `1500` in Custom px and press Return: the Max size menu shows `Fit 1500 px`.
12. [ ] A transparent PNG converted to JPEG gets a white background.

## Safety
13. [ ] Undo restores every original byte-for-byte (compare with your copies) and removes converted files created in this session. Rows show "Restored".
14. [ ] Again restores the originals first and then re-runs with the new settings.
15. [ ] Close the window, then open it again. Expected: an empty list. The earlier files stay as they were (no Undo any more).
16. [ ] Put a file in a read-only folder and drop it. Expected: the row shows an error, other rows continue.
17. [ ] Quit and relaunch: Level, Format and Max size are remembered.

## Finding the window again
18. [ ] Press `⌃⌥⌘O` from any app. Expected: the optimizer window opens in front. Press it again while the window is hidden behind other apps: it comes to the front.
19. [ ] With the window open, click another app so the window is hidden. Expected: OptimosApp shows a Dock icon and appears in Cmd-Tab; Cmd-Tab (or the Dock icon) brings the window back.
20. [ ] Close the window. Expected: the Dock icon and Cmd-Tab entry disappear again; the menu-bar icon and capture shortcuts still work.
21. [ ] With the window open, use `⌃⌥⌘4`: the capture overlay works as before.

