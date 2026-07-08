import { mkdir } from "node:fs/promises";
import { chromium } from "playwright";
const base = "http://localhost:8099/index.html";
const W = 390, H = 844;
await mkdir(".screenshots", { recursive: true });
const P = ".screenshots/P44-";
const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport: { width: W, height: H }, deviceScaleFactor: 1 });
page.setDefaultTimeout(20000);
async function tapVp(x, y) {
  const box = await page.locator("canvas").boundingBox();
  const vp = await page.evaluate(() => window.__bra_viewport || null);
  await page.mouse.click(box.x + x * box.width / (vp ? vp[0] : 720), box.y + y * box.height / (vp ? vp[1] : 1280));
}
const g = async (k) => page.evaluate(new Function("return window.__bra_" + k + " ?? null"));
async function cdpShot(name){
  const client = await page.context().newCDPSession(page);
  const { data } = await client.send("Page.captureScreenshot", { format: "png", captureBeyondViewport: false });
  const { writeFile } = await import("node:fs/promises");
  await writeFile(`${P}${name}.png`, Buffer.from(data, "base64"));
  console.log("shot", name);
}
try {
  await page.goto(`${base}?bra_coins=2000`, { waitUntil: "load", timeout: 90000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  await page.waitForTimeout(3500);
  const kb = await g("kennel_btn");
  await tapVp(kb.x, kb.y);
  await page.waitForTimeout(2000);
  await cdpShot("grid-t1");
  await page.waitForTimeout(2500);
  await cdpShot("grid-t2");
  console.log("ok");
} catch (e) { console.error("FAIL", e); }
finally { await browser.close(); process.exit(0); }
