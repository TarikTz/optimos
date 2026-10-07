# Packaged build — manual checks

Run `App/scripts/package.sh`, then use the DMG on a Mac that has NO Homebrew tools if you can (or temporarily rename `/opt/homebrew`'s `oxipng`, `pngquant` and `jpegtran`).

1. [ ] The script finishes with "Done" and a SHA-256, and the DMG mounts showing OptimosApp, an Applications shortcut and "READ ME FIRST.txt".
2. [ ] Drag the app to Applications. Opening it shows the Gatekeeper warning; the steps in the READ ME (Terminal command, or Privacy & Security > Open Anyway) get it open.
3. [ ] The menu-bar icon appears. Grant Screen Recording, restart the app, capture an area: copy and save work.
4. [ ] Optimize Images: drop a PNG and a JPEG at Balanced. Both shrink (PNG uses pngquant, JPEG uses jpegtran), with no "required tool … was not found" error.
5. [ ] About shows version 0.1.0; `Contents/Resources/licenses` in the app contains the license files and SOURCE-OFFER.txt.
6. [ ] Another person on macOS 26 follows only the READ ME and gets it running.
