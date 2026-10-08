"use client";

import { useState } from "react";
import { CopyButton } from "@/components/interior/copy-button";
import { SegmentedControl } from "@/components/interior/segmented-control";

const COMMAND = "xattr -dr com.apple.quarantine /Applications/OptimosApp.app";

const methods = [
  { value: "terminal", label: "Terminal" },
  { value: "settings", label: "System Settings" },
];

/** The two ways to approve a first launch of an app that Apple has not notarized. */
export default function FirstLaunch() {
  const [method, setMethod] = useState("terminal");

  return (
    <div className="flex flex-col items-center gap-5 rounded-2xl border border-border p-6">
      <div className="flex flex-col items-center gap-1 text-center">
        <h3 className="font-medium">Approve the first launch</h3>
        <p className="text-sm text-muted-foreground">Pick whichever you prefer. You only do this once.</p>
      </div>
      <SegmentedControl label="How to approve the first launch" options={methods} value={method} onValueChange={setMethod} />

      {method === "terminal" ? (
        <div className="flex w-full max-w-2xl flex-col gap-3">
          <p className="text-sm text-muted-foreground">
            Open Terminal, paste this line and press Return. Then open OptimosApp as usual.
          </p>
          <div className="flex items-center justify-between gap-3 rounded-xl bg-muted p-3 pl-4">
            <code className="min-w-0 overflow-x-auto whitespace-nowrap text-sm">{COMMAND}</code>
            <CopyButton value={COMMAND} label="Copy" copiedLabel="Copied" />
          </div>
        </div>
      ) : (
        <ol className="flex w-full max-w-2xl list-decimal flex-col gap-2 pl-5 text-sm text-muted-foreground marker:text-foreground">
          <li>Open OptimosApp and close the warning macOS shows.</li>
          <li>Open System Settings and go to Privacy &amp; Security.</li>
          <li>Scroll down and press <strong className="text-foreground">Open Anyway</strong> next to OptimosApp.</li>
          <li>Confirm with your password or Touch ID, then open the app again.</li>
        </ol>
      )}
    </div>
  );
}
