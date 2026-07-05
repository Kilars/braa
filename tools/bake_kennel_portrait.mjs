// Offline portrait baker (107, K-1) — the one-time tool that WRITES assets/kennel/dog_portrait.png.
//
// Local Godot GL is broken in this environment (GLX segfaults; software-GL fallback segfaults too),
// so the project's proven Chromium/SwiftShader path is the only way to render the dog. This boots the
// real Godot Web bundle with ?bra_bake_portrait=1 — main.gd then renders the CC0 dog to a transparent
// SubViewport, crops to the silhouette, and publishes the PNG bytes as base64 on window.__bra_portrait_png.
// We read that, base64-decode it, and write the committed PNG. The shipped kennel loads that static
// Texture2D — no SubViewport ever renders in normal play (X-7).
//
// Run once, then commit the PNG:
//   nix develop -c bash verify.sh   # (builds build/web) — or just export the Web preset
//   env -u LD_LIBRARY_PATH node tools/bake_kennel_portrait.mjs build/web
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

await mkdir("assets/kennel", { recursive: true });
const browser = await chromium.launch({
	args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"]
});
const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
page.on("console", (m) => { if (/\[bake\]/.test(m.text())) console.log("godot:", m.text()); });

let code = 1;
try {
	await page.goto(`${base}?bra_bake_portrait=1`, { waitUntil: "load", timeout: 60000 });
	await page.waitForFunction(
		"window.__bra_portrait_ready === true || window.__bra_portrait_error",
		undefined, { timeout: 120000 });
	const err = await page.evaluate(() => window.__bra_portrait_error || null);
	if (err) throw new Error(`godot bake error: ${err}`);
	const b64 = await page.evaluate(() => window.__bra_portrait_png);
	const w = await page.evaluate(() => window.__bra_portrait_w);
	const h = await page.evaluate(() => window.__bra_portrait_h);
	if (!b64 || typeof b64 !== "string") throw new Error("no base64 portrait on window.__bra_portrait_png");
	const bytes = Buffer.from(b64, "base64");
	if (bytes.length < 200) throw new Error(`portrait PNG suspiciously small (${bytes.length} bytes)`);
	await writeFile("assets/kennel/dog_portrait.png", bytes);
	console.log(`BAKED assets/kennel/dog_portrait.png — ${w}x${h}, ${bytes.length} bytes`);
	code = 0;
} catch (e) {
	console.error(`portrait bake FAILED: ${e.message}`);
	await page.screenshot({ path: ".screenshots/107-bake-FAIL.png" }).catch(() => {});
} finally {
	await browser.close();
	server.close();
}
process.exit(code);
