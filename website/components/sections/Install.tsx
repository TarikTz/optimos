import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { SITE } from "@/lib/site";
import FirstLaunch from "@/components/sections/FirstLaunch";

const steps = [
  { title: "Download and drag", text: "Open the disk image and drag OptimosApp into Applications." },
  { title: "Allow it once", text: "The app is not notarized by Apple yet, so macOS asks before the first launch. Approve it once, in Terminal or System Settings (see below)." },
  { title: "Grant screen recording", text: "The first capture asks for Screen Recording permission. Allow it, then quit and reopen the app." },
];

export default function Install() {
  return (
    <section id="install" className="scroll-mt-24">
      <div className="mx-auto max-w-4xl px-4 sm:px-8 py-20 flex flex-col gap-10">
        <div className="flex flex-col items-center gap-4 text-center">
          <Badge variant="outline" className="h-auto px-3 py-1 text-sm font-normal">Install</Badge>
          <h2 className="text-3xl font-semibold md:text-4xl">Up and running in a minute</h2>
          <p className="text-lg text-muted-foreground">{SITE.requirements}. Version {SITE.version}.</p>
        </div>
        <ol className="grid gap-4 md:grid-cols-3">
          {steps.map((s, i) => (
            <li key={s.title} className="flex flex-col gap-2 rounded-2xl border border-border p-6">
              <span className="flex size-8 items-center justify-center rounded-full bg-primary text-sm font-medium text-primary-foreground">{i + 1}</span>
              <h3 className="font-medium">{s.title}</h3>
              <p className="text-sm text-muted-foreground">{s.text}</p>
            </li>
          ))}
        </ol>
        <FirstLaunch />
        <div className="flex justify-center">
          <Button render={<a href={SITE.downloadUrl} />} nativeButton={false} className="h-11 rounded-full px-6">
            Download OptimosApp {SITE.version}
          </Button>
        </div>
      </div>
    </section>
  );
}
