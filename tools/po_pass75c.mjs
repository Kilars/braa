// PO pass-75c: capture the «Triks» completion menu + breed showcase.
import { chromium } from "playwright";
import { writeFile } from "fs/promises";
const base = "http://localhost:8099/index.html";
const browser = await chromium.launch({ args: ["--no-sandbox","--disable-dev-shm-usage","--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport:{width:390,height:844}, deviceScaleFactor:2 });
const client = await page.context().newCDPSession(page);
const errs=[]; page.on("console",m=>{if(m.type()==="error")errs.push(m.text());});
const g=async(k)=>page.evaluate(new Function("return window.__bra_"+k+" ?? null"));
async function cap(name){const{data}=await client.send("Page.captureScreenshot",{format:"png"});await writeFile(`.screenshots/${name}.png`,Buffer.from(data,"base64"));}
async function box(){return await page.evaluate(()=>{const c=document.querySelector("canvas");const r=c.getBoundingClientRect();return{x:r.x,y:r.y,w:r.width,h:r.height};});}
async function tapVp(x,y){const b=await box();const vp=await g("viewport")||[720,1558];await page.mouse.click(b.x+x*b.w/vp[0], b.y+y*b.h/vp[1]);}
async function tapScreen(sx,sy){const b=await box();await page.mouse.click(b.x+sx*b.w/390, b.y+sy*b.h/844);}
await page.goto(`${base}?bra_coins=5000`,{waitUntil:"load",timeout:90000});
await page.waitForFunction("window.__appReady === true",undefined,{timeout:120000});
await page.waitForTimeout(4000);
// open «Triks» menu (hamburger/Triks pill top-left ~ screen x30-70 y27)
const tb=await g("triks_btn"); if(tb){await tapVp(tb.x,tb.y);} else {await tapScreen(45,27);}
await page.waitForTimeout(1800);
console.log("menu_open",await g("menu_open"));
await cap("P75-menu");
// open showcase via «Vis frem hundene» ghost button
const sb=await g("showcase_btn"); if(sb){await tapVp(sb.x,sb.y);} else {await tapScreen(195,525);}
await page.waitForTimeout(2000);
console.log("showcase_open",await g("showcase_open"));
await cap("P75-showcase");
console.log("console errors:",errs.length,errs.slice(0,6));
await browser.close();
