// Grab N frames across several sit cycles so we can pick a SEATED pose to compare the coat
// against the pre-fix shot (032). Boots the Godot Web bundle in headless Chromium (SwiftShader
// == the deployed GL Compatibility renderer), settles, then screenshots every ~600ms.
// Usage: env -u LD_LIBRARY_PATH node tools/web_capture_frames.mjs <bundle-dir> <out-prefix> <count> [gapMs] [query]
//   [query] — a URL query string appended to index.html (e.g. "bra_trick=legg_deg") so a trick reachable
//   only via ?bra_trick= (065/067) can be captured before the 066 selector UI lands. Omit for default play.
import { createServer } from "node:http";
import { readFile, writeFile } from "node:fs/promises";
import { extname, join, normalize } from "node:path";
import { chromium } from "playwright";

const bundleDir = process.argv[2];
const prefix = process.argv[3] || ".screenshots/032-frame";
const count = parseInt(process.argv[4] || "8", 10);
const gapMs = parseInt(process.argv[5] || "600", 10);  // denser spacing catches brief transitions
const query = (process.argv[6] || "").replace(/^\?/, "");  // optional ?bra_trick= selector (065/067)
if (!bundleDir) { console.error("usage: web_capture_frames.mjs <bundle-dir> <out-prefix> <count>"); process.exit(2); }

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
const url = `http://127.0.0.1:${port}/index.html${query ? "?" + query : ""}`;

const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
try {
	await page.goto(url, { waitUntil: "load", timeout: 60000 });
	await page.waitForFunction("window.__appReady === true", { timeout: 120000 });
	await page.waitForTimeout(1500);
	for (let i = 0; i < count; i++) {
		const buf = await page.screenshot({ type: "png" });
		await writeFile(`${prefix}-${String(i).padStart(2, "0")}.png`, buf);
		await page.waitForTimeout(gapMs);
	}
	console.log(`saved ${count} frames to ${prefix}-NN.png`);
} catch (e) {
	console.error(`capture failed: ${e.message}`);
} finally {
	await browser.close();
	server.close();
}
