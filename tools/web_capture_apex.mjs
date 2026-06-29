// Pixel-proof the apex tell on the REAL web build (task 030). Serves a Godot Web/PWA
// bundle, boots it in headless Chromium (SwiftShader GL == the deployed GL Compatibility
// renderer), bursts screenshots across several sit cycles, and scores each frame for
// saturated-gold pixels in the lower (BRA-button) band — the apex ring. Saves the
// brightest frame as the binding proof and FAILS if no frame ever shows the ring (so a
// silently-faint tell can't pass). PNG decoding is done in-page via a 2D canvas, so no
// node image lib is needed; main.gd is untouched (no debug hooks).
//
// Usage: env -u LD_LIBRARY_PATH node tools/web_capture_apex.mjs <bundle-dir> <out.png>
import { createServer } from "node:http";
import { readFile, writeFile } from "node:fs/promises";
import { extname, join, normalize } from "node:path";
import { chromium } from "playwright";

const bundleDir = process.argv[2];
const outPng = process.argv[3] || ".screenshots/030-apex-tell-visible.png";
if (!bundleDir) { console.error("usage: web_capture_apex.mjs <bundle-dir> <out.png>"); process.exit(2); }

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
const url = `http://127.0.0.1:${port}/index.html`;

// Count saturated-gold pixels in the bottom band (the BRA button area, where the apex ring
// is drawn). Gold ring ≈ (255,199,51): high R, mid-high G, LOW B. The cream/tan dog has high
// B (~160+) so it's excluded; sky-blue and the dark grey button are excluded too.
const scoreFn = (dataUrl) => new Promise((resolve) => {
	const img = new Image();
	img.onload = () => {
		const c = document.createElement("canvas");
		c.width = img.width; c.height = img.height;
		const x = c.getContext("2d");
		x.drawImage(img, 0, 0);
		const y0 = Math.floor(img.height * 0.62); // lower ~38% — the button band + ring
		const d = x.getImageData(0, y0, img.width, img.height - y0).data;
		let gold = 0;
		for (let i = 0; i < d.length; i += 4) {
			const r = d[i], g = d[i + 1], b = d[i + 2];
			if (r > 180 && g > 120 && g < 230 && b < 110 && (r - b) > 90) gold++;
		}
		resolve(gold);
	};
	img.onerror = () => resolve(-1);
	img.src = dataUrl;
});

const logs = [];
const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport: { width: 390, height: 844 },
	reducedMotion: process.env.BRA_REDUCED || "no-preference" });
page.on("console", (m) => logs.push(m.text()));
page.on("pageerror", (e) => logs.push(`PAGEERROR: ${e.message}`));
// Decode/score screenshots on a clean page — the Godot page's CSP blocks data: images.
const decoder = await browser.newPage();
await decoder.goto("about:blank");

// BRA_FORCE=1 pins the tell to full intensity via the web build's `?bra_force_tell=1`
// seam (030), so a single screenshot is a DETERMINISTIC proof the gold ring renders —
// independent of catching the brief (~0.2s) live apex. The default burst mode instead
// proves the ring shows in NORMAL play, by sampling across several sit cycles.
const force = process.env.BRA_FORCE === "1";
const gotoUrl = force ? `${url}?bra_force_tell=1` : url;
let best = { score: -1, buf: null };
try {
	await page.goto(gotoUrl, { waitUntil: "load", timeout: 60000 });
	await page.waitForFunction("window.__appReady === true", { timeout: 120000 });
	const reduced = await page.evaluate("matchMedia('(prefers-reduced-motion: reduce)').matches");
	console.log(`prefers-reduced-motion: reduce = ${reduced}; force-tell = ${force}`);
	// Forced: a few frames to let the pinned marker's redraw composite, take the best.
	// Live: burst across many full idle→sit→idle cycles so an apex peak is caught.
	const frames = force ? 6 : Number(process.env.BRA_FRAMES || 80);
	const wait = force ? 150 : Number(process.env.BRA_WAIT || 80);
	const scores = [];
	for (let i = 0; i < frames; i++) {
		const buf = await page.screenshot({ type: "png" });
		const dataUrl = "data:image/png;base64," + buf.toString("base64");
		const score = await decoder.evaluate(scoreFn, dataUrl);
		scores.push(score);
		if (process.env.BRA_DUMP) await writeFile(`${process.env.BRA_DUMP}/f${String(i).padStart(3, "0")}.png`, buf);
		if (score > best.score) best = { score, buf };
		await page.waitForTimeout(wait);
	}
	console.log(`max gold = ${Math.max(...scores)}; nonzero frames = ${scores.filter((s) => s > 0).length}/${frames}`);
	console.log("per-frame gold scores:", scores.join(","));
} catch (e) {
	console.error(`capture failed: ${e.message}`);
	console.error(logs.join("\n"));
}
await browser.close();
server.close();

if (best.buf) await writeFile(outPng, best.buf);
console.log(`best gold-pixel count = ${best.score}; saved ${outPng}`);
const GOLD_FLOOR = 150; // the ring is ~hundreds of px; >150 saturated-gold px = unmistakable
if (best.score < GOLD_FLOOR) {
	console.error(`::error:: apex tell never showed a gold ring (best ${best.score} < ${GOLD_FLOOR})`);
	process.exit(1);
}
console.log(`PASS — apex tell renders a bold gold ring (${best.score} gold px)`);
process.exit(0);
