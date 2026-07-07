// PO father pass 33b — drive TWO masteries so the completion menu reveals ALL FOUR selection
// sections (tricks · breeds · marker-words · difficulty), then verify task 167's active-row
// pale-blue wash on the ACTIVE breed / ACTIVE word / SELECTED difficulty rows in pixels.
// Words reveal at ≥1 mastery, difficulty at ≥2 (MenuReveal). Autotap masters a trick in ~5 marks.
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
const P = ".screenshots/P33b-";
const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport: { width: W, height: H }, deviceScaleFactor: 3 });
const errors = [];
page.on("console", m => { if (m.type() === "error") errors.push(m.text()); });
async function tapVp(x, y) {
  const box = await page.locator("canvas").boundingBox();
  const vp = await page.evaluate(() => window.__bra_viewport || null);
  await page.mouse.click(box.x + x * box.width / (vp ? vp[0] : 720), box.y + y * box.height / (vp ? vp[1] : 1280));
}
const dump = async (k) => JSON.parse(await page.evaluate(new Function("return JSON.stringify(window.__bra_" + k + " ?? null)")));
// vp-y (1280 space) → screenshot-y (844 space)
const toScreenY = (vy) => vy * H / 1280;
async function cropRow(path, vy) {
  const y = toScreenY(vy);
  await page.screenshot({ path, clip: { x: 0, y: Math.max(0, y - 24), width: W, height: 48 } });
}
async function waitMenu(openState, ms) {
  const t0 = Date.now();
  while (Date.now() - t0 < ms) {
    if ((await dump("menu_open")) === openState) return true;
    await page.waitForTimeout(1000);
  }
  return false;
}
let code = 1;
try {
  await page.goto(`${base}?bra_autotap=1&bra_coins=120`, { waitUntil: "load", timeout: 90000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  await page.waitForTimeout(3000);

  // --- master trick #1 (Sitt): wait for the completion menu to auto-pop ---
  const m1 = await waitMenu(true, 60000);
  console.log("mastery#1 menu popped:", m1);
  await page.waitForTimeout(1000);
  // adopt 2nd breed so the breeds section has ACTIVE + sibling
  const br = await dump("breed_rows");
  const buy = br && br.find(r => r.id === "chocolate_labrador");
  if (buy) { await tapVp(buy.x, buy.y); await page.waitForTimeout(1200); }
  console.log("after adopt: balance", await dump("balance"), "owned", await dump("owned"));
  const w1 = await dump("word_rows");
  console.log("WORD ROWS after 1 mastery:", JSON.stringify(w1));
  await page.screenshot({ path: `${P}01-menu-1mastery.png` });

  // switch to Ligg to resume training on a 2nd trick
  const tr = await dump("trick_rows");
  const ligg = tr && tr.find(r => r.id === "ligg");
  if (ligg) { await tapVp(ligg.x, ligg.y); await page.waitForTimeout(1500); }
  console.log("switched trick, menu_open now:", await dump("menu_open"), "current_trick", await dump("current_trick"));

  // --- master trick #2 (Ligg) ---
  const m2 = await waitMenu(true, 60000);
  console.log("mastery#2 menu popped:", m2);
  await page.waitForTimeout(1000);
  await page.screenshot({ path: `${P}02-menu-2mastery.png` });

  const breedRows = await dump("breed_rows");
  const wordRows = await dump("word_rows");
  const diffRows = await dump("difficulty_rows");
  console.log("=== FINAL (2 masteries) ===");
  console.log("BREED ROWS", JSON.stringify(breedRows));
  console.log("WORD ROWS", JSON.stringify(wordRows));
  console.log("DIFF ROWS", JSON.stringify(diffRows));
  console.log("active_breed", await dump("active_breed"), "active_word", await dump("active_word"),
    "current_trick", await dump("current_trick"), "difficulty", await dump("difficulty"));

  // crop the ACTIVE/SELECTED row of each section
  if (breedRows) { const a = breedRows.find(r => r.active) || breedRows.find(r => r.id === "labrador"); if (a) await cropRow(`${P}03-breed-active.png`, a.y); }
  if (wordRows && wordRows.length) { const a = wordRows.find(r => r.active) || wordRows[0]; if (a) await cropRow(`${P}04-word-active.png`, a.y); }
  if (diffRows && diffRows.length) { const a = diffRows.find(r => r.selected || r.active) || diffRows[0]; if (a) await cropRow(`${P}05-diff-selected.png`, a.y); }

  console.log("console errors:", errors.length ? errors : "none");
  code = errors.length ? 1 : 0;
} catch (e) { console.error("FAIL", e); code = 1; }
finally { await browser.close(); server.close(); process.exit(code); }
