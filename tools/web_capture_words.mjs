// Visual-Review + e2e proof for the marker-word load/swap loop (092, P5-4).
// Boots the real Godot Web bundle in headless Chromium at 390×844 with ?bra_autotap=1 (each sit
// auto-scores PERFECT), then:
//   1. autotap masters Sitt → the completion menu pops → mastering 1 trick unlocks the first marker
//      word "dyktig" (091). Screenshot the menu: the "Marker words" section shows bra ACTIVE, dyktig
//      UNLOCKED (tappable), flink/super/kjempebra LOCKED (honest grey).
//   2. a REAL canvas tap on the dyktig word row LOADS it → __bra_active_word flips bra → dyktig, the
//      menu stays open, the row highlight moves. Screenshot again.
//   3. assert the active word actually swapped (P5-4 "load/swap outside the tap", no in-round button).
// Taps land on published viewport-space row centres (window.__bra_word_rows + __bra_viewport) mapped
// through the live canvas rect — the same honest-tap proof the 072/079 captures pioneered.
// Usage: env -u LD_LIBRARY_PATH node tools/web_capture_words.mjs <bundle-dir>
import { createServer } from "node:http";
import { readFile, mkdir } from "node:fs/promises";
import { extname, join, normalize } from "node:path";
import { chromium } from "playwright";

const bundleDir = process.argv[2];
if (!bundleDir) { console.error("usage: web_capture_words.mjs <bundle-dir>"); process.exit(2); }

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

const state = async () => page.evaluate(() => ({
	activeWord: window.__bra_active_word, words: window.__bra_word_rows,
	menu: window.__bra_menu_open, trick: window.__bra_current_trick,
}));

let code = 1;
try {
	await page.goto(`${base}?bra_autotap=1`, { waitUntil: "load", timeout: 60000 });
	await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });

	// 1. Autotap masters Sitt → menu pops → dyktig unlocks (1 mastered trick).
	await page.waitForFunction("window.__bra_menu_open === true", undefined, { timeout: 150000 });
	await page.waitForTimeout(500);
	let s = await state();
	console.log("after Sitt mastery:", JSON.stringify(s));
	if (s.activeWord !== "bra") throw new Error(`active word must default to 'bra', got '${s.activeWord}'`);
	const ids = (s.words || []).map((r) => r.id);
	if (!ids.includes("dyktig")) throw new Error(`mastering a trick must publish an unlocked 'dyktig' word row, rows=${JSON.stringify(ids)}`);
	await page.screenshot({ path: ".screenshots/092-01-words-section.png" });
	console.log("captured 092-01-words-section.png — Marker words section: bra ACTIVE, dyktig UNLOCKED, rest LOCKED");

	// 2. A REAL tap on the dyktig row LOADS it as the active word. Menu stays open.
	await tapRowById("__bra_word_rows", "dyktig");
	await page.waitForFunction("window.__bra_active_word === 'dyktig'", undefined, { timeout: 10000 });
	await page.waitForTimeout(400);
	s = await state();
	console.log("after loading dyktig:", JSON.stringify(s));
	if (s.activeWord !== "dyktig") throw new Error(`loading a word must swap the active word, got '${s.activeWord}'`);
	if (s.menu !== true) throw new Error("loading a word must keep the menu open (no close), P5-4");
	await page.screenshot({ path: ".screenshots/092-02-dyktig-loaded.png" });
	console.log("captured 092-02-dyktig-loaded.png — dyktig now ACTIVE, bra switchable");
	// (word-blob persistence across reload is covered by 091's TrickStore + MarkerWords round-trip unit tests.)

	console.log("MARKER-WORD LOAD/SWAP PASSED — unlock → load(real tap) → active swaps (P5-4)");
	code = 0;
} catch (e) {
	console.error(`words capture FAILED: ${e.message}`);
	await page.screenshot({ path: ".screenshots/092-FAIL.png" }).catch(() => {});
} finally {
	await browser.close();
	server.close();
}
process.exit(code);
