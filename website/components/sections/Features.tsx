import type { ReactNode } from "react";
import { Check } from "lucide-react";
import { CaptureMockup } from "@/components/mockups/CaptureMockup";
import { OptimizerMockup } from "@/components/mockups/OptimizerMockup";
import { ShareMockup } from "@/components/mockups/ShareMockup";

export type Feature = { id: string; title: string; body: string; points: string[]; visual: ReactNode };

export const FEATURES: Feature[] = [
  {
    id: "capture",
    title: "Capture any area, window or screen from a shortcut",
    body: "Press a shortcut, drag over what you need, or press Space to pick a whole window. The screen freezes while you choose, so what you select is what you get.",
    points: [
      "⌃⌥⌘4 for an area or window, ⌃⌥⌘3 for the whole screen",
      "Drag the handles to resize the selection, or drag inside it to move it",
      "Enter copies, ⌘S saves, Esc cancels. Works on every display and Space",
    ],
    visual: <CaptureMockup />,
  },
  {
    id: "annotate",
    title: "Mark it up. Hide what shouldn't be seen.",
    body: "Draw rectangles, circles, arrows and lines, highlight text, number the steps and add notes. Every mark is an object you can move, resize, recolour and undo.",
    points: [
      "Pixelate or blur passwords, emails, keys and faces",
      "Undo and redo every step",
      "Colour and size pickers for each mark",
    ],
    visual: <CaptureMockup annotated />,
  },
  {
    id: "optimize",
    title: "Drop images in. Get smaller files out.",
    body: "Drop files or whole folders on the window. Pick Lossless, Balanced or Smallest, convert to PNG, JPEG or WebP, and cap the longest side so nothing is bigger than it needs to be. iPhone photos (HEIC), TIFF and BMP convert too.",
    points: [
      "Replaced in place, only when the result is smaller",
      "Converted files get a new name and the originals stay",
      "Undo restores every original until you close the window",
    ],
    visual: <OptimizerMockup />,
  },
  {
    id: "share",
    title: "Copy, save or send in the format you chose",
    body: "Choose the format and size for each capture on the toolbar, then copy it, save it to a folder you pick, or send it through the macOS share menu.",
    points: [
      "PNG, JPEG or WebP, with a maximum size",
      "Always PNG on the clipboard, so every app can paste it",
      "Save automatically or choose where each time",
    ],
    visual: <ShareMockup />,
  },
];

export default function Features({ items, id }: { items: Feature[]; id?: string }) {
  return (
    <section id={id} className="scroll-mt-16">
      <div className="mx-auto flex max-w-7xl flex-col gap-24 px-4 py-20 sm:px-8">
        {items.map((f, i) => (
          <article key={f.id} className="grid items-center gap-10 lg:grid-cols-2 lg:gap-20">
            <div className={`flex flex-col items-start gap-5 ${i % 2 ? "lg:order-2" : ""}`}>
              <h2 className="feature-heading max-w-lg text-ink">{f.title}</h2>
              <p className="max-w-lg text-base leading-relaxed text-slate">{f.body}</p>
              <ul className="mt-1 flex max-w-lg flex-col gap-3">
                {f.points.map((p) => (
                  <li key={p} className="flex items-start gap-3 text-sm font-medium leading-snug text-charcoal">
                    <span className="mt-px flex size-4 shrink-0 items-center justify-center rounded-[4px] bg-ink text-white">
                      <Check size={11} strokeWidth={3} aria-hidden />
                    </span>
                    {p}
                  </li>
                ))}
              </ul>
            </div>
            <div className={`rounded-2xl bg-cloud p-5 shadow-cloud-card sm:p-10 ${i % 2 ? "lg:order-1" : ""}`}>{f.visual}</div>
          </article>
        ))}
      </div>
    </section>
  );
}
