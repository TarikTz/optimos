import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // `pnpm build` writes a plain static site to `out/`, ready for any static host.
  output: "export",
  images: { unoptimized: true },
  turbopack: {
    rules: {
      "*.css": {
        loaders: ["@tailwindcss/turbopack"],
        as: "*.css",
      },
    },
  },
};

export default nextConfig;
