// Visual-Review + e2e proof for the completion menu (072, PO note 1). Boots the real Godot Web bundle
// in headless Chromium at 390×844 with ?bra_autotap=1 (each sit auto-scores PERFECT), waits for the
// active trick (Sitt) to MASTER — which pops the completion menu (window.__bra_menu_open) — screenshots
// it, then taps the Available "Ligg" row and asserts a real canvas tap switches the trained trick
// (window.__bra_current_trick flips sitt→ligg) and the menu closes (offers resume). Two screenshots
// land under .screenshots/072-*. Requires the licensed Sitt-capable bundle (local build/web bundles it).
// Usage: env -u LD_LIBRARY_PATH node tools/web_capture_menu.mjs <bundle-dir>
import { createServer } from "node:http";
import { readFile, mkdir } from "node:fs/promises";
import { extname, join, normalize } from "node:path";
import { chromium } from "playwright";

const bundleDir = process.argv[2];
if (!bundleDir) { console.error("usage: web_capture_menu.mjs <bundle-dir>"); process.exit(2); }

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
// The completion menu is centred; the Godot canvas renders at a larger internal resolution and is
// CSS-scaled down to the 390×844 viewport, so a Godot-unit row rect is NOT a screenshot pixel. These
// are the Available "Ligg" row's centre measured in SCREENSHOT (== Playwright CSS) pixels on the
// licensed bundle: panel centred at x≈195, and the six rows land at y≈337 (Sitt/Learned), 370 (Ligg/
// Available), 408 (Legg deg/Available), then the three Locked roadmap rows below. Tapping Ligg proves
// a real canvas tap on an Available row switches the trained trick.
const liggX = 195, liggY = 370;

await mkdir(".screenshots", { recursive: true });
const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport: { width: W, height: H } });
let code = 1;
try {
	await page.goto(`http://127.0.0.1:${port}/index.html?bra_autotap=1`, { waitUntil: "load", timeout: 60000 });
	await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
	// Autotap scores a PERFECT each sit; 5 fill the bar → Sitt masters → the completion menu pops.
	// (timeout goes in the 3rd arg — the 2nd is the pageFunction's argument in Playwright.)
	await page.waitForFunction("window.__bra_menu_open === true", undefined, { timeout: 120000 });
	await page.waitForTimeout(400);  // let the modal settle for a clean frame
	const active = await page.evaluate("window.__bra_current_trick");
	if (active !== "sitt") throw new Error(`expected the mastered active trick to be 'sitt', got '${active}'`);
	await page.screenshot({ path: ".screenshots/072-menu-open.png" });
	console.log(`menu popped on mastering '${active}' — captured 072-menu-open.png`);
	// A real canvas tap on the Available Ligg row must switch the trained trick and close the menu.
	await page.mouse.click(liggX, liggY);
	await page.waitForFunction("window.__bra_current_trick === 'ligg'", undefined, { timeout: 8000 });
	await page.waitForFunction("window.__bra_menu_open === false", undefined, { timeout: 8000 });
	await page.waitForTimeout(300);
	await page.screenshot({ path: ".screenshots/072-after-switch.png" });
	console.log("menu tap PASSED — a real tap on the Available Ligg row switched sitt→ligg and closed the menu (offers resume); captured 072-after-switch.png");
	code = 0;
} catch (e) {
	console.error(`menu capture FAILED: ${e.message}`);
	await page.screenshot({ path: ".screenshots/072-FAIL.png" }).catch(() => {});
} finally {
	await browser.close();
	server.close();
}
process.exit(code);
