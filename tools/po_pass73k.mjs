import { chromium } from "playwright";
import { writeFile } from "fs/promises";
import { PNG } from "pngjs";
const base="http://localhost:8099/index.html";
const browser=await chromium.launch({args:["--no-sandbox","--disable-dev-shm-usage","--use-gl=swiftshader"]});
const page=await browser.newPage({viewport:{width:390,height:844},deviceScaleFactor:2});
const client=await page.context().newCDPSession(page);
const errs=[];page.on("console",m=>{if(m.type()==="error")errs.push(m.text());});
const g=async(k)=>page.evaluate(new Function("return window.__bra_"+k+" ?? null"));
async function cap(name,clip){const o=clip?{format:"png",clip:{...clip,scale:2}}:{format:"png"};const{data}=await client.send("Page.captureScreenshot",o);const buf=Buffer.from(data,"base64");await writeFile(`.screenshots/${name}.png`,buf);return buf;}
async function box(){return await page.evaluate(()=>{const c=document.querySelector("canvas");const r=c.getBoundingClientRect();return{x:r.x,y:r.y,w:r.width,h:r.height};});}
async function tapVp(x,y){const b=await box();const vp=await g("viewport")||[720,1558];await page.mouse.click(b.x+x*b.w/vp[0],b.y+y*b.h/vp[1]);}
function sampleFill(buf,label){const p=PNG.sync.read(buf);const px=[];for(let i=0;i<p.data.length;i+=4){const r=p.data[i],gc=p.data[i+1],b=p.data[i+2];const mx=Math.max(r,gc,b),mn=Math.min(r,gc,b);if(mx>205&&mx<252&&mx-mn<28)px.push([r,gc,b]);}if(!px.length){console.log(label,"none");return;}const m=px.reduce((a,c)=>[a[0]+c[0],a[1]+c[1],a[2]+c[2]],[0,0,0]).map(v=>Math.round(v/px.length));const bias=m[1]>m[0]&&m[1]>=m[2]?"GREEN":(m[2]>m[1]&&m[2]>m[0]?"BLUE":"neutral");console.log(label,"rgb("+m.join(",")+") n="+px.length+" =>",bias);}
await page.goto(`${base}?bra_coins=5000`,{waitUntil:"load",timeout:90000});
await page.waitForFunction("window.__appReady === true",undefined,{timeout:120000});
await page.waitForTimeout(3500);
const kb=await g("kennel_btn"); console.log("kennel_btn",kb);
await tapVp(kb.x,kb.y); await page.waitForTimeout(1800);
console.log("kennel_open",await g("kennel_open"));
await cap("P73-d-kennel-grid");
const cells=await g("kennel_cells"); const bella=(cells||[]).find(c=>c.id==="bella");
console.log("cells",(cells||[]).map(c=>c.id),"bella",bella);
await tapVp(bella.x,bella.y); await page.waitForTimeout(1600);
await cap("P73-e-bella-modal");
const kpill=await cap("P73-e-pill",{x:40,y:600,width:310,height:180});
sampleFill(kpill,"KENNEL Bella «Trener nå» area");
console.log("errors",errs.length,errs.slice(0,5));
await browser.close();
