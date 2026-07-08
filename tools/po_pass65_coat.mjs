// 191 visual review (PO father-pass-65 X-6/X-4): sample the THREE light-coat dogs in the kennel
// grid — Sol (golden), Bella (cream reference), Trulte (near-white) — and confirm they read as
// distinct breed hues (warm→neutral→cool ladder by R−B), not one flat cream. Decodes the CDP
// screenshot inside the page via a 2D canvas.
import { chromium } from "playwright";
import { writeFile } from "fs/promises";
const base = "http://localhost:8099/index.html";
const P = ".screenshots/P65-coat-";
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 1 });
const client = await page.context().newCDPSession(page);
const g = async (k) => page.evaluate(new Function("return window.__bra_" + k + " ?? null"));
async function cap(name){const {data}=await client.send("Page.captureScreenshot",{format:"png",captureBeyondViewport:false});await writeFile(`${P}${name}.png`,Buffer.from(data,"base64"));return "data:image/png;base64,"+data;}
async function box(){return await page.evaluate(()=>{const c=document.querySelector("canvas");const r=c.getBoundingClientRect();return {x:r.x,y:r.y,w:r.width,h:r.height};});}
async function tapVp(x,y){const b=await box();const vp=await g("viewport")||[720,1558];await page.mouse.click(b.x+x*b.w/vp[0], b.y+y*b.h/vp[1]);}
// mean RGB over the BRIGHTEST patch down a cell (the lit coat, not the dark band): sample several
// dy offsets and keep the one with the highest luminance so we read coat, not shadow/band.
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
      return {r, g:gg, b, rb:r-b, lum:0.2126*r+0.7152*gg+0.0722*b};
    }, {dataUrl,cx,cy:cy+dy});
    if(!best || s.lum>best.lum) best = s;
  }
  return best;
}

await page.goto(`${base}?bra_coins=5000`,{waitUntil:"load",timeout:90000});
await page.waitForFunction("window.__appReady === true",undefined,{timeout:120000});
await page.waitForTimeout(900);

// open kennel grid
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
  console.log("KENNEL-GRID", id.padEnd(7), `rgb(${s.r},${s.g},${s.b})`, "R-B", s.rb, "lum", Math.round(s.lum));
}
if(out.sol && out.bella && out.trulte){
  const ladder = out.sol.rb > out.bella.rb && out.bella.rb > out.trulte.rb;
  console.log("HUE LADDER warm->cool (Sol.rb > Bella.rb > Trulte.rb):", ladder ? "PASS" : "FAIL",
    `[${out.sol.rb} > ${out.bella.rb} > ${out.trulte.rb}]`);
}
await browser.close();
