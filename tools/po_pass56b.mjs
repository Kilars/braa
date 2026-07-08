import { chromium } from "playwright";
import { writeFile, mkdir } from "fs/promises";
const base = "http://localhost:8099/index.html";
await mkdir(".screenshots", { recursive: true });
const P = ".screenshots/P56-";
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
async function shot(name, clip){
  const client = await page.context().newCDPSession(page);
  const opt = { format: "png", captureBeyondViewport: false };
  if (clip) opt.clip = clip;
  const { data } = await client.send("Page.captureScreenshot", opt);
  await writeFile(`${P}${name}.png`, Buffer.from(data, "base64"));
  console.log("shot", name);
}
let code = 1;
try {
  await page.goto(`${base}?bra_coins=5000`, { waitUntil: "load", timeout: 90000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  await page.waitForTimeout(2500);
  // zoom top HUD (nav pills) — full device pixel width 1170, top ~150px
  await shot("hud-top", { x: 0, y: 0, width: 1170, height: 180, scale: 1 });

  // open kennel via kennel_btn seam
  const kb = await g("kennel_btn");
  console.log("kennel_btn", kb);
  await tapVp(kb.x, kb.y);
  await page.waitForTimeout(1500);
  console.log("kennel_open", await g("kennel_open"));
  await shot("k-kennel-grid");

  // tap a grid cell (Nova, cell index 1) via kennel_cells seam
  const cells = await g("kennel_cells");
  console.log("cells count", cells ? cells.length : null, cells ? cells.map(c=>c.id||c.name) : null);
  if (cells && cells.length > 1) {
    await tapVp(cells[1].x, cells[1].y);
    await page.waitForTimeout(1200);
    await shot("k-modal");
  }
  code = 0;
} catch (e) { console.error("FAIL", e); code = 1; }
finally { console.log("errors:", errors.length ? errors : "none"); await browser.close(); process.exit(code); }
