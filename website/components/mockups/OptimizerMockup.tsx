import { Plus } from "lucide-react";

const rows = [
  { name: "cover-photo.jpg", result: "4.2 MB → 910 KB (−78%)", tone: "text-emerald-600 dark:text-emerald-400" },
  { name: "chart.png", result: "1.3 MB → 380 KB (−71%)", tone: "text-emerald-600 dark:text-emerald-400" },
  { name: "portrait.png", result: "portrait.webp  2.8 MB → 240 KB (−91%)", tone: "text-emerald-600 dark:text-emerald-400" },
  { name: "logo.png", result: "Already optimal", tone: "text-muted-foreground" },
  { name: "newsroom/", result: "12 images added", tone: "text-muted-foreground" },
];

/** The Optimize Images window with a few finished rows. */
export function OptimizerMockup() {
  return (
    <div className="w-full overflow-hidden rounded-2xl border border-border bg-card shadow-2xl shadow-primary/10">
      <div className="flex items-center gap-1.5 border-b border-border bg-muted/60 px-3 py-2.5">
        <span className="size-2.5 rounded-full bg-red-400" />
        <span className="size-2.5 rounded-full bg-amber-400" />
        <span className="size-2.5 rounded-full bg-green-400" />
        <span className="mx-auto text-xs font-medium text-muted-foreground">Optimize Images</span>
      </div>
      <ul className="divide-y divide-border text-sm">
        {rows.map((r) => (
          <li key={r.name} className="flex items-center justify-between gap-4 px-4 py-3">
            <span className="truncate font-medium">{r.name}</span>
            <span className={`shrink-0 text-xs ${r.tone}`}>{r.result}</span>
          </li>
        ))}
      </ul>
      <div className="flex flex-wrap items-center gap-2 border-t border-border bg-muted/40 px-3 py-2.5 text-xs">
        <span className="flex size-6 items-center justify-center rounded-md border border-border"><Plus size={12} /></span>
        {["Balanced", "WebP", "Fit 1920 px"].map((label) => (
          <span key={label} className="rounded-md border border-border bg-background px-2 py-1">{label}</span>
        ))}
        <span className="ml-auto flex gap-2">
          <span className="rounded-md border border-border bg-background px-2.5 py-1">Undo</span>
          <span className="rounded-md border border-border bg-background px-2.5 py-1">Again</span>
        </span>
      </div>
    </div>
  );
}
