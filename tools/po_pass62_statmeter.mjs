import { chromium } from "playwright";
import { writeFile } from "fs/promises";
const base = "http://localhost:8099/index.html";
const P = ".screenshots/188-statmeter-";
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 1 });
const client = await page.context().newCDPSession(page);
const errors = [];
page.on("console", m => { if (m.type() === "error") errors.push(m.text()); });
const g = async (k) => page.evaluate(new Function("return window.__bra_" + k + " ?? null"));
async function cap(name){const {data}=await client.send("Page.captureScreenshot",{format:"png",captureBeyondViewport:false});await writeFile(`${P}${name}.png`,Buffer.from(data,"base64"));return Buffer.from(data,"base64");}
// viewport→css scale: the game renders at a fixed internal vp; taps use __bra_kennel_btn/cells coords already in that space
async function box(){return await page.evaluate(()=>{const c=document.querySelector("canvas");const r=c.getBoundingClientRect();return {x:r.x,y:r.y,w:r.width,h:r.height};});}
async function tapVp(x,y){const b=await box();const vp=await g("viewport")||[720,1558];await page.mouse.click(b.x+x*b.w/vp[0], b.y+y*b.h/vp[1]);}

await page.goto(`${base}?bra_coins=5000`,{waitUntil:"load",timeout:90000});
await page.waitForFunction("window.__appReady === true",undefined,{timeout:120000});
await page.waitForTimeout(800);

// open kennel via published nav-pill centre
const btn = await g("kennel_btn");
if(!btn){console.log("NO kennel_btn");await browser.close();process.exit(1);}
await tapVp(btn.x, btn.y);
await page.waitForFunction("window.__bra_kennel_open === true",undefined,{timeout:20000});
await page.waitForTimeout(600);
await cap("grid");

// tap Nova's cell → open modal (Mot is 4/5 on Nova, the directive's example)
const cells = await g("kennel_cells") || [];
const nova = cells.find(c=>c.id==="nova") || cells[1];
console.log("cells", cells.map(c=>c.id), "-> tapping", nova && nova.id);
await tapVp(nova.x, nova.y);
await page.waitForTimeout(1200); // past the 0.28s open tween + layout
await cap("nova-modal");

// also Sol (golden) for a second dog
console.log("errors", errors.length, errors.slice(0,4));
await browser.close();
