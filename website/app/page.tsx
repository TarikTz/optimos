import Header from "@/components/shadcn-space/blocks/hero-01/header";
import HeroSection from "@/components/shadcn-space/blocks/hero-01/hero";
import Features from "@/components/sections/Features";
import Editors from "@/components/sections/Editors";
import Install from "@/components/sections/Install";
import Faq from "@/components/shadcn-space/blocks/faq-01/faq";
import CTA from "@/components/shadcn-space/blocks/cta-01/cta";
import Footer from "@/components/sections/Footer";

const navigation = [
  { title: "Features", href: "#features" },
  { title: "For editors", href: "#editors" },
  { title: "Install", href: "#install" },
  { title: "FAQ", href: "#faq" },
];

export default function Home() {
  return (
    <div className="relative">
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
