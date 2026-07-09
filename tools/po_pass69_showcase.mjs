// PO father-pass-69: quick menu + breed-showcase capture. Menu opens via the Triks pill
// (fixed vp tap 70,32); with 5000 coins the Raser + «Vis frem hundene» rows reveal at once.
import { chromium } from "playwright";
import { writeFile } from "fs/promises";
const base = "http://localhost:8099/index.html";
const P = ".screenshots/P69s-";
const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 1 });
const client = await page.context().newCDPSession(page);
const errors = [];
page.on("console", m => { if (m.type() === "error") errors.push(m.text()); });
const g = async (k) => page.evaluate(new Function("return window.__bra_" + k + " ?? null"));
async function cap(name){const {data}=await client.send("Page.captureScreenshot",{format:"png",captureBeyondViewport:false});await writeFile(`${P}${name}.png`,Buffer.from(data,"base64"));}
async function box(){return await page.evaluate(()=>{const c=document.querySelector("canvas");const r=c.getBoundingClientRect();return {x:r.x,y:r.y,w:r.width,h:r.height};});}
async function tapVp(x,y){const b=await box();const vp=await g("viewport")||[720,1558];await page.mouse.click(b.x+x*b.w/vp[0], b.y+y*b.h/vp[1]);}

await page.goto(`${base}?bra_coins=5000`,{waitUntil:"load",timeout:90000});
await page.waitForFunction("window.__appReady === true",undefined,{timeout:120000});
await page.waitForTimeout(2500);
await tapVp(70,32); await page.waitForTimeout(1200);
console.log("menu_open", await g("menu_open"), "breed_rows", (await g("breed_rows")||[]).map(b=>b.id));
await cap("a-menu");
const sc = await g("showcase_row");
console.log("showcase_row", sc);
if(sc){ await tapVp(sc[0], sc[1]); await page.waitForTimeout(1600);
  console.log("showcase_open", await g("showcase_open"), "spotlit", await g("showcase_spotlit"));
  await cap("b-showcase");
}
console.log("errors", errors.length, errors.slice(0,6));
await browser.close();
