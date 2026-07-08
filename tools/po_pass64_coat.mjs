// 190 visual review: sample Bella's coat warm-bias on the training page vs the kennel
// (grid cell + inspect modal). Decodes the CDP screenshot inside the page via a 2D canvas.
import { chromium } from "playwright";
import { writeFile } from "fs/promises";
const base = "http://localhost:8099/index.html";
const P = ".screenshots/P64c-";
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 1 });
const client = await page.context().newCDPSession(page);
const g = async (k) => page.evaluate(new Function("return window.__bra_" + k + " ?? null"));
async function cap(name){const {data}=await client.send("Page.captureScreenshot",{format:"png",captureBeyondViewport:false});await writeFile(`${P}${name}.png`,Buffer.from(data,"base64"));return "data:image/png;base64,"+data;}
async function box(){return await page.evaluate(()=>{const c=document.querySelector("canvas");const r=c.getBoundingClientRect();return {x:r.x,y:r.y,w:r.width,h:r.height};});}
async function tapVp(x,y){const b=await box();const vp=await g("viewport")||[720,1558];await page.mouse.click(b.x+x*b.w/vp[0], b.y+y*b.h/vp[1]);}
// sample: mean RGB over a w×h patch centred on (cx,cy) CSS px of a PNG data URL
async function sample(dataUrl, cx, cy, w, h){
  return await page.evaluate(async ({dataUrl,cx,cy,w,h})=>{
    const img = new Image(); img.src = dataUrl; await img.decode();
    const cv = document.createElement("canvas"); cv.width=img.width; cv.height=img.height;
    const ctx = cv.getContext("2d"); ctx.drawImage(img,0,0);
    const d = ctx.getImageData(cx-w/2, cy-h/2, w, h).data;
    let r=0,g=0,b=0,n=0;
    for(let i=0;i<d.length;i+=4){ r+=d[i]; g+=d[i+1]; b+=d[i+2]; n++; }
    return {r:Math.round(r/n), g:Math.round(g/n), b:Math.round(b/n), rb:Math.round((r-b)/n)};
  }, {dataUrl,cx,cy,w,h});
}

await page.goto(`${base}?bra_coins=5000`,{waitUntil:"load",timeout:90000});
await page.waitForFunction("window.__appReady === true",undefined,{timeout:120000});
await page.waitForTimeout(900);
const training = await cap("training");
// training dog is centred; sample a few patches down the body to find coat
for(const [ly,lbl] of [[470,"chest"],[520,"belly"],[560,"legs"]]){
  console.log("TRAINING", lbl, await sample(training, 195, ly, 26, 26));
}

// kennel grid
const kbtn = await g("kennel_btn"); await tapVp(kbtn.x, kbtn.y);
await page.waitForFunction("window.__bra_kennel_open === true",undefined,{timeout:20000}).catch(()=>{});
await page.waitForTimeout(900);
const grid = await cap("grid");
const cells = await g("kennel_cells") || [];
const bcell = cells.find(c=>c.id==="bella");
if(bcell){ const b=await box(); const vp=await g("viewport")||[720,1558];
  const cx=b.x+bcell.x*b.w/vp[0], cy=b.y+bcell.y*b.h/vp[1];
  for(const dy of [-40,-20,0,20]) console.log("KENNEL-GRID bella dy",dy, await sample(grid, cx, cy+dy, 22, 22));
}

// bella modal
if(bcell){ await tapVp(bcell.x, bcell.y); await page.waitForTimeout(1200);
  const modal = await cap("modal-bella");
  for(const [ly,lbl] of [[300,"hero-upper"],[360,"hero-mid"],[420,"hero-low"]])
    console.log("KENNEL-MODAL bella", lbl, await sample(modal, 195, ly, 24, 24));
}
await browser.close();
