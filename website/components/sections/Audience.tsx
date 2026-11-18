import { Code2, PenLine } from "lucide-react";

const groups = [
  {
    icon: Code2,
    title: "For developers",
    lead: "Screenshots for bug reports, pull requests and docs, without leaking what is on your screen.",
    points: [
      "Hide tokens, emails and customer data before you paste an image into an issue",
      "Number the steps and point at the line that matters",
      "Convert images to WebP and cap their size before they go into the repository",
    ],
  },
  {
    icon: PenLine,
    title: "For writers and editors",
    lead: "Get images ready for a newsroom, a blog or a shop without learning a new tool.",
    points: [
      "Cap the longest side at 1920 or 1280 px and keep the quality",
      "Drop a whole folder and everything is optimized together",
      "Blur faces and names, and nothing leaves your Mac",
    ],
  },
];

export default function Audience() {
  return (
    <section id="audience" className="scroll-mt-16 border-t border-steel">
      <div className="mx-auto max-w-7xl px-4 py-20 sm:px-8 lg:py-28">
        <h2 className="display-section max-w-3xl text-ink">Built for people who share screenshots for a living</h2>
        <div className="mt-14 grid gap-6 md:grid-cols-2">
          {groups.map(({ icon: Icon, title, lead, points }) => (
            <div key={title} className="flex flex-col gap-5 rounded-2xl bg-cloud p-8 shadow-cloud-card">
              <span className="flex size-8 items-center justify-center rounded-[8px] bg-aqua text-ink">
                <Icon size={18} aria-hidden />
              </span>
              <h3 className="feature-heading text-ink">{title}</h3>
              <p className="text-base leading-relaxed text-slate">{lead}</p>
              <ul className="flex flex-col gap-3 border-t border-steel pt-5">
                {points.map((p) => (
                  <li key={p} className="text-sm font-medium leading-snug text-charcoal">
                    {p}
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
