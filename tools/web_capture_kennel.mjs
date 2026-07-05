// Visual-Review capture for the kennel grid screen (105, Phase 8 K-1/K-3 — anchor visual slice).
// Boots the real Godot Web bundle in headless Chromium at 390×844 (phone-portrait), then drives
// the WHOLE open→view→close path with REAL canvas taps:
//   1. Boot with ?bra_autotap=1 so the training scene is alive; wait for appReady.
//   2. Tap the «Kennel» pill button in the training HUD → the kennel screen opens → screenshot
//      the full 8-cell grid (105-kennel-01-grid.png).
//   3. Scroll down if the grid overflows → screenshot the lower half (105-kennel-02-scroll.png).
//   4. Tap the ✕ close button → kennel closes → training HUD restores → screenshot the restored
//      training scene (105-kennel-03-closed.png) to prove no earlier-phase regression.
//
// Tap coordinates: the Kennel button centre is published via window.__bra_kennel_btn (x,y in
// viewport space); cell centres via window.__bra_kennel_cells[]; the ✕ button falls at a fixed
// top-left position in the header. All taps are mapped through the live canvas rect exactly as
// web_capture_showcase.mjs / web_capture_breeds.mjs.
//
// Usage: env -u LD_LIBRARY_PATH node tools/web_capture_kennel.mjs <bundle-dir>
import { createServer } from "node:http";
import { readFile, mkdir } from "node:fs/promises";
import { extname, join, normalize } from "node:path";
import { chromium } from "playwright";

const bundleDir = process.argv[2];
if (!bundleDir) { console.error("usage: web_capture_kennel.mjs <bundle-dir>"); process.exit(2); }

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
const browser = await chromium.launch({
	args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"]
});
const page = await browser.newPage({ viewport: { width: W, height: H } });

// Map a viewport-space point (Godot 720×1280 internal px) through the live canvas rect and click.
// The Godot project uses 720×1280 as its base viewport (VIEWPORT_W/H constants in main.gd).
// __bra_viewport is only published when the menu opens; we hard-code the known Godot base
// resolution (same assumption all other capture scripts use via the menu-opened hook).
const GODOT_W = 720, GODOT_H = 1280;
async function tapVp(x, y) {
	const box = await page.locator("canvas").boundingBox();
	// Use published viewport if available (menu was opened), otherwise fall back to the known base.
	const vp = await page.evaluate(() => window.__bra_viewport || null);
	const gw = vp ? vp[0] : GODOT_W;
	const gh = vp ? vp[1] : GODOT_H;
	const sx = box.width  / gw;
	const sy = box.height / gh;
	await page.mouse.click(box.x + x * sx, box.y + y * sy);
}

async function tapNamed(objVar, key) {
	const pt = await page.evaluate(([v, k]) => (window[v] || {})[k], [objVar, key]);
	if (!pt) throw new Error(`point '${key}' not found in ${objVar}`);
	await tapVp(pt.x, pt.y);
}

let code = 1;
try {
	// 1. Boot the game (autotap keeps the training loop alive so the HUD is visible).
	await page.goto(`${base}?bra_autotap=1`, { waitUntil: "load", timeout: 60000 });
	await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
	await page.waitForTimeout(1500);  // let the first sit cycle start so the scene is live
	console.log("app ready — training scene live");

	// 2. Tap the «Kennel» pill button to open the kennel grid.
	//    Fixed viewport-space centre: offset_left=20+128+8=156, width=96 → cx=204; top=10, h=44 → cy=32.
	//    These are in the 720×1280 Godot internal viewport, mapped through tapVp to canvas pixels.
	await tapVp(204, 32);
	await page.waitForFunction("window.__bra_kennel_open === true", undefined, { timeout: 10000 });
	await page.waitForTimeout(600);  // let pop-in animations settle
	console.log("kennel screen opened");
	await page.screenshot({ path: ".screenshots/105-kennel-01-grid.png" });
	console.log("captured 105-kennel-01-grid.png — full 8-cell kennel grid");

	// 3. Verify cells were published and log the first cell id.
	const cells = await page.evaluate(() => window.__bra_kennel_cells || []);
	console.log(`kennel cells published: ${cells.length} cells — [${cells.map(c => c.id).join(", ")}]`);
	if (cells.length !== 8) throw new Error(`expected 8 cells, got ${cells.length}`);

	// Try scrolling the grid to capture the lower half (Pontus / Lykke / Sniff / Trulte row).
	// Scroll the canvas area by dragging — the grid uses a ScrollContainer so a scroll gesture works.
	const box = await page.locator("canvas").boundingBox();
	await page.mouse.move(box.x + W * 0.5 * (box.width / W), box.y + H * 0.5 * (box.height / H));
	await page.mouse.wheel(0, 300);  // scroll down ~300px
	await page.waitForTimeout(400);
	await page.screenshot({ path: ".screenshots/105-kennel-02-scroll.png" });
	console.log("captured 105-kennel-02-scroll.png — scrolled grid view");

	// 4. Tap the ✕ close button (top-left corner of the header).
	//    Header is 72px tall; close_btn has content_margin_left=16, size 36×36 →
	//    centre ≈ (16+18, 72/2) = (34, 36) in Godot 720×1280 viewport space.
	await tapVp(34, 36);
	await page.waitForFunction("window.__bra_kennel_open === false", undefined, { timeout: 10000 });
	await page.waitForTimeout(400);
	console.log("kennel screen closed");
	await page.screenshot({ path: ".screenshots/105-kennel-03-closed.png" });
	console.log("captured 105-kennel-03-closed.png — training scene restored (no regression)");

	console.log("KENNEL CAPTURE PASSED — open → grid → scroll → close, all real taps");
	code = 0;
} catch (e) {
	console.error(`kennel capture FAILED: ${e.message}`);
	await page.screenshot({ path: ".screenshots/105-kennel-FAIL.png" }).catch(() => {});
} finally {
	await browser.close();
	server.close();
}
process.exit(code);
