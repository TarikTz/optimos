import {
  ArrowUpRight, ChevronsUpDown, Circle, Clipboard, Download, Droplet, Grid3x3, Hash, Highlighter, Minus,
  MousePointer2, Share, Square, Type, X,
} from "lucide-react";
import { Desktop } from "./Desktop";

const colors = ["bg-red-500", "bg-orange-500", "bg-yellow-400", "bg-green-500", "bg-blue-500", "bg-white"];

/** The capture overlay: dimmed screen, a selection, and the two-row toolbar. */
export function CaptureMockup({ annotated = false }: { annotated?: boolean }) {
  return (
    <Desktop>
      {/* dim everything except the selection */}
      <div className="absolute left-[12%] top-[16%] h-[44%] w-[44%] rounded-sm border border-white/90 shadow-[0_0_0_999px_rgba(0,0,0,0.42)]">
        <span className="absolute -top-6 left-0 rounded bg-black/70 px-1.5 py-0.5 text-[10px] text-white">640 × 360</span>
        {annotated && (
          <>
            <div className="absolute left-[8%] top-[22%] h-[30%] w-[38%] rounded-sm border-[3px] border-red-500" />
            <svg className="absolute inset-0 size-full" viewBox="0 0 100 100" fill="none">
              <path d="M88 20 L62 42 M62 42 L62 31 M62 42 L73 42" stroke="#ef4444" strokeWidth="2.6" strokeLinecap="round" strokeLinejoin="round" />
            </svg>
            <div className="absolute bottom-[14%] left-[8%] grid h-[16%] w-[46%] grid-cols-8 overflow-hidden rounded-[2px]">
              {Array.from({ length: 32 }).map((_, i) => (
                <span key={i} className={i % 3 === 0 ? "bg-slate-400" : i % 3 === 1 ? "bg-slate-300" : "bg-slate-500"} />
              ))}
            </div>
            <span className="absolute right-[8%] bottom-[16%] text-[11px] font-semibold text-red-500 drop-shadow">Check this</span>
          </>
        )}
      </div>

      <div className="absolute left-[12%] top-[62%] w-[min(88%,420px)] rounded-lg border border-white/15 bg-neutral-800/90 p-2 text-white shadow-xl backdrop-blur">
        <div className="flex flex-wrap items-center gap-1.5 border-b border-white/15 pb-1.5">
          {[MousePointer2, Square, Circle, ArrowUpRight, Minus, Type, Highlighter, Hash, Grid3x3, Droplet].map((Icon, i) => (
            <span key={i} className={`flex size-5 items-center justify-center rounded ${i === 1 ? "bg-white/25" : ""}`}>
              <Icon size={12} />
            </span>
          ))}
          <span className="mx-0.5 h-3.5 w-px bg-white/25" />
          {colors.map((c, i) => (
            <span key={c} className={`size-3 rounded-full ${c} ${i === 0 ? "ring-1 ring-white ring-offset-1 ring-offset-neutral-800" : ""}`} />
          ))}
          <span className="mx-0.5 h-3.5 w-px bg-white/25" />
          <span className="hidden size-1 rounded-full bg-white sm:block" />
          <span className="hidden size-2 rounded-full bg-white sm:block" />
          <span className="hidden size-3 rounded-full bg-white sm:block" />
        </div>
        <div className="flex items-center gap-1.5 pt-1.5 text-[10px]">
          <span className="flex items-center gap-1 rounded bg-white/15 px-1.5 py-0.5">WebP <ChevronsUpDown size={9} /></span>
          <span className="flex items-center gap-1 rounded bg-white/15 px-1.5 py-0.5">Fit 1920 px <ChevronsUpDown size={9} /></span>
          <span className="ml-auto flex gap-2.5 pr-1">
            <Share size={12} />
            <Clipboard size={12} />
            <Download size={12} />
            <X size={12} />
          </span>
        </div>
      </div>
    </Desktop>
  );
}
