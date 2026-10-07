# Security policy

## Reporting a vulnerability
Please do not open a public issue for a security problem. Use the repository's private vulnerability reporting ("Report a vulnerability" under the Security tab) or contact the maintainer directly, with the steps to reproduce. You will get a reply as soon as possible, and a fix is released before details are made public.

## What the app does and does not do
- It runs entirely on your Mac. It makes no network connections, has no accounts, and sends no analytics.
- It needs the Screen Recording permission only to capture the screen when you press a capture shortcut.
- It bundles the open-source tools `oxipng`, `pngquant` and `jpegtran`, and runs them as separate processes with a clean environment, a timeout and no network use.
- Images are refused before decoding when they declare more than 100 megapixels or 30000 pixels on a side.
- Release builds use the hardened runtime.

## Known limits
Builds are signed with a self-signed certificate and are not notarized by Apple, so macOS asks you to approve the first launch (see `docs/INSTALL.md`). A review of the code and the fixes made are in `docs/security-review.md`.
