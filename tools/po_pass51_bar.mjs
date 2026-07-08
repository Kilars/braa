import { mkdir, writeFile } from "node:fs/promises";
import { chromium } from "playwright";
const base = "http://localhost:8099/index.html";
const W = 390, H = 844;
await mkdir(".screenshots", { recursive: true });
const P = ".screenshots/P51b-";
const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport: { width: W, height: H }, deviceScaleFactor: 2 });
page.setDefaultTimeout(20000);
const errors = [];
page.on("console", m => { const t = m.text(); if (m.type() === "error") errors.push(t); if (t.includes("[Bra!]") || t.includes("mark") || t.includes("mastery")) console.log("GAME:", t); });
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
  await page.waitForTimeout(2000);
  // poll for up to 40s: watch menu_open (auto-pops on mastery) + capture HUD every few sec
  for (let i = 0; i < 16; i++) {
    await page.waitForTimeout(2500);
    const mo = await g("menu_open");
    const ct = await g("current_trick");
    console.log(`t=${(2+2.5*(i+1)).toFixed(1)}s menu_open=${mo} trick=${ct}`);
    if (i % 2 === 0) await shot("t" + i);
    if (mo) { console.log(">>> MASTERY MENU POPPED — bar climbed to 100%"); await shot("mastered");
      console.log("trick_rows:", JSON.stringify(await g("trick_rows"))); break; }
  }
  console.log("console errors:", errors.length ? errors : "none");
  code = 0;
} catch (e) { console.error("FAIL", e); code = 1; }
finally { await browser.close(); process.exit(code); }
