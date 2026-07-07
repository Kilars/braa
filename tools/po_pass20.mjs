import { chromium } from "playwright";
const base = process.argv[2];
const GODOT_W = 720, GODOT_H = 1280;
const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
const errs = [];
page.on("console", m => { if (m.type() === "error") errs.push(m.text()); });
async function tapVp(x, y) {
  const box = await page.locator("canvas").boundingBox();
  const vp = await page.evaluate(() => window.__bra_viewport || null);
  await page.mouse.click(box.x + x * box.width / (vp?vp[0]:GODOT_W), box.y + y * box.height / (vp?vp[1]:GODOT_H));
}
await page.goto(base, { waitUntil: "load", timeout: 90000 });
await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
await page.waitForTimeout(2500);
await page.screenshot({ path: ".screenshots/P20-01-training.png" });
console.log("current_trick:", await page.evaluate(() => window.__bra_current_trick ?? null));
console.log("vp:", JSON.stringify(await page.evaluate(()=>window.__bra_viewport||null)));
// kennel grid — the focus (verify 155 yaw fix)
const kb = await page.evaluate(() => window.__bra_kennel_btn || null);
console.log("kennel_btn:", JSON.stringify(kb));
if (kb) await tapVp(kb.x, kb.y);
await page.waitForTimeout(1800);
await page.screenshot({ path: ".screenshots/P20-02-kennel-grid.png" });
console.log("kennel_active:", await page.evaluate(() => window.__bra_kennel_active ?? null));
console.log("kennel_cells:", JSON.stringify(await page.evaluate(() => window.__bra_kennel_cells ?? null)));
// open a modal on a buyable dog
await tapVp(kb.x, 330);
await page.waitForTimeout(1400);
await page.screenshot({ path: ".screenshots/P20-03-kennel-modal.png" });
console.log("errors:", JSON.stringify(errs));
await browser.close();
