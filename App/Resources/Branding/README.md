# Branding sources

The icon is a dark rounded tile with a mint-green picture (a mountain and a sun) inside four crop corners, with two grey arrows pressing in from above and below. Colours: tile `#27272B` to `#141416`, picture `#7CF3E5`, corners `#F4F4F5`, arrows `#4E4E56`.

| File | What it is |
|---|---|
| `optimos-icon-macos.svg` | The app icon as macOS shows it: the tile with a soft shadow and glow, on a transparent background with room around it. Source of the Dock icon. |
| `optimos-icon-flat.svg` | The same artwork as a full-size flat tile with no shadow. Source of the README, website and share images. |
| `optimos-icon-square.svg` | A full-bleed square version. Source of the website's Apple touch icon (the system rounds it). |
| `optimos-glyph.svg` | A one-colour version for the menu bar: crop corners around a picture, with heavier strokes so it stays readable at 18 px. |
| `og-template.html` | Template for the website share image (1200×630) and the GitHub social preview (1280×640). |
| `optimos-icon-1024.png` | The flat icon rendered at 1024 px. Used by the README. |

## Regenerating

Edit a source file, then run:

```sh
App/scripts/make-icons.sh
```

It needs Google Chrome (for transparent SVG rendering) and ImageMagick, and writes:

- `App/Sources/OptimosApp/Assets.xcassets/AppIcon.appiconset`: all sizes, from `optimos-icon-macos.svg`.
- `App/Sources/OptimosApp/Assets.xcassets/MenuBarIcon.imageset`: 18 and 36 px, black on transparent. It is marked as a template image, so macOS tints it for light and dark menu bars.
- `optimos-icon-1024.png`, `website/public/icon.png` and `website/app/icon.png`, from `optimos-icon-flat.svg`.
- `website/app/apple-icon.png`, from `optimos-icon-square.svg`.
- `website/public/og.png` and `docs/images/social-preview.png`, from `og-template.html`.

The GitHub social preview cannot be set from the repository: upload `docs/images/social-preview.png` under Settings > General > Social preview.
