import { mkdir } from "node:fs/promises";
import { chromium } from "playwright";
const base = "http://localhost:8099/index.html";
const W = 390, H = 844;
await mkdir(".screenshots", { recursive: true });
const P = ".screenshots/P40S-";
const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport: { width: W, height: H }, deviceScaleFactor: 3 });
const errors = [];
page.on("console", m => { if (m.type() === "error") errors.push(m.text()); });
async function tapVp(x, y) {
  const box = await page.locator("canvas").boundingBox();
  const vp = await page.evaluate(() => window.__bra_viewport || null);
  await page.mouse.click(box.x + x * box.width / (vp ? vp[0] : 720), box.y + y * box.height / (vp ? vp[1] : 1280));
}
const g = async (k) => page.evaluate(new Function("return window.__bra_" + k + " ?? null"));
const shot = (n) => page.screenshot({ path: `${P}${n}.png`, timeout: 60000 });
let code = 1;
try {
  await page.goto(`${base}?bra_coins=2000`, { waitUntil: "load", timeout: 90000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  await page.waitForTimeout(4000);
  // adopt + train Nova
  const kb = await g("kennel_btn"); await tapVp(kb.x, kb.y); await page.waitForTimeout(2500);
  let cells = await g("kennel_cells");
  for (let i = 0; i < 10 && !cells; i++) { await tapVp(kb.x, kb.y); await page.waitForTimeout(1200); cells = await g("kennel_cells"); }
  const nova = cells.find(c => c.id === "nova");
  await tapVp(nova.x, nova.y); await page.waitForTimeout(1600);
  let action = await g("kennel_action");
  for (let i = 0; i < 8 && !action; i++) { await page.waitForTimeout(500); action = await g("kennel_action"); }
  await tapVp(action.x, action.y); await page.waitForTimeout(1800);   // adopt
  for (let i = 0; i < 8; i++) { await page.waitForTimeout(400); action = await g("kennel_action"); }
  if (action) { await tapVp(action.x, action.y); await page.waitForTimeout(2200); } // train
  // open menu + showcase
  await tapVp(70, 32); await page.waitForTimeout(1500);
  const sc = await g("showcase_row");
  await tapVp(sc[0], sc[1]);
  // settle frames: 1s, 2.5s, 4s cumulative
  await page.waitForTimeout(1000); await shot("t1000");
  await page.waitForTimeout(1500); await shot("t2500");
  await page.waitForTimeout(1500); await shot("t4000");
  await page.waitForTimeout(2000); await shot("t6000");
  console.log("showcase_spotlit:", await g("showcase_spotlit"), "kennel_active:", await g("kennel_active"));
  console.log("console errors:", errors.length ? errors : "none");
  code = 0;
} catch (e) { console.error("FAIL", e); code = 1; }
finally { await browser.close(); process.exit(code); }
