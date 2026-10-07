# Code and security review, 2026-10-07 (version 0.2.1)

Scope: the Swift app, `OptimosCore`, the CLI, and the build, signing and deploy scripts. Findings were checked by running them where possible, and every fix below has a test or a manual check.

| # | Severity | Finding | Status |
|---|---|---|---|
| 1 | Medium | No hardened runtime: another program could launch the app with `DYLD_INSERT_LIBRARIES` and borrow its Screen Recording permission (reproduced). | Fixed: Release builds and `package.sh` use the hardened runtime; the same test is now blocked on the packaged app. |
| 2 | Medium | No image-size limit: a 49 KB PNG declaring 20000×20000 pixels used 1.5 GB (reproduced). | Fixed: `ImageLimits` (100 megapixels, 30000 px per side) is checked from the header before any decode, for PNG (IHDR read directly), WebP, and other formats; the same file is now refused in 0.4 s using 8 MB. |
| 3 | Low-medium | The app honoured `OPTIMOS_TOOLS_DIR` and `/usr/local/bin`, so a swapped tool would inherit the app's permissions. | Fixed: inside the app only the bundled tools are used; the variable is for the CLI only; `/usr/local/bin` removed; tools run with a clean environment (no inherited `DYLD_*`). |
| 4 | Low | Shared screenshots stayed in the temp folder until the next launch. | Fixed: removed 15 minutes after sharing (and at launch). |
| 5 | Info | `make-signing-cert.sh` passes a one-time password for a temporary file on the command line (`security import -P`). | Accepted: unavoidable with that tool, short-lived, protects a file deleted immediately. |
| 6 | Medium | A hung `pngquant`/`oxipng` could not be stopped; cancelling did nothing. | Fixed: 120 s timeout, and cancelling the task terminates the tool. |
| 7 | Low | Closing the optimizer window mid-run could leave an orphan backup folder. | Fixed: `BackupStore` refuses new backups after it is closed (the file is then left untouched). |
| 8 | Low | Transparency was detected by copying the whole image to RGBA. | Fixed: alpha-only bitmap (a quarter of the memory, no copy). |
| 9 | Low | The max-size presets were defined in three places. | Fixed: `MaxSizePresets`. |
| 10 | Low | `SelectionOverlay.swift` held selection, annotation editing, handles and text. | Fixed: annotation editing moved to `SelectionView+Annotations.swift` (a mechanical split, 683 → 487 + 201 lines). |
| 11 | Low | Optimizing a symlinked file replaced the link with a regular file. | Fixed: the real file is updated and the link stays a link. |

Checked and fine: temp and backup files stay in the per-user temp folder; new files are created without overwriting; the restart command passes its path as an argument; saving only writes to folders the user chose; no network access, logging or tracking; location and other metadata are stripped by default; the website is static with security headers and HTTPS.

Not covered: the app is not notarized and is signed with a self-signed certificate, so users must trust it manually (see `docs/INSTALL.md`). Running the capture overlay and the new limits against real files still needs the manual checks in `docs/manual-checks/`.
