// PO pass 48 — capture completion menu, kennel grid, a modal + HUD zoom crop.
import { mkdir, writeFile } from "node:fs/promises";
import { chromium } from "playwright";
import { PNG } from "playwright-core/lib/utilsBundle";
const base = "http://localhost:8099/index.html";
const W = 390, H = 844;
await mkdir(".screenshots", { recursive: true });
const P = ".screenshots/P48-";
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
  const buf = Buffer.from(data, "base64");
  await writeFile(`${P}${name}.png`, buf);
  return buf;
}
function crop(buf, name, x0f, y0f, x1f, y1f){
  const png = PNG.sync.read(buf);
  const iw = png.width, ih = png.height;
  const x0 = Math.floor(iw*x0f), y0 = Math.floor(ih*y0f), x1 = Math.floor(iw*x1f), y1 = Math.floor(ih*y1f);
  const cw = x1-x0, ch = y1-y0;
  const out = new PNG({ width: cw, height: ch });
  for (let y=0;y<ch;y++) for (let x=0;x<cw;x++){
    const si = ((y+y0)*iw + (x+x0))*4, di = (y*cw+x)*4;
    out.data[di]=png.data[si]; out.data[di+1]=png.data[si+1]; out.data[di+2]=png.data[si+2]; out.data[di+3]=png.data[si+3];
  }
  return writeFile(`${P}${name}.png`, PNG.sync.write(out));
}
let code = 1;
try {
  await page.goto(`${base}?bra_coins=2000`, { waitUntil: "load", timeout: 90000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  await page.waitForTimeout(3500);
  const train = await shot("s01-training");
  await crop(train, "s01-hud-zoom", 0.0, 0.0, 1.0, 0.16);

  // completion menu via Triks pill
  const kb = await g("kennel_btn");
  await tapVp(kb.x - 120, kb.y);
  await page.waitForTimeout(1600);
  console.log("menu_open:", await g("menu_open"));
  await shot("s02-menu");
  await page.mouse.wheel(0, 500); await page.waitForTimeout(700); await shot("s03-menu-scroll");

  // kennel grid
  await page.goto(`${base}?bra_coins=2000`, { waitUntil: "load", timeout: 90000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  await page.waitForTimeout(2500);
  const kb2 = await g("kennel_btn");
  await tapVp(kb2.x, kb2.y);
  await page.waitForTimeout(1800);
  console.log("kennel_open:", await g("kennel_open"));
  await shot("s04-kennel-grid");

  console.log("console errors:", errors.length ? errors : "none");
  code = 0;
} catch (e) { console.error("FAIL", e); code = 1; }
finally { await browser.close(); process.exit(code); }
