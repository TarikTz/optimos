import type { ReactNode } from "react";
import { cn } from "@/lib/utils";

/** A stand-in for a Mac screen: a plain backdrop with a fake app window, used behind the capture mockups. */
export function Desktop({ children, className }: { children?: ReactNode; className?: string }) {
  return (
    <div
      role="img"
      aria-label="Mockup of the OptimosApp capture toolbar over a selected area of the screen"
      className={cn(
        "relative aspect-[16/10] w-full overflow-hidden rounded-2xl border border-steel bg-steel/60 shadow-sheet",
        className,
      )}
    >
      <div className="absolute left-[6%] top-[9%] h-[62%] w-[56%] rounded-xl border border-black/10 bg-paper shadow-sheet">
        <div className="flex gap-1.5 border-b border-black/10 p-2.5">
          <span className="size-2.5 rounded-full bg-red-400" />
          <span className="size-2.5 rounded-full bg-amber-400" />
          <span className="size-2.5 rounded-full bg-green-400" />
        </div>
        <div className="space-y-2.5 p-4">
          <div className="h-3 w-2/5 rounded bg-slate-300 dark:bg-slate-600" />
          <div className="h-2 w-full rounded bg-slate-200 dark:bg-slate-700" />
          <div className="h-2 w-5/6 rounded bg-slate-200 dark:bg-slate-700" />
          <div className="h-2 w-3/4 rounded bg-slate-200 dark:bg-slate-700" />
          <div className="mt-4 h-16 w-full rounded-lg bg-cloud" />
        </div>
      </div>
      {children}
    </div>
  );
}
