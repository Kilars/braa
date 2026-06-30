// Pixel-proof the anti-mash BRA freeze (046, P2-7) on the REAL web build. Serves the Godot
// Web/PWA bundle, boots it in headless Chromium (SwiftShader GL == the deployed GL Compatibility
// renderer) at 390×844, then for each motion mode (normal + prefers-reduced-motion: reduce)
// captures two states of the BRA button:
//   armed  — loaded plain (full brightness, enabled)
//   locked — loaded with the web-only ?bra_force_lock=1 seam that PINS the locked look
// The real lock lasts only ~350 ms per tap, shorter than a headless screenshot's latency, so a
// non-deterministic burst can't reliably catch it — exactly why the seam exists (same pattern as
// ?bra_force_tell/_tier). The lock's behaviour/timing is proven in-engine by test_tap_gate_wiring;
// this proves the locked pixels are LEGIBLE. The dim reads off STATIC alpha (no animation), so the
// reduced-motion frames must match the normal ones — the X-5 legibility proof. Scores near-white
// "BRA" glyph pixels in the button band: a real dim drops that count sharply, so a silently-missing
// lock visual can't pass. Frames are saved for the by-eye review.
//
// Usage: env -u LD_LIBRARY_PATH node tools/web_capture_lock.mjs <bundle-dir>
import { createServer } from "node:http";
import { readFile, writeFile, mkdir } from "node:fs/promises";
import { extname, join, normalize } from "node:path";
import { chromium } from "playwright";

const bundleDir = process.argv[2];
if (!bundleDir) { console.error("usage: web_capture_lock.mjs <bundle-dir>"); process.exit(2); }
await mkdir(".screenshots", { recursive: true });

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

// Count near-white pixels in the BRA button band (the light "BRA" glyphs). The bright glyphs
// blend toward the background when the button dims to 0.4 alpha, so this count drops hard while
// locked and recovers after re-arm. The sky is blue-dominant (not near-white), so it doesn't
// pollute the count; the band is the bottom third where the button lives.
const whiteFn = (dataUrl) => new Promise((resolve) => {
	const img = new Image();
	img.onload = () => {
		const c = document.createElement("canvas");
		c.width = img.width; c.height = img.height;
		const x = c.getContext("2d");
		x.drawImage(img, 0, 0);
		const y0 = Math.floor(img.height * 0.72), y1 = Math.floor(img.height * 0.96);
		const d = x.getImageData(0, y0, img.width, y1 - y0).data;
		let white = 0;
		for (let i = 0; i < d.length; i += 4) {
			if (d[i] > 200 && d[i + 1] > 200 && d[i + 2] > 200) white++;
		}
		resolve(white);
	};
	img.onerror = () => resolve(-1);
	img.src = dataUrl;
});

const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });
const decoder = await browser.newPage();
await decoder.goto("about:blank");
const shotWhite = async (page) => {
	const buf = await page.screenshot({ type: "png" });
	const white = await decoder.evaluate(whiteFn, "data:image/png;base64," + buf.toString("base64"));
	return { buf, white };
};

const modes = [{ name: "normal", reducedMotion: "no-preference" }, { name: "reduced", reducedMotion: "reduce" }];
const results = {};
let failed = false;
for (const mode of modes) {
	const page = await browser.newPage({ viewport: { width: 390, height: 844 }, reducedMotion: mode.reducedMotion });
	const logs = [];
	page.on("console", (m) => logs.push(m.text()));
	page.on("pageerror", (e) => logs.push(`PAGEERROR: ${e.message}`));
	try {
		// armed — plain load: the gate is armed, button at full brightness.
		await page.goto(base, { waitUntil: "load", timeout: 60000 });
		await page.waitForFunction("window.__appReady === true", { timeout: 120000 });
		await page.waitForTimeout(1500); // first frame settles
		const armed = await shotWhite(page);
		await writeFile(`.screenshots/046-lock-${mode.name}-armed.png`, armed.buf);

		// locked — reload with the pin seam: the button is held dimmed + disabled every frame.
		await page.goto(`${base}?bra_force_lock=1`, { waitUntil: "load", timeout: 60000 });
		await page.waitForFunction("window.__appReady === true", { timeout: 120000 });
		await page.waitForTimeout(1500);
		const locked = await shotWhite(page);
		await writeFile(`.screenshots/046-lock-${mode.name}-locked.png`, locked.buf);

		results[mode.name] = { armed: armed.white, locked: locked.white };
		console.log(`${mode.name.padEnd(7)} armed=${armed.white}  locked=${locked.white}`);
	} catch (e) {
		failed = true;
		console.error(`${mode.name} capture failed: ${e.message}`);
		console.error(logs.join("\n"));
	}
	await page.close();
}
await browser.close();
server.close();

// Gate: the pinned lock dims the button, so the locked frame's near-white "BRA" glyph count must
// drop well below the armed frame's. Require under 60% of armed — a missing/insufficient dim
// can't pass. Checked in BOTH motion modes (the dim is static, so reduced must read the same).
let bad = [];
for (const mode of modes) {
	const r = results[mode.name];
	if (!r || r.armed < 50) { bad.push(`${mode.name}: no BRA glyphs detected (armed=${r?.armed})`); continue; }
	if (!(r.locked < r.armed * 0.6)) bad.push(`${mode.name}: locked not dim enough (locked=${r.locked} armed=${r.armed})`);
}
if (failed || bad.length) {
	console.error(`::error:: lock visual proof failed: ${bad.join("; ") || "(capture error)"}`);
	process.exit(1);
}
console.log("PASS — the BRA button reads clearly dimmed/locked vs armed, in both motion modes");
process.exit(0);
