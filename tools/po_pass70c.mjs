// PO pass-70 detail zooms: showcase bottom controls + completion menu (precise Triks tap at
// screen 62,27) after 1 mastery. 2x scale.
import { chromium } from "playwright";
import { writeFile } from "fs/promises";
const base = "http://localhost:8099/index.html";
const P = ".screenshots/P70c-";
const browser = await chromium.launch({ args: ["--no-sandbox","--disable-dev-shm-usage","--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport:{width:390,height:844}, deviceScaleFactor:2 });
const client = await page.context().newCDPSession(page);
const errors=[]; page.on("console",m=>{if(m.type()==="error")errors.push(m.text());});
const g=async(k)=>page.evaluate(new Function("return window.__bra_"+k+" ?? null"));
async function cap(name,clip){const o={format:"png"};if(clip)o.clip={...clip,scale:2};const{data}=await client.send("Page.captureScreenshot",o);await writeFile(`${P}${name}.png`,Buffer.from(data,"base64"));}
async function box(){return await page.evaluate(()=>{const c=document.querySelector("canvas");const r=c.getBoundingClientRect();return{x:r.x,y:r.y,w:r.width,h:r.height};});}
async function tapVp(x,y){const b=await box();const vp=await g("viewport")||[720,1558];await page.mouse.click(b.x+x*b.w/vp[0], b.y+y*b.h/vp[1]);}
async function tapScreen(sx,sy){const b=await box();await page.mouse.click(b.x+sx*b.w/390, b.y+sy*b.h/844);}

await page.goto(`${base}?bra_coins=5000&bra_autotap=1`,{waitUntil:"load",timeout:90000});
await page.waitForFunction("window.__appReady === true",undefined,{timeout:120000});

// master Sitt: poll by opening menu (Triks at screen 62,27) until word_rows>0
let ok=false;
for(let i=0;i<26 && !ok;i++){
  await page.waitForTimeout(6000);
  await tapScreen(62,27); await page.waitForTimeout(900);
  if(await g("menu_open")){
    const w=(await g("word_rows")||[]).length;
    console.log("try",i,"menu_open",true,"word_rows",w);
    if(w>0){ ok=true; break; }
    await tapScreen(195,764); await page.waitForTimeout(600); // continue
  } else { console.log("try",i,"menu_open",false); }
}
if(ok){
  await cap("menu-full");
  await cap("menu-trickrows",{x:100,y:250,width:290,height:250});
  await cap("menu-wordrows",{x:100,y:420,width:290,height:200});
  // showcase
  const sc=await g("showcase_row");
  console.log("showcase_row",sc);
  if(sc){ await tapVp(sc[0],sc[1]); await page.waitForTimeout(1400);
    console.log("showcase_open",await g("showcase_open"));
    await cap("showcase-full");
    await cap("showcase-bottom",{x:0,y:640,width:390,height:204});
  }
}
console.log("errors",errors.length,errors.slice(0,6));
await browser.close();
