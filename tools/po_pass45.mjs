import { mkdir, writeFile } from "node:fs/promises";
import { chromium } from "playwright";
const base = "http://localhost:8099/index.html";
const W = 390, H = 844;
await mkdir(".screenshots", { recursive: true });
const P = ".screenshots/P45-";
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
async function cdpShot(name){
  try {
    const client = await page.context().newCDPSession(page);
    const { data } = await client.send("Page.captureScreenshot", { format: "png", captureBeyondViewport: false });
    await writeFile(`${P}${name}.png`, Buffer.from(data, "base64"));
    console.log("cdp-shot ok", name);
  } catch(e){ console.log("cdp-shot-fail", name, e.message); }
}
let code = 1;
try {
  await page.goto(`${base}?bra_coins=2000`, { waitUntil: "load", timeout: 90000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  await page.waitForTimeout(3500);
  await cdpShot("01-training");
  const kb = await g("kennel_btn");
  await tapVp(kb.x, kb.y);
  await page.waitForTimeout(3500);
  await cdpShot("02-kennel-grid-t1");
  await page.waitForTimeout(2500);
  await cdpShot("03-kennel-grid-t2");
  let cells = await g("kennel_cells");
  for (let i = 0; i < 12 && !cells; i++) { await page.waitForTimeout(600); cells = await g("kennel_cells"); }
  console.log("cells:", cells ? cells.map(c=>c.id+"@"+Math.round(c.x)+","+Math.round(c.y)) : "null");
  if (cells) {
    for (const id of ["balder","sniff"]) {
      const t = cells.find(c => c.id === id);
      if (t) { await tapVp(t.x, t.y); await page.waitForTimeout(2200); await cdpShot("modal-"+id);
        // close modal
        await page.keyboard.press("Escape"); await page.waitForTimeout(800);
        const back = await g("kennel_modal_close"); if (back) { await tapVp(back.x, back.y); await page.waitForTimeout(1200); }
      }
    }
  }
  console.log("console errors:", errors.length ? errors : "none");
  code = 0;
} catch (e) { console.error("FAIL", e); code = 1; }
finally { await browser.close(); process.exit(code); }
