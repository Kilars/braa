import { chromium } from "playwright";
import { writeFile, mkdir } from "fs/promises";
const base = "http://localhost:8099/index.html";
await mkdir(".screenshots", { recursive: true });
const P = ".screenshots/P57-";
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
  await page.waitForTimeout(2000);
  const vp = await g("viewport"); const W = vp[0], H = vp[1];

  // open kennel via HUD "Kennel" pill (top, right of Triks)
  await tapVp(200, 32);
  await page.waitForTimeout(1200);
  console.log("kennel_open", await g("kennel_open"));
  await shot("kennel-grid");
  const cells = await g("kennel_cells");
  console.log("cells", cells && cells.length);
  // open a modal on a buyable dog (Nova, cell 1 usually)
  if (cells && cells[1]) { await tapVp(cells[1][0], cells[1][1]); await page.waitForTimeout(1000); await shot("kennel-modal"); }
  code = 0;
} catch (e) { console.error("FAIL", e); code = 1; }
finally { console.log("errors:", errors.length ? errors : "none"); await browser.close(); process.exit(code); }
