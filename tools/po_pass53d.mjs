import { mkdir, writeFile } from "node:fs/promises";
import { chromium } from "playwright";
const base = "http://localhost:8099/index.html";
const W = 390, H = 844;
await mkdir(".screenshots", { recursive: true });
const P = ".screenshots/P53-";
const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport: { width: W, height: H }, deviceScaleFactor: 2 });
page.setDefaultTimeout(20000);
const g = async (k) => page.evaluate(new Function("return window.__bra_" + k + " ?? null"));
async function shot(name, clip){
  const client = await page.context().newCDPSession(page);
  const opts = { format: "png", captureBeyondViewport: false };
  if (clip) opts.clip = { x: clip[0], y: clip[1], width: clip[2], height: clip[3], scale: 1 };
  const { data } = await client.send("Page.captureScreenshot", opts);
  await writeFile(`${P}${name}.png`, Buffer.from(data, "base64"));
  console.log("shot", name);
}
let code = 1;
try {
  await page.goto(`${base}?bra_autotap=1&bra_force_tier=perfect`, { waitUntil: "load", timeout: 90000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  // climb until near mastery, snapshot the readout row (CSS px clip)
  for (let i=0;i<22;i++){
    await page.waitForTimeout(3000);
    const mo = await g("menu_open");
    if (i>=6 && i%2===0 && !mo) await shot("bar-"+(3*(i+1))+"s", [8, 26, 374, 26]);
    if (mo) break;
  }
  code = 0;
} catch (e) { console.error("FAIL", e); code = 1; }
finally { await browser.close(); process.exit(code); }
