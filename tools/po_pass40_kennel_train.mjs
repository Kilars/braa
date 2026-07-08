import { mkdir } from "node:fs/promises";
import { chromium } from "playwright";
const base = "http://localhost:8099/index.html";
const W = 390, H = 844;
await mkdir(".screenshots", { recursive: true });
const P = ".screenshots/P40K-";
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
let code = 1;
try {
  await page.goto(`${base}?bra_coins=2000`, { waitUntil: "load", timeout: 90000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  await page.waitForTimeout(4000);
  const kb = await g("kennel_btn");
  console.log("kennel_btn:", JSON.stringify(kb));
  await tapVp(kb.x, kb.y);
  await page.waitForTimeout(2500);
  console.log("kennel_open:", await g("kennel_open"));
  const cells = await g("kennel_cells");
  const nova = cells.find(c => c.id === "nova");
  await tapVp(nova.x, nova.y);
  await page.waitForTimeout(1600);
  let action = await g("kennel_action");
  for (let i = 0; i < 8 && !action; i++) { await page.waitForTimeout(500); action = await g("kennel_action"); }
  console.log("action1 (adopt):", JSON.stringify(action));
  await tapVp(action.x, action.y);
  await page.waitForTimeout(1800);
  action = await g("kennel_action");
  for (let i = 0; i < 8; i++) { await page.waitForTimeout(400); action = await g("kennel_action"); }
  console.log("action2 (train):", JSON.stringify(action));
  if (action) { await tapVp(action.x, action.y); await page.waitForTimeout(2200); }
  await page.screenshot({ path: `${P}training-nova.png` });
  console.log("kennel_active:", await g("kennel_active"), "active_breed:", await g("active_breed"), "balance:", await g("balance"));
  // open completion menu
  await tapVp(70, 32);
  await page.waitForTimeout(1500);
  await page.screenshot({ path: `${P}menu-nova.png` });
  // open showcase
  const sc = await g("showcase_row");
  if (sc) { await tapVp(sc[0], sc[1]); await page.waitForTimeout(1800); }
  await page.screenshot({ path: `${P}showcase-nova.png` });
  console.log("showcase_spotlit:", await g("showcase_spotlit"));
  // step showcase forward one breed then back to active — coat-coherence check on Tilbake/dismiss
  await page.screenshot({ path: `${P}showcase-nova-full.png` });
  console.log("console errors:", errors.length ? errors : "none");
  code = 0;
} catch (e) { console.error("FAIL", e); code = 1; }
finally { await browser.close(); process.exit(code); }
