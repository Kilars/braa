// PO pass 49 — full deep-play sweep: training + mark burst, completion menu (scrolled),
// kennel grid, several modals (Nova/Balder/Trulte), showcase.
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
async function boot(q){
  await page.goto(`${base}${q}`, { waitUntil: "load", timeout: 90000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
}
let code = 1;
try {
  // --- training + mark burst ---
  await boot(`?bra_coins=2000&bra_autotap=1`);
  await page.waitForTimeout(4500);
  await shot("01-training-autotap");
  console.log("current_trick:", await g("current_trick"), "balance:", await g("balance"));

  // --- fresh training (no autotap) for clean hero read ---
  await boot(`?bra_coins=2000`);
  await page.waitForTimeout(3500);
  await shot("02-training");

  // completion menu
  const kb = await g("kennel_btn");
  await tapVp(kb.x - 120, kb.y);
  await page.waitForTimeout(1600);
  console.log("menu_open:", await g("menu_open"));
  await shot("03-menu");
  console.log("trick_rows:", JSON.stringify(await g("trick_rows")));
  console.log("word_rows:", JSON.stringify(await g("word_rows")));
  console.log("difficulty_rows:", JSON.stringify(await g("difficulty_rows")));
  await page.mouse.wheel(0, 400); await page.waitForTimeout(600); await shot("04-menu-scroll1");
  await page.mouse.wheel(0, 400); await page.waitForTimeout(600); await shot("05-menu-scroll2");

  // kennel grid
  await boot(`?bra_coins=2000`);
  await page.waitForTimeout(2500);
  const kb2 = await g("kennel_btn");
  await tapVp(kb2.x, kb2.y);
  await page.waitForTimeout(2000);
  console.log("kennel_open:", await g("kennel_open"));
  await shot("06-kennel-grid");
  const cells = await g("kennel_cells");
  console.log("cells:", JSON.stringify(cells));

  // open a few modals
  if (cells && cells.length) {
    for (const [label, idx] of [["nova",1],["balder",2],["trulte",7]]) {
      const c = cells[idx];
      if (!c) continue;
      await tapVp(c.x, c.y);
      await page.waitForTimeout(1600);
      await shot(`07-modal-${label}`);
      console.log(`modal ${label} action:`, JSON.stringify(await g("kennel_action")));
      // close: tap top-left back-ish region / escape
      await page.keyboard.press("Escape");
      await page.waitForTimeout(400);
      // re-open grid if needed
      if (!(await g("kennel_open"))) { await tapVp(kb2.x, kb2.y); await page.waitForTimeout(1200); }
    }
  }

  console.log("console errors:", errors.length ? errors : "none");
  code = 0;
} catch (e) { console.error("FAIL", e); code = 1; }
finally { await browser.close(); process.exit(code); }
