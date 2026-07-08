import { chromium } from "playwright";
import { writeFile, mkdir } from "fs/promises";
const base = "http://localhost:8099/index.html";
await mkdir(".screenshots", { recursive: true });
const P = ".screenshots/P60-";
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

  // ---- autotap mark burst, observe apex & payoff
  await page.goto(`${base}?bra_coins=5000&bra_autotap=1`, { waitUntil: "load", timeout: 90000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  for (let i=0;i<6;i++){ await page.waitForTimeout(700); await shot(`mark-${i}`); }
  console.log("learned", await g("learned"), "coins", await g("coins"));

  // ---- completion menu (deep zoom on each section)
  await tapVp(84, 32);
  await page.waitForTimeout(1000);
  console.log("menu_open", await g("menu_open"));
  await shot("menu");
  await shot("menu-top", { x: 0, y: 300, width: 1170, height: 900, scale: 1 });
  await shot("menu-mid", { x: 0, y: 1100, width: 1170, height: 900, scale: 1 });
  await shot("menu-bot", { x: 0, y: 1900, width: 1170, height: 632, scale: 1 });

  // ---- breed showcase (from menu "Vis frem hundene")
  const btns = await g("menu_buttons");
  console.log("menu_buttons", JSON.stringify(btns));

  // ---- kennel via nav pill
  await page.evaluate(() => { if (window.__bra_close_menu) window.__bra_close_menu(); });
  await page.waitForTimeout(500);
  await tapVp(204, 32);
  await page.waitForTimeout(1200);
  console.log("kennel_open", await g("kennel_open"));
  await shot("kennel-grid");
  const cells = await g("kennel_cells");
  console.log("kennel_cells", cells ? cells.length : null, JSON.stringify(cells));
  if (cells && cells.length > 1) {
    for (const idx of [1, 3]) {
      await tapVp(cells[idx].x, cells[idx].y); await page.waitForTimeout(1000);
      let active = await g("kennel_active");
      if (active === null) { await tapVp(cells[idx].x, cells[idx].y); await page.waitForTimeout(1000); active = await g("kennel_active"); }
      console.log("kennel_active", active);
      await shot(`kennel-modal-${idx}`);
      // close modal
      await page.evaluate(() => { if (window.__bra_kennel_close_modal) window.__bra_kennel_close_modal(); });
      await tapVp(360, 40); await page.waitForTimeout(600);
    }
  }
  code = 0;
} catch (e) { console.error("FAIL", e); code = 1; }
finally { console.log("errors:", errors.length ? errors : "none"); await browser.close(); process.exit(code); }
