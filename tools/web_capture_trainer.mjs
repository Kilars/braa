// Pixel-proof the P2-9 fading timing-trainer ring on the REAL web build (task 058). Serves the
// Godot Web/PWA bundle, boots it in headless Chromium (SwiftShader GL == the deployed GL
// Compatibility renderer) at 390×844, loads it with the web-only `?bra_force_trainer=1` seam that
// pins the approach ring ON (mid-approach radius, full opacity) regardless of whether a sit is
// open, then screenshots. This is the binding render proof — the apex tell once read green in
// tests yet was INVISIBLE in live pixels (bugs 030/036), so a tests-green ring is not enough; the
// cyan ring must actually composite over the BRA button on the real GL path. Scores the LOWER band
// (the button / grass area, below the horizon) for the ring's distinctive CYAN pixels — bright
// blue+green that pops against the green grass and is NOT the gold apex tell. ~0 cyan ⇒ the ring
// never rendered ⇒ the gate FAILS. Legibility itself is confirmed by eye on the saved frame.
//
// Usage: env -u LD_LIBRARY_PATH node tools/web_capture_trainer.mjs <bundle-dir>
import { createServer } from "node:http";
import { readFile, writeFile } from "node:fs/promises";
import { extname, join, normalize } from "node:path";
import { chromium } from "playwright";

const bundleDir = process.argv[2];
if (!bundleDir) { console.error("usage: web_capture_trainer.mjs <bundle-dir>"); process.exit(2); }

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

// Count CYAN ring pixels in the LOWER band (the BRA button / grass area, below the horizon). The
// approach ring is RING_COLOR ≈ rgb(64,191,255): high blue AND high green with a low-ish red, and
// b clearly above r. The green grass (b low) and the gold apex tell (b low, r high) don't match;
// the blue sky sits in the TOP band we exclude. So a non-trivial count proves the cyan ring drew.
const scoreFn = (dataUrl) => new Promise((resolve) => {
	const img = new Image();
	img.onload = () => {
		const c = document.createElement("canvas");
		c.width = img.width; c.height = img.height;
		const x = c.getContext("2d");
		x.drawImage(img, 0, 0);
		const y0 = Math.floor(img.height * 0.55), y1 = img.height; // lower band — button/grass
		const d = x.getImageData(0, y0, img.width, y1 - y0).data;
		let cyan = 0;
		for (let i = 0; i < d.length; i += 4) {
			const r = d[i], g = d[i + 1], b = d[i + 2];
			if (b > 180 && g > 130 && r < 140 && (b - r) > 80) cyan++;
		}
		resolve(cyan);
	};
	img.onerror = () => resolve(-1);
	img.src = dataUrl;
});

const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });
const decoder = await browser.newPage();
await decoder.goto("about:blank");

const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
const logs = [];
page.on("console", (m) => logs.push(m.text()));
page.on("pageerror", (e) => logs.push(`PAGEERROR: ${e.message}`));
let cyan = 0, failed = false;
try {
	await page.goto(`${base}?bra_force_trainer=1`, { waitUntil: "load", timeout: 60000 });
	await page.waitForFunction("window.__appReady === true", { timeout: 120000 });
	await page.waitForTimeout(1500); // let the pinned ring + first frame settle
	const buf = await page.screenshot({ type: "png" });
	const dataUrl = "data:image/png;base64," + buf.toString("base64");
	cyan = await decoder.evaluate(scoreFn, dataUrl);
	const out = ".screenshots/058-trainer-ring.png";
	await writeFile(out, buf);
	console.log(`forced trainer ring: cyan px=${cyan}  saved ${out}`);
} catch (e) {
	failed = true;
	console.error(`trainer capture failed: ${e.message}`);
	console.error(logs.join("\n"));
}
await page.close();
await browser.close();
server.close();

const FLOOR = 200; // a 14px-wide ring at ~99–259px radius is many hundreds of arc pixels
if (failed || cyan < FLOOR) {
	console.error(`::error:: trainer ring missing/thin (cyan px=${cyan}, floor ${FLOOR}) — the forced approach ring did not render`);
	process.exit(1);
}
console.log(`PASS — the forced approach ring renders as a bold cyan ring over the button (cyan px=${cyan})`);
process.exit(0);
