// PO father-pass-73: re-verify task 198 (showcase «Trener nå» pill now green-mint == kennel),
// full surface sweep, sample the showcase commit-pill fill RGB in the actual render.
import { chromium } from "playwright";
import { writeFile } from "fs/promises";
import { PNG } from "pngjs";
const base = "http://localhost:8099/index.html";
const browser = await chromium.launch({ args: ["--no-sandbox","--disable-dev-shm-usage","--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport:{width:390,height:844}, deviceScaleFactor:2 });
const client = await page.context().newCDPSession(page);
const errs=[]; page.on("console",m=>{if(m.type()==="error")errs.push(m.text());});
const g=async(k)=>page.evaluate(new Function("return window.__bra_"+k+" ?? null"));
async function cap(name,clip){const o=clip?{format:"png",clip:{...clip,scale:2}}:{format:"png"};const{data}=await client.send("Page.captureScreenshot",o);const buf=Buffer.from(data,"base64");await writeFile(`.screenshots/${name}.png`,buf);return buf;}
async function box(){return await page.evaluate(()=>{const c=document.querySelector("canvas");const r=c.getBoundingClientRect();return{x:r.x,y:r.y,w:r.width,h:r.height};});}
async function tapVp(x,y){const b=await box();const vp=await g("viewport")||[720,1558];await page.mouse.click(b.x+x*b.w/vp[0], b.y+y*b.h/vp[1]);}
async function tapScreen(sx,sy){const b=await box();await page.mouse.click(b.x+sx*b.w/390, b.y+sy*b.h/844);}
// find dominant near-white fill in a region: cluster the brightest opaque pixels, report mean RGB
function sampleFill(buf,label){const p=PNG.sync.read(buf);const px=[];for(let i=0;i<p.data.length;i+=4){const r=p.data[i],gc=p.data[i+1],b=p.data[i+2];const mx=Math.max(r,gc,b);if(mx>200&&mx-Math.min(r,gc,b)<40)px.push([r,gc,b]);}
  if(!px.length){console.log(label,"no near-white fill found");return null;}
  const m=px.reduce((a,c)=>[a[0]+c[0],a[1]+c[1],a[2]+c[2]],[0,0,0]).map(v=>Math.round(v/px.length));
  const bias=m[1]>m[0]&&m[1]>=m[2]?"GREEN-biased":(m[2]>m[1]&&m[2]>m[0]?"BLUE-biased":"neutral");
  console.log(label,"fill rgb("+m.join(",")+")  n="+px.length+"  =>",bias);return m;}
await page.goto(`${base}?bra_coins=5000`,{waitUntil:"load",timeout:90000});
await page.waitForFunction("window.__appReady === true",undefined,{timeout:120000});
await page.waitForTimeout(4000);
await cap("P73-a-training");
// menu
await tapScreen(62,27); await page.waitForTimeout(1200);
await cap("P73-b-menu");
// showcase
const sc=await g("showcase_row"); console.log("showcase_row",sc);
await tapVp(sc[0],sc[1]); await page.waitForTimeout(1800);
console.log("showcase_open",await g("showcase_open"),"spotlit",await g("showcase_spotlit"));
await cap("P73-c-showcase");
// commit «Trener nå» pill: screen ~x[119,271] y[796,819]
const pill=await cap("P73-c-pill",{x:110,y:792,width:170,height:30});
sampleFill(pill,"SHOWCASE «Trener nå» pill");
// back to training, then kennel
await tapVp(sc[0],1518);  // «Tilbake» in vp space (y ~ -40 from 1558 bottom)
await page.waitForTimeout(1200);
console.log("showcase_open after back",await g("showcase_open"));
const kb=await g("kennel_btn"); console.log("kennel_btn",kb);
if(kb){await tapVp(kb.x,kb.y); await page.waitForTimeout(1800);}
console.log("kennel_open",await g("kennel_open"));
await cap("P73-d-kennel-grid");
const cells=await g("kennel_cells"); const bella=cells&&cells.find(c=>c.id==="bella");
console.log("bella cell",bella);
if(bella){await tapVp(bella.x,bella.y); await page.waitForTimeout(1600);}
await cap("P73-e-bella-modal");
// Bella modal «Trener nå» pill — sample its fill; owned-active pill sits low in the modal
const kpill=await cap("P73-e-pill",{x:60,y:560,width:270,height:220});
sampleFill(kpill,"KENNEL Bella «Trener nå» region");
console.log("console errors:",errs.length, errs.slice(0,6));
await browser.close();
