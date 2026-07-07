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
const kb = await page.evaluate(() => window.__bra_kennel_btn || null);
console.log("kennel_btn:", JSON.stringify(kb), "vp:", JSON.stringify(await page.evaluate(()=>window.__bra_viewport||null)));
if (kb) await tapVp(kb.x, kb.y);
await page.waitForTimeout(1600);
await page.screenshot({ path: ".screenshots/P19-03-kennel-grid.png" });
console.log("kennel_active:", await page.evaluate(() => window.__bra_kennel_active ?? null));
// tap the second grid cell (top-right) for a buyable-dog modal
await tapVp(kb.x, 330);
await page.waitForTimeout(1400);
await page.screenshot({ path: ".screenshots/P19-04-kennel-modal.png" });
console.log("errors:", JSON.stringify(errs));
await browser.close();
