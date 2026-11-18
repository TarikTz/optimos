import type { Metadata } from "next";
import Link from "next/link";
import LegalPage from "@/components/sections/LegalPage";
import { SITE } from "@/lib/site";

export const metadata: Metadata = {
  title: `Support | ${SITE.name}`,
  description: `Get help with ${SITE.name}: fix the Screen Recording permission, open the app for the first time, or contact the developer.`,
  alternates: { canonical: "/support" },
};

export default function SupportPage() {
  return (
    <LegalPage
      title="Support"
      intro={`Need help with ${SITE.name}? Start with the fixes below. If they do not solve it, write to the developer.`}
    >
      <section>
        <h2>Capture does not work</h2>
        <ul>
          <li>Open System Settings, go to Privacy &amp; Security, then Screen &amp; System Audio Recording, and turn on {SITE.name}.</li>
          <li>When macOS or the app asks, restart {SITE.name}. Capture works after one restart.</li>
          <li>If {SITE.name} is listed but still fails, remove it with the minus button, add it again and restart the app.</li>
        </ul>
      </section>

      <section>
        <h2>macOS blocks the app on first launch</h2>
        <p>
          The downloaded app is not notarized by Apple yet. Press Open Anyway in System Settings under Privacy &amp;
          Security, or follow the steps in the <Link href="/#install">Install section</Link>.
        </p>
      </section>

      <section>
        <h2>A shortcut does not respond</h2>
        <p>
          Another app may use the same keys. Open Preferences, choose Shortcuts and record a different combination.
        </p>
      </section>

      <section>
        <h2>Contact the developer</h2>
        <p>
          Email {SITE.author} at <a href={`mailto:${SITE.contactEmail}`}>{SITE.contactEmail}</a>. Please include your
          macOS version, the {SITE.name} version (shown in the About window) and what you did before the problem
          appeared. Do not send screenshots that contain private information.
        </p>
        {SITE.repoUrl && (
          <p>
            You can also report bugs or request features on <a href={`${SITE.repoUrl}/issues`}>GitHub</a>.
          </p>
        )}
      </section>
    </LegalPage>
  );
}
