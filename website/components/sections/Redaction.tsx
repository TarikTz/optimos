"use client";

import { useState } from "react";
import { Blurred, Mosaic } from "./redact";

type Mode = "original" | "pixelate" | "blur";

const MODES: { value: Mode; label: string }[] = [
  { value: "original", label: "Original" },
  { value: "pixelate", label: "Pixelate" },
  { value: "blur", label: "Blur" },
];

/** One secret in the sample screenshot: shows as text, a mosaic or blurred text depending on the mode. */
function Secret({ mode, text }: { mode: Mode; text: string }) {
  if (mode === "pixelate") return <Mosaic chars={text.length} />;
  if (mode === "blur") return <Blurred>{text}</Blurred>;
  return <span className="text-volt">{text}</span>;
}

const points = [
  { title: "The detail is destroyed", text: "Pixelate and blur change the pixels themselves before the image is copied or saved. There is nothing underneath to recover." },
  { title: "Drag a box, pick a style", text: "Choose Pixelate or Blur on the toolbar and draw over the area. Move or resize it afterwards, and undo if you change your mind." },
  { title: "Made for the things you share", text: "API keys in a bug report, customer emails in a doc, faces in a tutorial, a password in a recording of your screen." },
];

export default function Redaction() {
  const [mode, setMode] = useState<Mode>("pixelate");

  return (
    <section id="redaction" className="scroll-mt-16 bg-ink text-white">
      <div className="mx-auto grid max-w-7xl gap-12 px-4 py-20 sm:px-8 lg:grid-cols-[1fr_1.1fr] lg:gap-20 lg:py-28">
        <div className="flex flex-col items-start gap-8">
          <h2 className="display-section">Share the screenshot, not the secrets</h2>
          <p className="max-w-md text-lg leading-relaxed text-white/60">
            Hide an API key, an email address or a face with one drag. What you hide is gone from the file, not just
            covered up.
          </p>
          <dl className="flex max-w-md flex-col gap-6">
            {points.map((p) => (
              <div key={p.title}>
                <dt className="font-medium">{p.title}</dt>
                <dd className="mt-1 text-sm leading-relaxed text-white/60">{p.text}</dd>
              </div>
            ))}
          </dl>
        </div>

        <div className="flex flex-col gap-4">
          <div role="group" aria-label="Choose how the sample screenshot is hidden" className="flex w-fit gap-1 rounded-2xl bg-white/10 p-1 shadow-inset-edge">
            {MODES.map((m) => (
              <button
                key={m.value}
                type="button"
                aria-pressed={mode === m.value}
                onClick={() => setMode(m.value)}
                className={`rounded-xl px-4 py-2 text-sm font-medium transition-colors ${
                  mode === m.value ? "bg-aqua text-ink" : "text-white/70 hover:text-white"
                }`}
              >
                {m.label}
              </button>
            ))}
          </div>

          <div className="rounded-2xl bg-graphite shadow-graphite-card">
            <div className="flex items-center gap-1.5 border-b border-white/10 px-4 py-3">
              <span className="size-2.5 rounded-full bg-white/20" />
              <span className="size-2.5 rounded-full bg-white/20" />
              <span className="size-2.5 rounded-full bg-white/20" />
              <span className="technical-label ml-3 text-white/50">deploy.log</span>
            </div>
            <pre className="technical-label overflow-x-auto p-5 leading-8 text-white/80">
              <code>
                {"$ vercel env pull\n"}
                {"STRIPE_SECRET_KEY="}
                <Secret mode={mode} text="sk_live_9fA2kLm41xQpZ7vR" />
                {"\nDATABASE_URL=postgres://admin:"}
                <Secret mode={mode} text="hunter2-prod" />
                {"@db.example.com\nNotify: "}
                <Secret mode={mode} text="maria.lopez@example.com" />
                {"\nStatus: deployed in 38s"}
              </code>
            </pre>
          </div>
          <p className="text-sm text-white/50">
            A demo of the effect. In the app, the same patch is drawn into the image you copy or save.
          </p>
        </div>
      </div>
    </section>
  );
}
