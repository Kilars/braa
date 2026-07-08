// PO pass 49 follow-up: adopt a SECOND breed, then verify the showcase chevrons
// APPEAR and "next" genuinely advances the spotlight (the pass-49 open question).
import { mkdir, writeFile } from "node:fs/promises";
import { chromium } from "playwright";
const base = "http://localhost:8099/index.html";
const W = 390, H = 844;
await mkdir(".screenshots", { recursive: true });
const P = ".screenshots/P49b-";
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
async function openMenu(){
  const kb = await g("kennel_btn");
  await tapVp(kb.x - 120, kb.y);
  await page.waitForTimeout(1500);
}
let code = 1;
try {
  await page.goto(`${base}?bra_coins=2000`, { waitUntil: "load", timeout: 90000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  await page.waitForTimeout(3000);

  await openMenu();
  let br = await g("breed_rows");
  console.log("breed_rows(before adopt):", JSON.stringify(br), "owned:", await g("owned"));
  // Adopt the second breed (Brun lab / chocolate — Adopter 30). Tap its row twice if needed
  // (row tap selects; adopt CTA lands on the row). Use the last breed row.
  const choc = br[br.length - 1];
  await tapVp(choc.x, choc.y);
  await page.waitForTimeout(1200);
  await tapVp(choc.x, choc.y);
  await page.waitForTimeout(1200);
  console.log("owned(after adopt taps):", await g("owned"), "balance:", await g("balance"));
  await shot("01-menu-after-adopt");

  // Re-open menu fresh to read roster
  await openMenu();
  br = await g("breed_rows");
  console.log("breed_rows(after):", JSON.stringify(br));

  // Open showcase
  const sc = await g("showcase_row");
  if (sc) { await tapVp(sc[0], sc[1]); await page.waitForTimeout(2200); }
  console.log("showcase_spotlit:", await g("showcase_spotlit"));
  const btns = await g("showcase_buttons");
  console.log("showcase_buttons:", JSON.stringify(btns));
  await shot("02-showcase-initial");
  if (btns && btns.next) {
    await tapVp(btns.next.x, btns.next.y);
    await page.waitForTimeout(2200);
    console.log("showcase_spotlit_after_next:", await g("showcase_spotlit"));
    await shot("03-showcase-after-next");
    await tapVp(btns.prev.x, btns.prev.y);
    await page.waitForTimeout(2200);
    console.log("showcase_spotlit_after_prev:", await g("showcase_spotlit"));
    await shot("04-showcase-after-prev");
  }
  console.log("console errors:", errors.length ? errors : "none");
  code = 0;
} catch (e) { console.error("FAIL", e); code = 1; }
finally { await browser.close(); process.exit(code); }
