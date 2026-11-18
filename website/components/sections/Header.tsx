"use client";

import { useState } from "react";
import Link from "next/link";
import { Menu, X } from "lucide-react";
import Logo from "@/assets/logo/logo";
import { SITE } from "@/lib/site";

const NAV = [
  { title: "Features", href: "/#features" },
  { title: "Hide sensitive info", href: "/#redaction" },
  { title: "Who it's for", href: "/#audience" },
  { title: "Install", href: "/#install" },
  { title: "FAQ", href: "/#faq" },
];

const downloadButton =
  "inline-flex items-center rounded-xl bg-graphite px-4 py-2 text-sm font-medium text-white shadow-inset-edge transition-colors hover:bg-ink";

export default function Header() {
  const [open, setOpen] = useState(false);

  return (
    <header className="sticky top-0 z-50 border-b border-steel bg-paper/95 backdrop-blur">
      <div className="mx-auto flex h-16 max-w-7xl items-center justify-between gap-6 px-4 sm:px-8">
        <Link href="/" aria-label={`${SITE.name} home`} className="rounded-sm">
          <Logo />
        </Link>

        <nav aria-label="Main" className="hidden items-center gap-6 lg:flex">
          {NAV.map((item) => (
            <a key={item.href} href={item.href} className="rounded-sm text-sm font-medium text-slate transition-colors hover:text-ink">
              {item.title}
            </a>
          ))}
        </nav>

        <div className="flex items-center gap-3">
          <a href={SITE.downloadUrl} className={`${downloadButton} max-sm:hidden`}>
            Download for Mac
          </a>
          <button
            type="button"
            className="rounded-xl border border-steel p-2 lg:hidden"
            aria-expanded={open}
            aria-controls="mobile-menu"
            aria-label={open ? "Close menu" : "Open menu"}
            onClick={() => setOpen((v) => !v)}
          >
            {open ? <X size={18} /> : <Menu size={18} />}
          </button>
        </div>
      </div>

      {open && (
        <nav id="mobile-menu" aria-label="Main" className="border-t border-steel bg-paper px-4 pb-6 pt-2 lg:hidden">
          <ul className="flex flex-col">
            {NAV.map((item) => (
              <li key={item.href}>
                <a href={item.href} onClick={() => setOpen(false)} className="block border-b border-steel/60 py-3 text-base font-medium text-ink">
                  {item.title}
                </a>
              </li>
            ))}
          </ul>
          <a href={SITE.downloadUrl} className={`${downloadButton} mt-5 w-full justify-center`}>
            Download for Mac
          </a>
        </nav>
      )}
    </header>
  );
}
