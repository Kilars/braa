// PO pass-70 focused menu + kennel capture. Boot autotap, wait for mastery (word_rows reveal),
// open completion menu via the Triks pill coordinate, capture at 2x. Then master a 2nd trick to
// reveal difficulty, re-capture. Then kennel grid + modal via kennel_btn seam.
import { chromium } from "playwright";
import { writeFile } from "fs/promises";
const base = "http://localhost:8099/index.html";
const P = ".screenshots/P70b-";
const browser = await chromium.launch({ args: ["--no-sandbox","--disable-dev-shm-usage","--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport:{width:390,height:844}, deviceScaleFactor:2 });
const client = await page.context().newCDPSession(page);
const errors=[]; page.on("console",m=>{if(m.type()==="error")errors.push(m.text());});
const g=async(k)=>page.evaluate(new Function("return window.__bra_"+k+" ?? null"));
async function cap(name,clip){const o={format:"png"};if(clip)o.clip={...clip,scale:2};const{data}=await client.send("Page.captureScreenshot",o);await writeFile(`${P}${name}.png`,Buffer.from(data,"base64"));}
async function box(){return await page.evaluate(()=>{const c=document.querySelector("canvas");const r=c.getBoundingClientRect();return{x:r.x,y:r.y,w:r.width,h:r.height};});}
async function tapVp(x,y){const b=await box();const vp=await g("viewport")||[720,1558];await page.mouse.click(b.x+x*b.w/vp[0], b.y+y*b.h/vp[1]);}
async function tapScreen(sx,sy){const b=await box();await page.mouse.click(b.x+sx*b.w/390, b.y+sy*b.h/844);}

await page.goto(`${base}?bra_coins=5000&bra_autotap=1`,{waitUntil:"load",timeout:90000});
await page.waitForFunction("window.__appReady === true",undefined,{timeout:120000});

// wait for mastery #1 → open menu → confirm words revealed
async function openMenu(){ await tapScreen(95,27); await page.waitForTimeout(1000);
  return await g("menu_open"); }
let revealed=false;
for(let i=0;i<24 && !revealed;i++){
  await page.waitForTimeout(6000);
  if(await openMenu()){ const w=(await g("word_rows")||[]).length; if(w>0){revealed=true;break;}
    await tapScreen(180,770); await page.waitForTimeout(600); } // close menu (continue btn approx)
}
console.log("mastery1 word_rows", (await g("word_rows")||[]).length, "menu_open", await g("menu_open"));
if(!(await g("menu_open"))) await openMenu();
await cap("menu1-full");
await cap("menu1-rows",{x:0,y:120,width:390,height:620});

// switch to ligg (2nd trick row) to earn mastery #2 → difficulty reveal
const tr=await g("trick_rows")||[]; console.log("trick_rows", tr.map(t=>t.id));
const ligg=tr.find(t=>t.id==="ligg");
if(ligg){ await tapVp(ligg.x, ligg.y); await page.waitForTimeout(700); }
await tapScreen(180,770); await page.waitForTimeout(700); // close menu, resume training
console.log("current_trick", await g("current_trick"));
let diff=false;
for(let i=0;i<26 && !diff;i++){
  await page.waitForTimeout(6000);
  if(await openMenu()){ const d=(await g("difficulty_rows")||[]).length; if(d>0){diff=true;break;}
    await tapScreen(180,770); await page.waitForTimeout(600); }
}
console.log("mastery2 diff_rows",(await g("difficulty_rows")||[]).length,"menu_open",await g("menu_open"));
if(!(await g("menu_open"))) await openMenu();
await cap("menu2-full");
await cap("menu2-worddiff",{x:0,y:300,width:390,height:500});

// close menu, go kennel
await tapScreen(180,770); await page.waitForTimeout(700);
const kb=await g("kennel_btn"); console.log("kennel_btn",kb);
if(kb){ await tapVp(kb.x,kb.y);
  await page.waitForFunction("window.__bra_kennel_active !== null",undefined,{timeout:15000}).catch(()=>{});
  await page.waitForTimeout(1200); await cap("kennel-grid"); }
console.log("errors",errors.length,errors.slice(0,6));
await browser.close();
