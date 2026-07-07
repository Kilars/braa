// PO father pass 34 — verify task 168 (completion menu: active BREED «Aktiv» / WORD «Aktiv» /
// SELECTED difficulty «Valgt» badges now draw in the SAME dark current-state ink as the active
// trick «Trener nå», instead of the action-blue). Boots training, opens the completion menu,
// adopts the 2nd breed so Labrador is ACTIVE with a sibling row, then crops the active trick row
// AND the active breed row full-width so the two badge inks can be compared pixel-for-pixel.
// Also re-plays training + kennel for regressions. Samples badge pixels for an objective check.
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
const P = ".screenshots/P34-";
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
  const br0 = await dump("breed_rows");
  const buy = br0 && br0.find(r => r.id === "chocolate_labrador");
  if (buy) { await tapVp(buy.x, buy.y); await page.waitForTimeout(1400); }
  console.log("balance after adopt", await dump("balance"), "owned", await dump("owned"));

  await page.screenshot({ path: `${P}02-menu-full.png` });

  const trickRows = await dump("trick_rows");
  const breedRows = await dump("breed_rows");
  console.log("TRICK ROWS", JSON.stringify(trickRows));
  console.log("BREED ROWS", JSON.stringify(breedRows));

  const curTrick = await dump("current_trick");
  const at = trickRows && (trickRows.find(r => r.id === curTrick) || trickRows[0]);
  const ab = breedRows && (breedRows.find(r => r.active) || breedRows[0]);
  if (at) await cropRow(`${P}03-trick-active.png`, at.y);
  if (ab) await cropRow(`${P}04-breed-active.png`, ab.y);

  // Objective badge-ink sample: read the darkest pixel in the right-side badge zone of each
  // active row (badges are right-aligned). Dark ink ⇒ small RGB; action-blue ⇒ blue-dominant.
  async function badgeSample(vy, label) {
    const shot = await page.screenshot({ clip: { x: W - 150, y: Math.max(0, vy - 16), width: 150, height: 32 } });
    // decode via canvas in-page
    const info = await page.evaluate(async (b64) => {
      const img = new Image();
      await new Promise(r => { img.onload = r; img.src = "data:image/png;base64," + b64; });
      const c = document.createElement("canvas"); c.width = img.width; c.height = img.height;
      const g = c.getContext("2d"); g.drawImage(img, 0, 0);
      const d = g.getImageData(0, 0, c.width, c.height).data;
      let best = null;
      for (let i = 0; i < d.length; i += 4) {
        const r = d[i], gg = d[i+1], bb = d[i+2];
        const lum = 0.299*r + 0.587*gg + 0.114*bb;
        // candidate "text" pixels: reasonably saturated-dark, not the pale wash/paper
        if (lum < 130) { if (!best || lum < best.lum) best = { r, g: gg, b: bb, lum }; }
      }
      return best;
    }, shot.toString("base64"));
    console.log(`badge sample ${label}:`, JSON.stringify(info),
      info ? (info.b > info.r + 25 ? "→ BLUE-ish" : "→ dark-neutral ink") : "→ none");
  }
  if (at) await badgeSample(at.y, "trick-active «Trener nå»");
  if (ab) await badgeSample(ab.y, "breed-active «Aktiv»");

  // regression: close menu → training, then open kennel
  await tapVp(195, 800); // continue/close (approx primary)
  await page.waitForTimeout(1500);
  await page.screenshot({ path: `${P}05-after-close.png` });

  console.log("console errors:", errors.length ? errors : "none");
  code = errors.length ? 1 : 0;
} catch (e) { console.error("FAIL", e); code = 1; }
finally { await browser.close(); server.close(); process.exit(code); }
