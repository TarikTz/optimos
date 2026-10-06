#!/bin/bash
# Generates the project and runs the unit tests (ad-hoc signed, no certificate needed).
# Prints a summary; the full log is App/build/last-test.log. Exits with xcodebuild's status.
set -uo pipefail
cd "$(dirname "$0")/.."
xcodegen generate --quiet || exit 1
mkdir -p build
xcodebuild test -project OptimosApp.xcodeproj -scheme OptimosApp \
  -destination 'platform=macOS,arch=arm64' -derivedDataPath build "$@" > build/last-test.log 2>&1
status=$?
grep -E "error:|warning:|Test run with|✘|\*\* TEST" build/last-test.log || true
echo "(full log: App/build/last-test.log)"
exit $status
