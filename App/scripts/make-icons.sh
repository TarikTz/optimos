#!/bin/bash
# Renders every icon and share image from the SVG sources in App/Resources/Branding.
# Needs Google Chrome (headless, for transparent SVG rendering) and ImageMagick (`brew install imagemagick`).
# Run it after editing a source SVG, then commit the regenerated files.
#
#   optimos-icon-macos.svg  -> App/Sources/OptimosApp/Assets.xcassets/AppIcon.appiconset (all sizes)
#   optimos-glyph.svg       -> App/Sources/OptimosApp/Assets.xcassets/MenuBarIcon.imageset (18 and 36 px)
#   optimos-icon-flat.svg   -> App/Resources/Branding/optimos-icon-1024.png, website/public/icon.png, website/app/icon.png
#   optimos-icon-square.svg -> website/app/apple-icon.png (full-bleed, the system rounds it)
#   og-template.html        -> website/public/og.png (1200x630) and docs/images/social-preview.png (1280x640)
set -euo pipefail
cd "$(dirname "$0")/../.."

CHROME=${CHROME:-"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"}
BRAND=App/Resources/Branding
ASSETS=App/Sources/OptimosApp/Assets.xcassets
[ -x "$CHROME" ] || { echo "error: Google Chrome not found (set CHROME=/path/to/chrome)" >&2; exit 1; }
command -v magick > /dev/null || { echo "error: ImageMagick not found (brew install imagemagick)" >&2; exit 1; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# Renders a page or SVG to a PNG at an exact size; the background stays transparent.
render() { # source size out [extra chrome flags]
  local source=$1 size=$2 out=$3; shift 3
  "$CHROME" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 \
    --default-background-color=00000000 --window-size="$size" --screenshot="$out" "$@" "$source" > /dev/null 2>&1
  [ -s "$out" ] || { echo "error: Chrome did not render $source" >&2; exit 1; }
}
resize() { magick "$1" -filter Lanczos -resize "${2}x${2}" "$3"; }

echo "==> Rendering masters"
render "file://$PWD/$BRAND/optimos-icon-macos.svg" 1024,1024 "$TMP/macos.png"
render "file://$PWD/$BRAND/optimos-icon-flat.svg" 1024,1024 "$TMP/flat.png"
render "file://$PWD/$BRAND/optimos-icon-square.svg" 1024,1024 "$TMP/square.png"
render "file://$PWD/$BRAND/optimos-glyph.svg" 576,576 "$TMP/glyph.png"
render "file://$PWD/$BRAND/og-template.html?w=1200&h=630" 1200,630 "$TMP/og.png" --virtual-time-budget=10000
render "file://$PWD/$BRAND/og-template.html?w=1280&h=640" 1280,640 "$TMP/social.png" --virtual-time-budget=10000

echo "==> App icon"
for spec in 16:16x16@1x 32:16x16@2x 32:32x32@1x 64:32x32@2x 128:128x128@1x 256:128x128@2x 256:256x256@1x 512:256x256@2x 512:512x512@1x 1024:512x512@2x; do
  resize "$TMP/macos.png" "${spec%%:*}" "$ASSETS/AppIcon.appiconset/icon_${spec#*:}.png"
done

echo "==> Menu-bar glyph (black on transparent, used as a template image)"
for n in 18 36; do
  magick "$TMP/glyph.png" -trim +repage -filter Lanczos -resize "$((n - 2))x$((n - 2))" \
    -background none -gravity center -extent "${n}x${n}" "$ASSETS/MenuBarIcon.imageset/menubar@$((n / 18))x.png"
done

echo "==> Website, README and GitHub images"
resize "$TMP/flat.png" 1024 "$BRAND/optimos-icon-1024.png"
resize "$TMP/flat.png" 512 website/public/icon.png
resize "$TMP/flat.png" 256 website/app/icon.png
resize "$TMP/square.png" 180 website/app/apple-icon.png
cp "$TMP/og.png" website/public/og.png
mkdir -p docs/images && cp "$TMP/social.png" docs/images/social-preview.png

# Lossless shrink when oxipng is available.
if command -v oxipng > /dev/null; then
  oxipng -q -o 4 --strip safe "$ASSETS"/AppIcon.appiconset/*.png "$ASSETS"/MenuBarIcon.imageset/*.png \
    "$BRAND/optimos-icon-1024.png" website/public/icon.png website/public/og.png website/app/icon.png \
    website/app/apple-icon.png docs/images/social-preview.png
fi
echo "==> Done. Review with git status, rebuild the app, and redeploy the website."
