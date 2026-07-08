import { mkdir, writeFile } from "node:fs/promises";
import { chromium } from "playwright";
const base = "http://localhost:8099/index.html";
const W = 390, H = 844;
await mkdir(".screenshots", { recursive: true });
const P = ".screenshots/P49-";
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
}
let code = 1;
try {
  await page.goto(`${base}?bra_coins=2000`, { waitUntil: "load", timeout: 90000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  await page.waitForTimeout(3000);
  const kb = await g("kennel_btn");
  await tapVp(kb.x - 120, kb.y);   // Triks pill -> completion menu
  await page.waitForTimeout(1500);
  const br = await g("breed_rows");
  console.log("breed_rows:", JSON.stringify(br));
  if (br && br.length) {
    const last = br[br.length - 1];
    await tapVp(360, last.y + 62);   // Vis frem hundene
    await page.waitForTimeout(2000);
    console.log("showcase_open:", await g("showcase_open"), "spotlit:", JSON.stringify(await g("showcase_spotlit")));
    await shot("08-showcase");
    const btns = await g("showcase_buttons");
    console.log("showcase_buttons:", JSON.stringify(btns));
    // advance to next breed if a chevron exists
    if (btns && btns.length) {
      const nxt = btns[btns.length-1];
      await tapVp(nxt.x, nxt.y);
      await page.waitForTimeout(2000);
      await shot("09-showcase-next");
      console.log("spotlit2:", JSON.stringify(await g("showcase_spotlit")));
    }
  }
  console.log("console errors:", errors.length ? errors : "none");
  code = 0;
} catch (e) { console.error("FAIL", e); code = 1; }
finally { await browser.close(); process.exit(code); }
