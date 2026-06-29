// Dense pixel-repro: record video of the live web build so the brief (~0.4s) apex-tell
// window can't be missed by slow manual screenshots (task 030 diagnosis).
// Usage: env -u LD_LIBRARY_PATH node tools/web_record.mjs <bundle-dir> <video-dir> [seconds]
import { createServer } from "node:http";
import { readFile } from "node:fs/promises";
import { extname, join, normalize } from "node:path";
import { chromium } from "playwright";

const bundleDir = process.argv[2];
const vdir = process.argv[3] || "/tmp/bra-video";
const secs = Number(process.argv[4] || 14);
const MIME = { ".html": "text/html; charset=utf-8", ".js": "text/javascript; charset=utf-8",
	".wasm": "application/wasm", ".pck": "application/octet-stream", ".json": "application/json",
	".png": "image/png", ".svg": "image/svg+xml", ".ico": "image/x-icon" };
const server = createServer(async (req, res) => {
	try {
		let p = decodeURIComponent(new URL(req.url, "http://localhost").pathname);
		if (p === "/") p = "/index.html";
		const body = await readFile(join(bundleDir, normalize(p).replace(/^(\.\.[/\\])+/, "")));
		res.setHeader("Content-Type", MIME[extname(p)] || "application/octet-stream");
		res.end(body);
	} catch { res.statusCode = 404; res.end("not found"); }
});
await new Promise((r) => server.listen(0, "127.0.0.1", r));
const { port } = server.address();

const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });
const ctx = await browser.newContext({ viewport: { width: 390, height: 844 },
	reducedMotion: "no-preference", recordVideo: { dir: vdir, size: { width: 390, height: 844 } } });
const page = await ctx.newPage();
const logs = [];
page.on("console", (m) => logs.push(m.text()));
await page.goto(`http://127.0.0.1:${port}/index.html`, { waitUntil: "load", timeout: 60000 });
await page.waitForFunction("window.__appReady === true", { timeout: 120000 });
console.log("booted; recording", secs, "s");
await page.waitForTimeout(secs * 1000);
await ctx.close();          // flushes the video file
await browser.close();
server.close();
console.log("done; video in", vdir);
