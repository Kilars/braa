// PO father-pass-62 play-test: verify 187 kennel modal↔grid coat parity + full surface sweep.
import { chromium } from "playwright";
import { writeFile, mkdir } from "fs/promises";
const base = "http://localhost:8099/index.html";
await mkdir(".screenshots", { recursive: true });
const P = ".screenshots/P62-";
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 3 });
const client = await page.context().newCDPSession(page);
const errors = [];
page.on("console", m => { if (m.type() === "error") errors.push(m.text()); });
const g = async (k) => page.evaluate(new Function("return window.__bra_" + k + " ?? null"));
async function box(){ return page.evaluate(()=>{const r=document.querySelector("#canvas").getBoundingClientRect();return{x:r.x,y:r.y,w:r.width,h:r.height};});}
async function tapVp(x,y){const b=await box();const vp=await g("viewport")||[720,1558];await page.mouse.click(b.x+x*b.w/vp[0], b.y+y*b.h/vp[1]);}
async function tapObj(o){const b=await box();const vp=await g("viewport")||[720,1558];await page.mouse.click(b.x+o.x*b.w/vp[0], b.y+o.y*b.h/vp[1]);}
async function cap(name){const {data}=await client.send("Page.captureScreenshot",{format:"png",captureBeyondViewport:false});if(name)await writeFile(`${P}${name}.png`,Buffer.from(data,"base64"));return "data:image/png;base64,"+data;}
async function meanRGB(url,px,py,pw,ph){return page.evaluate(async(a)=>{const img=new Image();img.src=a.url;await img.decode();const c=document.createElement("canvas");c.width=img.width;c.height=img.height;const cx=c.getContext("2d");cx.drawImage(img,0,0);const d=cx.getImageData(a.px,a.py,a.pw,a.ph).data;let r=0,gg=0,bl=0,n=0;for(let i=0;i<d.length;i+=4){r+=d[i];gg+=d[i+1];bl+=d[i+2];n++;}return[Math.round(r/n),Math.round(gg/n),Math.round(bl/n)];},{url,px:Math.round(px),py:Math.round(py),pw:Math.round(pw),ph:Math.round(ph)});}
const DSF=3;

await page.goto(`${base}?bra_coins=5000`,{waitUntil:"load",timeout:90000});
await page.waitForFunction("window.__appReady === true",undefined,{timeout:120000});
await page.waitForTimeout(1800);
await cap("a-training");

// open kennel via the real nav-pill center hook
const kbtn = await g("kennel_btn");
console.log("kennel_btn", JSON.stringify(kbtn));
if (kbtn) await tapObj(kbtn); else await tapVp(204,32);
await page.waitForTimeout(1600);
console.log("kennel_open", await g("kennel_open"));
const gridUrl = await cap("kennel-grid");
const cells = await g("kennel_cells");
console.log("cells", cells?cells.length:null);

const b = await box(); const vp = await g("viewport")||[720,1558];
// Nova = cells[1]; sample grid flank
const c1 = cells[1];
const gcx = b.x + c1.x*b.w/vp[0], gcy = b.y + c1.y*b.h/vp[1];
const gridRGB = await meanRGB(gridUrl,(gcx-14)*DSF,(gcy-4)*DSF,28*DSF,18*DSF);

// open Nova modal
await tapObj(c1); await page.waitForTimeout(1300);
let active = await g("kennel_active");
if (active===null){await tapObj(c1);await page.waitForTimeout(1300);active=await g("kennel_active");}
console.log("kennel_active", active);
const modalUrl = await cap("nova-modal");
const modalRGB = await meanRGB(modalUrl,(b.x+b.w*0.42)*DSF,(b.y+b.h*0.30)*DSF,34*DSF,24*DSF);

const lum=c=>0.299*c[0]+0.587*c[1]+0.114*c[2];
console.log("GRID_NOVA",JSON.stringify(gridRGB),"MODAL_NOVA",JSON.stringify(modalRGB));
console.log("DELTA_LUMA",Math.abs(lum(gridRGB)-lum(modalRGB)).toFixed(1));
console.log("GRID_warm(r-b)",gridRGB[0]-gridRGB[2],"MODAL_warm(r-b)",modalRGB[0]-modalRGB[2]);
console.log("errors",errors.length,errors.slice(0,4));
await browser.close();
