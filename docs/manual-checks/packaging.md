# Packaged build — manual checks

Run `App/scripts/package.sh`, then use the DMG on a Mac that has NO Homebrew tools if you can (or temporarily rename `/opt/homebrew`'s `oxipng`, `pngquant` and `jpegtran`).

1. [ ] The script finishes with "Done" and a SHA-256, and the DMG mounts showing OptimosApp, an Applications shortcut and "READ ME FIRST.txt".
2. [ ] Drag the app to Applications. Opening it shows the Gatekeeper warning; the steps in the READ ME (Terminal command, or Privacy & Security > Open Anyway) get it open.
3. [ ] The menu-bar icon appears. Grant Screen Recording, restart the app, capture an area: copy and save work.
4. [ ] Optimize Images: drop a PNG and a JPEG at Balanced. Both shrink (PNG uses pngquant, JPEG uses jpegtran), with no "required tool … was not found" error.
5. [ ] About shows version 0.1.0; `Contents/Resources/licenses` in the app contains the license files and SOURCE-OFFER.txt.
6. [ ] Another person on macOS 26 follows only the READ ME and gets it running.

## Stable signing and the permission flow
7. [ ] `codesign -dr - /Applications/OptimosApp.app` prints `certificate leaf = H"..."` (not `cdhash`), and the same hash for every build you make with `run.sh` or `package.sh`.
8. [ ] Once: remove old OptimosApp entries from System Settings > Privacy & Security > Screen & System Audio Recording (or run `tccutil reset ScreenCapture app.optimos.OptimosApp`). Press a capture shortcut: the system prompt appears and Settings opens on the right pane.
9. [ ] Turn OptimosApp on there. Within a couple of seconds OptimosApp shows "Screen Recording is on" with Restart Now / Later; Restart Now relaunches it and captures work.
10. [ ] Rebuild with `run.sh` (or install a newer DMG made on this Mac) and capture again: no new permission prompt, no restart needed.
11. [ ] The menu's "Allow Screen Recording…" item starts the same walkthrough while access is off.

