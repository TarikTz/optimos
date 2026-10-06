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
# Wait (up to ~5s) for the old process to exit so `open` starts a fresh instance, not the dying one.
for _ in $(seq 50); do
  pgrep -x OptimosApp > /dev/null || break
  sleep 0.1
done
open build/Build/Products/Debug/OptimosApp.app
