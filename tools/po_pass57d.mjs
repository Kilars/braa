import { chromium } from "playwright";
import { writeFile, mkdir } from "fs/promises";
const base = "http://localhost:8099/index.html";
await mkdir(".screenshots", { recursive: true });
const P = ".screenshots/P57-";
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 3 });
const errors = [];
page.on("console", m => { if (m.type() === "error") errors.push(m.text()); });
const g = async (k) => page.evaluate(new Function("return window.__bra_" + k + " ?? null"));
async function tapVp(x, y) {
  const box = await page.evaluate(() => { const r = document.querySelector("#canvas").getBoundingClientRect(); return {x:r.x,y:r.y,w:r.width,h:r.height}; });
  const vp = await page.evaluate(() => window.__bra_viewport || [720,1558]);
  const cx = box.x + x * box.w / vp[0], cy = box.y + y * box.h / vp[1];
  console.log("click at css", Math.round(cx), Math.round(cy), "from vp", x, y);
  await page.mouse.click(cx, cy);
}
async function shot(name){
  const client = await page.context().newCDPSession(page);
  const { data } = await client.send("Page.captureScreenshot", { format: "png", captureBeyondViewport: false });
  await writeFile(`${P}${name}.png`, Buffer.from(data, "base64"));
  console.log("shot", name);
}
let code = 1;
try {
  await page.goto(`${base}?bra_coins=5000`, { waitUntil: "load", timeout: 90000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  await page.waitForTimeout(2000);

  // --- feedback form (menu -> Gi tilbakemelding) ---
  await tapVp(84, 32); await page.waitForTimeout(900);
  const fr = await g("feedback_row"); console.log("feedback_row", fr);
  if (fr) { await tapVp(fr[0], fr[1]); await page.waitForTimeout(900); console.log("feedback_open", await g("feedback_open")); await shot("feedback"); }

  // reload for kennel modal
  await page.goto(`${base}?bra_coins=5000`, { waitUntil: "load", timeout: 90000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  await page.waitForTimeout(1500);
  await tapVp(200, 32); await page.waitForTimeout(1200);
  const cells = await g("kennel_cells"); console.log("cells", JSON.stringify(cells));
  if (cells && cells[1]) { await tapVp(cells[1][0], cells[1][1]); await page.waitForTimeout(1100); await shot("kennel-modal"); }
  code = 0;
} catch (e) { console.error("FAIL", e); code = 1; }
finally { console.log("errors:", errors.length ? errors : "none"); await browser.close(); process.exit(code); }
