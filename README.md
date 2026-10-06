# OptimosApp — Capture. Optimize. Convert.

This repository currently holds `OptimosCore` (image pipeline) and the `optimos` CLI.
See `PRD.md` and `docs/superpowers/` for the product definition, specs and plans.

## Build prerequisites (macOS 14+, Apple Silicon)

    brew install webp oxipng pngquant libjpeg-turbo

## Build and test

    swift build
    swift test

## CLI

    swift run optimos optimize shot.png
    swift run optimos optimize shot.png --preset Website -o out/
    swift run optimos convert shot.png --to webp --quality 82 --max-width 1600
    swift run optimos presets list

## OptimosApp (menu-bar app)

A menu-bar app that captures the screen and puts an optimized PNG on the clipboard.

Prerequisites (macOS 14+, Apple Silicon): `brew install xcodegen webp oxipng pngquant libjpeg-turbo`.
For Screen Recording permission to survive rebuilds, copy `App/Config/Local.xcconfig.example` to
`App/Config/Local.xcconfig` and set your team id (a free Apple ID "Apple Development" certificate is enough).

    App/scripts/test.sh     # unit tests (ad-hoc signed, no certificate needed)
    App/scripts/run.sh      # build and launch the app

Default shortcuts (rebinding comes in a later release):

| Shortcut | Action |
|---|---|
| `⌃⌥⌘4` | Capture an area, or press Space to pick a window |
| `⌃⌥⌘3` | Capture the screen under the mouse |
| `⌃⌥⌘5` | Capture an area and save it to `~/Pictures/Optimos/` |

These avoid macOS's own `⌘⇧3/4/5` so they work on first launch. Manual verification steps are in
`docs/manual-checks/capture-app.md`.
