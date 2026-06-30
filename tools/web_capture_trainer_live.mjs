// Live behavioral proof of the P2-9 trainer ring (task 058) on the licensed sit-capable dog the
// local Web bundle prefers. Boots the bundle in headless Chromium (SwiftShader == deployed GL) at
// 390×844 with NO force seam and NO autotap, so the learned bar stays at 0 (a brand-new trick →
// teach == 1 → bold ring) and the dog runs its real variable-cadence sit/feint loop. Bursts frames,
// scores each lower-band frame for the ring's cyan, and saves the frames where the ring is present —
// proving the LIVE drive path (not just the ?bra_force_trainer seam) actually renders the ring
// shrinking through a real sit, and that it's DARK between sits / during feints. The varying cyan
// counts across saved frames show the ring at different radii (the shrink). Eyeball the saved frames.
//
// Usage: env -u LD_LIBRARY_PATH node tools/web_capture_trainer_live.mjs <bundle-dir> [count] [gapMs]
import { createServer } from "node:http";
import { readFile, writeFile } from "node:fs/promises";
import { extname, join, normalize } from "node:path";
import { chromium } from "playwright";

const bundleDir = process.argv[2];
const count = parseInt(process.argv[3] || "48", 10);
const gapMs = parseInt(process.argv[4] || "180", 10);
if (!bundleDir) { console.error("usage: web_capture_trainer_live.mjs <bundle-dir> [count] [gapMs]"); process.exit(2); }

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
let failed = false;
const present = []; // frames where the ring rendered
try {
	await page.goto(base, { waitUntil: "load", timeout: 60000 }); // no force, no autotap
	await page.waitForFunction("window.__appReady === true", { timeout: 120000 });
	let maxCyan = 0, litFrames = 0;
	for (let i = 0; i < count; i++) {
		const buf = await page.screenshot({ type: "png" });
		const dataUrl = "data:image/png;base64," + buf.toString("base64");
		const cyan = await decoder.evaluate(scoreFn, dataUrl);
		if (cyan >= 150) { // ring clearly present this frame
			litFrames++;
			maxCyan = Math.max(maxCyan, cyan);
			const out = `.screenshots/058-live-${String(i).padStart(2, "0")}-cy${cyan}.png`;
			await writeFile(out, buf);
			present.push({ i, cyan, out });
		}
		await page.waitForTimeout(gapMs);
	}
	console.log(`bursted ${count} frames; ring present in ${litFrames} (max cyan=${maxCyan}).`);
	for (const p of present.sort((a, b) => b.cyan - a.cyan).slice(0, 6))
		console.log(`  frame ${p.i}: cyan=${p.cyan}  ${p.out}`);
	if (litFrames === 0) { failed = true; console.error("::error:: ring never appeared in a live (non-forced) sit"); }
} catch (e) {
	failed = true;
	console.error(`live capture failed: ${e.message}`);
}
await browser.close();
server.close();
process.exit(failed ? 1 : 0);
