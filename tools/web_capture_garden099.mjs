// Visual Review for 099 (Phase 6 — garden ambiance to the goal training screen). Boots the real
// Godot Web bundle in headless Chromium at 390×844 and captures three IDLE frames a couple seconds
// apart (the dog wanders, so we see the composed garden from a few dog positions), then a scored
// frame under ?bra_autotap=1 to confirm the dog stays centred + unoccluded at the mark. Frames land
// under .screenshots/099-*. Compare against .docs/specs/assets/goal-training-screen.png for
// composition + grounding + juice (not pixel identity).
// Usage: env -u LD_LIBRARY_PATH node tools/web_capture_garden099.mjs <bundle-dir>
import { createServer } from "node:http";
import { readFile, mkdir } from "node:fs/promises";
import { extname, join, normalize } from "node:path";
import { chromium } from "playwright";

const bundleDir = process.argv[2];
if (!bundleDir) { console.error("usage: web_capture_garden099.mjs <bundle-dir>"); process.exit(2); }

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

const W = 390, H = 844;
await mkdir(".screenshots", { recursive: true });
const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });
let code = 1;
try {
	// Three idle frames — the garden composition, the wandering dog at a few positions.
	const page = await browser.newPage({ viewport: { width: W, height: H } });
	await page.goto(`http://127.0.0.1:${port}/index.html`, { waitUntil: "load", timeout: 60000 });
	await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
	for (const [i, label] of [["a"], ["b"], ["c"]].entries()) {
		await page.waitForTimeout(i === 0 ? 1500 : 2200);
		await page.screenshot({ path: `.screenshots/099-idle-${label}.png` });
		console.log(`captured 099-idle-${label}.png`);
	}
	// A scored frame — autotap marks a PERFECT; grab a burst to catch the dog facing camera at apex.
	const ap = await browser.newPage({ viewport: { width: W, height: H } });
	await ap.goto(`http://127.0.0.1:${port}/index.html?bra_autotap=1`, { waitUntil: "load", timeout: 60000 });
	await ap.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
	await ap.waitForTimeout(2500);
	await ap.screenshot({ path: ".screenshots/099-scored.png" });
	console.log("captured 099-scored.png (autotap mark — dog should stay centred + unoccluded)");
	code = 0;
} catch (e) {
	console.error(`099 capture FAILED: ${e.message}`);
} finally {
	await browser.close();
	server.close();
}
process.exit(code);
