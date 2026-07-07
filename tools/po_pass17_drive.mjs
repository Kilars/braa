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
await page.waitForTimeout(3000);
await page.screenshot({ path: ".screenshots/P17-01-training.png" });
console.log("current_trick(training):", await page.evaluate(() => window.__bra_current_trick ?? null));

// Open the completion/pause Triks menu via the top-left pill
await tapVp(70, 32);
await page.waitForTimeout(1500);
await page.screenshot({ path: ".screenshots/P17-02-menu.png" });
console.log("menu_open:", await page.evaluate(() => window.__bra_menu_open ?? null));
console.log("current_trick(menu):", await page.evaluate(() => window.__bra_current_trick ?? null));
console.log("menu_rows:", JSON.stringify(await page.evaluate(() => window.__bra_menu_rows ?? null)));

console.log("ERRORS:", errs.length, errs.slice(0,5));
await browser.close();
