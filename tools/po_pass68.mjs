import { chromium } from "playwright";
import { writeFile } from "fs/promises";
const base = "http://localhost:8099/index.html";
const P = ".screenshots/P68-";
const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 1 });
const client = await page.context().newCDPSession(page);
const errors = [];
page.on("console", m => { if (m.type() === "error") errors.push(m.text()); });
const g = async (k) => page.evaluate(new Function("return window.__bra_" + k + " ?? null"));
async function cap(name){const {data}=await client.send("Page.captureScreenshot",{format:"png",captureBeyondViewport:false});await writeFile(`${P}${name}.png`,Buffer.from(data,"base64"));return Buffer.from(data,"base64");}
async function box(){return await page.evaluate(()=>{const c=document.querySelector("canvas");const r=c.getBoundingClientRect();return {x:r.x,y:r.y,w:r.width,h:r.height};});}
async function tapVp(x,y){const b=await box();const vp=await g("viewport")||[720,1558];await page.mouse.click(b.x+x*b.w/vp[0], b.y+y*b.h/vp[1]);}

// Master Sitt so the marker-words + difficulty sections reveal in the menu.
await page.goto(`${base}?bra_coins=5000&bra_autotap=1`,{waitUntil:"load",timeout:90000});
await page.waitForFunction("window.__appReady === true",undefined,{timeout:120000});
await page.waitForTimeout(9000);
await cap("a-training");
console.log("learned_pct", await g("learned_pct"));

// completion menu via Triks pill — key surface for 193 (section headings)
const triks = await g("triks_btn");
if(triks){ await tapVp(triks.x,triks.y); await page.waitForTimeout(900); await cap("b-menu-full"); }
console.log("menu_open", await g("menu_open"));

// zoomed crop of the section-heading band (Raser / Markørord / Vanskelighet)
const full = await cap("b-menu-full2");
console.log("errors_after_menu", errors.length);

// close menu (Fortsett treningen) then kennel
await tapVp(360, 1500); // approximate close, will re-open training
await page.waitForTimeout(600);

const btn = await g("kennel_btn");
if(btn){
  await tapVp(btn.x, btn.y);
  await page.waitForFunction("window.__bra_kennel_open === true",undefined,{timeout:20000}).catch(()=>{});
  await page.waitForTimeout(900);
  await cap("c-kennel-grid");
  const cells = await g("kennel_cells") || [];
  console.log("cells", cells.map(c=>c.id));
  for(const id of ["nova","sol","pontus"]){
    const c = cells.find(x=>x.id===id);
    if(c){ await tapVp(c.x,c.y); await page.waitForTimeout(1100); await cap(`d-modal-${id}`);
      // close modal
      const cl = await g("kennel_modal_close"); if(cl){ await tapVp(cl.x,cl.y);} else { await tapVp(360,60);} await page.waitForTimeout(700);
    }
  }
}
console.log("errors", errors.length, errors.slice(0,8));
await browser.close();
