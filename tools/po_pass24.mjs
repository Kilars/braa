// PO father pass 24 — verify 159 (opaque learned-bar panel) + hunt for improvements.
// Serves build/web over http, drives at 390x844 dsf3, captures HUD/menu/kennel.
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
const W = 390, H = 844;
await mkdir(".screenshots", { recursive: true });
const P = ".screenshots/P24-";

const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport: { width: W, height: H }, deviceScaleFactor: 3 });
const errors = [];
page.on("console", m => { if (m.type() === "error") errors.push(m.text()); });
async function tapVp(x, y) {
  const box = await page.locator("canvas").boundingBox();
  const vp = await page.evaluate(() => window.__bra_viewport || null);
  await page.mouse.click(box.x + x * box.width / (vp ? vp[0] : 720), box.y + y * box.height / (vp ? vp[1] : 1280));
}

let code = 1;
try {
  // ---- training page (autotap so bar fills) ----
  await page.goto(`${base}?bra_autotap=1`, { waitUntil: "load", timeout: 90000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  console.log("app ready; trick:", await page.evaluate(() => window.__bra_current_trick ?? null),
    "balance:", await page.evaluate(() => window.__bra_balance ?? null));
  await page.waitForTimeout(4200);
  await page.screenshot({ path: `${P}01-training.png` });
  await page.screenshot({ path: `${P}01b-hud.png`, clip: { x: 0, y: 55, width: W, height: 95 } });

  // ---- completion / trick menu ----
  await tapVp(70, 32);
  await page.waitForTimeout(1200);
  console.log("menu_open:", await page.evaluate(() => window.__bra_menu_open ?? null));
  await page.screenshot({ path: `${P}02-menu.png` });
  await tapVp(70, 32); // close
  await page.waitForTimeout(800);

  // ---- kennel grid ----
  const kb = await page.evaluate(() => window.__bra_kennel_btn || null);
  console.log("kennel_btn:", JSON.stringify(kb));
  if (kb) await tapVp(kb.x, kb.y);
  await page.waitForTimeout(1800);
  await page.screenshot({ path: `${P}03-kennel-grid.png` });
  const cells = await page.evaluate(() => window.__bra_kennel_cells ?? null);
  console.log("kennel_cells:", cells ? cells.length : null);

  // Nova (idx1) unaffordable modal
  if (cells && cells[1]) await tapVp(cells[1].x ?? cells[1][0], cells[1].y ?? cells[1][1]);
  await page.waitForTimeout(1400);
  await page.screenshot({ path: `${P}04-modal-nova.png` });
  await tapVp(360, 60);
  await page.waitForTimeout(700);

  // Bella (idx0) owned modal
  if (cells && cells[0]) await tapVp(cells[0].x ?? cells[0][0], cells[0].y ?? cells[0][1]);
  await page.waitForTimeout(1400);
  await page.screenshot({ path: `${P}05-modal-bella.png` });

  console.log("console errors:", errors.length ? errors : "none");
  code = errors.length ? 1 : 0;
} catch (e) { console.error("FAIL", e); code = 1; }
finally { await browser.close(); server.close(); process.exit(code); }
