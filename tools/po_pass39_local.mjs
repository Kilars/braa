import { mkdir } from "node:fs/promises";
import { chromium } from "playwright";
const base = "http://localhost:8099/index.html";
const W = 390, H = 844;
await mkdir(".screenshots", { recursive: true });
const P = ".screenshots/P39-";
const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport: { width: W, height: H }, deviceScaleFactor: 3 });
const errors = [];
page.on("console", m => { if (m.type() === "error") errors.push(m.text()); });
async function tapVp(x, y) {
  const box = await page.locator("canvas").boundingBox();
  const vp = await page.evaluate(() => window.__bra_viewport || null);
  await page.mouse.click(box.x + x * box.width / (vp ? vp[0] : 720), box.y + y * box.height / (vp ? vp[1] : 1280));
}
const g = async (k) => page.evaluate(new Function("return window.__bra_" + k + " ?? null"));
let code = 1;
try {
  await page.goto(`${base}?bra_autotap=1&bra_coins=120`, { waitUntil: "load", timeout: 90000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  await page.waitForTimeout(5000);
  await page.screenshot({ path: `${P}training.png` });
  console.log("active_breed:", await g("active_breed"), "balance:", await g("balance"));
  // open menu
  await tapVp(70, 32);
  await page.waitForTimeout(1500);
  await page.screenshot({ path: `${P}menu.png` });
  console.log("breed_rows:", JSON.stringify(await g("breed_rows")));
  console.log("showcase_row:", JSON.stringify(await g("showcase_row")));
  // adopt the 2nd breed so we have two breeds to show off (optional)
  const br = await g("breed_rows");
  const choc = br.find(r => r.id === "chocolate_labrador");
  if (choc) { await tapVp(choc.x, choc.y); await page.waitForTimeout(1200); await page.screenshot({ path: `${P}menu-after-adopt.png` }); }
  // open showcase
  const sc = await g("showcase_row");
  if (sc) { await tapVp(sc[0], sc[1]); await page.waitForTimeout(1600); }
  await page.screenshot({ path: `${P}showcase-0.png` });
  console.log("showcase_open:", await g("showcase_open"), "spotlit:", await g("showcase_spotlit"));
  // chevron next to view 2nd breed
  await page.waitForTimeout(1200);
  await page.screenshot({ path: `${P}showcase-1.png` });
  console.log("console errors:", errors.length ? errors : "none");
  code = 0;
} catch (e) { console.error("FAIL", e); code = 1; }
finally { await browser.close(); process.exit(code); }
