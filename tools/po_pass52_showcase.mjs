import { mkdir, writeFile } from "node:fs/promises";
import { chromium } from "playwright";
const base = "http://localhost:8099/index.html";
const W = 390, H = 844;
await mkdir(".screenshots", { recursive: true });
const P = ".screenshots/P52s-";
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
async function shot(name){
  const client = await page.context().newCDPSession(page);
  const { data } = await client.send("Page.captureScreenshot", { format: "png", captureBeyondViewport: false });
  await writeFile(`${P}${name}.png`, Buffer.from(data, "base64"));
  console.log("shot", name);
}
let code = 1;
try {
  await page.goto(`${base}?bra_coins=2000`, { waitUntil: "load", timeout: 90000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  await page.waitForTimeout(3000);
  // open menu, adopt Brun lab
  const kb = await g("kennel_btn");
  await tapVp(kb.x - 120, kb.y);
  await page.waitForTimeout(1500);
  const breeds = await g("breed_rows");
  const choc = breeds.find(b => b.id.includes("chocolate"));
  await tapVp(choc.x, choc.y);
  await page.waitForTimeout(1500);
  console.log("owned:", JSON.stringify(await g("owned")));
  // open showcase via the published menu row centre
  const sr = await g("showcase_row");
  console.log("showcase_row:", JSON.stringify(sr));
  await tapVp(sr[0], sr[1]);
  await page.waitForTimeout(2500);
  console.log("showcase_open:", await g("showcase_open"), "spotlit:", await g("showcase_spotlit"));
  await shot("01-showcase-bella");
  const btns = await g("showcase_buttons");
  console.log("showcase_buttons:", JSON.stringify(btns));
  if (btns && btns.length > 1) {
    const nextBtn = btns[btns.length - 1];
    await tapVp(nextBtn.x, nextBtn.y);
    await page.waitForTimeout(2500);
    console.log("spotlit after next:", await g("showcase_spotlit"));
    await shot("02-showcase-next");
  }
  console.log("errors:", errors.length ? errors : "none");
  code = 0;
} catch (e) { console.error("FAIL", e); code = 1; }
finally { await browser.close(); process.exit(code); }
