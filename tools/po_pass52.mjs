import { mkdir, writeFile } from "node:fs/promises";
import { chromium } from "playwright";
const base = "http://localhost:8099/index.html";
const W = 390, H = 844;
await mkdir(".screenshots", { recursive: true });
const P = ".screenshots/P52-";
const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport: { width: W, height: H }, deviceScaleFactor: 2 });
page.setDefaultTimeout(20000);
const errors = [];
page.on("console", m => { const t = m.text(); if (m.type() === "error") errors.push(t); });
const g = async (k) => page.evaluate(new Function("return window.__bra_" + k + " ?? null"));
async function shot(name){
  const client = await page.context().newCDPSession(page);
  const { data } = await client.send("Page.captureScreenshot", { format: "png", captureBeyondViewport: false });
  await writeFile(`${P}${name}.png`, Buffer.from(data, "base64"));
}
let code = 1;
try {
  await page.goto(`${base}?bra_autotap=1`, { waitUntil: "load", timeout: 90000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  await page.waitForTimeout(2500);
  await shot("00-training");        // 0% HUD
  // autotap climb — capture HUD when a mark lands (menu pops at 100%)
  let mastered = false;
  for (let i = 0; i < 24; i++) {
    await page.waitForTimeout(2500);
    const mo = await g("menu_open");
    console.log(`t=${(2.5+2.5*(i+1)).toFixed(1)}s menu_open=${mo}`);
    if (i === 6) await shot("partial-a");
    if (i === 14) await shot("partial-b");
    if (mo) { mastered = true; await shot("mastered"); break; }
  }
  // menu (open via tricks button if not already)
  if (!(await g("menu_open"))) { await page.evaluate("window.__bra_menu_open && window.__bra_menu_open()"); }
  await page.waitForTimeout(600);
  await shot("menu");
  console.log("errors:", errors.length ? errors : "none", "mastered:", mastered);
  code = 0;
} catch (e) { console.error("FAIL", e); code = 1; }
finally { await browser.close(); process.exit(code); }
