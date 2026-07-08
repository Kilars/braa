import { mkdir, writeFile } from "node:fs/promises";
import { chromium } from "playwright";
const base = "http://localhost:8099/index.html";
const W = 390, H = 844;
await mkdir(".screenshots", { recursive: true });
const P = ".screenshots/P54-";
const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport: { width: W, height: H }, deviceScaleFactor: 3 });
page.setDefaultTimeout(20000);
const errors = [];
page.on("console", m => { if (m.type() === "error") errors.push(m.text()); });
const g = async (k) => page.evaluate(new Function("return window.__bra_" + k + " ?? null"));
async function tapVp(x, y) {
  const box = await page.evaluate(() => { const r = document.querySelector("#canvas").getBoundingClientRect(); return {x:r.x,y:r.y,w:r.width,h:r.height}; });
  const vp = await page.evaluate(() => window.__bra_viewport || [720,1558]);
  await page.mouse.click(box.x + x * box.w / vp[0], box.y + y * box.h / vp[1]);
}
async function shot(name){
  const client = await page.context().newCDPSession(page);
  const { data } = await client.send("Page.captureScreenshot", { format: "png", captureBeyondViewport: false });
  await writeFile(`${P}${name}.png`, Buffer.from(data, "base64"));
  console.log("shot", name);
}
async function boot(q){
  await page.goto(`${base}${q}`, { waitUntil: "load", timeout: 90000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  await page.waitForTimeout(2500);
}
let code = 1;
try {
  // menu: own 2nd breed + active word so word/diff rows populate
  await boot(`?bra_coins=5000&bra_owned=chocolate&bra_active_word=dyktig`);
  console.log("vp:", await g("viewport"));
  await tapVp(84, 32);            // Triks pill
  await page.waitForTimeout(1200);
  console.log("menu_open:", await g("menu_open"));
  await shot("d-menu");
  console.log("word_rows:", JSON.stringify(await g("word_rows")));
  console.log("difficulty_rows:", JSON.stringify(await g("difficulty_rows")));

  // kennel grid + a modal
  await boot(`?bra_coins=5000`);
  const kb = await g("kennel_btn");
  console.log("kennel_btn:", JSON.stringify(kb));
  if (kb) { await tapVp(kb.x, kb.y); await page.waitForTimeout(1600); }
  await shot("d-kennel");
  // tap 2nd cell (Nova, epic) — grid is 2 cols; approximate cell center row1 col2
  const vp = await g("viewport");
  await tapVp(vp[0]*0.72, vp[1]*0.30);
  await page.waitForTimeout(1400);
  await shot("d-kennel-modal");

  code = 0;
} catch (e) { console.error("FAIL", e); code = 1; }
finally { console.log("errors:", errors.length ? errors : "none"); await browser.close(); process.exit(code); }
