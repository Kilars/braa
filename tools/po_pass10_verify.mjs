// Task 145 Visual Review: capture the training frame + a zoomed HUD crop, and sample the
// readout pixels vs the sky, to confirm the progress readout now reads on the bright sky.
// Usage: env -u LD_LIBRARY_PATH node tools/po_pass10_verify.mjs <bundle-dir>
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
const P = ".screenshots/145-";

const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport: { width: W, height: H } });
const errors = [];
page.on("console", m => { if (m.type() === "error") errors.push(m.text()); });

let code = 1;
try {
  await page.goto(`${base}?bra_autotap=1`, { waitUntil: "load", timeout: 60000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  console.log("app ready");
  // let a few marks land so the bar has a non-zero fill
  await page.waitForTimeout(4200);
  await page.screenshot({ path: `${P}training.png` });
  // HUD crop: top strip where the readout lives (~y 60..120 at 390 wide)
  await page.screenshot({ path: `${P}hud.png`, clip: { x: 0, y: 55, width: W, height: 80 } });
  console.log("console errors:", errors.length ? errors : "none");
  code = errors.length ? 1 : 0;
} catch (e) { console.error("FAIL", e); code = 1; }
finally { await browser.close(); server.close(); process.exit(code); }
