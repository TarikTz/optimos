import { Separator } from "@/components/ui/separator";
import Logo from "@/assets/logo/logo";
import { SITE } from "@/lib/site";

const tools = [
  ["oxipng", "https://github.com/shssoichiro/oxipng"],
  ["pngquant", "https://pngquant.org"],
  ["libjpeg-turbo", "https://libjpeg-turbo.org"],
  ["libwebp", "https://developers.google.com/speed/webp"],
] as const;

export default function Footer() {
  return (
    <footer className="border-t border-border">
      <div className="mx-auto max-w-7xl px-4 sm:px-8 py-12 flex flex-col gap-8">
        <div className="flex flex-col gap-8 md:flex-row md:justify-between">
          <div className="flex max-w-sm flex-col gap-3">
            <Logo />
            <p className="text-sm text-muted-foreground">{SITE.slogan} A free, open-source Mac app.</p>
          </div>
          <div className="flex flex-col gap-2 text-sm">
            <span className="font-medium">Project</span>
            <a className="text-muted-foreground hover:text-foreground" href={SITE.downloadUrl}>Download</a>
            {SITE.repoUrl && (
              <>
                <a className="text-muted-foreground hover:text-foreground" href={SITE.repoUrl}>Source code</a>
                <a className="text-muted-foreground hover:text-foreground" href={`${SITE.repoUrl}/blob/main/LICENSE`}>MIT license</a>
              </>
            )}
          </div>
          <div className="flex flex-col gap-2 text-sm">
            <span className="font-medium">Built with</span>
            {tools.map(([name, href]) => (
              <a key={name} className="text-muted-foreground hover:text-foreground" href={href}>{name}</a>
            ))}
          </div>
        </div>
        <Separator />
        <p className="text-sm text-muted-foreground">
          © 2026 {SITE.author}. Released under the MIT License. Mac and macOS are trademarks of Apple Inc.; OptimosApp is not affiliated with Apple.
        </p>
      </div>
    </footer>
  );
}
