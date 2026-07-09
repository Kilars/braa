// PO father-pass-69 critical sweep. Boot training, master Sitt (autotap), capture: training
// page, completion menu (1 mastery → words revealed), kennel grid + 3 modals, breed showcase.
// The difficulty-section (2-mastery) badge check runs separately in po_pass68_diffbadge.mjs.
import { chromium } from "playwright";
import { writeFile } from "fs/promises";
const base = "http://localhost:8099/index.html";
const P = ".screenshots/P69-";
const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 1 });
const client = await page.context().newCDPSession(page);
const errors = [];
page.on("console", m => { if (m.type() === "error") errors.push(m.text()); });
const g = async (k) => page.evaluate(new Function("return window.__bra_" + k + " ?? null"));
async function cap(name){const {data}=await client.send("Page.captureScreenshot",{format:"png",captureBeyondViewport:false});await writeFile(`${P}${name}.png`,Buffer.from(data,"base64"));return Buffer.from(data,"base64");}
async function box(){return await page.evaluate(()=>{const c=document.querySelector("canvas");const r=c.getBoundingClientRect();return {x:r.x,y:r.y,w:r.width,h:r.height};});}
async function tapVp(x,y){const b=await box();const vp=await g("viewport")||[720,1558];await page.mouse.click(b.x+x*b.w/vp[0], b.y+y*b.h/vp[1]);}

await page.goto(`${base}?bra_coins=5000&bra_autotap=1`,{waitUntil:"load",timeout:90000});
await page.waitForFunction("window.__appReady === true",undefined,{timeout:120000});
await page.waitForTimeout(9000);
await cap("a-training");
console.log("learned_pct", await g("learned_pct"), "viewport", await g("viewport"));

// completion menu via Triks pill
const triks = await g("triks_btn");
if(triks){ await tapVp(triks.x,triks.y); await page.waitForTimeout(1000); await cap("b-menu"); }
console.log("menu_open", await g("menu_open"), "word_rows", (await g("word_rows")||[]).length, "diff_rows", (await g("difficulty_rows")||[]).length);
console.log("trick_rows", (await g("trick_rows")||[]).map(t=>t.id), "breed_rows", (await g("breed_rows")||[]).map(b=>b.id));

// breed showcase from the menu
const sc = await g("showcase_row");
if(sc){ await tapVp(sc[0], sc[1]); await page.waitForTimeout(1400);
  console.log("showcase_open", await g("showcase_open"), "spotlit", await g("showcase_spotlit"));
  await cap("c-showcase");
  // back out of showcase
  await tapVp(80, 1500); await page.waitForTimeout(900);
}

// re-open menu, close via continue, then kennel
if(!(await g("menu_open"))){ const t2=await g("triks_btn"); if(t2){await tapVp(t2.x,t2.y);await page.waitForTimeout(900);} }
await tapVp(360, 1500); await page.waitForTimeout(700);

const btn = await g("kennel_btn");
if(btn){
  await tapVp(btn.x, btn.y);
  await page.waitForFunction("window.__bra_kennel_open === true",undefined,{timeout:20000}).catch(()=>{});
  await page.waitForTimeout(1000);
  await cap("d-kennel-grid");
  const cells = await g("kennel_cells") || [];
  console.log("cells", cells.map(c=>c.id));
  for(const id of ["nova","sol","trulte"]){
    const c = cells.find(x=>x.id===id);
    if(c){ await tapVp(c.x,c.y); await page.waitForTimeout(1200); await cap(`e-modal-${id}`);
      const cl = await g("kennel_modal_close"); if(cl){ await tapVp(cl.x,cl.y);} else { await tapVp(360,60);} await page.waitForTimeout(800);
    }
  }
}
console.log("errors", errors.length, errors.slice(0,8));
await browser.close();
