// PO pass-76: actively PLAY — mark loop, completion menu, difficulty, marker words, showcase, kennel.
import { chromium } from "playwright";
import { writeFile } from "fs/promises";
const base = "http://localhost:8137/index.html";
const browser = await chromium.launch({ args: ["--no-sandbox","--disable-dev-shm-usage","--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport:{width:390,height:844}, deviceScaleFactor:2 });
const client = await page.context().newCDPSession(page);
const errs=[]; page.on("console",m=>{if(m.type()==="error")errs.push(m.text());});
const g=async(k)=>page.evaluate(new Function("return window.__bra_"+k+" ?? null"));
async function cap(name,clip){const o={format:"png"};if(clip)o.clip=clip;const{data}=await client.send("Page.captureScreenshot",o);await writeFile(`.screenshots/${name}.png`,Buffer.from(data,"base64"));}
async function box(){return await page.evaluate(()=>{const c=document.querySelector("canvas");const r=c.getBoundingClientRect();return{x:r.x,y:r.y,w:r.width,h:r.height};});}
async function tapVp(x,y){const b=await box();const vp=await g("viewport")||[720,1558];await page.mouse.click(b.x+x*b.w/vp[0], b.y+y*b.h/vp[1]);}
async function tapScreen(sx,sy){const b=await box();await page.mouse.click(b.x+sx*b.w/390, b.y+sy*b.h/844);}

await page.goto(`${base}?bra_coins=5000`,{waitUntil:"load",timeout:90000});
await page.waitForFunction("window.__appReady === true",undefined,{timeout:120000});
await page.waitForTimeout(3500);
await cap("P76-01-training");

// ---- PLAY: autotap a mastery burst to drive the mark loop + completion menu ----
await page.goto(`${base}?bra_coins=5000&bra_autotap=1`,{waitUntil:"load",timeout:90000});
await page.waitForFunction("window.__appReady === true",undefined,{timeout:120000});
await page.waitForTimeout(2500);
await cap("P76-02-autotap-mark");
// let it accumulate marks toward mastery / completion menu
await page.waitForTimeout(6000);
await cap("P76-03-after-burst");
console.log("learned_pct",await g("learned_pct"),"mastered",await g("mastered"),"menu_open",await g("menu_open"));

// ---- Completion / Triks menu (open via nav) ----
await page.goto(`${base}?bra_coins=5000`,{waitUntil:"load",timeout:90000});
await page.waitForFunction("window.__appReady === true",undefined,{timeout:120000});
await page.waitForTimeout(3000);
await tapScreen(40,27);              // hamburger / Triks pill (left)
await page.waitForTimeout(1500);
console.log("menu_open",await g("menu_open"));
await cap("P76-04-menu");
// zoom the difficulty section (lower portion of the menu card)
const b=await box();
await cap("P76-04b-menu-lower",{x:b.x,y:b.y+b.h*0.45,width:b.w,height:b.h*0.45,scale:2});
await cap("P76-04c-menu-upper",{x:b.x,y:b.y+b.h*0.08,width:b.w,height:b.h*0.42,scale:2});

// ---- Marker word switch (tap a word row) ----
console.log("menu rows dump:",JSON.stringify(await g("menu_rows")||"none").slice(0,400));

console.log("console errors:",errs.length, errs.slice(0,10));
await browser.close();
