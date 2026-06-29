// Pixel-proof the tier readout contrast fix on the REAL web build (task 033, P1-7). Serves
// the Godot Web/PWA bundle, boots it in headless Chromium (SwiftShader GL == the deployed GL
// Compatibility renderer) at 390×844, and for each tier (MISS / OK / PERFECT) loads the build
// with the web-only `?bra_force_tier=` seam that pins the readout to that word, then
// screenshots. Saves each frame as the binding proof and scores the upper band for near-black
// OUTLINE pixels — the dark stroke that makes the word pop against the bright sky. If the
// outline never renders, the count stays ~0 and the gate FAILS, so a silently-missing outline
// can't pass. The legibility itself is confirmed by eye on the saved frames.
//
// Usage: env -u LD_LIBRARY_PATH node tools/web_capture_readout.mjs <bundle-dir>
import { createServer } from "node:http";
import { readFile, writeFile } from "node:fs/promises";
import { extname, join, normalize } from "node:path";
import { chromium } from "playwright";

const bundleDir = process.argv[2];
if (!bundleDir) { console.error("usage: web_capture_readout.mjs <bundle-dir>"); process.exit(2); }

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

// Count near-black OUTLINE pixels in the upper band (where the big word flashes). The dark
// stroke is the fix; the sky (bright, blue-dominant) and the coloured fills are not near-black.
const scoreFn = (dataUrl) => new Promise((resolve) => {
	const img = new Image();
	img.onload = () => {
		const c = document.createElement("canvas");
		c.width = img.width; c.height = img.height;
		const x = c.getContext("2d");
		x.drawImage(img, 0, 0);
		const y0 = 0, y1 = Math.floor(img.height * 0.45); // upper band — the readout area
		const d = x.getImageData(0, y0, img.width, y1 - y0).data;
		let outline = 0;
		for (let i = 0; i < d.length; i += 4) {
			const r = d[i], g = d[i + 1], b = d[i + 2];
			if (r < 60 && g < 60 && b < 70) outline++; // near-black stroke
		}
		resolve(outline);
	};
	img.onerror = () => resolve(-1);
	img.src = dataUrl;
});

const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });
const decoder = await browser.newPage();
await decoder.goto("about:blank");

const tiers = ["miss", "ok", "perfect"];
const results = {};
let failed = false;
for (const tier of tiers) {
	const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
	const logs = [];
	page.on("console", (m) => logs.push(m.text()));
	page.on("pageerror", (e) => logs.push(`PAGEERROR: ${e.message}`));
	try {
		await page.goto(`${base}?bra_force_tier=${tier}`, { waitUntil: "load", timeout: 60000 });
		await page.waitForFunction("window.__appReady === true", { timeout: 120000 });
		await page.waitForTimeout(1500); // let the pinned word + first frame settle
		const buf = await page.screenshot({ type: "png" });
		const dataUrl = "data:image/png;base64," + buf.toString("base64");
		const outline = await decoder.evaluate(scoreFn, dataUrl);
		const out = `.screenshots/033-readout-${tier}.png`;
		await writeFile(out, buf);
		results[tier] = outline;
		console.log(`${tier.toUpperCase().padEnd(7)} outline px=${outline}  saved ${out}`);
	} catch (e) {
		failed = true;
		console.error(`${tier} capture failed: ${e.message}`);
		console.error(logs.join("\n"));
	}
	await page.close();
}
await browser.close();
server.close();

const FLOOR = 200; // a real 12px stroke around an 88px word is many hundreds of px
const thin = tiers.filter((t) => (results[t] ?? 0) < FLOOR);
if (failed || thin.length) {
	console.error(`::error:: outline missing/thin for: ${thin.join(", ") || "(capture error)"}`);
	process.exit(1);
}
console.log(`PASS — every tier has a dark outline (miss=${results.miss} ok=${results.ok} perfect=${results.perfect})`);
process.exit(0);
