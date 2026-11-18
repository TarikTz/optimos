import type { ReactNode } from "react";
import Announcement from "@/components/sections/Announcement";
import Header from "@/components/sections/Header";
import Footer from "@/components/sections/Footer";

/** Shared frame for the plain text pages (privacy policy, support). */
export default function LegalPage({ title, intro, children }: { title: string; intro: string; children: ReactNode }) {
  return (
    <div className="relative">
      <Announcement />
      <Header />
      <main className="mx-auto max-w-3xl px-4 py-16 sm:px-8 lg:py-24">
        <h1 className="display-section text-ink">{title}</h1>
        <p className="mt-5 text-lg leading-relaxed text-slate">{intro}</p>
        <div className="mt-12 flex flex-col gap-10 text-base leading-relaxed text-charcoal [&_a]:underline [&_a]:underline-offset-4 [&_a:hover]:text-ink [&_h2]:feature-heading [&_h2]:text-ink [&_ul]:flex [&_ul]:list-disc [&_ul]:flex-col [&_ul]:gap-2 [&_ul]:pl-5 [&_section]:flex [&_section]:flex-col [&_section]:gap-3">
          {children}
        </div>
      </main>
      <Footer />
    </div>
  );
}
