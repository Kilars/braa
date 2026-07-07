import { chromium } from "playwright";
const base = process.argv[2];
const GODOT_W = 720, GODOT_H = 1280;
const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
async function tapVp(x, y) {
	const box = await page.locator("canvas").boundingBox();
	const vp = await page.evaluate(() => window.__bra_viewport || null);
	await page.mouse.click(box.x + x * box.width / (vp?vp[0]:GODOT_W), box.y + y * box.height / (vp?vp[1]:GODOT_H));
}
async function openCell(id) {
	const cells = await page.evaluate(() => window.__bra_kennel_cells || []);
	const c = cells.find(x => x.id === id);
	if (!c) return false;
	await tapVp(c.x, c.y); await page.waitForTimeout(1100); return true;
}
await page.goto(base + "?bra_autotap=1", { waitUntil: "load", timeout: 90000 });
await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
await page.waitForTimeout(2200);
await tapVp(204, 32);
await page.waitForFunction("window.__bra_kennel_open === true", undefined, { timeout: 12000 });
await page.waitForTimeout(900);
// adopt Trulte free
await openCell("trulte");
await tapVp(360, 876);              // «Adopter gratis ♥» CTA
await page.waitForTimeout(1400);
const active = await page.evaluate(() => window.__bra_active_dog || null);
console.log("active after adopt:", active);
await tapVp(40, 60); await page.waitForTimeout(700);
// re-open Bella
await openCell("bella");
await page.screenshot({ path: ".screenshots/P16-bella-switch2.png" });
await browser.close();
