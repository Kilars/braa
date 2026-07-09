// PO father-pass-74: fresh critical play-test. Drive training + mark burst + completion menu,
// «Triks» menu, breed showcase, kennel grid + modal. Capture full-frame screenshots for visual review.
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
await cap("P74-a-training");
console.log("learned_pct",await g("learned_pct"),"difficulty",await g("difficulty"),"current_trick",await g("current_trick"));

// mark burst: tap BRA repeatedly to exercise timing/scoring & drive toward mastery/menu
for(let i=0;i<40;i++){ await tapScreen(195,720); await page.waitForTimeout(220); }
await page.waitForTimeout(1000);
await cap("P74-b-after-marks");
console.log("learned_pct after burst",await g("learned_pct"),"menu_open",await g("menu_open"));

// open «Triks» menu
await tapScreen(62,27); await page.waitForTimeout(1200);
await cap("P74-c-menu");
console.log("menu_open",await g("menu_open"));

// showcase
const sc=await g("showcase_row"); console.log("showcase_row",sc);
if(sc){await tapVp(sc[0],sc[1]); await page.waitForTimeout(1800);}
console.log("showcase_open",await g("showcase_open"));
await cap("P74-d-showcase");

// back to training via Tilbake, then kennel
await tapVp((sc?sc[0]:360),1518); await page.waitForTimeout(1200);
const kb=await g("kennel_btn"); console.log("kennel_btn",kb);
if(kb){await tapVp(kb.x,kb.y); await page.waitForTimeout(1800);}
console.log("kennel_open",await g("kennel_open"));
await cap("P74-e-kennel-grid");
const cells=await g("kennel_cells"); console.log("cells",cells&&cells.map(c=>c.id));
const nova=cells&&cells.find(c=>c.id==="nova");
if(nova){await tapVp(nova.x,nova.y); await page.waitForTimeout(1600);}
await cap("P74-f-nova-modal");
// a buyable dog modal to check adopt CTA
console.log("console errors:",errs.length, errs.slice(0,8));
await browser.close();
