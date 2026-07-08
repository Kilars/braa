import { mkdir } from "node:fs/promises";
import { chromium } from "playwright";
const base = "http://localhost:8099/index.html";
const W = 390, H = 844;
await mkdir(".screenshots", { recursive: true });
const P = ".screenshots/P44-";
const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport: { width: W, height: H }, deviceScaleFactor: 3 });
const errors = [];
page.on("console", m => { if (m.type() === "error") errors.push(m.text()); });
async function tapVp(x, y) {
  const box = await page.locator("canvas").boundingBox();
  const vp = await page.evaluate(() => window.__bra_viewport || null);
  await page.mouse.click(box.x + x * box.width / (vp ? vp[0] : 720), box.y + y * box.height / (vp ? vp[1] : 1280));
}
const g = async (k) => page.evaluate(new Function("return window.__bra_" + k + " ?? null"));
let code = 1;
try {
  await page.goto(`${base}?bra_coins=2000`, { waitUntil: "load", timeout: 90000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  await page.waitForTimeout(4000);
  // 1. training page fresh
  await page.screenshot({ path: `${P}01-training.png` });
  // 2. autotap mastery burst -> completion menu
  await page.goto(`${base}?bra_coins=2000&bra_autotap=1`, { waitUntil: "load", timeout: 90000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  await page.waitForTimeout(6000);
  await page.screenshot({ path: `${P}02-autotap.png` });
  // open completion menu (hamburger top-left)
  await tapVp(70, 32);
  await page.waitForTimeout(1600);
  await page.screenshot({ path: `${P}03-menu.png` });
  // 3. kennel grid
  const kb = await g("kennel_btn");
  if (kb) { await tapVp(kb.x, kb.y); await page.waitForTimeout(2500); }
  await page.screenshot({ path: `${P}04-kennel-grid.png` });
  let cells = await g("kennel_cells");
  for (let i = 0; i < 12 && !cells; i++) { await page.waitForTimeout(600); cells = await g("kennel_cells"); }
  console.log("cells:", cells ? cells.map(c=>c.id).join(",") : "none");
  // 4. modal on Sol (golden)
  if (cells) {
    const t = cells.find(c => c.id === "sol") || cells[3];
    await tapVp(t.x, t.y);
    await page.waitForTimeout(1800);
    await page.screenshot({ path: `${P}05-modal-sol.png` });
  }
  console.log("console errors:", errors.length ? errors : "none");
  code = 0;
} catch (e) { console.error("FAIL", e); code = 1; }
finally { await browser.close(); process.exit(code); }
