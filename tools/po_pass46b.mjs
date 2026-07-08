import { mkdir, writeFile } from "node:fs/promises";
import { chromium } from "playwright";
const base = "http://localhost:8099/index.html";
const W = 390, H = 844;
await mkdir(".screenshots", { recursive: true });
const P = ".screenshots/P46-";
const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport: { width: W, height: H }, deviceScaleFactor: 2 });
page.setDefaultTimeout(20000);
const errors = [];
page.on("console", m => { if (m.type() === "error") errors.push(m.text()); });
async function tapVp(x, y) {
  const box = await page.locator("canvas").boundingBox();
  const vp = await page.evaluate(() => window.__bra_viewport || null);
  await page.mouse.click(box.x + x * box.width / (vp ? vp[0] : 720), box.y + y * box.height / (vp ? vp[1] : 1280));
}
const g = async (k) => page.evaluate(new Function("return window.__bra_" + k + " ?? null"));
async function cdpShot(name){
  try {
    const client = await page.context().newCDPSession(page);
    const { data } = await client.send("Page.captureScreenshot", { format: "png", captureBeyondViewport: false });
    await writeFile(`${P}${name}.png`, Buffer.from(data, "base64"));
  } catch(e){ console.log("cdp-shot-fail", name, e.message); }
}
let code = 1;
try {
  // autotap so the dog sits & faces camera at the apex -> fair coat/pose capture
  await page.goto(`${base}?bra_coins=2000&bra_autotap=1`, { waitUntil: "load", timeout: 90000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  // burst of frames to catch a front-facing apex
  for (let i = 0; i < 10; i++) { await page.waitForTimeout(700); await cdpShot("apex-"+i); }

  // kennel grid — front-¾ verification (177)
  const kb = await g("kennel_btn");
  await tapVp(kb.x, kb.y);
  await page.waitForTimeout(3500);
  await cdpShot("kennel-grid");
  await page.waitForTimeout(2500);
  await cdpShot("kennel-grid-t2");

  console.log("console errors:", errors.length ? errors : "none");
  code = 0;
} catch (e) { console.error("FAIL", e); code = 1; }
finally { await browser.close(); process.exit(code); }
