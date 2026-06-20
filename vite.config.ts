import { defineConfig } from "vite";
import { VitePWA } from "vite-plugin-pwa";

export default defineConfig({
  // GitHub Pages serves project sites under /<repo>/. The Pages workflow builds
  // with BASE_PATH="/bra/"; local dev, tests, and the Capacitor wrap stay at "/".
  base: process.env.BASE_PATH ?? "/",
  test: {
    // Pure game-logic tests run under fast node; only the DOM-bearing UI layer
    // (panel factories, hud) opts into jsdom — keeps the core suite quick while
    // letting src/ui tests exercise real document/element APIs.
    environment: "node",
    environmentMatchGlobs: [["src/ui/**", "jsdom"]],
    include: ["src/**/*.test.ts"],
    // Compact "dot" output (one char per test) keeps test runs from flooding
    // terminal/agent context; failures are still printed in full. Override with
    // `vitest run --reporter=verbose` when you need the per-test breakdown.
    reporters: ["dot"],
  },
  plugins: [
    VitePWA({
      registerType: "autoUpdate",
      injectRegister: "auto",
      manifest: {
        name: "Bra! — Dog Training",
        short_name: "Bra!",
        description:
          "A 3D dog-training game — reward tricks with taps to build an unbreakable bond with your virtual pup.",
        theme_color: "#4cde80",
        background_color: "#7ec8f0",
        display: "standalone",
        orientation: "portrait",
        // Relative paths resolve against the manifest URL, so the same manifest
        // works at root ("/") and under a Pages subpath ("/bra/") without edits.
        start_url: ".",
        icons: [
          {
            src: "icon-192.png",
            sizes: "192x192",
            type: "image/png",
          },
          {
            src: "icon-512.png",
            sizes: "512x512",
            type: "image/png",
          },
          {
            src: "icon-512-maskable.png",
            sizes: "512x512",
            type: "image/png",
            purpose: "maskable",
          },
        ],
      },
      workbox: {
        globPatterns: ["**/*.{js,css,html,ico,png,svg,woff2}"],
      },
    }),
  ],
  build: {
    rollupOptions: {
      output: {
        manualChunks(id) {
          if (id.includes("@babylonjs")) return "babylon";
          if (id.includes("node_modules")) return "vendor";
        },
      },
    },
    // Babylon is a 3D engine; its chunk (~1.46 MB raw / 342 kB gzip) will always
    // exceed the 500 kB default. Raising the limit suppresses noise for this
    // known-large, separately cacheable chunk — not to hide app-code bloat.
    chunkSizeWarningLimit: 1500,
  },
});
