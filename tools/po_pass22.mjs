import { chromium } from "playwright";
const base = process.argv[2];
const GODOT_W = 720, GODOT_H = 1280;
const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 3 });
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
await page.screenshot({ path: ".screenshots/P22-01-training.png" });
console.log("current_trick:", await page.evaluate(() => window.__bra_current_trick ?? null));

// completion menu
await tapVp(70, 32);
await page.waitForTimeout(1400);
await page.screenshot({ path: ".screenshots/P22-02-menu.png" });
console.log("menu_open:", await page.evaluate(() => window.__bra_menu_open ?? null));
await tapVp(70, 32);
await page.waitForTimeout(800);

// kennel grid
const kb = await page.evaluate(() => window.__bra_kennel_btn || null);
if (kb) await tapVp(kb.x, kb.y);
await page.waitForTimeout(1800);
await page.screenshot({ path: ".screenshots/P22-03-kennel-grid.png" });
const cells = await page.evaluate(() => window.__bra_kennel_cells ?? null);
console.log("kennel_cells:", JSON.stringify(cells));

// modal on Nova (2nd cell, buyable) — near-native for spelling verify
if (cells && cells[1]) await tapVp(cells[1].x ?? cells[1][0], cells[1].y ?? cells[1][1]);
await page.waitForTimeout(1400);
await page.screenshot({ path: ".screenshots/P22-04-kennel-modal-nova.png" });
// close, open Bella (owned, 1st cell)
await tapVp(360, 60);
await page.waitForTimeout(800);
if (cells && cells[0]) await tapVp(cells[0].x ?? cells[0][0], cells[0].y ?? cells[0][1]);
await page.waitForTimeout(1400);
await page.screenshot({ path: ".screenshots/P22-05-kennel-modal-bella.png" });

console.log("errors:", JSON.stringify(errs));
await browser.close();
