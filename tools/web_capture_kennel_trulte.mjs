// Visual-Review capture for the K-6 free-adopt easter egg (111, Phase 8). REAL canvas taps:
//   1. Boot with NO coin grant (balance 0) — the free adopt must not need money.
//   2. Open the kennel, scroll to + tap Trulte's cell → the detail modal opens.
//   3. Assert the modal shows the coral «Adopter gratis ♥» button (id FreeAdoptButton) — screenshot
//      the coral ribbon above the stats + the coral free-adopt button.
//   4. Tap free-adopt → Trulte becomes owned at balance 0 (nothing spent); the modal re-renders to
//      the green «Tren med Trulte» switch button (110) — she's trainable like any other dog.
//
// Usage: env -u LD_LIBRARY_PATH node tools/web_capture_kennel_trulte.mjs <bundle-dir>

import { createServer } from "node:http";
import { readFile, mkdir } from "node:fs/promises";
import { extname, join, normalize } from "node:path";
import { chromium } from "playwright";

const bundleDir = process.argv[2];
if (!bundleDir) { console.error("usage: web_capture_kennel_trulte.mjs <bundle-dir>"); process.exit(2); }

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
const GODOT_W = 720, GODOT_H = 1280;

await mkdir(".screenshots", { recursive: true });
const browser = await chromium.launch({
	args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"]
});
const page = await browser.newPage({ viewport: { width: W, height: H } });

async function tapVp(x, y) {
	const box = await page.locator("canvas").boundingBox();
	const vp = await page.evaluate(() => window.__bra_viewport || null);
	const gw = vp ? vp[0] : GODOT_W;
	const gh = vp ? vp[1] : GODOT_H;
	await page.mouse.click(box.x + x * (box.width / gw), box.y + y * (box.height / gh));
}

async function bootReady(query) {
	await page.goto(`${base}${query}`, { waitUntil: "load", timeout: 60000 });
	await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
	await page.waitForTimeout(1500);
}

let code = 1;
try {
	// 1. Boot with NO coins — the free dog must be adoptable at balance 0.
	await bootReady("?bra_view=1");
	const bal0 = await page.evaluate(() => window.__bra_balance);
	console.log(`app ready — balance ${bal0} (free adopt must not need coins)`);

	// 2. Open the kennel, find Trulte's cell.
	await tapVp(204, 32);
	await page.waitForFunction("window.__bra_kennel_open === true", undefined, { timeout: 10000 });
	await page.waitForTimeout(800);
	const cells = await page.evaluate(() => window.__bra_kennel_cells || []);
	console.log(`cells: [${cells.map(c => c.id).join(", ")}]`);
	const trulte = cells.find(c => c.id === "trulte");
	if (!trulte) throw new Error("Trulte cell not found — she must be in the grid (106)");
	await tapVp(trulte.x, trulte.y);
	await page.waitForTimeout(900);
	await page.screenshot({ path: ".screenshots/111-01-modal-free.png" });

	// 3. The published action button must be the coral FreeAdoptButton.
	const action = await page.evaluate(() => window.__bra_kennel_action || null);
	console.log(`action button: ${JSON.stringify(action)}`);
	if (!action || action.id !== "FreeAdoptButton")
		throw new Error(`expected FreeAdoptButton, got ${JSON.stringify(action)}`);

	// 4. Tap free-adopt → owned at balance 0, modal flips to «Tren med Trulte».
	await tapVp(action.x, action.y);
	await page.waitForTimeout(1000);
	const balAfter = await page.evaluate(() => window.__bra_balance);
	const owned = await page.evaluate(() => window.__bra_kennel_owned || []);
	console.log(`after free adopt — balance ${balAfter}, owned: [${owned}]`);
	if (balAfter !== bal0) throw new Error(`free adopt spent coins: ${bal0} → ${balAfter}`);
	if (!owned.includes("trulte")) throw new Error(`Trulte not owned after free adopt: [${owned}]`);
	await page.waitForFunction("window.__bra_kennel_action && window.__bra_kennel_action.id === 'TrainWithButton'",
		undefined, { timeout: 8000 });
	await page.screenshot({ path: ".screenshots/111-02-owned-trenmed.png" });

	console.log("TRULTE FREE-ADOPT CAPTURE PASSED — coral «Adopter gratis ♥» → owned at balance 0 → «Tren med Trulte» (K-6)");
	code = 0;
} catch (e) {
	console.error(`trulte free-adopt capture FAILED: ${e.message}`);
	await page.screenshot({ path: ".screenshots/111-FAIL.png" }).catch(() => {});
} finally {
	await browser.close();
	server.close();
}
process.exit(code);
