// PO pass-75b: zoom the Bella MODAL green corner badge to read its word.
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
await page.goto(`${base}?bra_coins=5000`,{waitUntil:"load",timeout:90000});
await page.waitForFunction("window.__appReady === true",undefined,{timeout:120000});
await page.waitForTimeout(4000);
const kb=await g("kennel_btn"); if(kb)await tapVp(kb.x,kb.y);
await page.waitForFunction("Array.isArray(window.__bra_kennel_cells)",undefined,{timeout:20000});
await page.waitForTimeout(600);
const cells=await g("kennel_cells"); const bg=cells&&cells.find(x=>x.id==="bella");
console.log("cells?",!!cells,"bella?",!!bg);
await tapVp(bg.x,bg.y); await page.waitForTimeout(1800);
const b=await box();
// modal green badge sits top-left of the hero band ~ screen x90-180 y248-278
const sx=b.x+90*b.w/390, sy=b.y+246*b.h/844;
await cap("P75k-modal-din-badge",{x:sx,y:sy,width:130*b.w/390,height:34*b.h/844,scale:2});
await browser.close();
