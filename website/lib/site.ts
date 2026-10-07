/** One place for everything that changes between releases. */
export const SITE = {
  name: "OptimosApp",
  slogan: "Capture. Optimize. Convert.",
  description:
    "A free, open-source Mac app to capture, annotate, optimize and convert images. Screenshots in a shortcut, smaller files before you publish. Everything stays on your Mac.",
  author: "Tarik Omercehajic",
  version: "0.1.0",
  // TODO(release): point these at the real GitHub repo and release once they exist.
  repoUrl: "https://github.com/OWNER/OptimosApp",
  downloadUrl: "https://github.com/OWNER/OptimosApp/releases/latest",
  // Used for social-share image links; set to the real address when the site is hosted.
  url: "https://optimosapp.example",
  requirements: "Apple silicon · macOS 26 or later",
} as const;
