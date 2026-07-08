import { chromium } from "playwright";
import { writeFile, mkdir } from "fs/promises";
const base = "http://localhost:8099/index.html";
await mkdir(".screenshots", { recursive: true });
const P = ".screenshots/P62-";
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 1 });
const client = await page.context().newCDPSession(page);
const errors = [];
page.on("console", m => { if (m.type() === "error") errors.push(m.text()); });
const g = async (k) => page.evaluate(new Function("return window.__bra_" + k + " ?? null"));
async function box(){ return page.evaluate(()=>{const r=document.querySelector("#canvas").getBoundingClientRect();return{x:r.x,y:r.y,w:r.width,h:r.height};});}
async function tapVp(x,y){const b=await box();const vp=await g("viewport")||[720,1558];await page.mouse.click(b.x+x*b.w/vp[0], b.y+y*b.h/vp[1]);}
async function tapObj(o){const b=await box();const vp=await g("viewport")||[720,1558];await page.mouse.click(b.x+o.x*b.w/vp[0], b.y+o.y*b.h/vp[1]);}
async function cap(name){const {data}=await client.send("Page.captureScreenshot",{format:"png",captureBeyondViewport:false});await writeFile(`${P}${name}.png`,Buffer.from(data,"base64"));}
async function csstap(cx,cy){const b=await box();const vp=await g("viewport")||[720,1558];await tapVp(cx*vp[0]/b.w, cy*vp[1]/b.h);}
await page.goto(`${base}?bra_coins=5000`,{waitUntil:"load",timeout:90000});
await page.waitForFunction("window.__appReady === true",undefined,{timeout:120000});
await page.waitForTimeout(1800);
// menu -> showcase
await tapVp(84,32); await page.waitForTimeout(1000);
await csstap(194,525);            // "Vis frem hundene"
await page.waitForTimeout(1400);
console.log("showcase_open?", await g("showcase_open"));
await cap("showcase");
// back to training, open kennel, Sol modal (cells[3]) and Sniff (cells[6])
await page.goto(`${base}?bra_coins=5000`,{waitUntil:"load",timeout:90000});
await page.waitForFunction("window.__appReady === true",undefined,{timeout:120000});
await page.waitForTimeout(1600);
const kbtn = await g("kennel_btn"); await tapObj(kbtn); await page.waitForTimeout(1400);
const cells = await g("kennel_cells");
await tapObj(cells[3]); await page.waitForTimeout(1200);   // Sol golden
if((await g("kennel_active"))===null){await tapObj(cells[3]);await page.waitForTimeout(1200);}
console.log("sol_active", await g("kennel_active"));
await cap("sol-modal");
console.log("errors", errors.length, errors.slice(0,4));
await browser.close();
