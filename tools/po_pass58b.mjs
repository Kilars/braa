import { chromium } from "playwright";
import { writeFile, mkdir } from "fs/promises";
const base = "http://localhost:8099/index.html";
await mkdir(".screenshots", { recursive: true });
const P = ".screenshots/P58-";
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 3 });
const errors = [];
page.on("console", m => { if (m.type() === "error") errors.push(m.text()); });
const g = async (k) => page.evaluate(new Function("return window.__bra_" + k + " ?? null"));
async function tapVp(x, y) {
  const box = await page.evaluate(() => { const r = document.querySelector("#canvas").getBoundingClientRect(); return {x:r.x,y:r.y,w:r.width,h:r.height}; });
  const vp = await page.evaluate(() => window.__bra_viewport || [720,1558]);
  await page.mouse.click(box.x + x * box.w / vp[0], box.y + y * box.h / vp[1]);
}
async function shot(name){
  const client = await page.context().newCDPSession(page);
  const { data } = await client.send("Page.captureScreenshot", { format: "png", captureBeyondViewport: false });
  await writeFile(`${P}${name}.png`, Buffer.from(data, "base64"));
  console.log("shot", name);
}
let code = 1;
try {
  await page.goto(`${base}?bra_coins=5000`, { waitUntil: "load", timeout: 90000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  await page.waitForTimeout(2500);

  // ---- kennel grid (tap the «Kennel» nav pill)
  const kb = await g("kennel_btn");
  console.log("kennel_btn", kb);
  if (kb && kb.x != null) { await tapVp(kb.x, kb.y); } else if (Array.isArray(kb)) { await tapVp(kb[0], kb[1]); } else { await tapVp(204, 32); }
  await page.waitForTimeout(1200);
  console.log("kennel_open", await g("kennel_open"));
  await shot("kennel-grid");

  // ---- open a modal on Nova (cell)
  const cells = await g("kennel_cells");
  console.log("cells", cells ? cells.length : null);
  if (cells && cells.length) {
    const nova = cells.find(c => c.id === "nova") || cells[1];
    await tapVp(nova.x, nova.y); await page.waitForTimeout(1000);
    console.log("kennel_active", await g("kennel_active"));
    await shot("kennel-modal");
  }

  // ---- back to training, open menu, open feedback form
  await page.goto(`${base}?bra_coins=5000`, { waitUntil: "load", timeout: 90000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  await page.waitForTimeout(2000);
  await tapVp(84, 32); await page.waitForTimeout(800);
  const fr = await g("feedback_row");
  console.log("feedback_row", fr);
  if (fr) { await tapVp(fr[0], fr[1]); await page.waitForTimeout(900); console.log("feedback_open", await g("feedback_open")); await shot("feedback"); }
  code = 0;
} catch (e) { console.error("FAIL", e); code = 1; }
finally { console.log("errors:", errors.length ? errors : "none"); await browser.close(); process.exit(code); }
