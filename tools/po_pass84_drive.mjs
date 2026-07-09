// PO father-pass-84 play-test drive. Boots the fresh local bundle, drives real taps,
// screenshots every persistent surface, and (for task-206 verification) grabs a high-res
// kennel grid + a zoomed crop of a corner badge for in-pixel contrast sampling.
// Usage: env -u LD_LIBRARY_PATH node tools/po_pass84_drive.mjs <bundle-dir>
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
const P = ".screenshots/PO84-";

const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport: { width: W, height: H }, deviceScaleFactor: 3 });
const errors = [];
page.on("console", m => { if (m.type() === "error") errors.push(m.text()); });

async function tapVp(x, y) {
  const box = await page.locator("canvas").boundingBox();
  const vp = await page.evaluate(() => window.__bra_viewport || null);
  const sx = box.width / (vp ? vp[0] : GODOT_W);
  const sy = box.height / (vp ? vp[1] : GODOT_H);
  await page.mouse.click(box.x + x * sx, box.y + y * sy);
}
async function shot(name, clip) { await page.screenshot({ path: `${P}${name}.png`, clip }); console.log("shot", name); }

let code = 1;
try {
  await page.goto(`${base}?bra_autotap=1`, { waitUntil: "load", timeout: 60000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  console.log("app ready");
  await page.waitForTimeout(1800);
  await shot("01-training");

  await tapVp(84, 32);
  await page.waitForTimeout(700);
  await shot("02-menu");
  await tapVp(360, 60);
  await page.waitForTimeout(500);

  const kb = await page.evaluate(() => window.__bra_kennel_btn || {x:204,y:32});
  await tapVp(kb.x, kb.y);
  await page.waitForFunction("window.__bra_kennel_open === true", undefined, { timeout: 10000 }).catch(()=>{});
  await page.waitForTimeout(900);
  await shot("03-kennel-grid");

  const cells = await page.evaluate(() => window.__bra_kennel_cells || []);
  console.log("cells", JSON.stringify(cells));
  for (const id of ["bella","nova","balder","trulte"]) {
    const cell = cells.find(c => c.id === id);
    if (!cell) continue;
    await tapVp(cell.x, cell.y);
    await page.waitForTimeout(900);
    await shot(`04-modal-${id}`);
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
