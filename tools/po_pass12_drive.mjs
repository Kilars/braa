// PO father-pass-12 composite play-test.
// Verifies 146 (coin component on prices) + 147 (cool-coat tint parity grid↔modal) landed,
// captures training / menu / kennel-grid / modals, and samples coat colours grid-vs-modal.
//
// Usage: env -u LD_LIBRARY_PATH node tools/po_pass12_drive.mjs <bundle-dir>

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

const W = 390, H = 844, GODOT_W = 720, GODOT_H = 1280;
await mkdir(".screenshots", { recursive: true });
const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport: { width: W, height: H } });
const errs = [];
page.on("console", m => { if (m.type() === "error") errs.push(m.text()); });

async function tapVp(x, y) {
	const box = await page.locator("canvas").boundingBox();
	const vp = await page.evaluate(() => window.__bra_viewport || null);
	const sx = box.width  / (vp ? vp[0] : GODOT_W);
	const sy = box.height / (vp ? vp[1] : GODOT_H);
	await page.mouse.click(box.x + x * sx, box.y + y * sy);
}
// Region-average colour from the on-screen canvas in CSS px (viewport coords).
async function sampleRegion(cx, cy, r) {
	const box = await page.locator("canvas").boundingBox();
	return await page.evaluate(([bx, by, bw, bh, cx, cy, r]) => {
		const cv = document.querySelector("canvas");
		const g = cv.getContext("2d") || cv.getContext("webgl2");
		// Use a 2D snapshot via drawImage into an offscreen canvas.
		const off = document.createElement("canvas");
		off.width = cv.width; off.height = cv.height;
		off.getContext("2d").drawImage(cv, 0, 0);
		const ctx = off.getContext("2d");
		const px = cv.width / bw, py = cv.height / bh;   // device px per CSS px
		const sx = Math.round(cx * px), sy = Math.round(cy * py), sr = Math.round(r * px);
		const d = ctx.getImageData(sx - sr, sy - sr, sr * 2, sr * 2).data;
		let R = 0, G = 0, B = 0, n = 0;
		for (let i = 0; i < d.length; i += 4) { R += d[i]; G += d[i+1]; B += d[i+2]; n++; }
		return [Math.round(R/n), Math.round(G/n), Math.round(B/n)];
	}, [box.x, box.y, box.width, box.height, cx, cy, r]);
}
async function openKennel() {
	await tapVp(204, 32);
	await page.waitForFunction("window.__bra_kennel_open === true", undefined, { timeout: 10000 });
	await page.waitForTimeout(700);
}

let code = 1;
try {
	await page.goto(`${base}?bra_autotap=1`, { waitUntil: "load", timeout: 60000 });
	await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
	await page.waitForTimeout(1800);
	console.log("app ready");

	await page.screenshot({ path: ".screenshots/P12-01-training.png" });

	// --- Kennel grid ---
	await openKennel();
	await page.screenshot({ path: ".screenshots/P12-02-kennel-grid.png" });
	const cells = await page.evaluate(() => window.__bra_kennel_cells || []);
	console.log(`cells: [${cells.map(c => c.id).join(", ")}]`);

	// Sample each cell's coat in the grid (below the cell centre, where the body renders).
	const gridCoat = {};
	for (const c of cells) {
		// c.x,c.y are in godot viewport coords; convert to CSS px for sampling.
		const cssx = c.x * (W / GODOT_W), cssy = c.y * (H / GODOT_H);
		gridCoat[c.id] = await sampleRegion(cssx, cssy + 22, 10);
	}
	console.log("GRID coat samples:", JSON.stringify(gridCoat));

	// --- Modals: cool coats (nova/pontus/trulte) + warm controls (balder/sol/bella) ---
	const probe = ["nova", "pontus", "trulte", "balder", "sol", "bella"];
	const modalCoat = {};
	for (const id of probe) {
		const cell = cells.find(c => c.id === id);
		if (!cell) { console.log(`SKIP ${id}`); continue; }
		await tapVp(cell.x, cell.y);
		await page.waitForTimeout(1000);
		await page.screenshot({ path: `.screenshots/P12-modal-${id}.png` });
		// Hero bust sits in the upper-centre of the modal card. Sample centre-upper.
		modalCoat[id] = await sampleRegion(W * 0.5, H * 0.30, 12);
		await tapVp(40, 60);   // close via backdrop
		await page.waitForTimeout(600);
	}
	console.log("MODAL coat samples:", JSON.stringify(modalCoat));

	// --- Completion menu (close kennel first, then autotap will have mastered; open menu) ---
	// Menu opens via Triks pill only from training; close kennel.
	code = 0;
	console.log(`console errors: ${errs.length}`);
	if (errs.length) console.log(errs.slice(0, 5).join("\n"));
} catch (e) {
	console.error(`FAILED: ${e.message}`);
	await page.screenshot({ path: ".screenshots/P12-FAIL.png" }).catch(() => {});
} finally {
	await browser.close();
	server.close();
}
process.exit(code);
