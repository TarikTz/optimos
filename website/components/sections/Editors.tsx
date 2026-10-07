import { Badge } from "@/components/ui/badge";
import { FileImage, FolderOpen, Undo2, Lock } from "lucide-react";

const items = [
  { icon: FileImage, title: "Right size before you publish", text: "Cap the longest side at 1920 or 1280 px and keep the quality. Smaller images load faster and fit the CMS limit." },
  { icon: FolderOpen, title: "A whole folder at once", text: "Drop the day's photos and they are optimized together. Nothing to configure each time." },
  { icon: Undo2, title: "Safe by default", text: "A file is only replaced when the new one is smaller, and Undo brings every original back." },
  { icon: Lock, title: "Nothing leaves your Mac", text: "Images are processed on your computer. There is no account, no upload and no tracking." },
];

export default function Editors() {
  return (
    <section id="editors" className="scroll-mt-24 bg-muted/40">
      <div className="mx-auto max-w-7xl px-4 sm:px-8 py-20 flex flex-col gap-12">
        <div className="flex flex-col items-center gap-4 text-center">
          <Badge variant="outline" className="h-auto px-3 py-1 text-sm font-normal">For writers and editors</Badge>
          <h2 className="max-w-2xl text-3xl font-semibold md:text-4xl">Not just for developers</h2>
          <p className="max-w-2xl text-lg text-muted-foreground">
            If you prepare images for a newsroom, a blog or a shop, OptimosApp gets them ready without learning a tool.
          </p>
        </div>
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {items.map(({ icon: Icon, title, text }) => (
            <div key={title} className="flex flex-col gap-3 rounded-2xl border border-border bg-background p-6">
              <Icon className="text-primary" size={22} />
              <h3 className="text-lg font-medium">{title}</h3>
              <p className="text-sm text-muted-foreground">{text}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
