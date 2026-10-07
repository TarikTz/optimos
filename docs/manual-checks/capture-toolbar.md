# Capture toolbar: format, max size and Share — manual checks

1. [ ] Select an area. The toolbar has two rows: annotation tools and pickers on top; Format, Max size, Share, Copy, Save, Cancel below. It fits on screen, also for a selection near an edge or the bottom of the display.
2. [ ] The Format and Max size menus start at your Preferences > Captures values. Change them in the toolbar, finish, then capture again: they are back at the Preferences values.
3. [ ] Choose WebP and "Fit 800 px", press Save: the save panel suggests a `.webp` name, and the saved file is WebP with a longest side of 800 px (or smaller if the selection was smaller; it is never enlarged).
4. [ ] Press Copy with WebP and a max size chosen: pasting into an app gives an image (PNG) at the reduced size.
5. [ ] With annotations drawn, choose "Fit 800 px" and Save: the arrows, text and hidden areas are in proportion in the result.
6. [ ] Press Share. Expected: the overlay closes and the macOS share menu opens near where the toolbar was, listing AirDrop, Messages, Mail and so on. Pick Messages or Mail: the attachment is the image file in the chosen format with a sensible name.
7. [ ] Press Share and dismiss the menu (click elsewhere or Esc): nothing is saved or copied, the app stays quiet and the overlay does not come back.
8. [ ] Menu bar menu works as before after sharing; a new capture right after works.
9. [ ] Quit and relaunch: nothing is left in `$TMPDIR/OptimosShare`.
10. [ ] Enter, `⌘C`, `⌘S`, Esc, the annotation shortcuts and the Cmd-Tab / Space-change exits still behave as before; clicking a Format or Max size menu does not move keyboard focus (Enter still copies afterwards).
