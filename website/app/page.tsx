import Header from "@/components/shadcn-space/blocks/hero-01/header";
import HeroSection from "@/components/shadcn-space/blocks/hero-01/hero";
import Features from "@/components/sections/Features";
import Editors from "@/components/sections/Editors";
import Install from "@/components/sections/Install";
import Faq, { FAQ_DATA } from "@/components/shadcn-space/blocks/faq-01/faq";
import CTA from "@/components/shadcn-space/blocks/cta-01/cta";
import Footer from "@/components/sections/Footer";
import { SITE } from "@/lib/site";

const navigation = [
  { title: "Features", href: "#features" },
  { title: "For editors", href: "#editors" },
  { title: "Install", href: "#install" },
  { title: "FAQ", href: "#faq" },
];

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
      <Header navigationData={navigation} />
      <main>
        <HeroSection />
        <Features />
        <Editors />
        <Install />
        <Faq />
        <CTA />
      </main>
      <Footer />
    </div>
  );
}
