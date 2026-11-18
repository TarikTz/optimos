import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from "@/components/ui/accordion";
import { Plus } from "lucide-react";
import { FAQ_DATA } from "@/lib/faq";

export default function Faq() {
  return (
    <section id="faq" className="scroll-mt-16 border-t border-steel">
      <div className="mx-auto grid max-w-7xl gap-12 px-4 py-20 sm:px-8 lg:grid-cols-[1fr_1.6fr] lg:py-28">
        <h2 className="display-section text-ink">Questions, answered</h2>
        <Accordion className="flex w-full flex-col">
          {FAQ_DATA.map((faq, i) => (
            <AccordionItem key={faq.question} value={`item-${i}`} className="group/item flex flex-col gap-3 border-b border-steel py-6 first:pt-0">
              <AccordionTrigger className="cursor-pointer p-0 text-lg font-medium text-ink hover:no-underline **:data-[slot=accordion-trigger-icon]:hidden">
                {faq.question}
                <Plus className="size-5 shrink-0 text-slate transition-transform duration-200 group-aria-expanded/accordion-trigger:rotate-45" aria-hidden />
              </AccordionTrigger>
              <AccordionContent className="p-0 text-base leading-relaxed text-slate">{faq.answer}</AccordionContent>
            </AccordionItem>
          ))}
        </Accordion>
      </div>
    </section>
  );
}
