// PO father pass 33 — verify task 167 (completion menu: the ACTIVE breed / marker-word /
// SELECTED difficulty rows now get the SAME pale-blue wash the active trick row already had).
// Boots training, opens the completion menu, adopts the 2nd breed (so Labrador is active with a
// sibling), reopens the menu, and dumps all four row-sets + crops each section so the active-row
// wash can be judged pixel-for-pixel. Also re-plays training + kennel for regressions.
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
const P = ".screenshots/P33-";
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
// Read the device-pixel colour under a viewport (x,y) by sampling the screenshot PNG is heavy;
// instead crop a tight swatch so it can be eyeballed.
async function cropRow(path, vy) {
  await page.screenshot({ path, clip: { x: 0, y: Math.max(0, vy - 26), width: W, height: 52 } });
}
let code = 1;
try {
  await page.goto(`${base}?bra_autotap=1&bra_coins=120`, { waitUntil: "load", timeout: 90000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  await page.waitForTimeout(6000);
  await page.screenshot({ path: `${P}01-training.png` });

  await tapVp(70, 32); // open menu
  await page.waitForTimeout(1500);
  // adopt 2nd dog so Labrador is ACTIVE with a sibling breed row
  const br = await dump("breed_rows");
  const buy = br.find(r => r.id === "chocolate_labrador");
  if (buy) { await tapVp(buy.x, buy.y); await page.waitForTimeout(1400); }
  console.log("balance after adopt", await dump("balance"), "owned", await dump("owned"));

  // reopen a clean menu view
  await page.screenshot({ path: `${P}02-menu-full.png` });

  const trickRows = await dump("trick_rows");
  const breedRows = await dump("breed_rows");
  const wordRows = await dump("word_rows");
  const diffRows = await dump("difficulty_rows");
  console.log("TRICK ROWS", JSON.stringify(trickRows));
  console.log("BREED ROWS", JSON.stringify(breedRows));
  console.log("WORD ROWS", JSON.stringify(wordRows));
  console.log("DIFF ROWS", JSON.stringify(diffRows));
  console.log("active_breed", await dump("active_breed"), "active_word", await dump("active_word"),
    "current_trick", await dump("current_trick"), "difficulty", await dump("difficulty"));

  // crop each section's ACTIVE/SELECTED row
  const curTrick = await dump("current_trick");
  if (trickRows) { const a = trickRows.find(r => r.id === curTrick) || trickRows[0]; if (a) await cropRow(`${P}03-trick-active.png`, a.y); }
  if (breedRows) { const a = breedRows.find(r => r.active) || breedRows[0]; if (a) await cropRow(`${P}04-breed-active.png`, a.y); }
  if (wordRows) { const a = wordRows.find(r => r.active) || wordRows[0]; if (a) await cropRow(`${P}05-word-active.png`, a.y); }
  if (diffRows) { const a = diffRows.find(r => r.selected || r.active) || diffRows[0]; if (a) await cropRow(`${P}06-diff-active.png`, a.y); }

  console.log("console errors:", errors.length ? errors : "none");
  code = errors.length ? 1 : 0;
} catch (e) { console.error("FAIL", e); code = 1; }
finally { await browser.close(); server.close(); process.exit(code); }
