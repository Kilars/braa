// PO pass-70 showcase bottom-control zoom. Open menu (Triks 62,27), tap showcase_row, 2x zoom.
import { chromium } from "playwright";
import { writeFile } from "fs/promises";
const base = "http://localhost:8099/index.html";
const P = ".screenshots/P70d-";
const browser = await chromium.launch({ args: ["--no-sandbox","--disable-dev-shm-usage","--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport:{width:390,height:844}, deviceScaleFactor:2 });
const client = await page.context().newCDPSession(page);
const errors=[]; page.on("console",m=>{if(m.type()==="error")errors.push(m.text());});
const g=async(k)=>page.evaluate(new Function("return window.__bra_"+k+" ?? null"));
async function cap(name,clip){const o={format:"png"};if(clip)o.clip={...clip,scale:2};const{data}=await client.send("Page.captureScreenshot",o);await writeFile(`${P}${name}.png`,Buffer.from(data,"base64"));}
async function box(){return await page.evaluate(()=>{const c=document.querySelector("canvas");const r=c.getBoundingClientRect();return{x:r.x,y:r.y,w:r.width,h:r.height};});}
async function tapVp(x,y){const b=await box();const vp=await g("viewport")||[720,1558];await page.mouse.click(b.x+x*b.w/vp[0], b.y+y*b.h/vp[1]);}
async function tapScreen(sx,sy){const b=await box();await page.mouse.click(b.x+sx*b.w/390, b.y+sy*b.h/844);}

await page.goto(`${base}?bra_coins=5000`,{waitUntil:"load",timeout:90000});
await page.waitForFunction("window.__appReady === true",undefined,{timeout:120000});
await page.waitForTimeout(4000);
await tapScreen(62,27); await page.waitForTimeout(1000);
console.log("menu_open", await g("menu_open"));
const sc=await g("showcase_row"); console.log("showcase_row",sc);
if(sc){ await tapVp(sc[0],sc[1]); await page.waitForTimeout(1600);
  console.log("showcase_open",await g("showcase_open"));
  await cap("full");
  await cap("bottom",{x:0,y:610,width:390,height:234});
  await cap("header",{x:0,y:0,width:390,height:90});
}
console.log("errors",errors.length,errors.slice(0,6));
await browser.close();
