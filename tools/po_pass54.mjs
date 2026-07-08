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
async function tapVp(x, y) {
  const box = await page.locator("canvas").boundingBox();
  const vp = await page.evaluate(() => window.__bra_viewport || null);
  await page.mouse.click(box.x + x * box.width / (vp ? vp[0] : 720), box.y + y * box.height / (vp ? vp[1] : 1280));
}
async function shot(name){
  const client = await page.context().newCDPSession(page);
  const { data } = await client.send("Page.captureScreenshot", { format: "png", captureBeyondViewport: false });
  await writeFile(`${P}${name}.png`, Buffer.from(data, "base64"));
  console.log("shot", name);
}
let code = 1;
try {
  // ---- Fresh training boot ----
  await page.goto(`${base}?bra_coins=2000`, { waitUntil: "load", timeout: 90000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  await page.waitForTimeout(3000);
  await shot("01-training-fresh");
  console.log("current_trick:", await g("current_trick"), "balance:", await g("balance"));

  // ---- Kennel grid ----
  const kb = await g("kennel_btn");
  console.log("kennel_btn:", JSON.stringify(kb));
  await tapVp(kb.x, kb.y);
  await page.waitForTimeout(1800);
  console.log("kennel_open:", await g("kennel_open"));
  await shot("02-kennel-grid");
  const cells = await g("kennel_cells");
  console.log("cells:", JSON.stringify(cells));

  // ---- open a modal on cell 1 (Nova, epic) ----
  if (cells && cells.length > 1) {
    await tapVp(cells[1].x, cells[1].y);
    await page.waitForTimeout(1500);
    await shot("03-kennel-modal");
  }
  code = 0;
} catch (e) { console.error("FAIL", e); code = 1; }
finally {
  console.log("errors:", errors.length ? errors : "none");
  await browser.close();
  process.exit(code);
}
