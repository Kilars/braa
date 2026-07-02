// PO Phase-3 play-test driver (throwaway, not committed by the build loop).
// Boots the real Godot Web bundle at 390x844 in headless Chromium (SwiftShader == deployed
// GL Compatibility), and does four captures the PO needs this pass:
//  A) default idle: watch framing/facing between offers (notes 3, 6) — burst of frames.
//  B) autotap reaction burst: dense frames across sit->mark->reaction->stand to inspect the
//     post-BRA jump/flick (note 7).
//  C) completion menu: autotap to master Sitt, screenshot the popped menu (note 1).
//  D) chocolate breed idle (?bra_breed=chocolate): 2nd breed render (note 4 / 076).
// All frames land under .screenshots/po-p3/. Boot console lines are printed (licensed + can Sitt).
import { createServer } from "node:http";
import { readFile, writeFile, mkdir } from "node:fs/promises";
import { extname, join, normalize } from "node:path";
import { chromium } from "playwright";

const bundleDir = process.argv[2] || "build/web";
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
await mkdir(".screenshots/po-p3", { recursive: true });

const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });

async function boot(query, tag) {
	const page = await browser.newPage({ viewport: { width: W, height: H } });
	const logs = [];
	page.on("console", (m) => logs.push(m.text()));
	page.on("pageerror", (e) => logs.push(`PAGEERROR: ${e.message}`));
	await page.goto(query ? `${base}?${query}` : base, { waitUntil: "load", timeout: 60000 });
	await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
	console.log(`\n=== [${tag}] boot (${query || "default"}) ===`);
	for (const l of logs) if (/licens|sitt|can |glb|error|ERROR|breed|choc/i.test(l)) console.log(`  ${l}`);
	return { page, logs };
}

// A) default idle framing — 12 frames over ~6s to see wander/facing/garden
{
	const { page } = await boot("", "idle-default");
	for (let i = 0; i < 12; i++) {
		await page.screenshot({ path: `.screenshots/po-p3/A-idle-${String(i).padStart(2, "0")}.png` });
		await page.waitForTimeout(500);
	}
	await page.close();
	console.log("  A) saved 12 idle frames");
}

// B) autotap reaction burst — dense frames to catch the post-BRA jump/flick (note 7)
{
	const { page } = await boot("bra_autotap=1", "reaction-burst");
	// dump ~90 frames at ~70ms = ~6.3s: several full sit->mark->reaction->stand cycles
	let prevTell = false, marks = 0;
	for (let i = 0; i < 90; i++) {
		await page.screenshot({ path: `.screenshots/po-p3/B-react-${String(i).padStart(3, "0")}.png` });
		await page.waitForTimeout(70);
	}
	await page.close();
	console.log("  B) saved 90 reaction frames");
}

// C) completion menu on mastering Sitt
{
	const { page } = await boot("bra_autotap=1", "menu");
	try {
		await page.waitForFunction("window.__bra_menu_open === true", undefined, { timeout: 120000 });
		await page.waitForTimeout(400);
		await page.screenshot({ path: ".screenshots/po-p3/C-menu.png" });
		const active = await page.evaluate("window.__bra_current_trick");
		console.log(`  C) menu popped; active trick = ${active}`);
	} catch (e) {
		await page.screenshot({ path: ".screenshots/po-p3/C-menu-FAIL.png" });
		console.log(`  C) menu FAILED: ${e.message}`);
	}
	await page.close();
}

// D) chocolate breed idle vs default (note 4 / 076)
{
	const { page } = await boot("bra_breed=chocolate", "chocolate");
	for (let i = 0; i < 4; i++) {
		await page.screenshot({ path: `.screenshots/po-p3/D-choc-${String(i).padStart(2, "0")}.png` });
		await page.waitForTimeout(500);
	}
	await page.close();
	console.log("  D) saved 4 chocolate-breed frames");
}

await browser.close();
server.close();
console.log("\nplaytest done");
process.exit(0);
