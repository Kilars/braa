// PO pass-75e: zoom kennel grid cell rows to scrutinize badge/price/name typography + alignment.
import { chromium } from "playwright";
import { writeFile } from "fs/promises";
const base = "http://localhost:8099/index.html";
const browser = await chromium.launch({ args: ["--no-sandbox","--disable-dev-shm-usage","--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport:{width:390,height:844}, deviceScaleFactor:2 });
const client = await page.context().newCDPSession(page);
const g=async(k)=>page.evaluate(new Function("return window.__bra_"+k+" ?? null"));
async function cap(name,clip){const o={format:"png"};if(clip)o.clip=clip;const{data}=await client.send("Page.captureScreenshot",o);await writeFile(`.screenshots/${name}.png`,Buffer.from(data,"base64"));}
async function box(){return await page.evaluate(()=>{const c=document.querySelector("canvas");const r=c.getBoundingClientRect();return{x:r.x,y:r.y,w:r.width,h:r.height};});}
async function tapVp(x,y){const b=await box();const vp=await g("viewport")||[720,1558];await page.mouse.click(b.x+x*b.w/vp[0], b.y+y*b.h/vp[1]);}
function reg(b,x,y,w,h){return{x:b.x+x*b.w/390,y:b.y+y*b.h/844,width:w*b.w/390,height:h*b.h/844,scale:2};}
await page.goto(`${base}?bra_coins=5000`,{waitUntil:"load",timeout:90000});
await page.waitForFunction("window.__appReady === true",undefined,{timeout:120000});
await page.waitForTimeout(4000);
const kb=await g("kennel_btn"); if(kb)await tapVp(kb.x,kb.y);
await page.waitForFunction("Array.isArray(window.__bra_kennel_cells)",undefined,{timeout:20000});
await page.waitForTimeout(600);
const b=await box();
// bottom row (Sniff «Vanlig» + Trulte «Påskeegg»/«Gratis») incl name+breed+badge+price
await cap("P75e-row-bottom",reg(b,0,655,390,190));
// second row (Balder «Sjelden»/650 + Sol «Sjelden»/500)
await cap("P75e-row-second",reg(b,0,240,390,190));
await browser.close();
