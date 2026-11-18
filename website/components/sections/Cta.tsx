import { ArrowRight } from "lucide-react";
import { SITE } from "@/lib/site";

export default function Cta() {
  return (
    <section className="bg-ink text-white">
      <div className="mx-auto flex max-w-7xl flex-col items-start gap-8 px-4 py-20 sm:px-8 lg:py-28">
        <h2 className="display-section max-w-3xl">Make every image lighter</h2>
        <p className="max-w-xl text-lg leading-relaxed text-white/60">
          Free, open source and private. Capture, mark up, hide, optimize and share from your menu bar.
        </p>
        <div className="flex flex-wrap items-center gap-3">
          <a
            href={SITE.downloadUrl}
            className="inline-flex items-center gap-2 rounded-2xl bg-aqua py-3 pl-[22px] pr-4 text-sm font-medium text-ink transition-[filter] hover:brightness-95"
          >
            Download for Mac
            <ArrowRight size={16} aria-hidden />
          </a>
          {SITE.repoUrl && (
            <a
              href={SITE.repoUrl}
              className="inline-flex items-center rounded-2xl bg-white/10 px-[22px] py-3 text-sm font-medium text-white shadow-inset-edge transition-colors hover:bg-white/15"
            >
              View on GitHub
            </a>
          )}
        </div>
      </div>
    </section>
  );
}
