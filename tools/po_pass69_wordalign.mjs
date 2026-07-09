// Task 195 self-review: capture the completion menu with the marker-words section revealed to
// confirm the word row names now start FLUSH with the trick / difficulty names (no decorative pip
// + extra indent — pass-69 X-6). Master Sitt (~9s autotap) → open menu → screenshot.
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
await page.goto(base + "?bra_autotap=1", { waitUntil: "load", timeout: 90000 });
await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
await page.waitForTimeout(65000);  // master Sitt → marker-words section reveals (menu-open pauses training, so master first)
await tapVp(70, 32);               // «Triks» pill
await page.waitForTimeout(1600);
await page.screenshot({ path: ".screenshots/P69-wordalign-menu.png" });
console.log("menu_open:", await page.evaluate(() => window.__bra_menu_open ?? null));
console.log("sitt_pct:", await page.evaluate(() => window.__bra_learned_pct ?? null));
console.log("errors:", JSON.stringify(errs));
await browser.close();
