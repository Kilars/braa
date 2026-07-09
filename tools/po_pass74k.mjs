// PO pass-74: open kennel grid + inspect modals (a buyable dog + owned Bella).
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
// tap «Kennel» nav pill (screen ~x115 y27)
const kb=await g("kennel_btn"); console.log("kennel_btn",kb);
if(kb){await tapVp(kb.x,kb.y);} else {await tapScreen(115,27);}
await page.waitForTimeout(2000);
console.log("kennel_open",await g("kennel_open"));
await cap("P74k-grid");
const cells=await g("kennel_cells"); console.log("cells",cells&&cells.map(c=>c.id+"@"+c.x+","+c.y));
// inspect a buyable dog (Sol) then Bella (owned)
for(const id of ["sol","bella"]){
  const c=cells&&cells.find(x=>x.id===id);
  if(c){await tapVp(c.x,c.y); await page.waitForTimeout(1600); await cap("P74k-modal-"+id);
    console.log(id,"modal_open",await g("modal_open"));
    // close modal
    await tapScreen(360,60); await page.waitForTimeout(900);}
}
console.log("console errors:",errs.length, errs.slice(0,8));
await browser.close();
