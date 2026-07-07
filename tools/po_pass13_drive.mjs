// PO father-pass-13 composite play-test.
// Verifies 148 (rarity ladder badges on all 8 kennel cells + modal echo) landed on the
// real deployed build, re-checks the signed-off surfaces (training / menu / kennel), and
// hunts for new polish defects.
//
// Usage: env -u LD_LIBRARY_PATH node tools/po_pass13_drive.mjs [baseUrl|bundle-dir]
//   default baseUrl = live Pages site.

import { createServer } from "node:http";
import { readFile, mkdir } from "node:fs/promises";
import { extname, join, normalize } from "node:path";
import { chromium } from "playwright";

const arg = process.argv[2] || "https://kilars.github.io/braa/";
const isUrl = arg.startsWith("http");
let base = arg;
let server = null;

if (!isUrl) {
	const bundleDir = arg;
	const MIME = { ".html": "text/html; charset=utf-8", ".js": "text/javascript; charset=utf-8",
		".wasm": "application/wasm", ".pck": "application/octet-stream", ".json": "application/json",
		".png": "image/png", ".svg": "image/svg+xml", ".ico": "image/x-icon" };
	server = createServer(async (req, res) => {
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
	base = `http://127.0.0.1:${server.address().port}/index.html`;
}

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
async function openKennel() {
	await tapVp(204, 32);
	await page.waitForFunction("window.__bra_kennel_open === true", undefined, { timeout: 12000 });
	await page.waitForTimeout(800);
}

let code = 1;
try {
	const url = base + (base.includes("?") ? "&" : "?") + "bra_autotap=1";
	await page.goto(url, { waitUntil: "load", timeout: 90000 });
	await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
	await page.waitForTimeout(2000);
	console.log("app ready");
	const boot = await page.evaluate(() => window.__bra_boot_log || null);
	if (boot) console.log("BOOT:", JSON.stringify(boot).slice(0, 300));

	await page.screenshot({ path: ".screenshots/P13-01-training.png" });

	// --- Kennel grid: rarity badges on ALL 8 cells ---
	await openKennel();
	await page.screenshot({ path: ".screenshots/P13-02-kennel-grid.png" });
	const cells = await page.evaluate(() => window.__bra_kennel_cells || []);
	console.log(`cells (${cells.length}): [${cells.map(c => c.id).join(", ")}]`);

	// --- Modals: rarity echo — one per tier ---
	const probe = ["nova", "balder", "sol", "pontus", "sniff", "bella", "trulte"];
	for (const id of probe) {
		const cell = cells.find(c => c.id === id);
		if (!cell) { console.log(`SKIP ${id}`); continue; }
		await tapVp(cell.x, cell.y);
		await page.waitForTimeout(1100);
		await page.screenshot({ path: `.screenshots/P13-modal-${id}.png` });
		await tapVp(40, 60);   // close via backdrop
		await page.waitForTimeout(700);
	}

	// --- Close kennel, back to training, open completion menu ---
	await tapVp(40, 60);
	await page.waitForTimeout(700);
	// Triks pill (top-left)
	await tapVp(70, 32);
	await page.waitForTimeout(1200);
	await page.screenshot({ path: ".screenshots/P13-05-menu.png" });

	code = 0;
	console.log(`console errors: ${errs.length}`);
	if (errs.length) console.log(errs.slice(0, 6).join("\n"));
} catch (e) {
	console.error(`FAILED: ${e.message}`);
	await page.screenshot({ path: ".screenshots/P13-FAIL.png" }).catch(() => {});
} finally {
	await browser.close();
	if (server) server.close();
	process.exit(code);
}
