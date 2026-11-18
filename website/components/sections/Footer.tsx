import Logo from "@/assets/logo/logo";
import { SITE } from "@/lib/site";

const tools = [
  ["oxipng", "https://github.com/shssoichiro/oxipng"],
  ["quantizr", "https://github.com/imazen/quantizr"],
  ["libjpeg-turbo", "https://libjpeg-turbo.org"],
  ["libwebp", "https://developers.google.com/speed/webp"],
] as const;

export default function Footer() {
  return (
    <footer className="border-t border-steel">
      <div className="mx-auto max-w-7xl px-4 sm:px-8 py-12 flex flex-col gap-8">
        <div className="flex flex-col gap-8 md:flex-row md:justify-between">
          <div className="flex max-w-sm flex-col gap-3">
            <Logo />
            <p className="text-sm text-slate">{SITE.slogan} A free, open-source Mac app. A Windows version is in development.</p>
          </div>
          <div className="flex flex-col gap-2 text-sm">
            <span className="font-medium text-ink">Project</span>
            <a className="text-slate hover:text-ink" href={SITE.downloadUrl}>Download</a>
            <a className="text-slate hover:text-ink" href="/support">Support</a>
            <a className="text-slate hover:text-ink" href="/privacy">Privacy policy</a>
            {SITE.repoUrl && (
              <>
                <a className="text-slate hover:text-ink" href={SITE.repoUrl}>Source code</a>
                <a className="text-slate hover:text-ink" href={`${SITE.repoUrl}/blob/main/LICENSE`}>MIT license</a>
              </>
            )}
          </div>
          <div className="flex flex-col gap-2 text-sm">
            <span className="font-medium text-ink">Built with</span>
            {tools.map(([name, href]) => (
              <a key={name} className="text-slate hover:text-ink" href={href}>{name}</a>
            ))}
          </div>
        </div>
        <div className="h-px bg-steel" />
        <p className="text-sm text-slate">
          © 2026 {SITE.author}. Released under the MIT License. Mac and macOS are trademarks of Apple Inc.; OptimosApp is not affiliated with Apple.
        </p>
      </div>
    </footer>
  );
}
