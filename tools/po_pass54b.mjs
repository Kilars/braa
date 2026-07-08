import { mkdir, writeFile } from "node:fs/promises";
import { chromium } from "playwright";
const base = "http://localhost:8099/index.html";
const W = 390, H = 844;
await mkdir(".screenshots", { recursive: true });
const P = ".screenshots/P54-";
const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport: { width: W, height: H }, deviceScaleFactor: 2 });
page.setDefaultTimeout(20000);
const errors = [];
page.on("console", m => { if (m.type() === "error") errors.push(m.text()); });
const g = async (k) => page.evaluate(new Function("return window.__bra_" + k + " ?? null"));
async function shot(name){
  const client = await page.context().newCDPSession(page);
  const { data } = await client.send("Page.captureScreenshot", { format: "png", captureBeyondViewport: false });
  await writeFile(`${P}${name}.png`, Buffer.from(data, "base64"));
  console.log("shot", name);
}
let code = 1;
try {
  await page.goto(`${base}?bra_autotap=1&bra_force_tier=perfect`, { waitUntil: "load", timeout: 90000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  // let it climb toward ~60%
  for (let i = 0; i < 40; i++) {
    await page.waitForTimeout(700);
    // no direct % seam; snapshot several
    if (i === 12) await shot("20-climb-a");
    if (i === 22) await shot("21-climb-b");
    if (i === 34) await shot("22-climb-c");
  }
  console.log("current_trick:", await g("current_trick"), "menu_open:", await g("menu_open"));
  code = 0;
} catch (e) { console.error("FAIL", e); code = 1; }
finally { console.log("errors:", errors.length ? errors : "none"); await browser.close(); process.exit(code); }
