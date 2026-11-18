#!/bin/bash
# Builds a Release OptimosApp.app, bundles the optimizer tools (and builds optimos-quant with cargo) and their libraries into it, ad-hoc signs
# everything, and writes App/dist/OptimosApp-<version>.dmg. Needs the Homebrew tools from the README
# and macOS 26+ on the machine that runs the result (the bundled jpegtran is built for macOS 26).
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION=$(sed -n 's/.*MARKETING_VERSION: "\(.*\)".*/\1/p' project.yml | head -1)
BREW=$(brew --prefix)
APP=build/release/Build/Products/Release/OptimosApp.app
DIST=dist
STAGING=build/dmg
RES="$APP/Contents/Resources"
# Same signing identity as the Xcode build (Config/Local.xcconfig), or ad hoc ("-") without one.
SIGN_ID=${SIGN_IDENTITY:-$(sed -n 's/^CODE_SIGN_IDENTITY *= *//p' Config/Local.xcconfig 2> /dev/null | head -1)}
SIGN_ID=${SIGN_ID:--}

echo "==> Building OptimosApp $VERSION (Release)"
xcodegen generate --quiet
xcodebuild build -project OptimosApp.xcodeproj -scheme OptimosApp -configuration Release \
  -destination 'platform=macOS,arch=arm64' -derivedDataPath build/release > build/last-package-build.log 2>&1 \
  || { tail -30 build/last-package-build.log; exit 1; }

echo "==> Bundling tools and libraries"
rm -rf "$RES/tools" "$RES/lib" "$RES/licenses"
mkdir -p "$RES/tools" "$RES/lib" "$RES/licenses"

# Copies every Homebrew library $1 depends on into Resources/lib and points $1 at the copy.
# $2 is the path prefix $1 uses to reach that folder.
bundle_deps() {
  local file=$1 prefix=$2 dep base
  otool -L "$file" | tail -n +2 | awk '{print $1}' | { grep -E '^(/opt/homebrew|/usr/local)' || true; } | while read -r dep; do
    base=$(basename "$dep")
    if [ ! -f "$RES/lib/$base" ]; then
      cp -L "$dep" "$RES/lib/$base"
      chmod u+w "$RES/lib/$base"
      install_name_tool -id "@loader_path/$base" "$RES/lib/$base"
      bundle_deps "$RES/lib/$base" "@loader_path"
    fi
    install_name_tool -change "$dep" "$prefix/$base" "$file"
  done
}

copy_tool() {
  local src
  src=$(readlink -f "$1")
  cp "$src" "$RES/tools/$(basename "$1")"
  chmod u+w "$RES/tools/$(basename "$1")"
  bundle_deps "$RES/tools/$(basename "$1")" "@loader_path/../lib"
}
copy_tool "$BREW/bin/oxipng"

# optimos-quant is our own MIT-licensed PNG quantizer (Tools/optimos-quant), built here from source for the
# oldest macOS the app targets. It links no Homebrew libraries, so it needs no bundling of dependencies.
echo "==> Building optimos-quant"
( cd ../Tools/optimos-quant && MACOSX_DEPLOYMENT_TARGET=14.0 cargo build --release --locked --quiet )
cp ../Tools/optimos-quant/target/release/optimos-quant "$RES/tools/optimos-quant"
chmod u+w "$RES/tools/optimos-quant"
copy_tool "$BREW/opt/jpeg-turbo/bin/jpegtran"
# jpegtran reaches its library through an @rpath entry; make sure the library is bundled too.
cp -L "$BREW/opt/jpeg-turbo/lib/libjpeg.8.dylib" "$RES/lib/libjpeg.8.dylib"
chmod u+w "$RES/lib/libjpeg.8.dylib"
install_name_tool -id "@rpath/libjpeg.8.dylib" "$RES/lib/libjpeg.8.dylib"

echo "==> Checking that nothing points at Homebrew any more"
if otool -L "$RES"/tools/* "$RES"/lib/* | grep -E '/opt/homebrew|/usr/local'; then
  echo "error: a bundled file still references Homebrew" >&2
  exit 1
fi

echo "==> Licenses"
cp "$BREW/opt/oxipng/LICENSE" "$RES/licenses/oxipng-LICENSE"
cp ../Tools/optimos-quant/THIRD-PARTY-LICENSES.txt "$RES/licenses/optimos-quant-THIRD-PARTY-LICENSES.txt"
cp "$BREW/opt/jpeg-turbo/LICENSE.md" "$RES/licenses/libjpeg-turbo-LICENSE.md"
cp "$BREW/opt/little-cms2/LICENSE" "$RES/licenses/lcms2-LICENSE"
cp "$BREW/opt/libpng/LICENSE" "$RES/licenses/libpng-LICENSE"
cp ../LICENSE "$RES/licenses/OptimosApp-MIT-LICENSE"
cp ../THIRD-PARTY-NOTICES.md "$RES/licenses/THIRD-PARTY-NOTICES.md"

echo "==> Signing with: $SIGN_ID"
for f in "$RES"/lib/* "$RES"/tools/*; do codesign --force --sign "$SIGN_ID" "$f" > /dev/null 2>&1; done
# Hardened runtime stops other programs from injecting code into the app (DYLD_INSERT_LIBRARIES),
# which would otherwise inherit its Screen Recording permission.
codesign --force --deep -o runtime --sign "$SIGN_ID" "$APP" > /dev/null 2>&1
codesign --verify --deep --strict "$APP"

echo "==> Smoke test: the bundled tools run with no Homebrew on the PATH"
TMP=$(mktemp -d)
printf 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==' | base64 -d > "$TMP/t.png"
sips -s format jpeg "$TMP/t.png" --out "$TMP/t.jpg" > /dev/null
env -i "$RES/tools/oxipng" - --stdout < "$TMP/t.png" > "$TMP/o1.png"
# The 1-pixel test image cannot get smaller, so "not smaller" (98) counts as a working tool.
env -i "$RES/tools/optimos-quant" --quality=0-100 - < "$TMP/t.png" > "$TMP/o2.png" && Q=0 || Q=$?
env -i "$RES/tools/jpegtran" -optimize < "$TMP/t.jpg" > "$TMP/o3.jpg"
[ "$(head -c 4 "$TMP/o1.png" | xxd -p)" = "89504e47" ] || { echo "error: bundled oxipng failed" >&2; exit 1; }
{ [ "$Q" = 98 ] || [ "$(head -c 4 "$TMP/o2.png" | xxd -p)" = "89504e47" ]; } || { echo "error: bundled optimos-quant failed" >&2; exit 1; }
[ "$(head -c 2 "$TMP/o3.jpg" | xxd -p)" = "ffd8" ] || { echo "error: bundled jpegtran failed" >&2; exit 1; }
rm -rf "$TMP"

echo "==> Building the disk image"
rm -rf "$STAGING" && mkdir -p "$STAGING" "$DIST"
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"
cp ../docs/INSTALL.md "$STAGING/READ ME FIRST.txt"
DMG="$DIST/OptimosApp-$VERSION.dmg"
rm -f "$DMG"
hdiutil create -quiet -volname "OptimosApp $VERSION" -srcfolder "$STAGING" -ov -format UDZO "$DMG"
# The same file under a fixed name, so the website can link to .../releases/latest/download/OptimosApp.dmg
cp "$DMG" "$DIST/OptimosApp.dmg"
echo "==> Done: App/$DMG (and App/$DIST/OptimosApp.dmg for the GitHub release)"
shasum -a 256 "$DMG"
