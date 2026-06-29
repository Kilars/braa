// Reaction capture — the visual gate for task 034 / P1-6 ("the mark reads as joy, not a lone
// bark"). Boots the Godot Web bundle in headless Chromium (SwiftShader == the deployed GL
// Compatibility renderer) with ?bra_autotap=1, which makes the game fire a real PERFECT mark
// at each sit's apex so the licensed dog's joyful hop (Jump_Place_IP) plays deterministically.
// Waits for window.__bra_reaction_n to tick (the exact frame the hop starts), then bursts a
// dense run of frames across the celebration + the blend back to the seat so review can confirm
// a clearly joyful, pop-free reaction.
//
// The local Web bundle bundles + prefers the licensed (reaction-capable) dog, so this is the
// genuine reaction — the CC0 dog has none.
//
// Usage: env -u LD_LIBRARY_PATH node tools/web_capture_reaction.mjs <bundle-dir> <out-prefix> [count] [gapMs]
import { createServer } from "node:http";
import { readFile, writeFile } from "node:fs/promises";
import { extname, join, normalize } from "node:path";
import { chromium } from "playwright";

const bundleDir = process.argv[2];
const prefix = process.argv[3] || ".screenshots/034-reaction";
const count = parseInt(process.argv[4] || "14", 10);
const gapMs = parseInt(process.argv[5] || "100", 10);
if (!bundleDir) { console.error("usage: web_capture_reaction.mjs <bundle-dir> <out-prefix> [count] [gapMs]"); process.exit(2); }

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
const url = `http://127.0.0.1:${port}/index.html?bra_autotap=1`;

const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
let failed = false;
try {
	await page.goto(url, { waitUntil: "load", timeout: 60000 });
	await page.waitForFunction("window.__appReady === true", { timeout: 120000 });
	// Capture one seated baseline BEFORE the hop, then wait for the reaction to fire.
	const baseline = await page.screenshot({ type: "png" });
	await writeFile(`${prefix}-00.png`, baseline);
	// The first sit takes ~inter_sit_gap + sit build; give it room. __bra_reaction_n ticks
	// the instant DogDirector.play_reaction() runs.
	await page.waitForFunction("(window.__bra_reaction_n||0) >= 1", { timeout: 60000 });
	for (let i = 1; i <= count; i++) {
		const buf = await page.screenshot({ type: "png" });
		await writeFile(`${prefix}-${String(i).padStart(2, "0")}.png`, buf);
		await page.waitForTimeout(gapMs);
	}
	console.log(`saved ${count + 1} frames (00 baseline + ${count} across the hop) to ${prefix}-NN.png`);
} catch (e) {
	failed = true;
	console.error(`capture failed: ${e.message}`);
} finally {
	await browser.close();
	server.close();
}
process.exit(failed ? 1 : 0);
