import { Mail, MessageCircle, Radio, StickyNote } from "lucide-react";

const targets = [
  { label: "AirDrop", icon: Radio },
  { label: "Messages", icon: MessageCircle },
  { label: "Mail", icon: Mail },
  { label: "Notes", icon: StickyNote },
];

/** The macOS share menu opened on a finished capture. */
export function ShareMockup() {
  return (
    <div className="relative mx-auto w-full max-w-sm rounded-2xl border border-border bg-gradient-to-br from-sky-100 to-indigo-100 p-6 shadow-2xl shadow-primary/10 dark:from-slate-800 dark:to-indigo-950">
      <div className="mb-4 flex items-center gap-3 rounded-xl bg-background/80 p-3 text-xs shadow-sm">
        <span className="size-10 shrink-0 rounded-lg bg-gradient-to-br from-blue-500 to-teal-400" />
        <span className="min-w-0">
          <span className="block truncate font-medium">Optimos 2026-10-07 at 14.02.11.webp</span>
          <span className="text-muted-foreground">212 KB · WebP</span>
        </span>
      </div>
      <ul className="overflow-hidden rounded-xl border border-border bg-background/90 text-sm shadow-lg">
        {targets.map(({ label, icon: Icon }) => (
          <li key={label} className="flex items-center gap-3 border-b border-border px-4 py-2.5 last:border-0">
            <Icon size={16} className="text-muted-foreground" />
            {label}
          </li>
        ))}
      </ul>
    </div>
  );
}
