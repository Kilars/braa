import { mkdir, writeFile } from "node:fs/promises";
import { chromium } from "playwright";
const base = "http://localhost:8099/index.html";
const W = 390, H = 844;
await mkdir(".screenshots", { recursive: true });
const P = ".screenshots/P53-";
const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport: { width: W, height: H }, deviceScaleFactor: 2 });
page.setDefaultTimeout(20000);
const errors = [];
page.on("console", m => { if (m.type() === "error") errors.push(m.text()); });
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
  // long climb, crop HUD every few seconds; stop when a non-zero fill appears then again mid
  for (let i=0;i<20;i++){
    await page.waitForTimeout(3000);
    const mo = await g("menu_open");
    console.log(`t=${3*(i+1)}s menu_open=${mo}`);
    if (i===3) await shot("hud-t12", [0, 60, W*2, 40]);
    if (i===7) await shot("hud-t24", [0, 60, W*2, 40]);
    if (i===12) await shot("hud-t39", [0, 60, W*2, 40]);
    if (mo){ await shot("hud-mastered", [0, 60, W*2, 40]); break; }
  }
  console.log("console errors:", errors.length ? errors : "none");
  code = 0;
} catch (e) { console.error("FAIL", e); code = 1; }
finally { await browser.close(); process.exit(code); }
