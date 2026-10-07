import type { ReactNode } from "react";
import { Badge } from "@/components/ui/badge";
import { CaptureMockup } from "@/components/mockups/CaptureMockup";
import { OptimizerMockup } from "@/components/mockups/OptimizerMockup";
import { ShareMockup } from "@/components/mockups/ShareMockup";

type Feature = { tag: string; title: string; body: string; points: string[]; visual: ReactNode };

const features: Feature[] = [
  {
    tag: "Capture",
    title: "Any area, window or screen, from a shortcut",
    body: "Press a shortcut, drag over what you need, or press Space to pick a whole window. The screen freezes so what you select is what you get.",
    points: ["⌃⌥⌘4 for an area or window, ⌃⌥⌘3 for the whole screen", "Drag the handles to resize the selection, or drag inside it to move it", "Enter copies, ⌘S saves, Esc cancels. Works on every display and Space"],
    visual: <CaptureMockup />,
  },
  {
    tag: "Annotate",
    title: "Mark it up, and hide what should not be seen",
    body: "Draw rectangles, circles, arrows and lines, highlight text, number the steps, add notes, and pixelate or blur passwords, emails and faces. Every mark is an object you can move, resize, recolour and undo.",
    points: ["Pixelate and blur destroy the detail underneath, so the text cannot be recovered", "Undo and redo every step", "Colour and size pickers for each mark"],
    visual: <CaptureMockup annotated />,
  },
  {
    tag: "Optimize and convert",
    title: "Drop images, get smaller files",
    body: "Drop files or whole folders on the window. Pick Lossless, Balanced or Smallest, convert to PNG, JPEG or WebP, and cap the longest side so nothing is bigger than it needs to be. iPhone photos (HEIC), TIFF and BMP convert too.",
    points: ["Replaced in place, only when the result is smaller", "Converted files get a new name; originals stay", "Undo restores every original until you close the window"],
    visual: <OptimizerMockup />,
  },
  {
    tag: "Share",
    title: "Copy, save or send, in the format you chose",
    body: "Choose the format and size for each capture right on the toolbar, then copy it, save it to a folder you pick, or share it with the macOS share menu.",
    points: ["PNG, JPEG or WebP, with a max size", "Always PNG on the clipboard so every app can paste it", "Autosave or ask where to save, your choice"],
    visual: <ShareMockup />,
  },
];

export default function Features() {
  return (
    <section id="features" className="scroll-mt-24">
      <div className="mx-auto max-w-7xl px-4 sm:px-8 py-16 flex flex-col gap-20">
        {features.map((f, i) => (
          <div key={f.tag} className="grid items-center gap-10 lg:grid-cols-2 lg:gap-16">
            <div className={`flex flex-col gap-4 ${i % 2 ? "lg:order-2" : ""}`}>
              <Badge variant="outline" className="h-auto w-fit px-3 py-1 text-sm font-normal">{f.tag}</Badge>
              <h2 className="text-3xl font-semibold md:text-4xl">{f.title}</h2>
              <p className="text-lg text-muted-foreground">{f.body}</p>
              <ul className="mt-2 flex flex-col gap-2 text-sm text-muted-foreground">
                {f.points.map((p) => (
                  <li key={p} className="flex gap-2"><span aria-hidden className="text-primary">✓</span>{p}</li>
                ))}
              </ul>
            </div>
            <div className={i % 2 ? "lg:order-1" : ""}>{f.visual}</div>
          </div>
        ))}
      </div>
    </section>
  );
}
