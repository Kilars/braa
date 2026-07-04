// Visual Review for 098 (Phase 6 — restyle the completion menu to the Design System).
// Boots the real Godot Web bundle in headless Chromium at 390×844 with ?bra_autotap=1,
// grabs the light DS training page first (098-training.png), then waits for Sitt to master
// (which pops the completion menu, window.__bra_menu_open) and screenshots the modal
// (098-menu.png). The two frames prove the menu now coheres with the restyled training page
// (light PAPER card, SLATE/BLUE, DS fonts) instead of the retired dark-navy/gold modal.
// Usage: env -u LD_LIBRARY_PATH node tools/web_capture_menu098.mjs <bundle-dir>
import { createServer } from "node:http";
import { readFile, mkdir } from "node:fs/promises";
import { extname, join, normalize } from "node:path";
import { chromium } from "playwright";

const bundleDir = process.argv[2];
if (!bundleDir) { console.error("usage: web_capture_menu098.mjs <bundle-dir>"); process.exit(2); }

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
let code = 1;
try {
	await page.goto(`http://127.0.0.1:${port}/index.html?bra_autotap=1`, { waitUntil: "load", timeout: 60000 });
	await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
	await page.waitForTimeout(1200);  // let the training page settle for the cohesion frame
	await page.screenshot({ path: ".screenshots/098-training.png" });
	console.log("captured 098-training.png (the light DS training page)");
	// Autotap scores a PERFECT each sit; 5 fill the bar → Sitt masters → the completion menu pops.
	await page.waitForFunction("window.__bra_menu_open === true", undefined, { timeout: 120000 });
	await page.waitForTimeout(500);  // let the modal settle for a clean frame
	await page.screenshot({ path: ".screenshots/098-menu.png" });
	console.log("captured 098-menu.png (the completion menu — should be a light DS PAPER card)");
	code = 0;
} catch (e) {
	console.error(`098 capture FAILED: ${e.message}`);
	await page.screenshot({ path: ".screenshots/098-FAIL.png" }).catch(() => {});
} finally {
	await browser.close();
	server.close();
}
process.exit(code);
