// Capture the training page after 097 design-system restyle (Phase 6).
// Boots the Godot Web bundle in headless Chromium (SwiftShader), waits for __appReady,
// settles a couple of seconds so a sit cycle plays out, then screenshots at 390×844.
// Usage: env -u LD_LIBRARY_PATH node tools/web_capture_training.mjs <bundle-dir> [out-prefix]
import { createServer } from "node:http";
import { readFile, writeFile, mkdir } from "node:fs/promises";
import { extname, join, normalize } from "node:path";
import { chromium } from "playwright";

const bundleDir = process.argv[2];
const prefix    = process.argv[3] || ".screenshots/097-training";
if (!bundleDir) {
  console.error("usage: env -u LD_LIBRARY_PATH node tools/web_capture_training.mjs <bundle-dir> [out-prefix]");
  process.exit(2);
}

const MIME = {
  ".html": "text/html; charset=utf-8",
  ".js":   "text/javascript; charset=utf-8",
  ".wasm": "application/wasm",
  ".pck":  "application/octet-stream",
  ".json": "application/json",
  ".png":  "image/png",
  ".svg":  "image/svg+xml",
  ".ico":  "image/x-icon",
};

const server = createServer(async (req, res) => {
  try {
    let p = decodeURIComponent(new URL(req.url, "http://localhost").pathname);
    if (p === "/") p = "/index.html";
    const safe = normalize(p).replace(/^(\.\.[/\\])+/, "");
    const body = await readFile(join(bundleDir, safe));
    res.setHeader("Content-Type", MIME[extname(safe)] || "application/octet-stream");
    res.end(body);
  } catch { res.statusCode = 404; res.end("not found"); }
});
await new Promise((r) => server.listen(0, "127.0.0.1", r));
const { port } = server.address();
const url = `http://127.0.0.1:${port}/index.html`;

await mkdir(".screenshots", { recursive: true });

const browser = await chromium.launch({
  args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"],
});
const page = await browser.newPage({ viewport: { width: 390, height: 844 } });

try {
  console.log(`loading ${url} …`);
  await page.goto(url, { waitUntil: "load", timeout: 60000 });
  console.log("waiting for __appReady …");
  await page.waitForFunction("window.__appReady === true", { timeout: 120000 });
  // Settle so a full sit cycle plays out and the HUD is populated.
  console.log("settling 3 s …");
  await page.waitForTimeout(3000);
  const frame0 = await page.screenshot({ type: "png" });
  const path0 = `${prefix}-01.png`;
  await writeFile(path0, frame0);
  console.log(`saved ${path0}`);
  // Second frame ~2 s later to catch a different sit phase.
  await page.waitForTimeout(2000);
  const frame1 = await page.screenshot({ type: "png" });
  const path1 = `${prefix}-02.png`;
  await writeFile(path1, frame1);
  console.log(`saved ${path1}`);
} catch (e) {
  console.error(`capture failed: ${e.message}`);
} finally {
  await browser.close();
  server.close();
}
