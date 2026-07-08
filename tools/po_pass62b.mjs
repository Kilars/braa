// PO pass-62 part B: completion menu (mastery), marker-word + difficulty rows, breed showcase.
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
async function cap(name){const {data}=await client.send("Page.captureScreenshot",{format:"png",captureBeyondViewport:false});if(name)await writeFile(`${P}${name}.png`,Buffer.from(data,"base64"));}

// autotap to mastery then open the completion menu
await page.goto(`${base}?bra_coins=5000&bra_autotap=1`,{waitUntil:"load",timeout:90000});
await page.waitForFunction("window.__appReady === true",undefined,{timeout:120000});
await page.waitForTimeout(4500);
console.log("menu_open?", await g("menu_open"));
await cap("menu");
console.log("errors", errors.length, errors.slice(0,4));
await browser.close();
