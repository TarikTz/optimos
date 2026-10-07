import { Button } from "@/components/ui/button";
import { ArrowUpRight } from "lucide-react";
import { SITE } from "@/lib/site";

const CTA = () => {
  return (
    <section>
      <div className="sm:py-20 py-8">
        <div className="max-w-7xl mx-auto sm:px-16 px-4">
          <div
            className="relative overflow-hidden min-h-96 flex items-center justify-center px-6 border border-border rounded-3xl before:absolute before:w-full before:h-4/5 before:bg-linear-to-r before:from-sky-100 before:from-15% before:via-white before:via-55% before:to-emerald-100 before:to-90% before:rounded-full before:top-24 before:blur-3xl before:-z-10 dark:before:from-sky-400/10 dark:before:from-40% dark:before:via-black dark:before:via-55% dark:before:to-amber-300/10 dark:before:to-60% dark:before:rounded-full dark:before:-z-10"
          >
            <div className="flex flex-col gap-6 items-center mx-auto animate-in fade-in slide-in-from-bottom-4 duration-1000">
              <div className="flex flex-col gap-3 items-center text-center">
                <h2 className="text-3xl md:text-5xl font-medium">
                  Make every image lighter
                </h2>
                <p className="max-w-2xl mx-auto">
                  Free, open source and private. Capture, mark up, optimize and share
                  from your menu bar.
                </p>
              </div>
              <Button render={<a href={SITE.downloadUrl} />} nativeButton={false} className="relative text-sm font-medium rounded-full h-12 p-1 ps-6 pe-14 group transition-all duration-500 hover:ps-14 hover:pe-6 w-fit overflow-hidden hover:bg-primary/80 cursor-pointer">
                <span className="relative z-10 transition-all duration-500">
                  Download for Mac
                </span>
                <div className="absolute right-1 w-10 h-10 bg-background text-foreground rounded-full flex items-center justify-center transition-all duration-500 group-hover:right-[calc(100%-44px)] group-hover:rotate-45">
                  <ArrowUpRight size={16} />
                </div>
              </Button>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default CTA;
