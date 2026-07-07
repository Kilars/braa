// PO father pass 26 — hunt for polish defects on surfaces the recent arc skipped:
// the spotlit BREED SHOWCASE (P3-4), the difficulty/breed menu rows, word-pop, locked states.
// Grants ?bra_coins to reveal breed section; autotap to master Sitt (reveals words).
import { createServer } from "node:http";
import { readFile, mkdir } from "node:fs/promises";
import { extname, join, normalize } from "node:path";
import { chromium } from "playwright";

const bundleDir = process.argv[2] || "build/web";
const MIME = { ".html": "text/html; charset=utf-8", ".js": "text/javascript; charset=utf-8",
  ".wasm": "application/wasm", ".pck": "application/octet-stream", ".json": "application/json",
  ".png": "image/png", ".svg": "image/svg+xml", ".ico": "image/x-icon" };
const server = createServer(async (req, res) => {
  try {
    let p = decodeURIComponent(new URL(req.url, "http://localhost").pathname);
    if (p === "/") p = "/index.html";
    const safe = normalize(p).replace(/^(\.\.[/\\])+/, "");
    const body = await readFile(join(bundleDir, safe));
    res.setHeader("Content-Type", MIME[extname(safe)] || "application/octet-stream");
    res.end(body);
  } catch { res.statusCode = 404; res.end("not found"); }
});
await new Promise((r) => server.listen(0, "127.0.0.1", r));
const { port } = server.address();
const base = `http://127.0.0.1:${port}/index.html`;
const W = 390, H = 844;
await mkdir(".screenshots", { recursive: true });
const P = ".screenshots/P26-";

const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport: { width: W, height: H }, deviceScaleFactor: 3 });
const errors = [];
page.on("console", m => { if (m.type() === "error") errors.push(m.text()); });
async function tapVp(x, y) {
  const box = await page.locator("canvas").boundingBox();
  const vp = await page.evaluate(() => window.__bra_viewport || null);
  await page.mouse.click(box.x + x * box.width / (vp ? vp[0] : 720), box.y + y * box.height / (vp ? vp[1] : 1280));
}
const dump = async (k) => JSON.stringify(await page.evaluate(new Function("return window.__bra_" + k + " ?? null")));

let code = 1;
try {
  await page.goto(`${base}?bra_autotap=1&bra_coins=120`, { waitUntil: "load", timeout: 90000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  console.log("ready; trick", await dump("current_trick"), "balance", await dump("balance"));
  // let autotap run to master Sitt (unlocks first word -> reveals words section)
  await page.waitForTimeout(9000);
  await page.screenshot({ path: `${P}01-training.png` });
  console.log("active_word", await dump("active_word"), "owned", await dump("owned"));

  // open menu
  await tapVp(70, 32);
  await page.waitForTimeout(1400);
  console.log("menu_open", await dump("menu_open"));
  console.log("trick_rows", await dump("trick_rows"));
  console.log("word_rows", await dump("word_rows"));
  console.log("difficulty_rows", await dump("difficulty_rows"));
  console.log("breed_rows", await dump("breed_rows"));
  console.log("showcase_buttons", await dump("showcase_buttons"));
  await page.screenshot({ path: `${P}02-menu-full.png`, fullPage: false });

  // try to open the breed showcase via its button/row
  const sb = await page.evaluate(() => window.__bra_showcase_buttons || null);
  const br = await page.evaluate(() => window.__bra_breed_rows || null);
  console.log("showcase_buttons raw", JSON.stringify(sb), "breed_rows raw", JSON.stringify(br));
  // showcase row is usually the last breed-section row ("Vis frem hundene")
  if (br && br.length) {
    const last = br[br.length - 1];
    await tapVp(last.x ?? last[0], last.y ?? last[1]);
    await page.waitForTimeout(1600);
  }
  console.log("showcase_open", await dump("showcase_open"), "spotlit", await dump("showcase_spotlit"));
  await page.screenshot({ path: `${P}03-showcase.png` });

  // showcase chevrons -> next dog
  const scb = await page.evaluate(() => window.__bra_showcase_buttons || null);
  console.log("showcase_buttons after open", JSON.stringify(scb));
  if (scb && scb.next) { await tapVp(scb.next.x ?? scb.next[0], scb.next.y ?? scb.next[1]); await page.waitForTimeout(1200); }
  await page.screenshot({ path: `${P}04-showcase-next.png` });

  console.log("console errors:", errors.length ? errors : "none");
  code = errors.length ? 1 : 0;
} catch (e) { console.error("FAIL", e); code = 1; }
finally { await browser.close(); server.close(); process.exit(code); }
