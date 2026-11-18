import type { ReactNode } from "react";
import { cn } from "@/lib/utils";

/** A pixelated patch, sized in characters so it can stand in for a piece of text. */
export function Mosaic({ chars, className }: { chars: number; className?: string }) {
  return (
    <span
      aria-hidden
      className={cn("mosaic inline-block h-[1.15em] rounded-[2px] align-text-bottom", className)}
      style={{ width: `${chars}ch` }}
    />
  );
}

/** Blurred text. Hidden from assistive tech so the secret is not read out. */
export function Blurred({ children, className }: { children: ReactNode; className?: string }) {
  return (
    <span aria-hidden className={cn("inline-block select-none blur-[5px]", className)}>
      {children}
    </span>
  );
}
