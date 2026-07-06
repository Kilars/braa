// PO father-pass-7 full play-test drive. Boots the fresh local bundle, drives real taps,
// screenshots every persistent surface for a critical polish review.
// Usage: env -u LD_LIBRARY_PATH node tools/po_pass7_drive.mjs <bundle-dir>
import { createServer } from "node:http";
import { readFile, mkdir } from "node:fs/promises";
import { extname, join, normalize } from "node:path";
import { chromium } from "playwright";

const bundleDir = process.argv[2] || "build/web";
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
const base = `http://127.0.0.1:${port}/index.html`;
const W = 390, H = 844, GODOT_W = 720, GODOT_H = 1280;
await mkdir(".screenshots", { recursive: true });
const P = ".screenshots/PO8-";

const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport: { width: W, height: H } });
const errors = [];
page.on("console", m => { if (m.type() === "error") errors.push(m.text()); });

async function tapVp(x, y) {
  const box = await page.locator("canvas").boundingBox();
  const vp = await page.evaluate(() => window.__bra_viewport || null);
  const sx = box.width / (vp ? vp[0] : GODOT_W);
  const sy = box.height / (vp ? vp[1] : GODOT_H);
  await page.mouse.click(box.x + x * sx, box.y + y * sy);
}
async function shot(name) { await page.screenshot({ path: `${P}${name}.png` }); console.log("shot", name); }

let code = 1;
try {
  await page.goto(`${base}?bra_autotap=1`, { waitUntil: "load", timeout: 60000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  console.log("app ready");
  await page.waitForTimeout(1800);
  await shot("01-training-a");
  await page.waitForTimeout(1400);
  await shot("02-training-b");
  await page.waitForTimeout(1400);
  await shot("03-training-c");

  // Completion menu via the Triks pill (center ~84,32 in Godot coords).
  await tapVp(84, 32);
  await page.waitForTimeout(700);
  await shot("04-menu");
  // scroll attempt: tap lower to reveal more rows is not needed; capture as-is.

  // Close menu (tap the "Fortsett" area / backdrop). Try tapping bottom.
  await tapVp(360, 60);
  await page.waitForTimeout(500);

  // Kennel
  const kb = await page.evaluate(() => window.__bra_kennel_btn || {x:204,y:32});
  await tapVp(kb.x, kb.y);
  await page.waitForFunction("window.__bra_kennel_open === true", undefined, { timeout: 10000 }).catch(()=>{});
  await page.waitForTimeout(800);
  await shot("05-kennel-grid");
  // scroll the grid
  await page.mouse.move(W/2, H*0.6); await page.mouse.wheel(0, 500);
  await page.waitForTimeout(600);
  await shot("06-kennel-scroll");
  await page.mouse.wheel(0, -800); await page.waitForTimeout(500);

  const cells = await page.evaluate(() => window.__bra_kennel_cells || []);
  console.log("cells", cells.map(c=>c.id).join(","));
  // Modal for an owned (bella), an affordable/locked, and trulte easter egg
  for (const id of ["bella","nova","trulte"]) {
    const cell = cells.find(c => c.id === id);
    if (!cell) continue;
    await tapVp(cell.x, cell.y);
    await page.waitForTimeout(900);
    await shot(`07-modal-${id}`);
    await tapVp(40, 60);
    await page.waitForTimeout(500);
  }
  console.log("ERRORS:", errors.length ? errors.join(" | ") : "none");
  code = 0;
} catch (e) {
  console.error("drive FAILED:", e.message);
  await shot("FAIL");
} finally {
  await browser.close();
  server.close();
}
process.exit(code);
