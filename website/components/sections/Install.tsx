import { SITE } from "@/lib/site";
import FirstLaunch from "@/components/sections/FirstLaunch";

const steps = [
  { title: "Download and drag", text: "Open the disk image and drag OptimosApp into Applications." },
  { title: "Allow it once", text: "The app is not notarized by Apple yet, so macOS asks before the first launch. Approve it once, in Terminal or System Settings (see below)." },
  { title: "Grant screen recording", text: "The first capture asks for Screen Recording permission. Allow it, then quit and reopen the app." },
];

export default function Install() {
  return (
    <section id="install" className="scroll-mt-16 border-t border-steel">
      <div className="mx-auto flex max-w-7xl flex-col gap-12 px-4 py-20 sm:px-8 lg:py-28">
        <div className="flex max-w-2xl flex-col gap-4">
          <h2 className="display-section text-ink">Up and running in a minute</h2>
          <p className="text-lg text-slate">
            {SITE.requirements}. Version {SITE.version}.
          </p>
        </div>
        <ol className="grid gap-4 md:grid-cols-3">
          {steps.map((s, i) => (
            <li key={s.title} className="flex flex-col gap-3 rounded-2xl border border-steel p-6">
              <span className="technical-label flex size-7 items-center justify-center rounded-[8px] bg-ink text-white">{i + 1}</span>
              <h3 className="font-medium text-ink">{s.title}</h3>
              <p className="text-sm leading-relaxed text-slate">{s.text}</p>
            </li>
          ))}
        </ol>
        <FirstLaunch />
        <div>
          <a
            href={SITE.downloadUrl}
            className="inline-flex items-center rounded-2xl bg-aqua px-[22px] py-3 text-sm font-medium text-ink transition-[filter] hover:brightness-95"
          >
            Download OptimosApp {SITE.version}
          </a>
        </div>
      </div>
    </section>
  );
}
