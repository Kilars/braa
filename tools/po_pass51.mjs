import { mkdir, writeFile } from "node:fs/promises";
import { chromium } from "playwright";
const base = "http://localhost:8099/index.html";
const W = 390, H = 844;
await mkdir(".screenshots", { recursive: true });
const P = ".screenshots/P51-";
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
  // ── Learned-bar drill: 0% → partial → mastered ──────────────
  await page.goto(`${base}`, { waitUntil: "load", timeout: 90000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  await page.waitForTimeout(3500);
  await shot("hud-00");   // 0% fresh
  console.log("trick:", await g("current_trick"), "trick_rows:", JSON.stringify(await g("trick_rows")));

  // Drive fill with autotap + forced-perfect, capture snapshots along the ramp.
  await page.goto(`${base}?bra_autotap=1&bra_force_tier=perfect`, { waitUntil: "load", timeout: 90000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  await page.waitForTimeout(2500);
  await shot("hud-ramp1");
  await page.waitForTimeout(2500);
  await shot("hud-ramp2");
  await page.waitForTimeout(3000);
  await shot("hud-ramp3");
  await page.waitForTimeout(4000);
  await shot("hud-mastered");   // gold latch hopefully
  console.log("trick_rows after ramp:", JSON.stringify(await g("trick_rows")));

  // ── Full sweep ──────────────
  await page.goto(`${base}?bra_coins=2000`, { waitUntil: "load", timeout: 90000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  await page.waitForTimeout(3000);
  await shot("01-training");

  const kb = await g("kennel_btn");
  await tapVp(kb.x - 120, kb.y);
  await page.waitForTimeout(1500);
  console.log("menu_open:", await g("menu_open"));
  await shot("02-menu");
  console.log("trick_rows:", JSON.stringify(await g("trick_rows")));
  console.log("breed_rows:", JSON.stringify(await g("breed_rows")));
  console.log("word_rows:", JSON.stringify(await g("word_rows")));
  console.log("difficulty_rows:", JSON.stringify(await g("difficulty_rows")));

  // Showcase - tap "Vis frem hundene"
  const sb = await g("showcase_buttons");
  console.log("showcase_buttons:", JSON.stringify(sb));

  // kennel
  await page.goto(`${base}?bra_coins=2000`, { waitUntil: "load", timeout: 90000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  await page.waitForTimeout(3000);
  const kb2 = await g("kennel_btn");
  await tapVp(kb2.x, kb2.y);
  await page.waitForTimeout(4500);
  console.log("kennel_open:", await g("kennel_open"));
  await shot("03-kennel-grid");
  const cells = await g("kennel_cells");
  console.log("kennel_cells:", JSON.stringify(cells));
  if (cells && cells.length > 1) {
    await tapVp(cells[1].x, cells[1].y);
    await page.waitForTimeout(2500);
    console.log("kennel_action:", await g("kennel_action"));
    await shot("04-kennel-modal");
  }

  console.log("console errors:", errors.length ? errors : "none");
  code = 0;
} catch (e) { console.error("FAIL", e); code = 1; }
finally { await browser.close(); process.exit(code); }
