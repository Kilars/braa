// PO father-pass-70 critical sweep. Boot training, master Sitt+Ligg (autotap) to reveal
// marker-words (mastery #1) and difficulty (#2), capture: training page, completion menu
// (0 + 2 masteries), breed showcase, kennel grid + modals. Re-verify 195 word-row flush.
import { chromium } from "playwright";
import { writeFile } from "fs/promises";
const base = "http://localhost:8099/index.html";
const P = ".screenshots/P70-";
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

// completion menu via Triks pill (0 masteries)
const triks = await g("triks_btn");
if(triks){ await tapVp(triks.x,triks.y); await page.waitForTimeout(1200); await cap("b-menu0"); }
console.log("menu0 word_rows", (await g("word_rows")||[]).length, "diff_rows", (await g("difficulty_rows")||[]).length);
console.log("trick_rows", (await g("trick_rows")||[]).map(t=>t.id), "breed_rows", (await g("breed_rows")||[]).map(b=>b.id));
// close menu
await tapVp(360,1500); await page.waitForTimeout(700);

// master Sitt (#1) then switch to Ligg and master (#2) to reveal difficulty
await page.waitForFunction("(window.__bra_learned_pct||0) >= 100",undefined,{timeout:120000}).catch(()=>{});
console.log("after1 learned", await g("learned_pct"));
// switch trick via menu row if available
if(triks){ await tapVp(triks.x,triks.y); await page.waitForTimeout(900);
  const tr = (await g("trick_rows")||[]);
  const ligg = tr.find(t=>t.id==="ligg");
  if(ligg && ligg.x!==undefined){ await tapVp(ligg.x, ligg.y); await page.waitForTimeout(800); }
  await tapVp(360,1500); await page.waitForTimeout(700);
}
await page.waitForFunction("(window.__bra_learned_pct||0) >= 100",undefined,{timeout:140000}).catch(()=>{});
console.log("after2 learned", await g("learned_pct"), "current_trick", await g("current_trick"));

// completion menu at 2 masteries — capture full card + zoom word/difficulty band
if(triks){ const t3=await g("triks_btn"); if(t3){ await tapVp(t3.x,t3.y); await page.waitForTimeout(1200); await cap("c-menu2"); } }
console.log("menu2 word_rows", (await g("word_rows")||[]).length, "diff_rows", (await g("difficulty_rows")||[]).length);
const wr = await g("word_rows")||[]; const dr = await g("difficulty_rows")||[]; const tr2 = await g("trick_rows")||[];
console.log("word_rows", wr.map(w=>({id:w.id,x:w.x})));
console.log("diff_rows", dr.map(d=>({id:d.id,x:d.x})));
console.log("trick_rows", tr2.map(t=>({id:t.id,x:t.x})));

// breed showcase
const sc = await g("showcase_row");
if(sc){ await tapVp(sc[0], sc[1]); await page.waitForTimeout(1400); await cap("d-showcase");
  console.log("showcase_open", await g("showcase_open"));
  await tapVp(80, 1500); await page.waitForTimeout(900);
}
if(!(await g("menu_open"))){ const t4=await g("triks_btn"); if(t4){await tapVp(t4.x,t4.y);await page.waitForTimeout(900);} }
await tapVp(360, 1500); await page.waitForTimeout(700);

// kennel
const btn = await g("kennel_btn");
if(btn){
  await tapVp(btn.x, btn.y);
  await page.waitForFunction("window.__bra_kennel_open === true",undefined,{timeout:20000}).catch(()=>{});
  await page.waitForTimeout(1200);
  await cap("e-kennel-grid");
  const cells = await g("kennel_cells") || [];
  console.log("cells", cells.map(c=>c.id));
  for(const id of ["bella","balder","lykke"]){
    const c = cells.find(x=>x.id===id);
    if(c){ await tapVp(c.x,c.y); await page.waitForTimeout(1200); await cap(`f-modal-${id}`);
      const cl = await g("kennel_modal_close"); if(cl){ await tapVp(cl.x,cl.y);} else { await tapVp(360,60);} await page.waitForTimeout(800);
    }
  }
}
console.log("errors", errors.length, errors.slice(0,8));
await browser.close();
