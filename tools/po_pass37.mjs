// PO father pass 37 — verify task 171 (breed-showcase «Tilbake» back-button label + ◀▶ chevron
// glyphs now clear WCAG AA; ghost pill flipped from a white@0.14 LIGHTENING fill to a black@0.45
// DARKENING ink overlay). Re-play training + completion menu + kennel + showcase for regressions,
// and sample the control-bar chrome pixel-for-pixel to confirm the fix landed in-pixel.
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
const P = ".screenshots/P37-";
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

// WCAG relative luminance + contrast from a screenshot crop, decoded in-page.
function relLum(r, g, b) {
  const f = c => { c /= 255; return c <= 0.03928 ? c/12.92 : Math.pow((c+0.055)/1.055, 2.4); };
  return 0.2126*f(r) + 0.7152*f(g) + 0.0722*f(b);
}
function cr(a, b) { const L1 = relLum(...a), L2 = relLum(...b); const hi = Math.max(L1,L2), lo = Math.min(L1,L2); return (hi+0.05)/(lo+0.05); }

// Decode a crop and return {lightest, darkest} pixels (label chrome vs pill body).
async function sampleCrop(clip, label) {
  const shot = await page.screenshot({ clip });
  const px = await page.evaluate(async (b64) => {
    const img = new Image();
    await new Promise(r => { img.onload = r; img.src = "data:image/png;base64," + b64; });
    const c = document.createElement("canvas"); c.width = img.width; c.height = img.height;
    const g = c.getContext("2d"); g.drawImage(img, 0, 0);
    const d = g.getImageData(0, 0, c.width, c.height).data;
    let light = null, dark = null;
    for (let i = 0; i < d.length; i += 4) {
      const r = d[i], gg = d[i+1], bb = d[i+2];
      const lum = 0.299*r + 0.587*gg + 0.114*bb;
      if (!light || lum > light.lum) light = { r, g: gg, b: bb, lum };
      if (!dark || lum < dark.lum) dark = { r, g: gg, b: bb, lum };
    }
    return { light, dark };
  }, shot.toString("base64"));
  const lightRGB = [px.light.r, px.light.g, px.light.b];
  const darkRGB = [px.dark.r, px.dark.g, px.dark.b];
  console.log(`${label}: lightest(text)=${JSON.stringify(lightRGB)} darkest(pill)=${JSON.stringify(darkRGB)} CR=${cr(lightRGB, darkRGB).toFixed(2)}:1`);
  return { lightRGB, darkRGB, contrast: cr(lightRGB, darkRGB) };
}

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

  // adopt 2nd dog so showcase has 2 pips → chevrons live
  const br = JSON.parse(await dump("breed_rows"));
  const buy = br.find(r => r.id === "chocolate_labrador");
  if (buy) { await tapVp(buy.x, buy.y); await page.waitForTimeout(1400); }
  console.log("balance after adopt", await dump("balance"), "owned", await dump("owned"));

  // open showcase
  const br2 = JSON.parse(await dump("breed_rows"));
  const last = br2[br2.length - 1];
  await tapVp(last.x, last.y + 62);
  await page.waitForTimeout(1600);
  console.log("showcase spotlit", await dump("showcase_spotlit"));
  await page.screenshot({ path: `${P}03-showcase.png` });
  // control bar band — CSS px (Playwright clip is viewport coords). y ~ [740,812] is the control row.
  await page.screenshot({ path: `${P}03c-controlbar.png`, clip: { x: 0, y: 740, width: W, height: 72 } });

  // Sample the «Tilbake» pill (right side of control bar) and the chevron pills (flanking the pip).
  console.log("--- 171 in-pixel verification (chrome over its own pill) ---");
  await sampleCrop({ x: W-100, y: 748, width: 96, height: 56 }, "«Tilbake» pill zone");
  await sampleCrop({ x: 8, y: 744, width: 34, height: 42 }, "◀ left-chevron pill");
  await sampleCrop({ x: 348, y: 744, width: 34, height: 42 }, "▶ right-chevron pill");
  // Non-spotlit «Brun lab» pip — text=BTN_SECONDARY_TEXT (white@0.96) on PIP_OFF (white@0.14 lifting pill).
  await sampleCrop({ x: 192, y: 750, width: 58, height: 22 }, "«Brun lab» non-spotlit pip interior");
  // Pill-FILL-only patch (left padding of the «Brun lab» pill, no glyph): its lightest≈darkest≈fill,
  // then contrast that fill against the glyph white (BTN_SECONDARY_TEXT ≈ 250) → the real text-on-pill CR.
  const fillPatch = await sampleCrop({ x: 194, y: 756, width: 6, height: 10 }, "«Brun lab» pill FILL patch");
  console.log("→ text-on-pill CR (white@250 over that fill):", cr([250,250,250], fillPatch.darkRGB).toFixed(2) + ":1");

  // regression: close showcase → kennel
  await page.evaluate(() => { if (window.__bra_close_showcase) window.__bra_close_showcase(); });
  await page.waitForTimeout(1200);
  await page.screenshot({ path: `${P}04-after-close.png` });

  code = errors.length ? 1 : 0;
  console.log("console errors:", errors.length ? errors : "none");
} catch (e) { console.error("FAIL", e); code = 1; }
finally { await browser.close(); server.close(); process.exit(code); }
