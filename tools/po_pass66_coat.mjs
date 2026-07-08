// 192 visual review (PO father-pass-66 X-6/X-4): re-sample the three light-coat dogs in the kennel
// grid after easing Trulte's cool bias (0.84,0.98,1.24 -> 0.90,0.99,1.16). Confirm Trulte no longer
// renders icy blue: rendered B-R must be small (well under the ~24 that flagged blue) while Trulte
// stays the coolest/whitest of the three (warm->cool R-B ladder Sol > Bella > Trulte preserved).
import { chromium } from "playwright";
import { writeFile } from "fs/promises";
const base = "http://localhost:8099/index.html";
const P = ".screenshots/P66-coat-";
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 1 });
const client = await page.context().newCDPSession(page);
const g = async (k) => page.evaluate(new Function("return window.__bra_" + k + " ?? null"));
async function cap(name){const {data}=await client.send("Page.captureScreenshot",{format:"png",captureBeyondViewport:false});await writeFile(`${P}${name}.png`,Buffer.from(data,"base64"));return "data:image/png;base64,"+data;}
async function box(){return await page.evaluate(()=>{const c=document.querySelector("canvas");const r=c.getBoundingClientRect();return {x:r.x,y:r.y,w:r.width,h:r.height};});}
async function tapVp(x,y){const b=await box();const vp=await g("viewport")||[720,1558];await page.mouse.click(b.x+x*b.w/vp[0], b.y+y*b.h/vp[1]);}
async function sampleCoat(dataUrl, cx, cy){
  let best = null;
  for(const dy of [-46,-30,-16,0,16,30]){
    const s = await page.evaluate(async ({dataUrl,cx,cy})=>{
      const img = new Image(); img.src = dataUrl; await img.decode();
      const cv = document.createElement("canvas"); cv.width=img.width; cv.height=img.height;
      const ctx = cv.getContext("2d"); ctx.drawImage(img,0,0);
      const d = ctx.getImageData(cx-11, cy-11, 22, 22).data;
      let r=0,gg=0,b=0,n=0;
      for(let i=0;i<d.length;i+=4){ r+=d[i]; gg+=d[i+1]; b+=d[i+2]; n++; }
      r=Math.round(r/n); gg=Math.round(gg/n); b=Math.round(b/n);
      return {r, g:gg, b, rb:r-b, br:b-r, lum:0.2126*r+0.7152*gg+0.0722*b};
    }, {dataUrl,cx,cy:cy+dy});
    if(!best || s.lum>best.lum) best = s;
  }
  return best;
}

await page.goto(`${base}?bra_coins=5000`,{waitUntil:"load",timeout:90000});
await page.waitForFunction("window.__appReady === true",undefined,{timeout:120000});
await page.waitForTimeout(900);

const kbtn = await g("kennel_btn"); await tapVp(kbtn.x, kbtn.y);
await page.waitForFunction("window.__bra_kennel_open === true",undefined,{timeout:20000}).catch(()=>{});
await page.waitForTimeout(900);
const grid = await cap("grid");
const cells = await g("kennel_cells") || [];
const b = await box(); const vp = await g("viewport")||[720,1558];
const out = {};
for(const id of ["sol","bella","trulte"]){
  const cell = cells.find(c=>c.id===id);
  if(!cell){ console.log("MISSING CELL", id); continue; }
  const cx=b.x+cell.x*b.w/vp[0], cy=b.y+cell.y*b.h/vp[1];
  const s = await sampleCoat(grid, cx, cy);
  out[id]=s;
  console.log("KENNEL-GRID", id.padEnd(7), `rgb(${s.r},${s.g},${s.b})`, "R-B", s.rb, "B-R", s.br, "lum", Math.round(s.lum));
}
if(out.sol && out.bella && out.trulte){
  const ladder = out.sol.rb > out.bella.rb && out.bella.rb > out.trulte.rb;
  console.log("HUE LADDER warm->cool (Sol.rb > Bella.rb > Trulte.rb):", ladder ? "PASS" : "FAIL",
    `[${out.sol.rb} > ${out.bella.rb} > ${out.trulte.rb}]`);
  const gentle = out.trulte.br < 12;
  console.log("TRULTE GENTLE (not icy blue, B-R < 12):", gentle ? "PASS" : "FAIL", `[B-R = ${out.trulte.br}]`);
}
await browser.close();
