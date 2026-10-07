"use client";

import { Instrument_Serif } from "next/font/google";
import { Button } from "@/components/ui/button";
import { motion } from "motion/react";
import { ArrowUpRight } from "lucide-react";
import { SITE } from "@/lib/site";
import { CaptureMockup } from "@/components/mockups/CaptureMockup";

const instrumentSerif = Instrument_Serif({ subsets: ["latin"], weight: ["400"], style: ["italic"] });

export default function HeroSection() {
  return (
    <section id="top">
      <div className="relative w-full pt-0 md:pt-16 pb-6 md:pb-10 before:absolute before:w-full before:h-full before:bg-linear-to-r before:from-sky-100 before:via-white before:to-emerald-100 before:rounded-full before:top-24 before:blur-3xl before:-z-10 dark:before:from-slate-800 dark:before:via-black dark:before:to-teal-950">
        <div className="container mx-auto relative z-10 px-4">
          <div className="flex flex-col max-w-5xl mx-auto gap-10">
            <div className="relative flex flex-col text-center items-center sm:gap-6 gap-4">
              <motion.h1
                initial={{ opacity: 0, y: 32 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 1, ease: "easeInOut" }}
                className="lg:text-8xl md:text-7xl text-5xl font-medium leading-[1.05]"
              >
                Capture. Optimize.{" "}
                <span className={`${instrumentSerif.className} tracking-tight`}>Convert.</span>
              </motion.h1>
              <motion.p
                initial={{ opacity: 0, y: 32 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 1, delay: 0.1, ease: "easeInOut" }}
                className="text-lg font-normal max-w-2xl text-muted-foreground"
              >
                Screenshots in one shortcut, marked up and shrunk before they leave your Mac. Drop in any image
                to make it smaller or turn it into WebP. Free and open source.
              </motion.p>
            </div>
            <motion.div
              initial={{ opacity: 0, y: 32 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 1, delay: 0.2, ease: "easeInOut" }}
              className="flex items-center flex-col gap-3"
            >
              <Button
                render={<a href={SITE.downloadUrl} />}
                nativeButton={false}
                className="relative text-sm font-medium rounded-full h-12 p-1 ps-6 pe-14 group transition-all duration-500 hover:ps-14 hover:pe-6 w-fit overflow-hidden cursor-pointer"
              >
                <span className="relative z-10 transition-all duration-500">Download for Mac</span>
                <span className="absolute right-1 w-10 h-10 bg-background text-foreground rounded-full flex items-center justify-center transition-all duration-500 group-hover:right-[calc(100%-44px)] group-hover:rotate-45">
                  <ArrowUpRight size={16} />
                </span>
              </Button>
              <p className="text-sm text-muted-foreground">
                Version {SITE.version} · {SITE.requirements} · Free, MIT license
              </p>
            </motion.div>
            <motion.div
              initial={{ opacity: 0, y: 48 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 1, delay: 0.35, ease: "easeInOut" }}
            >
              <CaptureMockup annotated />
            </motion.div>
          </div>
        </div>
      </div>
    </section>
  );
}
