// Confirm the 9:16 letterbox on both the local bundle and the LIVE Pages site at 390x844.
// Reports the actual canvas element geometry and screenshots one framed shot with a magenta
// border so the black letterbox bands are unmistakable.
import { createServer } from "node:http";
import { readFile, writeFile } from "node:fs/promises";
import { extname, join, normalize } from "node:path";
import { chromium } from "playwright";

const MIME = { ".html":"text/html; charset=utf-8",".js":"text/javascript; charset=utf-8",".wasm":"application/wasm",".pck":"application/octet-stream",".json":"application/json",".png":"image/png",".svg":"image/svg+xml",".ico":"image/x-icon" };
const server = createServer(async (req,res)=>{try{let p=decodeURIComponent(new URL(req.url,"http://localhost").pathname);if(p==="/")p="/index.html";const safe=normalize(p).replace(/^(\.\.[/\\])+/,"");const body=await readFile(join("build/web",safe));res.setHeader("Content-Type",MIME[extname(safe)]||"application/octet-stream");res.end(body);}catch{res.statusCode=404;res.end("nf");}});
await new Promise(r=>server.listen(0,"127.0.0.1",r));
const local=`http://127.0.0.1:${server.address().port}/index.html`;

const browser=await chromium.launch({args:["--no-sandbox","--disable-dev-shm-usage","--use-gl=swiftshader"]});
async function check(name,url){
  const page=await browser.newPage({viewport:{width:390,height:844}});
  try{
    await page.goto(url,{waitUntil:"load",timeout:90000});
    await page.waitForFunction("window.__appReady === true",{timeout:120000});
    await page.waitForTimeout(2000);
    const geo=await page.evaluate(()=>{const c=document.querySelector("canvas");const r=c.getBoundingClientRect();return{win:[window.innerWidth,window.innerHeight],cssCanvas:[Math.round(r.width),Math.round(r.height)],top:Math.round(r.top),left:Math.round(r.left),attr:[c.width,c.height]};});
    console.log(`\n[${name}] window=${geo.win}  canvasCSS=${geo.cssCanvas} @top=${geo.top},left=${geo.left}  canvasAttr=${geo.attr}`);
    const buf=await page.screenshot({type:"png"});
    await writeFile(`.screenshots/po-p2/letterbox-${name}.png`,buf);
  }catch(e){console.log(`[${name}] FAILED: ${e.message}`);}finally{await page.close();}
}
try{
  await check("local",local);
  await check("live","https://kilars.github.io/braa/");
}finally{await browser.close();server.close();}
