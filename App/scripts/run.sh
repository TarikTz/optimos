#!/bin/bash
# Builds the app (using App/Config/Local.xcconfig if present) and launches it.
# The full build log is App/build/last-build.log. Exits with xcodebuild's status.
set -uo pipefail
cd "$(dirname "$0")/.."
xcodegen generate --quiet || exit 1
mkdir -p build
xcodebuild build -project OptimosApp.xcodeproj -scheme OptimosApp -configuration Debug \
  -destination 'platform=macOS,arch=arm64' -derivedDataPath build -allowProvisioningUpdates \
  > build/last-build.log 2>&1
status=$?
grep -E "error:|warning:|\*\* BUILD" build/last-build.log || true
[ $status -eq 0 ] || exit $status
pkill -x OptimosApp || true
open build/Build/Products/Debug/OptimosApp.app
