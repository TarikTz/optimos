# OptimosApp website

The static landing page for OptimosApp. Next.js (static export), Tailwind and shadcn/ui, with sections adapted from the free [shadcnspace](https://shadcnspace.com) blocks (MIT).

    pnpm install
    pnpm dev      # http://localhost:3000
    pnpm build    # writes the plain static site to out/

`out/` is ordinary HTML, CSS and JS: upload it to any static host (GitHub Pages, Netlify, Cloudflare Pages). On GitHub Pages under `https://<user>.github.io/<repo>/`, set `basePath: "/<repo>"` in `next.config.ts` first.

Everything that changes between releases lives in `lib/site.ts` (version, download and repo links, site URL). **Before publishing, replace the `OWNER` placeholder in the two GitHub links and set `url`.** The screenshots on the page are drawn mockups in `components/mockups/`; to use real screenshots, put them in `public/screens/` and swap the mockup component for an `<Image>` in `components/sections/Features.tsx`.
