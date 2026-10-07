# Preferences, About and branding — manual checks

Open **Preferences…** from the menu-bar menu (or `⌘,` while the menu is open).

## Window
1. [ ] The window opens in front with five tabs: General, Saving, Shortcuts, Optimizer, Captures. While it is open the app shows in the Dock and Cmd-Tab; closing it removes them (unless the optimizer window is still open).
2. [ ] The menu no longer has "Ask Where to Save…", "Save Location…" or "Saving to…". It has Preferences… and About OptimosApp.

## General and Saving
3. [ ] Toggle **Launch at login** on, check System Settings > General > Login Items lists OptimosApp, toggle it off again. If macOS refuses, the toggle reverts and a red message explains.
4. [ ] Saving: choose "Ask where to save each time", press Save on a capture: the save panel appears. Choose "Save automatically", press Save: no panel, the file lands in the folder shown. **Choose…** changes that folder.

## Shortcuts
5. [ ] Click a shortcut, press a new combination (for example `⌃⌥⌘K`). Expected: it is shown, the menu shows it, and it works immediately.
6. [ ] Record a combination without ⌃, ⌥ or ⌘ (for example just `K`): an inline message says to include one. Record `⌘Q`: refused as used by macOS.
7. [ ] Record the shortcut that another action already uses: refused with "Already used by …".
8. [ ] Record a shortcut that another app or macOS owns (for example one set in System Settings > Keyboard > Shortcuts): "already in use" is shown and the old shortcut keeps working.
9. [ ] Esc while recording cancels and keeps the old shortcut. **Disable** removes a shortcut (shown as "Disabled", menu line shows no shortcut, pressing it does nothing). **Reset** restores the default.
10. [ ] Quit and relaunch: your shortcuts (and disabled ones) are remembered.

## Optimizer and Captures
11. [ ] Change Level/Format/Max size in Preferences, then open Optimize Images: the bar shows the same values; change them in the bar and the Preferences tab shows them after you reopen it.
12. [ ] "Save a copy": optimize a PNG; the original is untouched and `name-optimized.png` appears. Drop it again: `name-optimized 2.png` is created, nothing is overwritten.
13. [ ] Metadata "Keep": a JPEG with GPS or credits keeps them after optimizing (check with Preview > Tools > Show Inspector); with "Remove" they are gone. WebP output never keeps them.
14. [ ] Captures: set Format to WebP and Level to Balanced. Capture and Save: the file is `.webp` (and the save panel offers `.webp`). Copy and paste into an app: it pastes as an image (PNG). Set Format back to PNG, Level Lossless to restore today's behaviour.

## Branding and About
15. [ ] The menu-bar icon is the new glyph (a mountain with four corners and arrows), adapts to light and dark menu bars, and is not blurry.
16. [ ] **About OptimosApp** shows the coloured icon, name, version 0.1.0, "© 2026 Tarik Omercehajic", the slogan and the tool credits with working links.
17. [ ] The Dock icon (while a window is open) and Cmd-Tab show the coloured icon.
