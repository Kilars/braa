// PO pass-74: high-res clip of Bella owned badge in grid vs modal to confirm «Din hund» vs «Din».
import { chromium } from "playwright";
import { writeFile } from "fs/promises";
const base = "http://localhost:8099/index.html";
const browser = await chromium.launch({ args: ["--no-sandbox","--disable-dev-shm-usage","--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport:{width:390,height:844}, deviceScaleFactor:2 });
const client = await page.context().newCDPSession(page);
const g=async(k)=>page.evaluate(new Function("return window.__bra_"+k+" ?? null"));
async function clip(name,x,y,w,h){const{data}=await client.send("Page.captureScreenshot",{format:"png",clip:{x,y,width:w,height:h,scale:4}});await writeFile(`.screenshots/${name}.png`,Buffer.from(data,"base64"));}
async function box(){return await page.evaluate(()=>{const c=document.querySelector("canvas");const r=c.getBoundingClientRect();return{x:r.x,y:r.y,w:r.width,h:r.height};});}
async function tapVp(x,y){const b=await box();const vp=await g("viewport")||[720,1558];await page.mouse.click(b.x+x*b.w/vp[0], b.y+y*b.h/vp[1]);}
await page.goto(`${base}?bra_coins=5000`,{waitUntil:"load",timeout:90000});
await page.waitForFunction("window.__appReady === true",undefined,{timeout:120000});
await page.waitForTimeout(4000);
const kb=await g("kennel_btn"); await tapVp(kb.x,kb.y); await page.waitForTimeout(2000);
// Bella grid badge (top-left of top-left cell): screen ~x8..95 y44..62
await clip("P74b-grid-badge",6,44,95,20);
// open Bella modal
const cells=await g("kennel_cells"); const bella=cells.find(c=>c.id==="bella");
await tapVp(bella.x,bella.y); await page.waitForTimeout(1600);
// modal badge top-left: screen ~x96..185 y40..60
await clip("P74b-modal-badge",96,250,105,26);
await browser.close();
console.log("done");
