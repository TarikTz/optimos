# Contributing to OptimosApp

Thanks for helping. A few notes to make a change easy to review.

## Set up
Requirements: a Mac with Apple silicon, macOS 14 or later to build (the packaged app needs macOS 26), Xcode 16 or later, [XcodeGen](https://github.com/yonaskolb/XcodeGen) and Homebrew in its default `/opt/homebrew` location.

    brew install webp oxipng pngquant jpeg-turbo xcodegen
    swift test                 # OptimosCore and the optimos command-line tool
    cd App && ./scripts/test.sh   # the app's unit tests (generates the Xcode project first)

`App/scripts/run.sh` builds and launches the app. The Screen Recording permission survives rebuilds only if you sign with a stable certificate: see "Signing and the Screen Recording permission" in the README.

## Project layout
- `Sources/OptimosCore`: the image pipeline (decode, resize, convert, optimize). No UI. Most logic and tests live here.
- `Sources/optimos`: the command-line front end.
- `App/`: the menu-bar app (AppKit and SwiftUI). `project.yml` is the XcodeGen spec; the `.xcodeproj` is generated and git-ignored.
- `website/`: the static landing page (Next.js).
- `docs/manual-checks/`: checklists for the things unit tests cannot cover (overlay, permissions, install).

## Guidelines
- Keep tests to pure logic and rendering; describe UI changes in the manual checklists.
- Swift 6 strict concurrency is on. Match the style of the surrounding code.
- Never weaken the safety rules: images are processed locally, nothing is uploaded, a file is only replaced when the result is smaller, originals can be undone, and size limits apply before decoding.
- Run both test suites before opening a pull request, and say which manual checks you ran.
- One change per pull request, with a short description of why.
