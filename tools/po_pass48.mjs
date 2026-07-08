// 178 (X-6) verification: capture the training screen and measure the white «BRA» label
// bounding box as a fraction of screen width. Goal art ≈ 18% (65/359). Prior build ≈ 12%.
import { mkdir, writeFile } from "node:fs/promises";
import { chromium } from "playwright";
import { PNG } from "playwright-core/lib/utilsBundle";
const base = "http://localhost:8099/index.html";
const W = 390, H = 844;
await mkdir(".screenshots", { recursive: true });
const P = ".screenshots/P48-";
const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport: { width: W, height: H }, deviceScaleFactor: 2 });
page.setDefaultTimeout(20000);
const errors = [];
page.on("console", m => { if (m.type() === "error") errors.push(m.text()); });
let code = 1;
try {
  await page.goto(`${base}?bra_coins=2000`, { waitUntil: "load", timeout: 90000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  await page.waitForTimeout(3500);
  const client = await page.context().newCDPSession(page);
  const { data } = await client.send("Page.captureScreenshot", { format: "png", captureBeyondViewport: false });
  const buf = Buffer.from(data, "base64");
  await writeFile(`${P}01-training.png`, buf);
  // Measure white label box. Image is deviceScaleFactor 2 → 780×1688. The BRA button band
  // sits in the bottom ~third; scan white pixels there (avoid the cream dog/paper above).
  const png = PNG.sync.read(buf);
  const iw = png.width, ih = png.height;
  const yTop = Math.floor(ih * 0.68), yBot = Math.floor(ih * 0.95);
  let minX = iw, maxX = 0, minY = ih, maxY = 0, n = 0;
  for (let y = yTop; y < yBot; y++) {
    for (let x = 0; x < iw; x++) {
      const i = (y * iw + x) * 4;
      const r = png.data[i], g = png.data[i+1], b = png.data[i+2];
      if (r > 232 && g > 232 && b > 232) { // near-white label glyphs
        if (x < minX) minX = x; if (x > maxX) maxX = x;
        if (y < minY) minY = y; if (y > maxY) maxY = y; n++;
      }
    }
  }
  const labelW = (maxX - minX) / iw;      // fraction of screen width
  const labelH = (maxY - minY) / ih;
  console.log(JSON.stringify({
    imgW: iw, imgH: ih, whitePx: n,
    labelWidthPct: +(labelW * 100).toFixed(1),
    labelHeightPct: +(labelH * 100).toFixed(1),
    goalWidthPct: 18.1, priorWidthPct: 11.8,
    box: { minX, maxX, minY, maxY },
  }, null, 2));
  console.log("console errors:", errors.length ? errors : "none");
  code = 0;
} catch (e) { console.error("FAIL", e); code = 1; }
finally { await browser.close(); process.exit(code); }
