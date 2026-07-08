import { mkdir } from "node:fs/promises";
import { chromium } from "playwright";
const base = "https://kilars.github.io/braa/index.html";
await mkdir(".screenshots", { recursive: true });
const P = ".screenshots/P38K-";
const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 3 });
const errors = [];
page.on("console", m => { if (m.type() === "error") errors.push(m.text()); });
async function tapVp(x, y) {
  const box = await page.locator("canvas").boundingBox();
  const vp = await page.evaluate(() => window.__bra_viewport || null);
  await page.mouse.click(box.x + x * box.width / (vp ? vp[0] : 720), box.y + y * box.height / (vp ? vp[1] : 1280));
}
const dump = async (k) => JSON.stringify(await page.evaluate(new Function("return window.__bra_" + k + " ?? null")));
try {
  await page.goto(`${base}?bra_coins=200`, { waitUntil: "load", timeout: 90000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  await page.waitForTimeout(4000);
  const kb = JSON.parse(await dump("kennel_btn"));
  await tapVp(kb.x, kb.y); // open kennel
  await page.waitForTimeout(2500);
  await page.screenshot({ path: `${P}grid.png` });
  // tap a non-owned dog cell (Nova ~ second cell) to open modal
  await tapVp(540, 430);
  await page.waitForTimeout(1600);
  await page.screenshot({ path: `${P}modal.png` });
  console.log("kennel_btn:", JSON.stringify(kb));
  console.log("console errors:", errors.length ? errors : "none");
} catch (e) { console.error("FAIL", e); }
finally { await browser.close(); process.exit(0); }
