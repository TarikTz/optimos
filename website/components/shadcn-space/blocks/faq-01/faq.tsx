import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from "@/components/ui/accordion";
import { Badge } from "@/components/ui/badge";
import { PlusIcon } from "lucide-react";
import { cn } from "@/lib/utils";

export const FAQ_DATA = [
  {
    question: "Is OptimosApp really free?",
    answer:
      "Yes. It is open source under the MIT license: free to use, change and share. There is no account, subscription or ad.",
  },
  {
    question: "Does it upload my screenshots or images?",
    answer:
      "No. Capturing, marking up, optimizing and converting all happen on your Mac. Nothing is sent anywhere, and the app has no tracking.",
  },
  {
    question: "Why does macOS warn me the first time I open it?",
    answer:
      "The app is not signed and notarized with an Apple Developer account yet. Run the one line in the Install section, or press Open Anyway in System Settings > Privacy & Security, and it opens normally from then on.",
  },
  {
    question: "What does it need to run?",
    answer:
      "A Mac with Apple silicon running macOS 26 or later. The optimizer tools are built in, so there is nothing else to install.",
  },
  {
    question: "Will it overwrite my original images?",
    answer:
      "When you optimize a file without changing its format, it is replaced, but only if the new file is smaller, and Undo restores the originals until you close the window. Converting to another format always writes a new file and keeps the original. In Preferences you can choose to save copies instead.",
  },
  {
    question: "Which formats does it support?",
    answer:
      "PNG, JPEG and WebP for optimizing and converting. More formats such as HEIC are planned.",
  },
];

export default function Faq() {
  return (
    <section id="faq" className="scroll-mt-24">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 xl:py-24 py-8 flex flex-col gap-16">
        <div className="flex flex-col gap-4 items-center animate-in fade-in slide-in-from-top-10 duration-1000 delay-100 ease-in-out fill-mode-both">
          <Badge
            variant="outline"
            className="text-sm h-auto py-1 px-3 border-0 outline outline-border"
          >
            FAQ
          </Badge>
          <h2 className="text-5xl font-medium text-center max-w-lg">
            Questions, answered
          </h2>
        </div>
        <div>
          <Accordion className="w-full flex flex-col gap-6">
            {FAQ_DATA.map((faq, index) => (
              <AccordionItem
                key={`item-${index}`}
                value={`item-${index}`}
                className={cn(
                  "p-6 border border-border rounded-2xl flex flex-col gap-3 group/item data-[open]:bg-accent transition-colors animate-in fade-in slide-in-from-bottom-8 duration-700 fill-mode-both",
                  index === 0 && "delay-100",
                  index === 1 && "delay-200",
                  index === 2 && "delay-300",
                  index === 3 && "delay-400",
                  index === 4 && "delay-500",
                  index === 5 && "delay-500",
                )}
              >
                <AccordionTrigger className="p-0 text-xl font-medium hover:no-underline **:data-[slot=accordion-trigger-icon]:hidden cursor-pointer">
                  {faq.question}
                  <PlusIcon className="w-6 h-6 shrink-0 transition-transform duration-200 group-aria-expanded/accordion-trigger:rotate-45" />
                </AccordionTrigger>
                <AccordionContent className="p-0 text-muted-foreground text-base">
                  {faq.answer}
                </AccordionContent>
              </AccordionItem>
            ))}
          </Accordion>
        </div>
      </div>
    </section>
  );
}
