import { SITE } from "@/lib/site";

/** Site-wide notice above the header. */
export default function Announcement() {
  return (
    <div className="bg-lime-notice px-4 py-2 text-center text-sm font-medium text-ink/80">
      OptimosApp for Windows is in development.{" "}
      {SITE.repoUrl ? (
        <a className="underline underline-offset-4 hover:text-ink" href={SITE.repoUrl}>
          Follow the project on GitHub
        </a>
      ) : null}
    </div>
  );
}
