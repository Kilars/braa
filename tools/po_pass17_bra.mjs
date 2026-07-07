import { chromium } from "playwright";
const base = process.argv[2];
const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
// NO autotap — let the button rest so we see its normal (non-cooldown) label colour
await page.goto(base, { waitUntil: "load", timeout: 90000 });
await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
await page.waitForTimeout(3500);
await page.screenshot({ path: ".screenshots/P17-03-rest.png" });
console.log("done");
await browser.close();
