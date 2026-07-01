// Boot a Godot 4 Web/PWA export in headless Chromium and PROVE it actually runs.
//
// Why this exists (025 / ADR-0006): the licensed dog ships in an ENCRYPTED .pck that
// only the custom-key wasm web template can decrypt. The linux `godot --headless`
// runtime (verify.sh's boot leg) CANNOT decrypt it — so the only honest proof that the
// encrypted bundle decrypts AND loads the licensed Labrador is to boot the real web
// build in a real browser. That is exactly what this does, in CI, before the owner ever
// spends time Chrome-testing the artifact.
//
// Usage:  node tools/web_boot_check.mjs <bundle-dir> [--require <substr>]...
//   - waits for window.__appReady === true (main.gd sets it from _notify_web_ready;
//     if the pck failed to decrypt the app never boots and this times out → fail)
//   - asserts every --require substring appears in the captured browser console
//     (main.gd prints "[Bra!] dog loaded: …", "[Bra!] dog can Sitt …" — the same
//     console signals verify.sh's headless boot gate already keys off)
// Exit 0 on success, non-zero otherwise. Prints the full console on failure.
//
// NOTE (local runs only): per project memory, local Playwright/Chromium needs
// `env -u LD_LIBRARY_PATH node tools/web_boot_check.mjs …`. CI is unaffected.

import { createServer } from "node:http";
import { readFile } from "node:fs/promises";
import { extname, join, normalize } from "node:path";
import { chromium } from "playwright";

const bundleDir = process.argv[2];
if (!bundleDir) {
	console.error("usage: web_boot_check.mjs <bundle-dir> [--query <qs>] [--require <substr>]...");
	process.exit(2);
}
const required = [];
let query = "";  // optional ?bra_trick= selector (065/067) appended to index.html
for (let i = 3; i < process.argv.length; i++) {
	if (process.argv[i] === "--require") required.push(process.argv[++i]);
	else if (process.argv[i] === "--query") query = (process.argv[++i] || "").replace(/^\?/, "");
}

// Godot's loader uses streaming wasm compilation — the .wasm MUST be served as
// application/wasm or instantiation fails. Single-threaded export → no SharedArrayBuffer,
// so no COOP/COEP headers are needed (matches the Pages deploy, ADR-0004/0005).
const MIME = {
	".html": "text/html; charset=utf-8",
	".js": "text/javascript; charset=utf-8",
	".mjs": "text/javascript; charset=utf-8",
	".wasm": "application/wasm",
	".pck": "application/octet-stream",
	".json": "application/json",
	".png": "image/png",
	".svg": "image/svg+xml",
	".ico": "image/x-icon",
};

const server = createServer(async (req, res) => {
	try {
		let p = decodeURIComponent(new URL(req.url, "http://localhost").pathname);
		if (p === "/") p = "/index.html";
		// Contain path traversal: strip any leading ../ after normalisation.
		const safe = normalize(p).replace(/^(\.\.[/\\])+/, "");
		const full = join(bundleDir, safe);
		const body = await readFile(full);
		res.setHeader("Content-Type", MIME[extname(full)] || "application/octet-stream");
		res.end(body);
	} catch {
		res.statusCode = 404;
		res.end("not found");
	}
});

await new Promise((r) => server.listen(0, "127.0.0.1", r));
const { port } = server.address();
const url = `http://127.0.0.1:${port}/index.html${query ? "?" + query : ""}`;
console.log(`serving ${bundleDir} at ${url}`);

const logs = [];
const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage"] });
const page = await browser.newPage();
page.on("console", (m) => logs.push(m.text()));
page.on("pageerror", (e) => logs.push(`PAGEERROR: ${e.message}`));

let booted = false;
try {
	await page.goto(url, { waitUntil: "load", timeout: 60000 });
	// 120s: a cold wasm download + Godot init on a CI runner is slow but bounded.
	await page.waitForFunction("window.__appReady === true", { timeout: 120000 });
	booted = true;
} catch (e) {
	console.error(`boot failed: ${e.message}`);
}

const consoleText = logs.join("\n");
const missing = required.filter((s) => !consoleText.includes(s));

await browser.close();
server.close();

if (!booted || missing.length) {
	console.error("\n--- captured browser console ---");
	console.error(consoleText || "(empty)");
	console.error("--- end console ---");
	if (!booted) console.error("::error::web bundle never reached window.__appReady (did the encrypted .pck fail to decrypt?)");
	if (missing.length) console.error(`::error::missing required console output: ${JSON.stringify(missing)}`);
	process.exit(1);
}

console.log(`web boot check PASSED — __appReady true; all required signals present: ${JSON.stringify(required)}`);
process.exit(0);
