import type { Metadata } from "next";
import LegalPage from "@/components/sections/LegalPage";
import { SITE } from "@/lib/site";

export const metadata: Metadata = {
  title: `Privacy policy | ${SITE.name}`,
  description: `${SITE.name} does not collect, upload or share your data. This page explains what the app and this website do and do not do.`,
  alternates: { canonical: "/privacy" },
};

export default function PrivacyPage() {
  return (
    <LegalPage
      title="Privacy policy"
      intro={`${SITE.name} does not collect your data. This page explains what the app and this website do with information, in plain language. Last updated 18 November 2026.`}
    >
      <section>
        <h2>The short version</h2>
        <ul>
          <li>No account, no analytics, no advertising and no tracking, in the app or on this website.</li>
          <li>The app never connects to the internet. Your screenshots and images are processed on your Mac and are never uploaded.</li>
          <li>The developer receives no personal data from the app.</li>
        </ul>
      </section>

      <section>
        <h2>What the app does with your content</h2>
        <p>
          {SITE.name} captures the screen only when you press a capture shortcut. It needs the Screen Recording
          permission in macOS to do this, and uses it for nothing else. Captured images and any images you drop into
          the Optimize Images window are processed on your Mac. Results go to the clipboard, to the folder you choose,
          or to the app you pick in the macOS share menu. What that app does with the image is covered by its own
          privacy policy.
        </p>
        <p>
          Pixelate and blur are applied to the image itself, so the hidden detail is not stored in the saved or copied
          file.
        </p>
      </section>

      <section>
        <h2>What is stored on your Mac</h2>
        <ul>
          <li>Your preferences: shortcuts, default format and size, optimization level and the save folder you chose. They are kept in the standard macOS preferences for the app.</li>
          <li>Temporary copies of images you optimize, so that Undo can restore the originals. They are kept in your Mac&apos;s temporary folder.</li>
          <li>Saved optimization presets, in the app&apos;s Application Support folder.</li>
        </ul>
        <p>This information stays on your Mac. Removing the app and its preferences removes it.</p>
      </section>

      <section>
        <h2>This website</h2>
        <p>
          The website is a static page. It sets no cookies, runs no analytics or advertising scripts, and loads no
          third-party fonts or resources. Like any web server, the server that hosts it keeps standard access logs
          (IP address, time and page requested) for security and troubleshooting. They are not used to profile or
          identify visitors.
        </p>
      </section>

      <section>
        <h2>Downloads</h2>
        <p>
          The Mac app is downloaded from GitHub Releases, which processes download requests under the{" "}
          <a href="https://docs.github.com/en/site-policy/privacy-policies/github-general-privacy-statement">GitHub privacy statement</a>.
          If you get the app from the Mac App Store, Apple handles the download under its own privacy policy, and the
          developer sees only the aggregate statistics Apple provides.
        </p>
      </section>

      <section>
        <h2>Children</h2>
        <p>The app and the website collect no personal information from anyone, including children.</p>
      </section>

      <section>
        <h2>Changes to this policy</h2>
        <p>If the app or the website ever handles data differently, this page will be updated first and the date above will change.</p>
      </section>

      <section>
        <h2>Contact</h2>
        <p>
          Questions about privacy? Email {SITE.author} at <a href={`mailto:${SITE.contactEmail}`}>{SITE.contactEmail}</a>.
        </p>
      </section>
    </LegalPage>
  );
}
