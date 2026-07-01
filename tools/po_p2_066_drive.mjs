// PO play-test driver for Phase 2 at HEAD 7a3f12f (task 066 selector + 065/067 trick roster).
// Two modes:
//   selector  — boot default, tap each of the 3 real chips, assert __bra_current_trick flips,
//               screenshot the top selector band before/after each tap.
//   burst <query> <n> — boot with a query (e.g. bra_trick=ligg), save N frames so the held
//               trick apex pose can be eyeballed. Also logs console + pageerror.
// Usage: env -u LD_LIBRARY_PATH node tools/po_p2_066_drive.mjs <bundle> <outdir> <mode> [query] [n]
import { createServer } from "node:http";
import { readFile, writeFile, mkdir } from "node:fs/promises";
import { extname, join, normalize } from "node:path";
import { chromium } from "playwright";

const [bundleDir, outDir, mode, arg4, arg5] = process.argv.slice(2);
if (!bundleDir || !outDir || !mode) { console.error("usage: <bundle> <outdir> <mode> [query] [n]"); process.exit(2); }
await mkdir(outDir, { recursive: true });

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
const logs = [];
const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport: { width: W, height: H } });
page.on("console", (m) => logs.push(m.text()));
page.on("pageerror", (e) => logs.push(`PAGEERROR: ${e.message}`));
let code = 1;
try {
	const query = mode === "burst" ? (arg4 || "") : "";
	const url = `http://127.0.0.1:${port}/index.html${query ? "?" + query : ""}`;
	await page.goto(url, { waitUntil: "load", timeout: 60000 });
	await page.waitForFunction("window.__appReady === true", { timeout: 120000 });
	await page.waitForTimeout(1500);

	if (mode === "selector") {
		const chips = [
			{ name: "sitt", x: W * 0.17 },
			{ name: "ligg", x: W * 0.5 },
			{ name: "legg_deg", x: W * 0.83 },
		];
		const boot = await page.evaluate("window.__bra_current_trick");
		console.log(`boot trick = ${boot}`);
		await page.screenshot({ path: join(outDir, "sel-00-boot.png") });
		// crop just the top selector band for a close look
		await page.screenshot({ path: join(outDir, "sel-00-boot-band.png"), clip: { x: 0, y: 0, width: W, height: 70 } });
		let i = 1;
		for (const c of chips) {
			await page.mouse.click(c.x, 30);
			try {
				await page.waitForFunction(`window.__bra_current_trick === '${c.name}'`, { timeout: 5000 });
				console.log(`TAP ${c.name} @x=${Math.round(c.x)} -> current=${await page.evaluate("window.__bra_current_trick")} OK`);
			} catch {
				console.log(`TAP ${c.name} @x=${Math.round(c.x)} -> current=${await page.evaluate("window.__bra_current_trick")} MISMATCH`);
			}
			await page.waitForTimeout(400);
			await page.screenshot({ path: join(outDir, `sel-0${i}-${c.name}.png`) });
			await page.screenshot({ path: join(outDir, `sel-0${i}-${c.name}-band.png`), clip: { x: 0, y: 0, width: W, height: 70 } });
			i++;
		}
		code = 0;
	} else if (mode === "burst") {
		const n = Number(arg5 || 40);
		console.log(`burst query='${query}' current=${await page.evaluate("window.__bra_current_trick")}`);
		for (let f = 0; f < n; f++) {
			const buf = await page.screenshot({ type: "png" });
			await writeFile(join(outDir, `f${String(f).padStart(2, "0")}.png`), buf);
			await page.waitForTimeout(130);
		}
		code = 0;
	}
} catch (e) {
	console.error(`FAILED: ${e.message}`);
} finally {
	console.log("--- console tail ---");
	console.log(logs.slice(0, 20).join("\n"));
	const errs = logs.filter((l) => /error|PAGEERROR|SCRIPT ERROR/i.test(l));
	console.log(`console errors: ${errs.length}`);
	if (errs.length) console.log(errs.join("\n"));
	await browser.close();
	server.close();
}
process.exit(code);
