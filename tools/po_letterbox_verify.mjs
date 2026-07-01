// 063 verification: prove the garden fills 390x844 with NO black letterbox on the LOCAL
// (post-fix) bundle. Samples top/bottom row mean brightness by decoding the screenshot in a
// 2D canvas inside the page (no Node PNG dep). A black letterbox band reads ~0.
import { createServer } from "node:http";
import { readFile, writeFile } from "node:fs/promises";
import { extname, join, normalize } from "node:path";
import { chromium } from "playwright";

const MIME = { ".html":"text/html; charset=utf-8",".js":"text/javascript; charset=utf-8",".wasm":"application/wasm",".pck":"application/octet-stream",".json":"application/json",".png":"image/png",".svg":"image/svg+xml",".ico":"image/x-icon" };
const server = createServer(async (req,res)=>{try{let p=decodeURIComponent(new URL(req.url,"http://localhost").pathname);if(p==="/")p="/index.html";const safe=normalize(p).replace(/^(\.\.[/\\])+/,"");const body=await readFile(join("build/web",safe));res.setHeader("Content-Type",MIME[extname(safe)]||"application/octet-stream");res.end(body);}catch{res.statusCode=404;res.end("nf");}});
await new Promise(r=>server.listen(0,"127.0.0.1",r));
const url=`http://127.0.0.1:${server.address().port}/index.html`;

const browser=await chromium.launch({args:["--no-sandbox","--disable-dev-shm-usage","--use-gl=swiftshader"]});
const page=await browser.newPage({viewport:{width:390,height:844}});
await page.goto(url,{waitUntil:"load",timeout:90000});
await page.waitForFunction("window.__appReady === true",{timeout:120000});
await page.waitForTimeout(2500);
const buf=await page.screenshot({type:"png"});
await writeFile(".screenshots/po-p2/letterbox-fixed-local.png",buf);

const b64=buf.toString("base64");
const rows=await page.evaluate(async(b64)=>{
  const img=new Image();
  await new Promise((res,rej)=>{img.onload=res;img.onerror=rej;img.src="data:image/png;base64,"+b64;});
  const c=document.createElement("canvas");c.width=img.width;c.height=img.height;
  const ctx=c.getContext("2d");ctx.drawImage(img,0,0);
  const rowMean=(y)=>{const d=ctx.getImageData(0,y,img.width,1).data;let s=0;for(let x=0;x<img.width;x++){const i=x*4;s+=(d[i]+d[i+1]+d[i+2])/3;}return s/img.width;};
  return {w:img.width,h:img.height,top0:rowMean(0),top2:rowMean(2),botLast:rowMean(img.height-1),bot3:rowMean(img.height-3)};
},b64);

console.log(`viewport=${rows.w}x${rows.h}`);
console.log(`  row top(0)     mean-brightness=${rows.top0.toFixed(1)}`);
console.log(`  row top(2)     mean-brightness=${rows.top2.toFixed(1)}`);
console.log(`  row bot(${rows.h-3})  mean-brightness=${rows.bot3.toFixed(1)}`);
console.log(`  row bot(${rows.h-1})  mean-brightness=${rows.botLast.toFixed(1)}`);
const LETTERBOX_THRESH=8;  // pure-black band ~0; garden sky/grass read well above
const boxed=rows.top0<LETTERBOX_THRESH||rows.botLast<LETTERBOX_THRESH;
console.log(boxed?"RESULT: FAIL — black letterbox band still present":"RESULT: PASS — no black letterbox; garden reaches top+bottom edges");
await browser.close();server.close();
process.exit(boxed?1:0);
