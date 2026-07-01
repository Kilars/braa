// Prove the trick selector actually switches the trained trick on a REAL canvas tap (066, P2-1).
// The scene-level test proves select_trick's routing and the unit test proves _gui_input emits, but
// the crux of the selector is that a live browser tap on a chip reaches _gui_input at all. This boots
// the real Godot Web bundle in headless Chromium, reads the web-only hook window.__bra_current_trick
// (main sets it from select_trick), clicks the canvas at a chip's centre, and asserts the trick flips.
// Usage: env -u LD_LIBRARY_PATH node tools/web_selector_switch.mjs <bundle-dir>
import { createServer } from "node:http";
import { readFile } from "node:fs/promises";
import { extname, join, normalize } from "node:path";
import { chromium } from "playwright";

const bundleDir = process.argv[2];
if (!bundleDir) { console.error("usage: web_selector_switch.mjs <bundle-dir>"); process.exit(2); }

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
const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport: { width: W, height: H } });
let code = 1;
try {
	await page.goto(`http://127.0.0.1:${port}/index.html`, { waitUntil: "load", timeout: 60000 });
	await page.waitForFunction("window.__appReady === true", { timeout: 120000 });
	await page.waitForTimeout(1500);
	const before = await page.evaluate("window.__bra_current_trick");
	if (before !== "sitt") throw new Error(`expected the initial trick to be 'sitt', got '${before}'`);
	// The selector spans the top HUD band across the full width (SELECTOR_MARGIN_X inset both sides);
	// three equal chips → the MIDDLE chip is Ligg. Click its centre: x = mid-width, y = the chip band.
	await page.mouse.click(W * 0.5, 30);
	await page.waitForFunction("window.__bra_current_trick === 'ligg'", { timeout: 5000 });
	const after = await page.evaluate("window.__bra_current_trick");
	console.log(`selector switch PASSED — a real chip tap flipped the trained trick '${before}' → '${after}'`);
	code = 0;
} catch (e) {
	console.error(`selector switch FAILED: ${e.message}`);
} finally {
	await browser.close();
	server.close();
}
process.exit(code);
