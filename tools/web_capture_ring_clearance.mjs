// Visual Review for task 123: the approach ring must render ABOVE the BRA button, not crossing it.
// Boots the web build with ?bra_force_trainer=1 (pins the cyan ring at mid-approach radius, full
// opacity) and saves a screenshot to .screenshots/123-ring-clearance.png. The scorer counts
// ring-cyan pixels in two bands:
//   band A (ring zone, rows 250-680): should contain ring-cyan (ring lives here after the move)
//   band B (button zone, rows 660-800): must contain NO ring-cyan (pill must be clear of the ring)
//
// Coordinate reasoning (390x844 viewport, bottom-anchor 1280-space):
//   RING_CENTER_Y = -580  =>  y_in_1280 = 1280 - 580 = 700  =>  y_in_844 = 700 * (844/1280) ~= 461
//   ring radius at full expansion ~= 259 * (844/1280) ~= 171 px in 844-space
//   ring top  ~= 461 - 171 = 290 px from top
//   ring bottom ~= 461 + 171 = 632 px from top
//   BRA button top: BRA_OFFSET_TOP=-280 => y_in_1280=1000 => y_in_844 ~= 660 px from top
//   Gap between ring bottom (~632) and button top (~660): ~28 px -- visible clear gap.
//
// Color disambiguation:
//   RING_COLOR = Color(0.25, 0.75, 1.0) ~= rgb(64, 191, 255): b>180, g>170, r<120
//   BRA button BLUE = Color("4a90e2") = rgb(74, 144, 226): g~=144, fails g>170 -- not counted
//
// Usage: env -u LD_LIBRARY_PATH node tools/web_capture_ring_clearance.mjs <bundle-dir>
import { createServer } from "node:http";
import { readFile, writeFile } from "node:fs/promises";
import { extname, join, normalize } from "node:path";
import { chromium } from "playwright";

const bundleDir = process.argv[2];
if (!bundleDir) { console.error("usage: web_capture_ring_clearance.mjs <bundle-dir>"); process.exit(2); }

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

// Ring-cyan detector: requires g > 170 to distinguish from the BRA button blue (g ~= 144).
// RING_COLOR(0.25,0.75,1.0) ~= rgb(64,191,255): b=255*1.0=255, g=255*0.75=191, r=255*0.25=64.
// SwiftShader blending softens values, so use thresholds with headroom.
const scoreFn = (dataUrl) => new Promise((resolve) => {
	const img = new Image();
	img.onload = () => {
		const c = document.createElement("canvas");
		c.width = img.width; c.height = img.height;
		const ctx = c.getContext("2d");
		ctx.drawImage(img, 0, 0);
		const w = img.width;
		// Ring zone: rows 250-680 (mid-screen above the button, where the shifted ring lives).
		const dRing = ctx.getImageData(0, 250, w, 430).data;
		// Button zone: rows 660-800 (BRA pill, must be free of ring-cyan).
		const dBtn = ctx.getImageData(0, 660, w, 140).data;
		const isCyan = (r, g, b) => b > 180 && g > 170 && r < 120 && (b - r) > 100;
		let cyanRing = 0, cyanBtn = 0;
		for (let i = 0; i < dRing.length; i += 4)
			if (isCyan(dRing[i], dRing[i + 1], dRing[i + 2])) cyanRing++;
		for (let i = 0; i < dBtn.length; i += 4)
			if (isCyan(dBtn[i], dBtn[i + 1], dBtn[i + 2])) cyanBtn++;
		resolve({ cyanRing, cyanBtn });
	};
	img.onerror = () => resolve({ cyanRing: -1, cyanBtn: -1 });
	img.src = dataUrl;
});

const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });
const decoder = await browser.newPage();
await decoder.goto("about:blank");

const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
const logs = [];
page.on("console", (m) => logs.push(m.text()));
page.on("pageerror", (e) => logs.push(`PAGEERROR: ${e.message}`));
let result = { cyanRing: 0, cyanBtn: 0 }, failed = false;
try {
	await page.goto(`${base}?bra_force_trainer=1`, { waitUntil: "load", timeout: 60000 });
	await page.waitForFunction("window.__appReady === true", { timeout: 120000 });
	await page.waitForTimeout(1500);
	const buf = await page.screenshot({ type: "png" });
	const dataUrl = "data:image/png;base64," + buf.toString("base64");
	result = await decoder.evaluate(scoreFn, dataUrl);
	const out = ".screenshots/123-ring-clearance.png";
	await writeFile(out, buf);
	console.log(`ring zone cyan=${result.cyanRing}  button zone cyan=${result.cyanBtn}  saved ${out}`);
} catch (e) {
	failed = true;
	console.error(`capture failed: ${e.message}`);
	console.error(logs.join("\n"));
}
await page.close();
await browser.close();
server.close();

const RING_FLOOR = 200; // ring must draw visibly in the upper zone (14px-wide arc at ~171px radius)
const BTN_CEIL  = 20;  // button zone must be essentially free of ring-cyan
let pass = true;
if (failed) { console.error("::error:: capture failed"); pass = false; }
if (result.cyanRing < RING_FLOOR) {
	console.error(`::error:: ring not visible in upper zone (cyan=${result.cyanRing}, floor ${RING_FLOOR})`);
	pass = false;
}
if (result.cyanBtn > BTN_CEIL) {
	console.error(`::error:: ring bleeds into BRA button zone (cyan=${result.cyanBtn}, ceil ${BTN_CEIL}) -- clearance violated`);
	pass = false;
}
if (pass) {
	console.log(`PASS -- ring renders above BRA pill (ring zone cyan=${result.cyanRing}; button zone cyan=${result.cyanBtn} <= ${BTN_CEIL})`);
	process.exit(0);
} else {
	process.exit(1);
}
