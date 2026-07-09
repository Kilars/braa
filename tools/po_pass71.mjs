import { chromium } from "playwright";
import { writeFile } from "fs/promises";
import { PNG } from "pngjs";
const base = "http://localhost:8099/index.html";
const browser = await chromium.launch({ args: ["--no-sandbox","--disable-dev-shm-usage","--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport:{width:390,height:844}, deviceScaleFactor:2 });
const client = await page.context().newCDPSession(page);
const errs=[]; page.on("console",m=>{if(m.type()==="error")errs.push(m.text());});
const g=async(k)=>page.evaluate(new Function("return window.__bra_"+k+" ?? null"));
async function cap(name,clip,s){const{data}=await client.send("Page.captureScreenshot",{format:"png",clip:{...clip,scale:s||2}});const buf=Buffer.from(data,"base64");await writeFile(`.screenshots/${name}.png`,buf);return buf;}
async function box(){return await page.evaluate(()=>{const c=document.querySelector("canvas");const r=c.getBoundingClientRect();return{x:r.x,y:r.y,w:r.width,h:r.height};});}
async function tapVp(x,y){const b=await box();const vp=await g("viewport")||[720,1558];await page.mouse.click(b.x+x*b.w/vp[0], b.y+y*b.h/vp[1]);}
async function tapScreen(sx,sy){const b=await box();await page.mouse.click(b.x+sx*b.w/390, b.y+sy*b.h/844);}
const lin=(c)=>{c/=255;return c<=0.03928?c/12.92:Math.pow((c+0.055)/1.055,2.4);};
const lum=(r,gc,b)=>0.2126*lin(r)+0.7152*lin(gc)+0.0722*lin(b);
const contrast=(a,b)=>{const h=Math.max(a,b),l=Math.min(a,b);return (h+0.05)/(l+0.05);};
// darkest 10% = scrim chip, brightest 2% = white ink; AA = ink vs chip
function measure(buf,label){const p=PNG.sync.read(buf);const L=[];for(let i=0;i<p.data.length;i+=4)L.push(lum(p.data[i],p.data[i+1],p.data[i+2]));L.sort((a,b)=>a-b);
  const chip=L[Math.floor(L.length*0.10)];const ink=L[Math.floor(L.length*0.98)];
  console.log(label,"ink",ink.toFixed(3),"chip",chip.toFixed(3),"=>",contrast(ink,chip).toFixed(2)+":1");}
await page.goto(`${base}?bra_coins=5000`,{waitUntil:"load",timeout:90000});
await page.waitForFunction("window.__appReady === true",undefined,{timeout:120000});
await page.waitForTimeout(4000);
await cap("P71-a-training",{x:0,y:0,width:390,height:844});
// open menu
await tapScreen(62,27); await page.waitForTimeout(1200);
await cap("P71-b-menu",{x:0,y:0,width:390,height:844});
const sc=await g("showcase_row"); console.log("showcase_row",sc);
if(sc){ await tapVp(sc[0],sc[1]); await page.waitForTimeout(1800);
  await cap("P71-c-showcase",{x:0,y:0,width:390,height:844});
  // header subtitle chip region & bottom hint chip region
  const sub=await cap("P71-c-sub",{x:120,y:38,width:150,height:22},4);
  const hint=await cap("P71-c-hint",{x:70,y:762,width:250,height:26},4);
  measure(sub,"SUBTITLE «Labrador»");
  measure(hint,"HINT «Adopter …»  ");
}
console.log("console errors:",errs.length, errs.slice(0,5));
await browser.close();
