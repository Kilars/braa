import { chromium } from "playwright";
import { writeFile } from "fs/promises";
const base = "http://localhost:8099/index.html";
const P = ".screenshots/P64-";
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 1 });
const client = await page.context().newCDPSession(page);
const errors = [];
page.on("console", m => { if (m.type() === "error") errors.push(m.text()); });
const g = async (k) => page.evaluate(new Function("return window.__bra_" + k + " ?? null"));
async function cap(name){const {data}=await client.send("Page.captureScreenshot",{format:"png",captureBeyondViewport:false});await writeFile(`${P}${name}.png`,Buffer.from(data,"base64"));}
async function box(){return await page.evaluate(()=>{const c=document.querySelector("canvas");const r=c.getBoundingClientRect();return {x:r.x,y:r.y,w:r.width,h:r.height};});}
async function tapVp(x,y){const b=await box();const vp=await g("viewport")||[720,1558];await page.mouse.click(b.x+x*b.w/vp[0], b.y+y*b.h/vp[1]);}

await page.goto(`${base}?bra_coins=5000`,{waitUntil:"load",timeout:90000});
await page.waitForFunction("window.__appReady === true",undefined,{timeout:120000});
await page.waitForTimeout(800);

const btn = await g("kennel_btn");
await tapVp(btn.x, btn.y);
await page.waitForFunction("window.__bra_kennel_open === true",undefined,{timeout:20000}).catch(()=>{});
await page.waitForTimeout(800);
await cap("grid");

const cells = await g("kennel_cells") || [];
console.log("cells", cells.map(c=>c.id));
for (const id of ["sol","bella","nova"]) {
  const cell = cells.find(c=>c.id===id);
  if(!cell){ console.log("no cell", id); continue; }
  await tapVp(cell.x, cell.y);
  await page.waitForTimeout(1200);
  await cap(`modal-${id}`);
  // close via backdrop tap top-left corner to reset, then reopen next
  await page.keyboard.press("Escape").catch(()=>{});
  await tapVp(20,20);
  await page.waitForTimeout(600);
}
console.log("errors", errors.length, errors.slice(0,6));
await browser.close();
