# Branding sources

| File | What it is |
|---|---|
| `optimos-glyph.svg` | The one-colour glyph: a picture with a sun, inside four corner brackets with two inward arrows. The source of everything below. |
| `optimos-icon-color.svg` | The app icon artwork: the glyph in white on a blue-to-teal tile, with an orange sun. |
| `optimos-icon-1024.png` | The icon rendered at 1024 px, used by the README and as the source for the icon sizes. |

How the shipped files are made (ImageMagick `magick` plus macOS Quick Look):

- **App icon sizes** (`App/Sources/OptimosApp/Assets.xcassets/AppIcon.appiconset`): render `optimos-icon-color.svg` to 1024 px with `qlmanage -t -s 1024`, cut it to a rounded tile with a mask, then resize to 16, 32, 64, 128, 256, 512 and 1024 px.
- **Menu-bar glyph** (`Assets.xcassets/MenuBarIcon.imageset`): render `optimos-glyph.svg` with `qlmanage`, turn black-on-white into black-on-transparent, trim, and resize to 18 and 36 px. It is marked as a template image so macOS tints it for light and dark menu bars.
- **Website icon and share image** (`website/public`): resized from `optimos-icon-1024.png`.
