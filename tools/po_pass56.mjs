import { chromium } from "playwright";
import { writeFile, mkdir } from "fs/promises";
const base = "http://localhost:8099/index.html";
await mkdir(".screenshots", { recursive: true });
const P = ".screenshots/P56-";
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 3 });
const errors = [];
page.on("console", m => { if (m.type() === "error") errors.push(m.text()); });
const g = async (k) => page.evaluate(new Function("return window.__bra_" + k + " ?? null"));
async function tapVp(x, y) {
  const box = await page.evaluate(() => { const r = document.querySelector("#canvas").getBoundingClientRect(); return {x:r.x,y:r.y,w:r.width,h:r.height}; });
  const vp = await page.evaluate(() => window.__bra_viewport || [720,1558]);
  await page.mouse.click(box.x + x * box.w / vp[0], box.y + y * box.h / vp[1]);
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
  await page.waitForTimeout(2500);
  await shot("a-training");
  const vp = await g("viewport"); const W = vp[0], H = vp[1];
  console.log("viewport", vp);

  // open completion menu
  await tapVp(84, 32);
  await page.waitForTimeout(1200);
  await shot("b-menu");

  // open feedback form
  const fr = await g("feedback_row");
  console.log("feedback_row", fr);
  await tapVp(fr[0], fr[1]);
  await page.waitForTimeout(1000);
  console.log("feedback_open", await g("feedback_open"));
  await shot("c-feedback-blank");   // 182: disabled Send should be muted grey-blue

  // tap a chip -> Send should snap to deep blue
  await tapVp(0.36 * W, 0.535 * H);
  await page.waitForTimeout(500);
  await shot("d-feedback-chip");
  code = 0;
} catch (e) { console.error("FAIL", e); code = 1; }
finally { console.log("errors:", errors.length ? errors : "none"); await browser.close(); process.exit(code); }
