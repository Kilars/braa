// PO play-test capture (2026-07-05, Phase-10 pass): training-page finish + completion menu.
// Boots the real Godot Web bundle in headless Chromium at 390×844.
//   1) training page: a burst of frames across a sit cycle to catch the approach/apex ring
//      near the BRA button (dir #1), the grass coins (dir #2), sun/bloom wash (dir #3),
//      BRA button colour (dir #4), top HUD legibility (dir #5).
//   2) ?bra_autotap=1: waits for the completion menu and screenshots it (dir #6 menu overload).
// Usage: env -u LD_LIBRARY_PATH node tools/po_phase10_review.mjs <bundle-dir>
import { createServer } from "node:http";
import { readFile, mkdir, writeFile } from "node:fs/promises";
import { extname, join, normalize } from "node:path";
import { chromium } from "playwright";

const bundleDir = process.argv[2];
if (!bundleDir) { console.error("usage: po_phase10_review.mjs <bundle-dir>"); process.exit(2); }

const MIME = { ".html": "text/html; charset=utf-8", ".js": "text/javascript; charset=utf-8",
  ".wasm": "application/wasm", ".pck": "application/octet-stream", ".json": "application/json",
  ".png": "image/png", ".svg": "image/svg+xml", ".ico": "image/x-icon" };
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
const W = 390, H = 844;

await mkdir(".screenshots", { recursive: true });
const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });

// ---- Pass 1: training page, burst of frames to catch the ring animation.
{
  const page = await browser.newPage({ viewport: { width: W, height: H } });
  await page.goto(`http://127.0.0.1:${port}/index.html`, { waitUntil: "load", timeout: 60000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  await page.waitForTimeout(2500);
  for (let i = 0; i < 14; i++) {
    await page.screenshot({ path: `.screenshots/PO10-train-${String(i).padStart(2,"0")}.png` });
    await page.waitForTimeout(500);
  }
  console.log("training burst: 14 frames PO10-train-00..13");
  await page.close();
}

// ---- Pass 2: completion menu via autotap mastery.
{
  const page = await browser.newPage({ viewport: { width: W, height: H } });
  let ok = false;
  try {
    await page.goto(`http://127.0.0.1:${port}/index.html?bra_autotap=1`, { waitUntil: "load", timeout: 60000 });
    await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
    await page.waitForFunction("window.__bra_menu_open === true", undefined, { timeout: 120000 });
    await page.waitForTimeout(500);
    await page.screenshot({ path: ".screenshots/PO10-menu.png" });
    // full-page tall grab too, in case the menu scrolls
    await page.screenshot({ path: ".screenshots/PO10-menu-full.png", fullPage: true });
    console.log("completion menu captured PO10-menu.png");
    ok = true;
  } catch (e) {
    console.error(`menu capture failed: ${e.message}`);
    await page.screenshot({ path: ".screenshots/PO10-menu-FAIL.png" }).catch(()=>{});
  }
  await page.close();
  if (!ok) console.error("NOTE: menu pass failed (may need licensed Sitt-capable bundle)");
}

await browser.close();
server.close();
console.log("done");
