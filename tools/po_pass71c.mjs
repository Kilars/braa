import { chromium } from "playwright";
import { writeFile } from "fs/promises";
const base = "http://localhost:8099/index.html";
const browser = await chromium.launch({ args: ["--no-sandbox","--disable-dev-shm-usage","--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport:{width:390,height:844}, deviceScaleFactor:2 });
const client = await page.context().newCDPSession(page);
const errs=[]; page.on("console",m=>{if(m.type()==="error")errs.push(m.text());});
const g=async(k)=>page.evaluate(new Function("return window.__bra_"+k+" ?? null"));
async function cap(name,clip,s){const{data}=await client.send("Page.captureScreenshot",{format:"png",clip:{...clip,scale:s||4}});await writeFile(`.screenshots/${name}.png`,Buffer.from(data,"base64"));}
async function box(){return await page.evaluate(()=>{const c=document.querySelector("canvas");const r=c.getBoundingClientRect();return{x:r.x,y:r.y,w:r.width,h:r.height};});}
async function tapVp(x,y){const b=await box();const vp=await g("viewport")||[720,1558];await page.mouse.click(b.x+x*b.w/vp[0], b.y+y*b.h/vp[1]);}
async function tapScreen(sx,sy){const b=await box();await page.mouse.click(b.x+sx*b.w/390, b.y+sy*b.h/844);}
await page.goto(`${base}?bra_coins=5000`,{waitUntil:"load",timeout:90000});
await page.waitForFunction("window.__appReady === true",undefined,{timeout:120000});
await page.waitForTimeout(4000);
await cap("P71-topbar",{x:0,y:8,width:390,height:52},4);
// showcase bottom controls
await tapScreen(62,27); await page.waitForTimeout(1200);
const sc=await g("showcase_row");
if(sc){ await tapVp(sc[0],sc[1]); await page.waitForTimeout(1800);
  await cap("P71-showbottom",{x:0,y:735,width:390,height:109},4);
}
console.log("errors:",errs.length,errs.slice(0,4));
await browser.close();
