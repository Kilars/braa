import { chromium } from "playwright";
import { writeFile } from "fs/promises";
const base="http://localhost:8099/index.html";
const browser=await chromium.launch({args:["--no-sandbox","--disable-dev-shm-usage","--use-gl=swiftshader"]});
const page=await browser.newPage({viewport:{width:390,height:844},deviceScaleFactor:3});
const client=await page.context().newCDPSession(page);
const g=async(k)=>page.evaluate(new Function("return window.__bra_"+k+" ?? null"));
async function cap(name,clip){const{data}=await client.send("Page.captureScreenshot",{format:"png",clip:{...clip,scale:3}});await writeFile(`.screenshots/${name}.png`,Buffer.from(data,"base64"));}
async function box(){return await page.evaluate(()=>{const c=document.querySelector("canvas");const r=c.getBoundingClientRect();return{x:r.x,y:r.y,w:r.width,h:r.height};});}
async function tapVp(x,y){const b=await box();const vp=await g("viewport")||[720,1558];await page.mouse.click(b.x+x*b.w/vp[0],b.y+y*b.h/vp[1]);}
await page.goto(`${base}?bra_coins=5000`,{waitUntil:"load",timeout:90000});
await page.waitForFunction("window.__appReady === true",undefined,{timeout:120000});
await page.waitForTimeout(3500);
const kb=await g("kennel_btn"); await tapVp(kb.x,kb.y); await page.waitForTimeout(1800);
// zoom top row (Bella + Nova badges + names) and price-chip row
await cap("P73z-toprow",{x:0,y:40,width:390,height:200});
await cap("P73z-pricerow",{x:0,y:355,width:390,height:120});
await browser.close();
