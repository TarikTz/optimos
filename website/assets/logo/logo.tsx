import Image from "next/image";
import { SITE } from "@/lib/site";

const Logo = ({ className }: { className?: string }) => (
  <div className={`flex items-center gap-2.5 ${className ?? ""}`}>
    <Image src="/icon.png" alt="" width={36} height={36} className="rounded-[10px]" />
    <span className="text-lg font-semibold tracking-tight">{SITE.name}</span>
  </div>
);

export default Logo;
