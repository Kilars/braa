/// <reference types="vitest/config" />
import { defineConfig } from "vitest/config";

// Base is relative ("./") so the build also works under a GitHub Pages
// project sub-path (ADR-0005). Vitest runs in the node environment by
// default; UI/DOM-specific suites opt into jsdom per-file when needed.
export default defineConfig({
  base: "./",
  build: {
    target: "es2022",
    // Babylon's engine is a large single dependency; the dog scene pulls it in
    // as one ~5 MB chunk (root-import for registration safety). Raise the limit
    // so `bun run build` stays warning-free (task 003 / tech-decisions §1); the
    // bundle is cached once for offline play (X-7). Trimming it via targeted
    // `@babylonjs/core/...` deep imports is a tracked follow-up (task 003 notes).
    chunkSizeWarningLimit: 6000,
  },
  test: {
    globals: true,
    environment: "node",
    include: ["src/**/*.test.ts"],
  },
});
