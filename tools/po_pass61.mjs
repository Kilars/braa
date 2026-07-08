import { chromium } from "playwright";
import { writeFile, mkdir } from "fs/promises";
const base = "http://localhost:8099/index.html";
await mkdir(".screenshots", { recursive: true });
const P = ".screenshots/P61-";
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
  const opts = { format: "png", captureBeyondViewport: false };
  if (clip) opts.clip = clip;
  const { data } = await client.send("Page.captureScreenshot", opts);
  await writeFile(`${P}${name}.png`, Buffer.from(data, "base64"));
  console.log("shot", name);
}
let code = 1;
try {
  await page.goto(`${base}?bra_coins=5000`, { waitUntil: "load", timeout: 90000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  await page.waitForTimeout(2500);
  await shot("a-training");

  await page.goto(`${base}?bra_coins=5000&bra_autotap=1`, { waitUntil: "load", timeout: 90000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  for (let i=0;i<5;i++){ await page.waitForTimeout(700); await shot(`mark-${i}`); }
  console.log("learned", await g("learned"), "coins", await g("coins"));

  // completion menu + deep zoom on each section subheading
  await tapVp(84, 32);
  await page.waitForTimeout(1000);
  console.log("menu_open", await g("menu_open"));
  await shot("menu");
  await shot("menu-raser", { x: 40, y: 900, width: 1090, height: 520, scale: 1 });
  await shot("menu-merkeord", { x: 40, y: 1500, width: 1090, height: 520, scale: 1 });
  await shot("menu-vansk", { x: 40, y: 2050, width: 1090, height: 480, scale: 1 });

  await page.evaluate(() => { if (window.__bra_close_menu) window.__bra_close_menu(); });
  await page.waitForTimeout(500);
  // kennel via nav pill
  await tapVp(204, 32);
  await page.waitForTimeout(1200);
  console.log("kennel_open", await g("kennel_open"));
  await shot("kennel-grid");
  const cells = await g("kennel_cells");
  console.log("kennel_cells", cells ? cells.length : null);
  if (cells && cells.length > 1) {
    await tapVp(cells[1].x, cells[1].y); await page.waitForTimeout(1000);
    let active = await g("kennel_active");
    if (active === null) { await tapVp(cells[1].x, cells[1].y); await page.waitForTimeout(1000); active = await g("kennel_active"); }
    console.log("kennel_active", active);
    await shot("kennel-modal");
  }
  code = 0;
} catch (e) { console.error("FAIL", e); code = 1; }
finally { console.log("errors:", errors.length ? errors : "none"); await browser.close(); process.exit(code); }
