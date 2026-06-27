import { defineConfig, devices } from "@playwright/test";

// Phone-portrait only (spec X-1): a 390×844 viewport, the Visual Review
// reference size (P1-10). We drive the system Google Chrome via the
// `chrome` channel so no browser download is needed in CI/sandbox.
const PORT = 4317;

// The build sandbox sets LD_LIBRARY_PATH to a nix alsa-lib path that drags in
// a mismatched nix glibc, which makes Chrome fail to launch
// (`GLIBC_ABI_DT_X86_64_PLT not found`). Hand the browser a copy of the env
// with that one variable stripped; node/vite keep the original env untouched.
const browserEnv: Record<string, string> = {};
for (const [key, value] of Object.entries(process.env)) {
  if (key === "LD_LIBRARY_PATH") continue;
  if (value !== undefined) browserEnv[key] = value;
}

export default defineConfig({
  testDir: "./e2e",
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: 0,
  reporter: [["list"]],
  use: {
    baseURL: `http://localhost:${PORT}`,
    viewport: { width: 390, height: 844 },
    trace: "off",
    launchOptions: { env: browserEnv },
  },
  projects: [
    {
      name: "chromium",
      use: {
        ...devices["Desktop Chrome"],
        channel: "chrome",
        viewport: { width: 390, height: 844 },
      },
    },
  ],
  webServer: {
    // Dev server so `bun run e2e` is order-independent (no prior build needed).
    command: `vite --port ${PORT} --strictPort`,
    port: PORT,
    reuseExistingServer: !process.env.CI,
    timeout: 120_000,
  },
});
