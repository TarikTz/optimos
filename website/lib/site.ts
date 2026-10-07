/** One place for everything that changes between releases. */
export const SITE = {
  name: "OptimosApp",
  slogan: "Capture. Optimize. Convert.",
  description:
    "Free, open-source Mac app to capture screenshots, annotate and hide details, then optimize and convert images to WebP, JPEG or PNG. Private: it all runs on your Mac.",
  author: "Tarik Omercehajic",
  version: "0.1.0",
  // The DMG is hosted on 075codes.com (HTTPS: browsers warn about plain-HTTP downloads).
  downloadUrl: "https://075codes.com/OptimosApp-0.1.0.dmg",
  // Set when the source is published; the "Source code" link stays hidden while this is null.
  repoUrl: null as string | null,
  url: "https://optimos.075codes.com",
  title: "OptimosApp: Screenshot, Annotate and Image Optimizer for Mac",
  keywords: [
    "Mac screenshot app", "screenshot annotation Mac", "image optimizer Mac", "compress PNG JPEG WebP",
    "convert to WebP", "pixelate screenshot", "resize images Mac", "ImageOptim alternative",
    "open source screenshot tool", "menu bar screenshot",
  ],
  requirements: "Apple silicon · macOS 26 or later",
} as const;
