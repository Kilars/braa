// PO pass-75: verify 199 (owned badge word «Din hund» unified grid↔modal) + full surface sweep.
import { chromium } from "playwright";
import { writeFile } from "fs/promises";
const base = "http://localhost:8099/index.html";
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
await page.waitForTimeout(4000);
await cap("P75-a-training");

// ---- Kennel grid ----
const kb=await g("kennel_btn");
if(kb){await tapVp(kb.x,kb.y);} else {await tapScreen(115,27);}
await page.waitForTimeout(2200);
console.log("kennel_open",await g("kennel_open"));
await cap("P75k-grid");
const cells=await g("kennel_cells"); console.log("cells",cells&&cells.map(c=>c.id+"@"+Math.round(c.x)+","+Math.round(c.y)));
// zoom Bella's grid badge (top-left corner of Bella's cell)
const bg=cells&&cells.find(x=>x.id==="bella");
if(bg){const b=await box();const vp=await g("viewport")||[720,1558];
  const sx=b.x+bg.x*b.w/vp[0], sy=b.y+bg.y*b.h/vp[1], cw=b.w/2;
  await cap("P75k-bella-cell",{x:Math.max(0,sx-cw*0.5),y:Math.max(0,sy-b.h*0.14),width:cw,height:b.h*0.18,scale:2});}

// ---- Bella owned modal ----
if(bg){await tapVp(bg.x,bg.y); await page.waitForTimeout(1800);
  console.log("bella modal_open",await g("modal_open"));
  await cap("P75k-bella-modal");
  const b=await box(); await cap("P75k-bella-modal-badge",{x:b.x,y:b.y+b.h*0.06,width:b.w*0.6,height:b.h*0.12,scale:2});
  await tapScreen(360,60); await page.waitForTimeout(900);
}
// ---- Trulte secret modal (parity check) + a buyable ----
for(const id of ["trulte","nova"]){
  const c=cells&&cells.find(x=>x.id===id);
  if(c){await tapVp(c.x,c.y); await page.waitForTimeout(1500); await cap("P75k-modal-"+id);
    console.log(id,"modal_open",await g("modal_open"));
    await tapScreen(360,60); await page.waitForTimeout(800);}
}
// close kennel
await tapScreen(360,60); await page.waitForTimeout(1000);

console.log("console errors:",errs.length, errs.slice(0,8));
await browser.close();
