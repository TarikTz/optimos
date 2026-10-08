# Third-party notices

OptimosApp itself is MIT-licensed (see `LICENSE`). It uses these open-source components, each under its own license.

| Component | How it is used | License |
|---|---|---|
| [libwebp](https://developers.google.com/speed/webp) | Linked statically into `OptimosCore` for WebP encoding and decoding | BSD-3-Clause |
| [oxipng](https://github.com/shssoichiro/oxipng) | Run as a separate program for lossless PNG optimization | MIT |
| [pngquant](https://pngquant.org) | Run as a separate program for lossy PNG color reduction | GPL-3.0-or-later |
| [jpegtran](https://libjpeg-turbo.org) (libjpeg) | Run as a separate program for lossless JPEG optimization | IJG / BSD-style |
| [swift-argument-parser](https://github.com/apple/swift-argument-parser) | Command-line parsing in the `optimos` tool | Apache-2.0 |

## Website
The landing page in `website/` is not part of the app. It is built with these MIT-licensed projects, and some of their components were copied into the source and adapted:

| Project | Use |
|---|---|
| [Next.js](https://nextjs.org), [React](https://react.dev), [Tailwind CSS](https://tailwindcss.com) | The site itself |
| [shadcn/ui](https://ui.shadcn.com) and [Shadcn Space](https://shadcnspace.com) blocks | Header, hero, FAQ and call-to-action layouts |
| [interior.dev](https://www.interior.dev) | The copy button and the segmented control in the install section |
| [Motion](https://motion.dev) | The animations inside the interior.dev components |
| [Lucide](https://lucide.dev) | Icons |

## pngquant and the GPL
OptimosApp only **runs** `pngquant` as a separate program; it does not link to it, so OptimosApp's own code is not a GPL work. If a packaged release **bundles** the `pngquant` binary, that release must also include the GPL-3.0 license text and an offer of the corresponding source for `pngquant`. The packaging step is where this gets handled; until then `pngquant` is an optional tool installed separately (see `README.md`).
