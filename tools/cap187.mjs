// 187 visual review: Nova (cell[1]) grid cell vs inspect-modal hero — coat brightness/hue parity.
// Uses CDP Page.captureScreenshot (playwright's page.screenshot hangs on the animated WebGL canvas).
import { chromium } from "playwright";
import { writeFile, mkdir } from "fs/promises";
const base = "http://localhost:8099/index.html";
await mkdir(".screenshots", { recursive: true });
const P = ".screenshots/187-";
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 3 });
const client = await page.context().newCDPSession(page);
const errors = [];
page.on("console", m => { if (m.type() === "error") errors.push(m.text()); });
const g = async (k) => page.evaluate(new Function("return window.__bra_" + k + " ?? null"));
async function capture(name) {
  const { data } = await client.send("Page.captureScreenshot", { format: "png", captureBeyondViewport: false });
  if (name) await writeFile(`${P}${name}.png`, Buffer.from(data, "base64"));
  return "data:image/png;base64," + data;
}
async function canvasBox() {
  return page.evaluate(() => { const r = document.querySelector("#canvas").getBoundingClientRect(); return {x:r.x,y:r.y,w:r.width,h:r.height}; });
}
async function tapVp(x, y) {
  const box = await canvasBox();
  const vp = await page.evaluate(() => window.__bra_viewport || [720,1558]);
  await page.mouse.click(box.x + x * box.w / vp[0], box.y + y * box.h / vp[1]);
}
// mean RGB of a DEVICE-pixel rect within a captured full-frame data URL.
async function meanRGB(dataUrl, px, py, pw, ph) {
  return page.evaluate(async (a) => {
    const img = new Image(); img.src = a.url; await img.decode();
    const c = document.createElement("canvas"); c.width = img.width; c.height = img.height;
    const cx = c.getContext("2d"); cx.drawImage(img, 0, 0);
    const d = cx.getImageData(a.px, a.py, a.pw, a.ph).data;
    let r=0,gg=0,bl=0,n=0;
    for (let i=0;i<d.length;i+=4){ r+=d[i]; gg+=d[i+1]; bl+=d[i+2]; n++; }
    return [Math.round(r/n), Math.round(gg/n), Math.round(bl/n)];
  }, { url: dataUrl, px: Math.round(px), py: Math.round(py), pw: Math.round(pw), ph: Math.round(ph) });
}
const DSF = 3;

await page.goto(`${base}?bra_coins=5000`, { waitUntil: "load", timeout: 90000 });
await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
await page.waitForTimeout(1500);
await tapVp(204, 32);              // open kennel via nav pill
await page.waitForTimeout(1500);
console.log("kennel_open", await g("kennel_open"));
const gridUrl = await capture("grid");
const cells = await g("kennel_cells");
const box = await canvasBox();
const vp = await page.evaluate(()=>window.__bra_viewport||[720,1558]);
const c1 = cells[1];              // Nova
const cxCss = box.x + c1.x * box.w / vp[0];
const cyCss = box.y + c1.y * box.h / vp[1];
// device-pixel patch on Nova's upper-body flank in the grid cell
const gridRGB = await meanRGB(gridUrl, (cxCss-14)*DSF, (cyCss-4)*DSF, 28*DSF, 18*DSF);

await tapVp(c1.x, c1.y); await page.waitForTimeout(1200);
let active = await g("kennel_active");
if (active === null) { await tapVp(c1.x, c1.y); await page.waitForTimeout(1200); active = await g("kennel_active"); }
console.log("kennel_active", active);
const modalUrl = await capture("modal");
// modal hero flank patch (upper band, left-of-centre)
const modalRGB = await meanRGB(modalUrl, (box.x+box.w*0.42)*DSF, (box.y+box.h*0.30)*DSF, 34*DSF, 24*DSF);

console.log("GRID_NOVA_RGB", JSON.stringify(gridRGB));
console.log("MODAL_NOVA_RGB", JSON.stringify(modalRGB));
const lum = c => 0.299*c[0]+0.587*c[1]+0.114*c[2];
console.log("DELTA_LUMA", Math.abs(lum(gridRGB)-lum(modalRGB)).toFixed(1));
console.log("GRID_warm(r-b)", gridRGB[0]-gridRGB[2], "MODAL_warm(r-b)", modalRGB[0]-modalRGB[2]);
console.log("errors", errors.length, errors.slice(0,3));
await browser.close();
