import { chromium } from "playwright";
import { writeFile } from "fs/promises";
const base="http://localhost:8099/index.html";
const browser=await chromium.launch({args:["--no-sandbox","--disable-dev-shm-usage","--use-gl=swiftshader"]});
const page=await browser.newPage({viewport:{width:390,height:844},deviceScaleFactor:3});
const client=await page.context().newCDPSession(page);
const errs=[];page.on("console",m=>{if(m.type()==="error")errs.push(m.text());});
const g=async(k)=>page.evaluate(new Function("return window.__bra_"+k+" ?? null"));
async function cap(name,clip){const o=clip?{format:"png",clip:{...clip,scale:3}}:{format:"png"};const{data}=await client.send("Page.captureScreenshot",o);await writeFile(`.screenshots/${name}.png`,Buffer.from(data,"base64"));}
async function box(){return await page.evaluate(()=>{const c=document.querySelector("canvas");const r=c.getBoundingClientRect();return{x:r.x,y:r.y,w:r.width,h:r.height};});}
async function tapVp(x,y){const b=await box();const vp=await g("viewport")||[720,1558];await page.mouse.click(b.x+x*b.w/vp[0],b.y+y*b.h/vp[1]);}
await page.goto(`${base}?bra_coins=500`,{waitUntil:"load",timeout:90000});  // 500: can't afford Nova(900) -> gate state
await page.waitForFunction("window.__appReady === true",undefined,{timeout:120000});
await page.waitForFunction("window.__bra_kennel_btn != null",undefined,{timeout:30000}); await page.waitForTimeout(1500);
const kb=await g("kennel_btn"); await tapVp(kb.x,kb.y); await page.waitForTimeout(1800);
const cells=await g("kennel_cells"); const nova=(cells||[]).find(c=>c.id==="nova");
await tapVp(nova.x,nova.y); await page.waitForTimeout(1600);
await cap("P73n-nova-modal");
console.log("kennel_action",await g("kennel_action"),"errors",errs.length,errs.slice(0,4));
await browser.close();
