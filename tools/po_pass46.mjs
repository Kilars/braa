import { mkdir, writeFile } from "node:fs/promises";
import { chromium } from "playwright";
const base = "http://localhost:8099/index.html";
const W = 390, H = 844;
await mkdir(".screenshots", { recursive: true });
const P = ".screenshots/P46-";
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

  // open completion menu via the Triks pill (kennel_btn.x - 120, same y)
  const kb = await g("kennel_btn");
  await tapVp(kb.x - 120, kb.y);
  await page.waitForTimeout(1600);
  console.log("menu_open:", await g("menu_open"));
  console.log("trick_rows:", JSON.stringify(await g("trick_rows")));
  console.log("word_rows:", JSON.stringify(await g("word_rows")));
  console.log("breed_rows:", JSON.stringify(await g("breed_rows")));
  console.log("difficulty_rows:", JSON.stringify(await g("difficulty_rows")));
  await cdpShot("02-menu");
  // scroll the menu down if scrollable to see words/difficulty; capture again
  await page.mouse.wheel(0, 400); await page.waitForTimeout(800); await cdpShot("03-menu-scroll");

  // open breed showcase via a breed row tap (if exposed)
  const brows = await g("breed_rows");
  if (brows && brows.length) {
    const active = brows.find(r => r.state === "ACTIVE") || brows[0];
    if (active && active.x != null) { await tapVp(active.x, active.y); await page.waitForTimeout(1600);
      console.log("showcase_open:", await g("showcase_open"));
      await cdpShot("04-showcase");
      const sb = await g("showcase_buttons");
      if (sb) { const back = sb.find(b => /tilbake|back/i.test(b.id||b.label||"")); if (back) { await tapVp(back.x, back.y); await page.waitForTimeout(1000);} }
    }
  }
  // feedback form
  const fr = await g("feedback_row");
  if (fr && fr.x != null) { await tapVp(fr.x, fr.y); await page.waitForTimeout(1200); await cdpShot("05-feedback"); console.log("feedback_open:", await g("feedback_open")); }

  console.log("console errors:", errors.length ? errors : "none");
  code = 0;
} catch (e) { console.error("FAIL", e); code = 1; }
finally { await browser.close(); process.exit(code); }
