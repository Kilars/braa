// Pixel-proof the dog's contact shadow on the REAL web build (task 031). Serves the Godot
// Web/PWA bundle, boots it in headless Chromium (SwiftShader GL == the deployed GL
// Compatibility renderer), lets the idle pose settle, and screenshots at 390×844. Saves the
// frame as the binding proof and scores the band UNDER the dog's feet for near-black soft
// pixels (the blob) so a silently-missing shadow can't pass. The shadow is static + always
// on, so no force seam is needed — one settled frame is deterministic.
//
// Usage: env -u LD_LIBRARY_PATH node tools/web_capture_shadow.mjs <bundle-dir> <out.png>
import { createServer } from "node:http";
import { readFile, writeFile } from "node:fs/promises";
import { extname, join, normalize } from "node:path";
import { chromium } from "playwright";

const bundleDir = process.argv[2];
const outPng = process.argv[3] || ".screenshots/031-contact-shadow.png";
if (!bundleDir) { console.error("usage: web_capture_shadow.mjs <bundle-dir> <out.png>"); process.exit(2); }

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

// Count near-black soft pixels in the lower-middle band, where the blob sits under the feet.
// The blob is flat black blended over sky-blue, so it reads as DARK + low-saturation (its
// channels are all pulled down toward 0). The sky (high, blue-dominant) and the cream dog
// (bright) are excluded; the dark-grey BRA button lives lower (below y 0.80), so the band is
// clamped above it. A genuine shadow contributes a few hundred such pixels.
const scoreFn = (dataUrl) => new Promise((resolve) => {
	const img = new Image();
	img.onload = () => {
		const c = document.createElement("canvas");
		c.width = img.width; c.height = img.height;
		const x = c.getContext("2d");
		x.drawImage(img, 0, 0);
		const y0 = Math.floor(img.height * 0.45);
		const y1 = Math.floor(img.height * 0.80); // stay above the dark BRA button band
		const d = x.getImageData(0, y0, img.width, y1 - y0).data;
		let dark = 0;
		for (let i = 0; i < d.length; i += 4) {
			const r = d[i], g = d[i + 1], b = d[i + 2];
			const mx = Math.max(r, g, b), mn = Math.min(r, g, b);
			if (mx < 120 && (mx - mn) < 60) dark++; // dim and low-saturation = the smudge
		}
		resolve(dark);
	};
	img.onerror = () => resolve(-1);
	img.src = dataUrl;
});

const logs = [];
const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
page.on("console", (m) => logs.push(m.text()));
page.on("pageerror", (e) => logs.push(`PAGEERROR: ${e.message}`));
const decoder = await browser.newPage();
await decoder.goto("about:blank");

let saved = { score: -1, buf: null };
try {
	await page.goto(url, { waitUntil: "load", timeout: 60000 });
	await page.waitForFunction("window.__appReady === true", { timeout: 120000 });
	await page.waitForTimeout(1500); // let the idle pose + first rendered frame settle
	// A few frames; the shadow is static so they agree — take the darkest (best-composited).
	for (let i = 0; i < 4; i++) {
		const buf = await page.screenshot({ type: "png" });
		const dataUrl = "data:image/png;base64," + buf.toString("base64");
		const score = await decoder.evaluate(scoreFn, dataUrl);
		if (score > saved.score) saved = { score, buf };
		await page.waitForTimeout(250);
	}
	console.log(`dark-blob pixel count under the dog = ${saved.score}`);
} catch (e) {
	console.error(`capture failed: ${e.message}`);
	console.error(logs.join("\n"));
}
await browser.close();
server.close();

if (saved.buf) await writeFile(outPng, saved.buf);
console.log(`saved ${outPng}`);
const FLOOR = 120; // a real soft disc under the feet is hundreds of px; >120 = unmistakable
if (saved.score < FLOOR) {
	console.error(`::error:: no contact shadow under the dog (best ${saved.score} < ${FLOOR})`);
	process.exit(1);
}
console.log(`PASS — a contact shadow grounds the dog (${saved.score} dark px)`);
process.exit(0);
