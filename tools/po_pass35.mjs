// PO father pass 35 — verify task 169 (breed-showcase hint caption «Bla med pilene …» now
// clears WCAG AA over the bright-grass view; SUBTLE white 0.78→0.92). Re-play training +
// completion menu + kennel for regressions, and tight-crop the showcase hint caption so the
// contrast can be judged pixel-for-pixel over the default (bright-grass) active view.
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
const P = ".screenshots/P35-";
const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport: { width: W, height: H }, deviceScaleFactor: 3 });
const errors = [];
page.on("console", m => { if (m.type() === "error") errors.push(m.text()); });
async function tapVp(x, y) {
  const box = await page.locator("canvas").boundingBox();
  const vp = await page.evaluate(() => window.__bra_viewport || null);
  await page.mouse.click(box.x + x * box.width / (vp ? vp[0] : 720), box.y + y * box.height / (vp ? vp[1] : 1280));
}
const dump = async (k) => JSON.stringify(await page.evaluate(new Function("return window.__bra_" + k + " ?? null")));
let code = 1;
try {
  await page.goto(`${base}?bra_autotap=1&bra_coins=120`, { waitUntil: "load", timeout: 90000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  await page.waitForTimeout(6000);
  await page.screenshot({ path: `${P}01-training.png` });

  // completion menu
  await tapVp(70, 32);
  await page.waitForTimeout(1500);
  await page.screenshot({ path: `${P}02-menu.png` });

  // adopt 2nd dog so the showcase has 2 pips → HINT_MULTI is shown
  const br = JSON.parse(await dump("breed_rows"));
  const buy = br.find(r => r.id === "chocolate_labrador");
  if (buy) { await tapVp(buy.x, buy.y); await page.waitForTimeout(1400); }
  console.log("balance after adopt", await dump("balance"), "owned", await dump("owned"));

  // open showcase (spotlights active labrador first — the bright-grass default view)
  const br2 = JSON.parse(await dump("breed_rows"));
  const last = br2[br2.length - 1];
  await tapVp(last.x, last.y + 62);
  await page.waitForTimeout(1600);
  console.log("showcase spotlit", await dump("showcase_spotlit"));
  await page.screenshot({ path: `${P}03-showcase-active.png` });
  // tight crop of the hint caption band: viewport y ~ [700,748] → device px ×3
  await page.screenshot({ path: `${P}03h-hint.png`, clip: { x: 0, y: 700, width: W, height: 52 } });

  // sample the hint glyph vs band pixels for a contrast read
  const probe = await page.evaluate(() => {
    const c = document.querySelector("canvas");
    const g = c.getContext("2d") || c.getContext("webgl2");
    return null; // webgl canvas — pixel read done from PNG instead
  });

  await page.evaluate(() => { if (window.__bra_close_showcase) window.__bra_close_showcase(); });
  code = errors.length ? 1 : 0;
  console.log("console errors:", errors.length ? errors : "none");
} catch (e) { console.error("FAIL", e); code = 1; }
finally { await browser.close(); server.close(); process.exit(code); }
