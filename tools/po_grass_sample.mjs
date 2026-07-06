// 144 verify: boot the fresh bundle, capture the training frame, sample the grass foreground
// vs mid-field and report region-averages to check the PO bar (foreground green within ~15% of
// mid-field, never below ~100, no muddy dark blotch). Decodes the shot in a 2D canvas (no native deps).
// Usage: env -u LD_LIBRARY_PATH node tools/po_grass_sample.mjs <bundle-dir>
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
const W = 390, H = 844;
await mkdir(".screenshots", { recursive: true });

const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport: { width: W, height: H } });
try {
  await page.goto(`http://127.0.0.1:${port}/index.html?bra_autotap=1`, { waitUntil: "load", timeout: 60000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  await page.waitForTimeout(2000);
  const buf = await page.screenshot({ path: ".screenshots/144-grass.png" });
  const dataUrl = "data:image/png;base64," + buf.toString("base64");

  const out = await page.evaluate(async (url) => {
    const img = new Image();
    await new Promise((r) => { img.onload = r; img.src = url; });
    const c = document.createElement("canvas");
    c.width = img.width; c.height = img.height;
    const cx = c.getContext("2d");
    cx.drawImage(img, 0, 0);
    function region(fx, fy, halfw = 18, halfh = 10) {
      const px = Math.round(fx * c.width), py = Math.round(fy * c.height);
      const d = cx.getImageData(px - halfw, py - halfh, halfw * 2 + 1, halfh * 2 + 1).data;
      let r = 0, g = 0, b = 0, n = d.length / 4;
      for (let i = 0; i < d.length; i += 4) { r += d[i]; g += d[i + 1]; b += d[i + 2]; }
      return [Math.round(r / n), Math.round(g / n), Math.round(b / n)];
    }
    const grid = {};
    for (const fy of [0.40, 0.50, 0.58, 0.66, 0.74, 0.82])
      for (const fx of [0.12, 0.30, 0.50, 0.70, 0.88])
        grid[`y${fy}_x${fx}`] = region(fx, fy, 10, 6);
    return {
      mid: region(0.18, 0.52),
      fg65: region(0.18, 0.65),
      fg75: region(0.18, 0.78),
      fgBand: region(0.20, 0.72, 60, 40),
      grid,
    };
  }, dataUrl);

  console.log(JSON.stringify(out.grid, null, 0));
  console.log(JSON.stringify({ mid: out.mid, fg65: out.fg65, fg75: out.fg75, fgBand: out.fgBand }));
  const within15 = out.fg65[1] >= out.mid[1] * 0.85 && out.fg75[1] >= out.mid[1] * 0.85;
  const above100 = out.fg65[1] >= 100 && out.fg75[1] >= 100 && out.fgBand[1] >= 100;
  console.log("within15%_of_mid:", within15, " never_below_100:", above100);
  process.exitCode = within15 && above100 ? 0 : 2;
} finally {
  await browser.close();
  server.close();
}
