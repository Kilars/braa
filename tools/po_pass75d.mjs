// PO pass-75d: zoom training HUD learned bar (legibility over sky) + menu rows.
import { chromium } from "playwright";
import { writeFile } from "fs/promises";
const base = "http://localhost:8099/index.html";
const browser = await chromium.launch({ args: ["--no-sandbox","--disable-dev-shm-usage","--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport:{width:390,height:844}, deviceScaleFactor:2 });
const client = await page.context().newCDPSession(page);
const g=async(k)=>page.evaluate(new Function("return window.__bra_"+k+" ?? null"));
async function cap(name,clip){const o={format:"png"};if(clip)o.clip=clip;const{data}=await client.send("Page.captureScreenshot",o);await writeFile(`.screenshots/${name}.png`,Buffer.from(data,"base64"));}
async function box(){return await page.evaluate(()=>{const c=document.querySelector("canvas");const r=c.getBoundingClientRect();return{x:r.x,y:r.y,w:r.width,h:r.height};});}
async function tapScreen(sx,sy){const b=await box();await page.mouse.click(b.x+sx*b.w/390, b.y+sy*b.h/844);}
function reg(b,x,y,w,h){return{x:b.x+x*b.w/390,y:b.y+y*b.h/844,width:w*b.w/390,height:h*b.h/844,scale:2};}
await page.goto(`${base}?bra_coins=5000`,{waitUntil:"load",timeout:90000});
await page.waitForFunction("window.__appReady === true",undefined,{timeout:120000});
await page.waitForTimeout(4000);
let b=await box();
// training HUD: full top strip (pills + learned bar) over sky
await cap("P75d-hud",reg(b,0,8,390,70));
// open menu, zoom the trick+raser rows
await tapScreen(45,27); await page.waitForTimeout(1600);
b=await box();
await cap("P75d-menu-rows",reg(b,95,270,200,240));
await browser.close();
