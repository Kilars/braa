// PO Phase-2 play-test pass. Boots the local licensed Web bundle (SwiftShader == deployed
// GL Compatibility renderer) at 390x844, captures the boot log, and drives four scenarios:
//   free   — no seam: garden + wandering dog + unforced trainer ring + face-turn
//   tap    — ?bra_autotap=1: sit -> face -> mark -> learned-bar fill cycle
//   lock   — ?bra_force_lock=1: anti-mash locked BRA
//   train  — ?bra_force_trainer=1: pinned trainer ring
// Sweeps every run for SCRIPT ERROR / pageerror. Usage:
//   env -u LD_LIBRARY_PATH node tools/po_phase2_pass.mjs <bundle-dir> <out-dir>
import { createServer } from "node:http";
import { readFile, writeFile } from "node:fs/promises";
import { extname, join, normalize } from "node:path";
import { chromium } from "playwright";

const bundleDir = process.argv[2] || "build/web";
const outDir = process.argv[3] || ".screenshots/po-p2";

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

const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });

async function run(label, query, frames, gap) {
	const logs = [], errors = [];
	const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
	page.on("console", (m) => logs.push(m.text()));
	page.on("pageerror", (e) => { errors.push(`PAGEERROR: ${e.message}`); });
	try {
		await page.goto(base + query, { waitUntil: "load", timeout: 90000 });
		await page.waitForFunction("window.__appReady === true", { timeout: 120000 });
		await page.waitForTimeout(1800);
		for (let i = 0; i < frames; i++) {
			const buf = await page.screenshot({ type: "png" });
			await writeFile(`${outDir}/${label}-${String(i).padStart(2, "0")}.png`, buf);
			await page.waitForTimeout(gap);
		}
		const boot = logs.filter((l) => /dog loaded|can Sitt|licensed|coat surface|ambles|feint|cadence/i.test(l));
		const errs = logs.filter((l) => /SCRIPT ERROR|Uncaught|undefined method|Invalid call|nil/i.test(l)).concat(errors);
		console.log(`\n=== ${label} (${query || "no seam"}) — ${frames} frames ===`);
		boot.forEach((l) => console.log("  BOOT: " + l));
		console.log(`  ERRORS: ${errs.length}`);
		errs.forEach((l) => console.log("  !! " + l));
		return { boot, errs };
	} catch (e) {
		console.error(`${label} failed: ${e.message}`);
		console.error(logs.slice(-20).join("\n"));
		return { boot: [], errs: [e.message] };
	} finally {
		await page.close();
	}
}

try {
	await run("free", "", 16, 550);        // garden, wander, unforced trainer ring, face-turn
	await run("tap", "?bra_autotap=1", 18, 320);   // sit->face->mark->fill cycle
	await run("lock", "?bra_force_lock=1", 3, 300); // anti-mash locked BRA
	await run("train", "?bra_force_trainer=1", 3, 300); // pinned trainer ring
	console.log("\nDONE");
} finally {
	await browser.close();
	server.close();
}
