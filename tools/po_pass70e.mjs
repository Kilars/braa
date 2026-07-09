// PO pass-70e — verify task 196: the showcase caption tier («Labrador» subtitle + «Adopter flere …»
// hint) clears WCAG AA in the ACTUAL render after the dark-outline halo fix. Opens the showcase, caps
// the header + bottom bands, then samples brightest-ink-vs-band contrast the way the father does by hand.
import { chromium } from "playwright";
import { writeFile } from "fs/promises";
import { PNG } from "pngjs";
const base = "http://localhost:8099/index.html";
const P = ".screenshots/P70e-";
const browser = await chromium.launch({ args: ["--no-sandbox","--disable-dev-shm-usage","--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport:{width:390,height:844}, deviceScaleFactor:2 });
const client = await page.context().newCDPSession(page);
const errors=[]; page.on("console",m=>{if(m.type()==="error")errors.push(m.text());});
const g=async(k)=>page.evaluate(new Function("return window.__bra_"+k+" ?? null"));
async function cap(name,clip){const o={format:"png"};if(clip)o.clip={...clip,scale:2};const{data}=await client.send("Page.captureScreenshot",o);const buf=Buffer.from(data,"base64");await writeFile(`${P}${name}.png`,buf);return buf;}
async function box(){return await page.evaluate(()=>{const c=document.querySelector("canvas");const r=c.getBoundingClientRect();return{x:r.x,y:r.y,w:r.width,h:r.height};});}
async function tapVp(x,y){const b=await box();const vp=await g("viewport")||[720,1558];await page.mouse.click(b.x+x*b.w/vp[0], b.y+y*b.h/vp[1]);}
async function tapScreen(sx,sy){const b=await box();await page.mouse.click(b.x+sx*b.w/390, b.y+sy*b.h/844);}
const lin=(c)=>{c/=255;return c<=0.03928?c/12.92:Math.pow((c+0.055)/1.055,2.4);};
const lum=(r,gc,b)=>0.2126*lin(r)+0.7152*lin(gc)+0.0722*lin(b);
const contrast=(l1,l2)=>{const a=Math.max(l1,l2),b=Math.min(l1,l2);return (a+0.05)/(b+0.05);};
// Within a band strip, the caption is the brightest ~white ink; the band is the dark median. Measure the
// brightest text pixel's luminance vs the median band luminance — the father's worst-case caption read.
function measure(buf){const png=PNG.sync.read(buf);const {width,height,data}=png;const lums=[];
  for(let i=0;i<data.length;i+=4){lums.push(lum(data[i],data[i+1],data[i+2]));}
  lums.sort((a,b)=>a-b);
  const band=lums[Math.floor(lums.length*0.5)];        // median = the dark band
  const ink=lums[Math.floor(lums.length*0.995)];       // brightest 0.5% = the white glyph strokes
  return {ink,band,ratio:contrast(ink,band),px:width*height};}

await page.goto(`${base}?bra_coins=5000`,{waitUntil:"load",timeout:90000});
await page.waitForFunction("window.__appReady === true",undefined,{timeout:120000});
await page.waitForTimeout(4000);
await tapScreen(62,27); await page.waitForTimeout(1000);
const sc=await g("showcase_row"); console.log("showcase_row",sc);
if(sc){ await tapVp(sc[0],sc[1]); await page.waitForTimeout(1600);
  console.log("showcase_open",await g("showcase_open"));
  // Subtitle band strip (top, under the big name) and the hint strip (bottom control band).
  const sub=await cap("subtitle",{x:40,y:78,width:310,height:24});
  const hint=await cap("hint",{x:20,y:668,width:350,height:22});
  const ms=measure(sub), mh=measure(hint);
  console.log("SUBTITLE «Labrador»  ink",ms.ink.toFixed(3),"band",ms.band.toFixed(3),"=>",ms.ratio.toFixed(2)+":1");
  console.log("HINT «Adopter …»     ink",mh.ink.toFixed(3),"band",mh.band.toFixed(3),"=>",mh.ratio.toFixed(2)+":1");
}
console.log("errors",errors.length,errors.slice(0,6));
await browser.close();
