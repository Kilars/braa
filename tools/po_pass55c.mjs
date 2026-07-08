import { chromium } from "playwright";
import { writeFile, mkdir } from "fs/promises";
const base = "http://localhost:8099/index.html";
await mkdir(".screenshots", { recursive: true });
const P = ".screenshots/P55-";
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
  await tapVp(84, 32);                 // Triks pill → open the completion menu
  await page.waitForTimeout(1200);
  const fr = await g("feedback_row");
  const vp = await g("viewport");
  console.log("feedback_row:", JSON.stringify(fr), "viewport:", JSON.stringify(vp));
  await tapVp(fr[0], fr[1]);           // tap the "Gi tilbakemelding" row
  await page.waitForTimeout(1200);
  console.log("feedback_open:", await g("feedback_open"));
  // Tap the first "Feil" chip. Modal is centred; chip row at ~y 452/844, "Feil" x ~140/390.
  const W = vp ? vp[0] : 720, H = vp ? vp[1] : 1558;
  await tapVp(0.36 * W, 0.535 * H);
  await page.waitForTimeout(500);
  await shot("f-feedback-chip-enabled");
  code = 0;
} catch (e) { console.error("FAIL", e); code = 1; }
finally { console.log("errors:", errors.length ? errors : "none"); await browser.close(); process.exit(code); }
