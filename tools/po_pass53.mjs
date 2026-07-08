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
async function tapVp(x, y) {
  const box = await page.locator("canvas").boundingBox();
  const vp = await page.evaluate(() => window.__bra_viewport || null);
  await page.mouse.click(box.x + x * box.width / (vp ? vp[0] : 720), box.y + y * box.height / (vp ? vp[1] : 1280));
}
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
  // Training + HUD partial fill
  await page.goto(`${base}?bra_autotap=1&bra_force_tier=perfect&bra_coins=2000`, { waitUntil: "load", timeout: 90000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  await page.waitForTimeout(2500);
  await shot("01-training-fresh");
  await page.waitForTimeout(6000);
  await shot("02-training-partial");
  await shot("02b-hud-crop", [0, 0, W*2, 240]);      // HUD strip @2x
  // let it master → menu
  let mo = false;
  for (let i=0;i<16 && !mo;i++){ await page.waitForTimeout(2500); mo = await g("menu_open"); }
  if (!mo) { await page.evaluate("window.__bra_menu_open && window.__bra_menu_open()"); await page.waitForTimeout(600); }
  await shot("03-menu");
  console.log("trick_rows:", JSON.stringify(await g("trick_rows")));
  console.log("word_rows:", JSON.stringify(await g("word_rows")));
  console.log("difficulty_rows:", JSON.stringify(await g("difficulty_rows")));
  console.log("breed_rows:", JSON.stringify(await g("breed_rows")));

  // Kennel grid + modal
  await page.goto(`${base}?bra_coins=2000`, { waitUntil: "load", timeout: 90000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  await page.waitForTimeout(3000);
  const kb = await g("kennel_btn");
  await tapVp(kb.x, kb.y);
  await page.waitForTimeout(4500);
  await shot("04-kennel-grid");
  const cells = await g("kennel_cells");
  console.log("cells:", JSON.stringify(cells));
  if (cells && cells.length > 2) {
    await tapVp(cells[2].x, cells[2].y);   // a buyable dog
    await page.waitForTimeout(2500);
    await shot("05-kennel-modal");
    console.log("kennel_action:", await g("kennel_action"));
  }
  console.log("console errors:", errors.length ? errors : "none");
  code = 0;
} catch (e) { console.error("FAIL", e); code = 1; }
finally { await browser.close(); process.exit(code); }
