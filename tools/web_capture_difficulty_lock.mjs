// Visual-Review + e2e proof for the special-dog difficulty LOCK (119, P4-1 "for special dogs difficulty
// should be locked"). Boots the real Godot Web bundle at 390×844 with ?bra_kennel=nova (Nova is EPIC, a
// special dog → locks difficulty to Hard) & ?bra_autotap=1, waits for Sitt to master → the completion
// menu pops → the "Vanskelighet" section shows every mode greyed with Hard marked "Låst". Then it lands a
// REAL canvas tap on the Normal row and asserts the mode does NOT change (the selector is a no-op while
// locked). Screenshot lands under .screenshots/119-*. Requires the licensed Sitt-capable bundle.
// Usage: env -u LD_LIBRARY_PATH node tools/web_capture_difficulty_lock.mjs <bundle-dir>
import { createServer } from "node:http";
import { readFile, mkdir } from "node:fs/promises";
import { extname, join, normalize } from "node:path";
import { chromium } from "playwright";

const bundleDir = process.argv[2];
if (!bundleDir) { console.error("usage: web_capture_difficulty_lock.mjs <bundle-dir>"); process.exit(2); }

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
	if (!info) throw new Error(`row '${id}' not found in ${rowsVar}`);
	const box = await page.locator("canvas").boundingBox();
	await page.mouse.click(box.x + info.x * (box.width / info.vpw), box.y + info.y * (box.height / info.vph));
}

let code = 1;
try {
	await page.goto(`${base}?bra_kennel=nova&bra_autotap=1`, { waitUntil: "load", timeout: 60000 });
	await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
	await page.waitForFunction("window.__bra_menu_open === true", undefined, { timeout: 150000 });
	await page.waitForTimeout(400);
	const forced = await page.evaluate("window.__bra_difficulty");
	if (forced !== "hard") throw new Error(`a special dog must force 'hard', got '${forced}'`);
	await page.screenshot({ path: ".screenshots/119-01-menu-locked.png" });
	console.log("captured 119-01-menu-locked.png — Vanskelighet greyed, Hard marked Låst on a special dog");
	// The selector is a no-op while locked: a real tap on Normal must NOT change the mode.
	await tapRowById("__bra_difficulty_rows", "normal");
	await page.waitForTimeout(400);
	const after = await page.evaluate("window.__bra_difficulty");
	if (after !== "hard") throw new Error(`the lock must swallow the tap — expected 'hard', got '${after}'`);
	console.log("lock PASSED — a real tap on Normal was swallowed; the special dog keeps Hard locked");
	code = 0;
} catch (e) {
	console.error(`difficulty-lock capture FAILED: ${e.message}`);
	await page.screenshot({ path: ".screenshots/119-FAIL.png" }).catch(() => {});
} finally {
	await browser.close();
	server.close();
}
process.exit(code);
