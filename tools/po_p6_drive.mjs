// PO Phase-6 play-test driver. Boots the real Godot Web bundle at 390×844 (SwiftShader),
// captures: (A) idle training-page composition, (B) a dense mark burst under ?bra_autotap=1
// to catch the word pop + BRA button + PERFECT verdict, (C) the completion menu on mastery.
// Usage: env -u LD_LIBRARY_PATH node tools/po_p6_drive.mjs <bundle-dir>
import { createServer } from "node:http";
import { readFile, mkdir } from "node:fs/promises";
import { extname, join, normalize } from "node:path";
import { chromium } from "playwright";

const bundleDir = process.argv[2];
if (!bundleDir) { console.error("usage: po_p6_drive.mjs <bundle-dir>"); process.exit(2); }

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

// ---- Pass A: idle composition (no autotap), let a sit cycle settle ----
{
  const page = await browser.newPage({ viewport: { width: W, height: H } });
  const errs = [];
  page.on("console", (m) => { if (m.type() === "error") errs.push(m.text()); });
  await page.goto(`http://127.0.0.1:${port}/index.html`, { waitUntil: "load", timeout: 60000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  for (const [label, wait] of [["idle-a", 2500], ["idle-b", 2500], ["idle-c", 2500]]) {
    await page.waitForTimeout(wait);
    await page.screenshot({ path: `.screenshots/po-p6-${label}.png` });
    console.log(`saved po-p6-${label}.png`);
  }
  console.log(`pass A console errors: ${errs.length}${errs.length ? " :: " + errs.join(" | ") : ""}`);
  await page.close();
}

// ---- Pass B: dense mark burst to catch the word pop, + menu on mastery ----
{
  const page = await browser.newPage({ viewport: { width: W, height: H } });
  const errs = [];
  page.on("console", (m) => { if (m.type() === "error") errs.push(m.text()); });
  await page.goto(`http://127.0.0.1:${port}/index.html?bra_autotap=1`, { waitUntil: "load", timeout: 60000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  // Dense burst: 30 frames × 250ms = 7.5s, catches several autotapped marks + word pops.
  for (let i = 0; i < 30; i++) {
    await page.waitForTimeout(250);
    const n = String(i).padStart(2, "0");
    await page.screenshot({ path: `.screenshots/po-p6-mark-${n}.png` });
  }
  console.log("saved po-p6-mark-00..29");
  // Wait for mastery → completion menu.
  try {
    await page.waitForFunction("window.__bra_menu_open === true", undefined, { timeout: 60000 });
    await page.waitForTimeout(500);
    await page.screenshot({ path: `.screenshots/po-p6-menu.png` });
    const active = await page.evaluate("window.__bra_current_trick");
    console.log(`saved po-p6-menu.png (mastered active trick = ${active})`);
  } catch (e) {
    console.log(`menu did not open: ${e.message}`);
  }
  console.log(`pass B console errors: ${errs.length}${errs.length ? " :: " + errs.join(" | ") : ""}`);
  await page.close();
}

await browser.close();
server.close();
console.log("done");
