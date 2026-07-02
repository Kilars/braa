// Visual-Review + e2e proof for the collect-and-train loop (079, PO 2026-07-02 Change 3 / P3-1·D3·P3-4).
// Boots the real Godot Web bundle in headless Chromium at 390×844 with ?bra_autotap=1 (each sit
// auto-scores PERFECT), then drives the WHOLE loop with REAL canvas taps (no faked state):
//   1. master Sitt (10 coins) → the completion menu pops → screenshot the Breeds section: the chocolate
//      Lab reads a clear priced LOCKED state (10 < 30) beside its honest coat swatch;
//   2. master Ligg + Legg deg too (→ 30 coins) so the chocolate row flips to Adopt;
//   3. a real tap on the chocolate row ADOPTS it (spends 30 → balance 0, __bra_owned gains it);
//   4. a real tap on the now-Owned chocolate row SWITCHES the active breed → the menu closes → the dog
//      re-tints to the chocolate coat on the running stage;
//   5. RELOAD the same page (same-origin IndexedDB) → the roster + active breed persist → the returning
//      player boots straight into the chocolate Lab.
// Taps land on published viewport-space row centres (window.__bra_trick_rows / __bra_breed_rows +
// __bra_viewport) mapped through the live canvas rect — robust to the taller (breeds-section) panel,
// the same honest real-tap proof the 072 menu capture pioneered. Requires the licensed Sitt-capable
// bundle (local build/web bundles it). Usage: env -u LD_LIBRARY_PATH node tools/web_capture_breeds.mjs <bundle-dir>
import { createServer } from "node:http";
import { readFile, mkdir } from "node:fs/promises";
import { extname, join, normalize } from "node:path";
import { chromium } from "playwright";

const bundleDir = process.argv[2];
if (!bundleDir) { console.error("usage: web_capture_breeds.mjs <bundle-dir>"); process.exit(2); }

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
const CHOC = "chocolate_labrador";

await mkdir(".screenshots", { recursive: true });
const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport: { width: W, height: H } });

// Land a REAL canvas tap on the row `id` of the published rows-array `rowsVar`, mapping the row's
// viewport-space centre through the live canvas rect to a CSS pixel. Honest tap: it enters the engine
// through _gui_input exactly like a finger, not a state poke.
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
	const cx = box.x + info.x * sx, cy = box.y + info.y * sy;
	await page.mouse.click(cx, cy);
}

const state = async () => page.evaluate(() => ({
	owned: window.__bra_owned, active: window.__bra_active_breed,
	balance: window.__bra_balance, menu: window.__bra_menu_open, trick: window.__bra_current_trick,
}));

let code = 1;
try {
	await page.goto(`${base}?bra_autotap=1`, { waitUntil: "load", timeout: 60000 });
	await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });

	// 1. Autotap masters the active trick (Sitt) → the completion menu pops with 10 coins.
	await page.waitForFunction("window.__bra_menu_open === true", undefined, { timeout: 150000 });
	await page.waitForTimeout(400);
	let s = await state();
	console.log("after Sitt mastery:", JSON.stringify(s));
	if (!(s.owned?.length === 1 && s.owned[0] === "labrador")) throw new Error(`fresh player must own only the Labrador, got ${JSON.stringify(s.owned)}`);
	if (s.active !== "labrador") throw new Error(`fresh active breed must be the Labrador, got '${s.active}'`);
	if (s.balance < 10) throw new Error(`mastering Sitt must earn coins, balance=${s.balance}`);
	await page.screenshot({ path: ".screenshots/079-01-breeds-locked.png" });
	console.log("captured 079-01-breeds-locked.png — chocolate priced+locked at 10 coins");

	// 2. Master Ligg + Legg deg too → 30 coins, so the chocolate row becomes Adopt-able.
	for (const t of ["ligg", "legg_deg"]) {
		await tapRowById("__bra_trick_rows", t);                       // switch to the next trick → menu closes, offers resume
		await page.waitForFunction(`window.__bra_current_trick === '${t}'`, undefined, { timeout: 10000 });
		await page.waitForFunction("window.__bra_menu_open === true", undefined, { timeout: 150000 });  // autotap masters it → menu pops
		await page.waitForTimeout(300);
		console.log(`after ${t} mastery:`, JSON.stringify(await state()));
	}
	s = await state();
	if (s.balance < 30) throw new Error(`three masteries must fund the adopt, balance=${s.balance}`);
	await page.screenshot({ path: ".screenshots/079-02-breeds-buyable.png" });
	console.log(`captured 079-02-breeds-buyable.png — chocolate adopt-able at ${s.balance} coins`);

	// 3. A real tap on the chocolate row ADOPTS it (spends 30 → 0; owned gains it). Menu stays open.
	await tapRowById("__bra_breed_rows", CHOC);
	await page.waitForFunction(`(window.__bra_owned || []).includes('${CHOC}')`, undefined, { timeout: 10000 });
	s = await state();
	console.log("after adopt:", JSON.stringify(s));
	if (!s.owned.includes(CHOC)) throw new Error("adopt must add the chocolate Lab to the roster");
	if (s.active !== "labrador") throw new Error("adopt alone must NOT switch the active breed");
	await page.waitForTimeout(300);
	await page.screenshot({ path: ".screenshots/079-03-adopted.png" });
	console.log(`captured 079-03-adopted.png — chocolate owned, balance now ${s.balance}`);

	// 4. A real tap on the now-Owned chocolate row SWITCHES the active breed → menu closes → coat re-tints.
	await tapRowById("__bra_breed_rows", CHOC);
	await page.waitForFunction(`window.__bra_active_breed === '${CHOC}'`, undefined, { timeout: 10000 });
	await page.waitForFunction("window.__bra_menu_open === false", undefined, { timeout: 10000 });
	await page.waitForTimeout(600);
	s = await state();
	console.log("after switch:", JSON.stringify(s));
	if (s.active !== CHOC) throw new Error("switch must make the chocolate Lab active");
	await page.screenshot({ path: ".screenshots/079-04-switched-coat.png" });
	console.log("captured 079-04-switched-coat.png — running dog switched to the chocolate coat");

	// 5. RELOAD the same page (same-origin IndexedDB) → the roster + active breed persist.
	await page.goto(base, { waitUntil: "load", timeout: 60000 });
	await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
	await page.waitForFunction(`window.__bra_active_breed === '${CHOC}'`, undefined, { timeout: 15000 });
	s = await state();
	console.log("after reload:", JSON.stringify(s));
	if (!s.owned.includes(CHOC)) throw new Error("the adopted roster must survive a reload");
	if (s.active !== CHOC) throw new Error("the active breed must survive a reload");
	await page.waitForTimeout(500);
	await page.screenshot({ path: ".screenshots/079-05-reload-persist.png" });
	console.log("captured 079-05-reload-persist.png — returning player boots into the chocolate Lab");

	console.log("BREEDS LOOP PASSED — adopt(spend) → switch(coat change) → reload(persist), all via real taps");
	code = 0;
} catch (e) {
	console.error(`breeds capture FAILED: ${e.message}`);
	await page.screenshot({ path: ".screenshots/079-FAIL.png" }).catch(() => {});
} finally {
	await browser.close();
	server.close();
}
process.exit(code);
