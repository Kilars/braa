import { chromium } from "playwright";
import { writeFile } from "fs/promises";
const base = "http://localhost:8099/index.html";
const P = ".screenshots/P63-";
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 1 });
const client = await page.context().newCDPSession(page);
const errors = [];
page.on("console", m => { if (m.type() === "error") errors.push(m.text()); });
const g = async (k) => page.evaluate(new Function("return window.__bra_" + k + " ?? null"));
async function cap(name){const {data}=await client.send("Page.captureScreenshot",{format:"png",captureBeyondViewport:false});await writeFile(`${P}${name}.png`,Buffer.from(data,"base64"));return Buffer.from(data,"base64");}
async function box(){return await page.evaluate(()=>{const c=document.querySelector("canvas");const r=c.getBoundingClientRect();return {x:r.x,y:r.y,w:r.width,h:r.height};});}
async function tapVp(x,y){const b=await box();const vp=await g("viewport")||[720,1558];await page.mouse.click(b.x+x*b.w/vp[0], b.y+y*b.h/vp[1]);}

const q = process.argv[2] || "";
await page.goto(`${base}?bra_coins=5000${q}`,{waitUntil:"load",timeout:90000});
await page.waitForFunction("window.__appReady === true",undefined,{timeout:120000});
await page.waitForTimeout(800);
await cap("a-training");

// completion menu via Triks pill
const triks = await g("triks_btn");
if(triks){ await tapVp(triks.x,triks.y); await page.waitForTimeout(700); await cap("b-menu"); }

// kennel
const btn = await g("kennel_btn");
if(btn){
  await tapVp(btn.x, btn.y);
  await page.waitForFunction("window.__bra_kennel_open === true",undefined,{timeout:20000}).catch(()=>{});
  await page.waitForTimeout(700);
  await cap("c-kennel-grid");
  const cells = await g("kennel_cells") || [];
  const nova = cells.find(c=>c.id==="nova") || cells[1];
  console.log("cells", cells.map(c=>c.id), "-> tapping", nova && nova.id);
  if(nova){ await tapVp(nova.x, nova.y); await page.waitForTimeout(1200); await cap("d-nova-modal"); }
}
console.log("errors", errors.length, errors.slice(0,6));
await browser.close();
