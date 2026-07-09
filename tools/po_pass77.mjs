// PO pass-77 / task-200: measure nav-pill label render contrast in shipped pixels vs the "Sitt" control.
// Recalibrated for the 390x844 CSS capture (regions in CSS px). «Kennel» is pure text (no glyph) → the
// clean nav-text control; «Sitt» is the learned-bar label (dark INK) control.
import { chromium } from "playwright";
import { writeFile } from "fs/promises";
import { PNG } from "pngjs";
const base = "http://localhost:8137/index.html";
const browser = await chromium.launch({ args: ["--no-sandbox","--disable-dev-shm-usage","--use-gl=swiftshader"] });
// Block the PWA service worker + bypass HTTP cache so a fresh export is actually rendered (not a
// stale cached index.pck) — task 200 hit exactly this stale-SW trap.
const context = await browser.newContext({ viewport:{width:390,height:844}, deviceScaleFactor:2, serviceWorkers:"block", bypassCSP:true });
const page = await context.newPage();
await context.route("**/*", r => r.continue());
await page.setExtraHTTPHeaders({ "Cache-Control":"no-cache", "Pragma":"no-cache" });
const client = await page.context().newCDPSession(page);
await client.send("Network.enable");
await client.send("Network.clearBrowserCache");
await client.send("Network.setCacheDisabled",{cacheDisabled:true});
const errs=[]; page.on("console",m=>{if(m.type()==="error")errs.push(m.text());});
async function capBuf(clip){const o={format:"png"};if(clip)o.clip=clip;const{data}=await client.send("Page.captureScreenshot",o);return Buffer.from(data,"base64");}

await page.goto(`${base}?bra_coins=5000`,{waitUntil:"load",timeout:90000});
await page.waitForFunction("window.__appReady === true",undefined,{timeout:120000});
await page.waitForTimeout(3500);
const full = await capBuf();
await writeFile(".screenshots/P77-training.png", full);
const hud = await capBuf({x:0,y:0,width:300,height:70,scale:4});
await writeFile(".screenshots/P77-hud-zoom.png", hud);

const lin=c=>{c/=255;return c<=0.03928?c/12.92:Math.pow((c+0.055)/1.055,2.4);};
const lum=(r,g,b)=>0.2126*lin(r)+0.7152*lin(g)+0.0722*lin(b);
const contrast=(a,b)=>{const L1=Math.max(a,b),L2=Math.min(a,b);return (L1+0.05)/(L2+0.05);};

const png = PNG.sync.read(full);
const {width:W,height:H,data}=png;
const at=(x,y)=>{const i=(y*W+x)*4;return [data[i],data[i+1],data[i+2]];};
// Glyph-core sampler: darkest-by-luminance pixel that is NOT pale sky. The pale-blue sky
// ([~126,166,215]) is strongly blue-dominant (b-r large) and bleeds around the rounded pill
// ends/shadow; the dark nav ink glyph is near-neutral (b-r small). Excluding sky pixels isolates
// the actual stroke core on the paper pill. brightest = the local paper fill (contrast reference).
function isSky(r,g,b){ return (b - r) > 40 && b > 150; }
function scan(x0,y0,x1,y1){
  let darkest=[255,255,255],dl=2, brightest=[0,0,0],bl=-1;
  for(let y=y0;y<Math.min(y1,H);y++)for(let x=x0;x<Math.min(x1,W);x++){
    const [r,g,b]=at(x,y); const L=lum(r,g,b);
    if(!isSky(r,g,b) && L<dl){dl=L;darkest=[r,g,b];}
    if(L>bl){bl=L;brightest=[r,g,b];}
  }
  return {darkest,brightest};
}
// CSS-px regions (390 wide). Nav pills y[10..54]; text vertically centred ~y[20..48].
// Triks label: pill x[20..148], glyph occupies left → text x[58..138]. Kennel label pill x[156..274] → text x[172..258].
// CSS-px regions read off the 4× HUD zoom (there is a ~0.6 UI scale factor: Godot offsets ≠ CSS px).
// Tight on each glyph run so the darkest non-sky pixel is a true stroke core.
const regions={
  Triks:  [43,11,71,24],
  Kennel: [97,11,136,24],
  Sitt:   [24,33,47,45],    // learned-bar «Sitt» label (dark INK control)
};
console.log("W,H:",W,H);
// Measure each label on its OWN high-res clip (scale 4 super-samples the 2× render) — the 390-wide
// `full` downsamples thin glyphs toward the pill and never reaches the true stroke-core value. This
// matches how the PO hand-sampled a zoomed capture.
for(const [name,[x0,y0,x1,y1]] of Object.entries(regions)){
  const SC=4;
  const buf = await capBuf({x:x0,y:y0,width:x1-x0,height:y1-y0,scale:SC});
  await writeFile(`.screenshots/P77-lbl-${name}.png`, buf);
  const p = PNG.sync.read(buf);
  let darkest=[255,255,255],dl=2, brightest=[0,0,0],bl=-1;
  for(let i=0;i<p.data.length;i+=4){
    const r=p.data[i],g=p.data[i+1],b=p.data[i+2]; const L=lum(r,g,b);
    if(!isSky(r,g,b) && L<dl){dl=L;darkest=[r,g,b];}
    if(L>bl){bl=L;brightest=[r,g,b];}
  }
  const cr=contrast(lum(...darkest), lum(...brightest));
  console.log(`${name}: ink(darkest)=[${darkest}] fill(brightest)=[${brightest}]  contrast=${cr.toFixed(2)}:1`);
}
console.log("console errors:",errs.length, errs.slice(0,6));
await browser.close();
