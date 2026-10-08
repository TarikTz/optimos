# OptimosApp website

The static landing page for OptimosApp. Next.js (static export), Tailwind and shadcn/ui, with sections adapted from the free [shadcnspace](https://shadcnspace.com) blocks (MIT).

    pnpm install
    pnpm dev      # http://localhost:3000
    pnpm build    # writes the plain static site to out/

`out/` is ordinary HTML, CSS and JS: upload it to any static host (GitHub Pages, Netlify, Cloudflare Pages). On GitHub Pages under `https://<user>.github.io/<repo>/`, set `basePath: "/<repo>"` in `next.config.ts` first.

## Deploying
Live at https://optimos.075codes.com (nginx on the 075codes server; the DMG is served from GitHub Releases). `DEPLOY_HOST=user@server scripts/deploy.sh` builds and uploads `out/` with rsync. The nginx host in `deploy/optimos.075codes.com.conf` was installed once into `/etc/nginx/sites-available` (symlinked into `sites-enabled`), and `certbot --nginx -d optimos.075codes.com` added HTTPS and renews it automatically. The Download button points at `https://github.com/TarikTz/optimos/releases/latest/download/OptimosApp.dmg`, so a new GitHub release needs only the `version` in `lib/site.ts` and a redeploy.

Everything that changes between releases lives in `lib/site.ts` (version, download and repo links, site URL). The "Source code" footer links stay hidden until you set `repoUrl` there. The screenshots on the page are drawn mockups in `components/mockups/`; to use real screenshots, put them in `public/screens/` and swap the mockup component for an `<Image>` in `components/sections/Features.tsx`.
