import Announcement from "@/components/sections/Announcement";
import Header from "@/components/sections/Header";
import Hero from "@/components/sections/Hero";
import Features, { FEATURES } from "@/components/sections/Features";
import Redaction from "@/components/sections/Redaction";
import Audience from "@/components/sections/Audience";
import Install from "@/components/sections/Install";
import Faq from "@/components/sections/Faq";
import Cta from "@/components/sections/Cta";
import Footer from "@/components/sections/Footer";
import { FAQ_DATA } from "@/lib/faq";
import { SITE } from "@/lib/site";

const structuredData = {
  "@context": "https://schema.org",
  "@graph": [
    {
      "@type": "SoftwareApplication",
      name: SITE.name,
      description: SITE.description,
      url: SITE.url,
      applicationCategory: "MultimediaApplication",
      operatingSystem: "macOS 26 or later",
      softwareVersion: SITE.version,
      downloadUrl: SITE.downloadUrl,
      image: `${SITE.url}/og.png`,
      license: "https://opensource.org/license/mit",
      isAccessibleForFree: true,
      offers: { "@type": "Offer", price: "0", priceCurrency: "USD" },
      author: { "@type": "Person", name: SITE.author },
    },
    {
      "@type": "FAQPage",
      mainEntity: FAQ_DATA.map((f) => ({
        "@type": "Question",
        name: f.question,
        acceptedAnswer: { "@type": "Answer", text: f.answer },
      })),
    },
  ],
};

export default function Home() {
  return (
    <div className="relative">
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(structuredData) }} />
      <Announcement />
      <Header />
      <main>
        <Hero />
        <Features id="features" items={FEATURES.slice(0, 2)} />
        <Redaction />
        <Features items={FEATURES.slice(2)} />
        <Audience />
        <Install />
        <Faq />
        <Cta />
      </main>
      <Footer />
    </div>
  );
}
