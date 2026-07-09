// PO father-pass-69: reach the 2-mastery completion menu so «Vanskelighet» reveals, then
// capture + read the difficulty rows to verify task 194's selectable-row «Bytt» badge.
// Autotap lands OK-tier marks (~0.08 each → ~13 sits/trick), so wait GENEROUSLY & uninterrupted
// (opening the menu pauses training). word_rows>0 proves mastery#1, difficulty_rows>0 proves #2.
import { chromium } from "playwright";
import { writeFile } from "fs/promises";
const base = "http://localhost:8099/index.html";
const P = ".screenshots/P69d-";
const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 1 });
const client = await page.context().newCDPSession(page);
const errors = [];
page.on("console", m => { if (m.type() === "error") errors.push(m.text()); });
const g = async (k) => page.evaluate(new Function("return window.__bra_" + k + " ?? null"));
async function cap(name){const {data}=await client.send("Page.captureScreenshot",{format:"png",captureBeyondViewport:false});await writeFile(`${P}${name}.png`,Buffer.from(data,"base64"));}
async function box(){return await page.evaluate(()=>{const c=document.querySelector("canvas");const r=c.getBoundingClientRect();return {x:r.x,y:r.y,w:r.width,h:r.height};});}
async function tapVp(x,y){const b=await box();const vp=await g("viewport")||[720,1558];await page.mouse.click(b.x+x*b.w/vp[0], b.y+y*b.h/vp[1]);}
async function openMenu(){ await tapVp(70,32); await page.waitForTimeout(1200); return await g("menu_open"); }

await page.goto(`${base}?bra_coins=5000&bra_autotap=1`,{waitUntil:"load",timeout:90000});
await page.waitForFunction("window.__appReady === true",undefined,{timeout:120000});

// Mastery #1 (Sitt) — wait uninterrupted.
await page.waitForTimeout(160000);
await openMenu();
let words = (await g("word_rows")||[]).length;
let tricks = await g("trick_rows")||[];
console.log("after #1: menu_open", await g("menu_open"), "current", await g("current_trick"), "word_rows", words);
await cap("m1");
if(words === 0){ console.log("!! Sitt not mastered after 160s — autotap too slow"); }

// Switch to Ligg (auto-closes menu, resumes training on ligg).
const ligg = tricks.find(t=>t.id==="ligg");
if(ligg){ await tapVp(ligg.x, ligg.y); await page.waitForTimeout(1500); }
console.log("switched to", await g("current_trick"), "menu_open", await g("menu_open"));

// Mastery #2 (Ligg) — wait uninterrupted.
await page.waitForTimeout(160000);
await openMenu();
const diffs = await g("difficulty_rows")||[];
console.log("after #2: menu_open", await g("menu_open"), "current", await g("current_trick"), "diff_rows", diffs.length, JSON.stringify(diffs));
await cap("m2-difficulty");

console.log("errors", errors.length, errors.slice(0,6));
await browser.close();
