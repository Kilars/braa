import { chromium } from "playwright";
import { writeFile } from "fs/promises";
const base = "http://localhost:8099/index.html";
const P = ".screenshots/P62-";
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 1 });
const client = await page.context().newCDPSession(page);
const errors = [];
page.on("console", m => { if (m.type() === "error") errors.push(m.text()); });
const g = async (k) => page.evaluate(new Function("return window.__bra_" + k + " ?? null"));
async function cap(name){const {data}=await client.send("Page.captureScreenshot",{format:"png",captureBeyondViewport:false});await writeFile(`${P}${name}.png`,Buffer.from(data,"base64"));}
await page.goto(`${base}?bra_coins=5000&bra_autotap=1`,{waitUntil:"load",timeout:90000});
await page.waitForFunction("window.__appReady === true",undefined,{timeout:120000});
// capture several frames trying to catch a mark verdict / word pop
for (let i=0;i<14;i++){ await page.waitForTimeout(650); await cap("mark-"+i); }
console.log("errors", errors.length, errors.slice(0,4));
await browser.close();
