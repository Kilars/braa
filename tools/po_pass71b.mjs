import { chromium } from "playwright";
import { writeFile } from "fs/promises";
const base = "http://localhost:8099/index.html";
const browser = await chromium.launch({ args: ["--no-sandbox","--disable-dev-shm-usage","--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport:{width:390,height:844}, deviceScaleFactor:2 });
const client = await page.context().newCDPSession(page);
const errs=[]; page.on("console",m=>{if(m.type()==="error")errs.push(m.text());});
const g=async(k)=>page.evaluate(new Function("return window.__bra_"+k+" ?? null"));
async function cap(name,s){const{data}=await client.send("Page.captureScreenshot",{format:"png",clip:{x:0,y:0,width:390,height:844,scale:s||2}});await writeFile(`.screenshots/${name}.png`,Buffer.from(data,"base64"));}
async function box(){return await page.evaluate(()=>{const c=document.querySelector("canvas");const r=c.getBoundingClientRect();return{x:r.x,y:r.y,w:r.width,h:r.height};});}
async function tapVp(x,y){const b=await box();const vp=await g("viewport")||[720,1558];await page.mouse.click(b.x+x*b.w/vp[0], b.y+y*b.h/vp[1]);}
await page.goto(`${base}?bra_coins=5000&bra_autotap=1`,{waitUntil:"load",timeout:90000});
await page.waitForFunction("window.__appReady === true",undefined,{timeout:120000});
await page.waitForTimeout(9000); // let autotap master + open completion menu
await cap("P71-d-completion",2);
console.log("completion errors so far:",errs.length);
// reload without autotap to browse kennel
await page.goto(`${base}?bra_coins=5000`,{waitUntil:"load",timeout:90000});
await page.waitForFunction("window.__appReady === true",undefined,{timeout:120000});
await page.waitForTimeout(4000);
const kb=await g("kennel_btn"); console.log("kennel_btn",kb);
if(kb){ await tapVp(kb.x,kb.y); await page.waitForTimeout(1800); await cap("P71-e-kennel",2);
  // tap a cell (Nova ~ second cell). grid is 2 cols x 4 rows in vp coords; tap cell 2
  await tapVp(540,520); await page.waitForTimeout(1600); await cap("P71-f-modal",2);
}
console.log("console errors:",errs.length, errs.slice(0,6));
await browser.close();
