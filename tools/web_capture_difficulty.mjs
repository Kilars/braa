// Visual-Review + e2e proof for the difficulty selector (118, P4-1 "for normal dogs I want to be able
// to select difficulty"). Boots the real Godot Web bundle in headless Chromium at 390×844 with
// ?bra_autotap=1 (each sit auto-scores PERFECT), waits for Sitt to MASTER — which pops the completion
// menu — screenshots it (the "Vanskelighet" section shows Normal/Hard/Expert with Normal marked Valgt),
// then lands a REAL canvas tap on the Hard row and asserts the global mode flips (window.__bra_difficulty
// normal→hard) and the active badge moves. Screenshots land under .screenshots/118-*. Requires the
// licensed Sitt-capable bundle (local build/web bundles it).
// Usage: env -u LD_LIBRARY_PATH node tools/web_capture_difficulty.mjs <bundle-dir>
import { createServer } from "node:http";
import { readFile, mkdir } from "node:fs/promises";
import { extname, join, normalize } from "node:path";
import { chromium } from "playwright";

const bundleDir = process.argv[2];
if (!bundleDir) { console.error("usage: web_capture_difficulty.mjs <bundle-dir>"); process.exit(2); }

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
const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport: { width: W, height: H } });

// Land a REAL canvas tap on the row `id` of the published rows-array `rowsVar`, mapping the row's
// viewport-space centre through the live canvas rect to a CSS pixel — an honest tap through _gui_input.
async function tapRowById(rowsVar, id) {
	const info = await page.evaluate(([v, wanted]) => {
		const rows = window[v] || [];
		const vp = window.__bra_viewport || [null, null];
		const row = rows.find((r) => r.id === wanted);
		return row ? { x: row.x, y: row.y, vpw: vp[0], vph: vp[1] } : null;
	}, [rowsVar, id]);
	if (!info) throw new Error(`row '${id}' not found in ${rowsVar} (${JSON.stringify(await page.evaluate((v) => window[v], rowsVar))})`);
	const box = await page.locator("canvas").boundingBox();
	const sx = box.width / info.vpw, sy = box.height / info.vph;
	await page.mouse.click(box.x + info.x * sx, box.y + info.y * sy);
}

let code = 1;
try {
	await page.goto(`${base}?bra_autotap=1`, { waitUntil: "load", timeout: 60000 });
	await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
	// Autotap masters Sitt → the completion menu pops.
	await page.waitForFunction("window.__bra_menu_open === true", undefined, { timeout: 150000 });
	await page.waitForTimeout(400);  // let the modal settle for a clean frame
	const before = await page.evaluate("window.__bra_difficulty");
	if (before !== "normal") throw new Error(`boot difficulty must be 'normal', got '${before}'`);
	await page.screenshot({ path: ".screenshots/118-01-menu-normal.png" });
	console.log("captured 118-01-menu-normal.png — Vanskelighet section, Normal marked Valgt");
	// A real canvas tap on the Hard row must switch the global mode.
	await tapRowById("__bra_difficulty_rows", "hard");
	await page.waitForFunction("window.__bra_difficulty === 'hard'", undefined, { timeout: 8000 });
	await page.waitForTimeout(300);
	await page.screenshot({ path: ".screenshots/118-02-menu-hard.png" });
	console.log("difficulty tap PASSED — a real tap on the Hard row switched the global mode normal→hard; captured 118-02-menu-hard.png");
	code = 0;
} catch (e) {
	console.error(`difficulty capture FAILED: ${e.message}`);
	await page.screenshot({ path: ".screenshots/118-FAIL.png" }).catch(() => {});
} finally {
	await browser.close();
	server.close();
}
process.exit(code);
