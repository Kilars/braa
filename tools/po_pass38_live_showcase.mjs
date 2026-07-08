import { mkdir } from "node:fs/promises";
import { chromium } from "playwright";
const base = "https://kilars.github.io/braa/index.html";
const W = 390, H = 844;
await mkdir(".screenshots", { recursive: true });
const P = ".screenshots/P38L-";
const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport: { width: W, height: H }, deviceScaleFactor: 3 });
const errors = [];
page.on("console", m => { if (m.type() === "error") errors.push(m.text()); });
async function tapVp(x, y) {
  const box = await page.locator("canvas").boundingBox();
  const vp = await page.evaluate(() => window.__bra_viewport || null);
  await page.mouse.click(box.x + x * box.width / (vp ? vp[0] : 720), box.y + y * box.height / (vp ? vp[1] : 1280));
}
const dump = async (k) => JSON.stringify(await page.evaluate(new Function("return window.__bra_" + k + " ?? null")));
let code = 1;
try {
  await page.goto(`${base}?bra_autotap=1&bra_coins=120`, { waitUntil: "load", timeout: 90000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  await page.waitForTimeout(6000);
  const boot = await page.evaluate(() => window.__bra_boot_dog || "n/a");
  await tapVp(70, 32);
  await page.waitForTimeout(1500);
  const br = JSON.parse(await dump("breed_rows"));
  const buy = br.find(r => r.id === "chocolate_labrador");
  if (buy) { await tapVp(buy.x, buy.y); await page.waitForTimeout(1400); }
  const br2 = JSON.parse(await dump("breed_rows"));
  const last = br2[br2.length - 1];
  await tapVp(last.x, last.y + 62);
  await page.waitForTimeout(800);
  for (const t of [0, 1500, 3000, 4500, 6000]) {
    await page.waitForTimeout(t === 0 ? 200 : 1500);
    await page.screenshot({ path: `${P}t${t}.png` });
  }
  console.log("boot_dog:", boot);
  console.log("console errors:", errors.length ? errors : "none");
  code = 0;
} catch (e) { console.error("FAIL", e); code = 1; }
finally { await browser.close(); process.exit(code); }
