import { chromium } from "playwright";
import { writeFile } from "fs/promises";
import { PNG } from "pngjs";
const base = "http://localhost:8099/index.html";
const browser = await chromium.launch({ args: ["--no-sandbox","--disable-dev-shm-usage","--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport:{width:390,height:844}, deviceScaleFactor:2 });
const client = await page.context().newCDPSession(page);
const g=async(k)=>page.evaluate(new Function("return window.__bra_"+k+" ?? null"));
async function cap(name,clip,s){const{data}=await client.send("Page.captureScreenshot",{format:"png",clip:{...clip,scale:s||4}});const buf=Buffer.from(data,"base64");await writeFile(`.screenshots/${name}.png`,buf);return buf;}
async function box(){return await page.evaluate(()=>{const c=document.querySelector("canvas");const r=c.getBoundingClientRect();return{x:r.x,y:r.y,w:r.width,h:r.height};});}
async function tapVp(x,y){const b=await box();const vp=await g("viewport")||[720,1558];await page.mouse.click(b.x+x*b.w/vp[0], b.y+y*b.h/vp[1]);}
async function tapScreen(sx,sy){const b=await box();await page.mouse.click(b.x+sx*b.w/390, b.y+sy*b.h/844);}
const lin=(c)=>{c/=255;return c<=0.03928?c/12.92:Math.pow((c+0.055)/1.055,2.4);};
const lum=(r,gc,b)=>0.2126*lin(r)+0.7152*lin(gc)+0.0722*lin(b);
const contrast=(a,b)=>{const h=Math.max(a,b),l=Math.min(a,b);return (h+0.05)/(l+0.05);};
function measure(buf,label){const p=PNG.sync.read(buf);const L=[];for(let i=0;i<p.data.length;i+=4)L.push(lum(p.data[i],p.data[i+1],p.data[i+2]));L.sort((a,b)=>a-b);
  const band=L[Math.floor(L.length*0.08)];const ink=L[Math.floor(L.length*0.99)];
  console.log(label,"ink",ink.toFixed(3),"band",band.toFixed(3),"=>",contrast(ink,band).toFixed(2)+":1");}
await page.goto(`${base}?bra_coins=5000`,{waitUntil:"load",timeout:90000});
await page.waitForFunction("window.__appReady === true",undefined,{timeout:120000});
await page.waitForTimeout(4000);
await tapScreen(62,27); await page.waitForTimeout(1000);
const sc=await g("showcase_row");
if(sc){ await tapVp(sc[0],sc[1]); await page.waitForTimeout(1600);
  const sub=await cap("P70i-subtitle",{x:150,y:43,width:90,height:16});
  const hint=await cap("P70i-hint",{x:95,y:770,width:200,height:20});
  measure(sub,"SUBTITLE «Labrador»");
  measure(hint,"HINT «Adopter …»  ");
}
await browser.close();
