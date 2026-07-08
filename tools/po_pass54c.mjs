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
  await page.goto(`${base}?bra_coins=2000&bra_menu_open=1`, { waitUntil: "load", timeout: 90000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  await page.waitForTimeout(2500);
  console.log("menu_open:", await g("menu_open"));
  await shot("30-menu");
  console.log("trick_rows:", JSON.stringify(await g("trick_rows")));
  console.log("breed_rows:", JSON.stringify(await g("breed_rows")));
  console.log("word_rows:", JSON.stringify(await g("word_rows")));
  console.log("feedback_row:", JSON.stringify(await g("feedback_row")));
  // open feedback
  const fr = await g("feedback_row");
  if (fr) {
    await tapVp(fr.x ?? fr[0], fr.y ?? fr[1]);
    await page.waitForTimeout(1500);
    console.log("feedback_open:", await g("feedback_open"));
    await shot("31-feedback");
  }
  code = 0;
} catch (e) { console.error("FAIL", e); code = 1; }
finally { console.log("errors:", errors.length ? errors : "none"); await browser.close(); process.exit(code); }
