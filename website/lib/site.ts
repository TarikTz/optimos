/** One place for everything that changes between releases. */
export const SITE = {
  name: "OptimosApp",
  slogan: "Capture. Optimize. Convert.",
  description:
    "Free, open-source Mac app to capture screenshots, annotate and hide details, then optimize and convert images to WebP, JPEG or PNG. Private: it all runs on your Mac.",
  author: "Tarik Omercehajic",
  version: "0.2.1",
  // GitHub's "latest release" always serves the newest DMG under this fixed name (see the release
  // steps in the README), so a new release needs no link change, only the version below.
  downloadUrl: "https://github.com/TarikTz/optimos/releases/latest/download/OptimosApp.dmg",
  // The "Source code" and "MIT license" footer links stay hidden while this is null.
  repoUrl: "https://github.com/TarikTz/optimos" as string | null,
  url: "https://optimos.075codes.com",
  title: "OptimosApp: Screenshot, Annotate and Image Optimizer for Mac",
  keywords: [
    "Mac screenshot app", "screenshot annotation Mac", "image optimizer Mac", "compress PNG JPEG WebP",
    "convert to WebP", "HEIC to JPEG", "pixelate screenshot", "blur screenshot", "resize images Mac", "ImageOptim alternative",
    "open source screenshot tool", "menu bar screenshot",
  ],
  requirements: "Apple silicon · macOS 26 or later",
} as const;
