import { ArrowRight, Crop, PenLine, Gauge } from "lucide-react";
import { SITE } from "@/lib/site";
import { Blurred, Mosaic } from "./redact";

const capabilities = [
  { icon: Crop, label: "Capture" },
  { icon: PenLine, label: "Annotate and hide" },
  { icon: Gauge, label: "Optimize and convert" },
];

/** Stacked sheets: the raw capture, the screenshot with parts hidden, and the optimized result. */
function SheetStack() {
  return (
    <div
      role="img"
      aria-label="A screenshot with an API key pixelated and an email address blurred, then converted to WebP and reduced from 2.4 MB to 212 KB"
      className="relative mx-auto h-[440px] w-full max-w-[560px] sm:h-[500px]"
    >
      {/* back sheet: the original, as captured */}
      <div className="absolute left-0 top-10 h-[290px] w-[74%] -rotate-3 rounded-2xl border border-steel bg-cloud p-5 shadow-sheet">
        <p className="technical-label text-slate">capture.png</p>
        <div className="mt-4 space-y-2.5">
          <div className="h-2.5 w-4/5 rounded-sm bg-steel" />
          <div className="h-2.5 w-3/5 rounded-sm bg-steel" />
          <div className="h-2.5 w-2/3 rounded-sm bg-steel" />
        </div>
        <p className="technical-label absolute bottom-5 left-5 text-slate">2.4 MB</p>
      </div>

      {/* middle sheet: the screenshot with the secrets hidden */}
      <div className="absolute right-0 top-0 w-[84%] rotate-2 rounded-2xl border border-steel bg-paper shadow-sheet">
        <div className="flex items-center gap-1.5 border-b border-steel px-4 py-3">
          <span className="size-2.5 rounded-full bg-steel" />
          <span className="size-2.5 rounded-full bg-steel" />
          <span className="size-2.5 rounded-full bg-steel" />
          <span className="technical-label ml-3 text-slate">Account · API keys</span>
        </div>
        <dl className="space-y-4 p-5 text-sm">
          <div>
            <dt className="text-slate">Signed in as</dt>
            <dd className="mt-1 font-medium text-ink">
              <Blurred>maria.lopez@example.com</Blurred>
            </dd>
          </div>
          <div>
            <dt className="text-slate">Secret key</dt>
            <dd className="technical-label mt-1 text-ink">
              <Mosaic chars={26} />
            </dd>
          </div>
          <div className="relative">
            <dt className="text-slate">Webhook</dt>
            <dd className="technical-label mt-1 text-ink">https://api.example.com/hooks</dd>
            <span className="absolute -inset-x-1.5 -inset-y-1 rounded-md border-2 border-aqua" aria-hidden />
          </div>
        </dl>
      </div>

      {/* front tile: the result */}
      <div className="absolute bottom-0 left-[4%] w-[66%] rounded-2xl bg-graphite p-5 text-white shadow-graphite-card">
        <p className="technical-label text-white/60">capture.png → capture.webp</p>
        <div className="mt-3 flex items-end justify-between gap-3">
          <p className="font-display whitespace-nowrap text-[1.5rem] font-medium sm:text-[2rem] leading-none tracking-[-0.04em]">
            2.4 MB<span className="text-white/50"> → </span>212 KB
          </p>
          <span className="technical-label rounded-md bg-aqua px-2 py-1 font-medium text-ink">−91%</span>
        </div>
      </div>
    </div>
  );
}

export default function Hero() {
  return (
    <section id="top" className="scroll-mt-24 overflow-x-clip">
      <div className="mx-auto grid max-w-7xl items-center gap-14 px-4 py-16 sm:px-8 lg:grid-cols-[1.05fr_1fr] lg:py-24">
        <div className="flex flex-col items-start gap-6">
          <h1 className="display-hero text-ink">
            Capture.
            <br />
            Optimize.
            <br />
            Convert.
          </h1>
          <p className="max-w-lg text-lg leading-relaxed text-slate">
            Take a screenshot with one shortcut, mark it up, hide the private parts, and shrink it before it leaves
            your Mac. Drop in any image to make it smaller or turn it into WebP.
          </p>
          <ul className="flex flex-wrap gap-x-5 gap-y-2">
            {capabilities.map(({ icon: Icon, label }) => (
              <li key={label} className="flex items-center gap-2 text-sm font-medium text-ink">
                <span className="flex size-5 items-center justify-center rounded-[4px] bg-ink text-white">
                  <Icon size={12} aria-hidden />
                </span>
                {label}
              </li>
            ))}
          </ul>
          <div className="flex flex-wrap items-center gap-3 pt-2">
            <a
              href={SITE.downloadUrl}
              className="inline-flex items-center gap-2 rounded-2xl bg-aqua py-3 pl-[22px] pr-4 text-sm font-medium text-ink transition-[filter] hover:brightness-95"
            >
              Download for Mac
              <ArrowRight size={16} aria-hidden />
            </a>
            <a
              href="#features"
              className="inline-flex items-center rounded-2xl border border-steel px-[22px] py-3 text-sm font-medium text-ink transition-colors hover:bg-cloud"
            >
              See what it does
            </a>
          </div>
          <p className="technical-label text-slate">
            v{SITE.version} · {SITE.requirements} · Free, MIT license
          </p>
        </div>
        <SheetStack />
      </div>
    </section>
  );
}
