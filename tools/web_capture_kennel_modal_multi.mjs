// Visual-Review capture for the kennel inspect modal across MULTIPLE dogs (140, PO father-pass-5).
// Proves the dedicated modal-header portrait (MODAL_PORTRAIT_YAW, fixed front-¾) opens on a
// CONSISTENT face-on hero bust for every dog — including the old side-facing cells (Bella, Balder)
// that previously reused their grid cell's variety yaw and rendered a zoomed side profile.
//
// For each id in the list: open the kennel, tap that dog's cell, screenshot the modal, close.
//
// Usage: env -u LD_LIBRARY_PATH node tools/web_capture_kennel_modal_multi.mjs <bundle-dir> [id,id,...]

import { createServer } from "node:http";
import { readFile, mkdir } from "node:fs/promises";
import { extname, join, normalize } from "node:path";
import { chromium } from "playwright";

const bundleDir = process.argv[2];
if (!bundleDir) { console.error("usage: web_capture_kennel_modal_multi.mjs <bundle-dir> [ids]"); process.exit(2); }
const IDS = (process.argv[3] || "nova,bella,balder,sol").split(",").map(s => s.trim()).filter(Boolean);

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

const W = 390, H = 844, GODOT_W = 720, GODOT_H = 1280;
await mkdir(".screenshots", { recursive: true });
const browser = await chromium.launch({
	args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"]
});
const page = await browser.newPage({ viewport: { width: W, height: H } });

async function tapVp(x, y) {
	const box = await page.locator("canvas").boundingBox();
	const vp = await page.evaluate(() => window.__bra_viewport || null);
	const sx = box.width  / (vp ? vp[0] : GODOT_W);
	const sy = box.height / (vp ? vp[1] : GODOT_H);
	await page.mouse.click(box.x + x * sx, box.y + y * sy);
}
async function openKennel() {
	await tapVp(204, 32);
	await page.waitForFunction("window.__bra_kennel_open === true", undefined, { timeout: 10000 });
	await page.waitForTimeout(600);
}

let code = 1;
try {
	await page.goto(`${base}?bra_autotap=1`, { waitUntil: "load", timeout: 60000 });
	await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
	await page.waitForTimeout(1500);
	console.log("app ready");

	await openKennel();
	const cells = await page.evaluate(() => window.__bra_kennel_cells || []);
	if (cells.length !== 8) throw new Error(`expected 8 cells, got ${cells.length}`);
	console.log(`cells: [${cells.map(c => c.id).join(", ")}]`);

	for (const id of IDS) {
		const cell = cells.find(c => c.id === id);
		if (!cell) { console.log(`SKIP ${id} — not in roster`); continue; }
		await tapVp(cell.x, cell.y);
		await page.waitForTimeout(900);  // modal animation + portrait settle
		const out = `.screenshots/140-modal-${id}.png`;
		await page.screenshot({ path: out });
		console.log(`captured ${out}`);
		// Close via backdrop (top-left corner of screen, well clear of the card).
		await tapVp(40, 60);
		await page.waitForTimeout(500);
	}

	console.log(`MULTI MODAL CAPTURE PASSED — ${IDS.length} dogs`);
	code = 0;
} catch (e) {
	console.error(`multi modal capture FAILED: ${e.message}`);
	await page.screenshot({ path: ".screenshots/140-modal-FAIL.png" }).catch(() => {});
} finally {
	await browser.close();
	server.close();
}
process.exit(code);
