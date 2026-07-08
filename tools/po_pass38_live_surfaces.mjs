import { mkdir } from "node:fs/promises";
import { chromium } from "playwright";
const base = "https://kilars.github.io/braa/index.html";
await mkdir(".screenshots", { recursive: true });
const P = ".screenshots/P38S-";
const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 3 });
const errors = [];
page.on("console", m => { if (m.type() === "error") errors.push(m.text()); });
async function tapVp(x, y) {
  const box = await page.locator("canvas").boundingBox();
  const vp = await page.evaluate(() => window.__bra_viewport || null);
  await page.mouse.click(box.x + x * box.width / (vp ? vp[0] : 720), box.y + y * box.height / (vp ? vp[1] : 1280));
}
try {
  await page.goto(`${base}?bra_autotap=1&bra_coins=120`, { waitUntil: "load", timeout: 90000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  await page.waitForTimeout(5000);
  await page.screenshot({ path: `${P}training.png` });
  await tapVp(70, 32); // menu
  await page.waitForTimeout(1500);
  await page.screenshot({ path: `${P}menu.png` });
  console.log("console errors:", errors.length ? errors : "none");
} catch (e) { console.error("FAIL", e); }
finally { await browser.close(); process.exit(0); }
