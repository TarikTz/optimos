# Changelog

## 0.2.1 (unreleased)
- Release builds use the hardened runtime, which stops other programs from injecting code into the app.
- Images that declare more than 100 megapixels or 30000 pixels on a side are refused before decoding.
- Bundled tools are used exclusively inside the app, run with a clean environment, and stop after 2 minutes or when cancelled.
- Optimizing a symlinked file updates the real file; shared screenshots are removed after 15 minutes; no orphan backup after closing the window.
- Stable signing certificate (`App/scripts/make-signing-cert.sh`) so the Screen Recording permission survives rebuilds and updates.
- Guided Screen Recording permission with an offer to restart the app.
- Website: faster first paint (no JavaScript animation library).

## 0.2.0
- HEIC, TIFF and BMP input in the optimizer (converted to PNG, JPEG or WebP).
- Drag handles to resize and move the capture selection, and to resize annotations.
- New annotation tools: circle, line, highlight, numbered markers and blur.
- Landing page and packaging script.

## 0.1.0
- Menu-bar capture (area, window, screen) with copy and save, annotations (rectangle, arrow, text, pixelate) with undo and redo.
- Optimize Images window: lossless, balanced or smallest, convert to PNG, JPEG or WebP, resize, undo.
- Preferences: launch at login, save location, rebindable shortcuts, optimizer and capture defaults.
- Per-capture format and max size, and Share, on the capture toolbar.
