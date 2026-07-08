import { mkdir, writeFile } from "node:fs/promises";
import { chromium } from "playwright";
const base = "http://localhost:8099/index.html";
const W = 390, H = 844;
await mkdir(".screenshots", { recursive: true });
const P = ".screenshots/P47-";
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

  // open kennel via kennel_btn
  const kb = await g("kennel_btn");
  console.log("kennel_btn:", JSON.stringify(kb));
  await tapVp(kb.x, kb.y);
  await page.waitForTimeout(2500);
  console.log("kennel_open:", await g("kennel_open"));
  await cdpShot("02-kennel-grid");

  // tap a mid dog cell — try Balder (brown, cell 3) and Sol (golden, cell 4)
  const cells = await g("kennel_cells");
  console.log("kennel_cells:", JSON.stringify(cells));
  if (cells && cells.length) {
    const balder = cells.find(c => /balder/i.test(c.name||c.id||"")) || cells[2];
    if (balder && balder.x != null) { await tapVp(balder.x, balder.y); await page.waitForTimeout(2000); await cdpShot("03-modal-balder");
      console.log("modal_open:", await g("kennel_modal_open"));
      // close modal
      const cx = await g("kennel_modal_close"); if (cx && cx.x!=null){ await tapVp(cx.x, cx.y); await page.waitForTimeout(1200);}
    }
    const sol = cells.find(c => /sol/i.test(c.name||c.id||""));
    if (sol && sol.x != null) { await tapVp(sol.x, sol.y); await page.waitForTimeout(2000); await cdpShot("04-modal-sol");
      const cx = await g("kennel_modal_close"); if (cx && cx.x!=null){ await tapVp(cx.x, cx.y); await page.waitForTimeout(1000);} }
  }

  console.log("console errors:", errors.length ? errors : "none");
  code = 0;
} catch (e) { console.error("FAIL", e); code = 1; }
finally { await browser.close(); process.exit(code); }
