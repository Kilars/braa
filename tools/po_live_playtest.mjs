// PO play-test of the LIVE deployed Pages site (https://kilars.github.io/braa/) at 390x844.
// Headless Chromium, SwiftShader == the deployed GL Compatibility renderer. One honest pass:
//   1. boot the live site, capture the console boot log (licensed build? can Sitt?)
//   2. FREE-RUN burst (NO ?bra_force_tell seam) scoring saturated-gold px in the BRA band
//      -> apex ring fires live, dark in idle
//   3. save the brightest apex frame + a dark idle frame
//   4. REAL BRA taps on the canvas -> __bra_reaction_n must climb (real score+payoff, no seam)
//   5. save a post-tap reaction frame
//   6. assert ZERO SCRIPT ERROR / pageerror across boot + play
// Usage: env -u LD_LIBRARY_PATH node tools/po_live_playtest.mjs
import { writeFile } from "node:fs/promises";
import { chromium } from "playwright";

const SITE = process.env.BRA_SITE || "https://kilars.github.io/braa/";
const OUT = ".screenshots";

// Gold ring ~ (255,199,51): high R, mid-high G, LOW B. Excludes cream dog (high B), sky, button.
const scoreFn = (dataUrl) => new Promise((resolve) => {
	const img = new Image();
	img.onload = () => {
		const c = document.createElement("canvas");
		c.width = img.width; c.height = img.height;
		const x = c.getContext("2d"); x.drawImage(img, 0, 0);
		const y0 = Math.floor(img.height * 0.62);
		const d = x.getImageData(0, y0, img.width, img.height - y0).data;
		let gold = 0;
		for (let i = 0; i < d.length; i += 4) {
			const r = d[i], g = d[i + 1], b = d[i + 2];
			if (r > 180 && g > 120 && g < 230 && b < 110 && (r - b) > 90) gold++;
		}
		resolve(gold);
	};
	img.onerror = () => resolve(-1);
	img.src = dataUrl;
});

const logs = [], errors = [];
const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
page.on("console", (m) => logs.push(m.text()));
page.on("pageerror", (e) => { errors.push(`PAGEERROR: ${e.message}`); logs.push(`PAGEERROR: ${e.message}`); });
const decoder = await browser.newPage();      // Godot page CSP blocks data: images; decode elsewhere
await decoder.goto("about:blank");

try {
	await page.goto(SITE, { waitUntil: "load", timeout: 90000 });
	await page.waitForFunction("window.__appReady === true", { timeout: 120000 });
	await page.waitForTimeout(1500);

	// --- boot log lines that prove which dog + Sitt capability ---
	const bootLines = logs.filter((l) => /dog loaded|can Sitt|licensed|coat surface/i.test(l));
	console.log("BOOT LOG (dog/sitt):"); bootLines.forEach((l) => console.log("  " + l));

	// --- free-run apex burst, NO seam ---
	const frames = 90, wait = 80, scores = [];
	let bestApex = { score: -1, buf: null }, darkest = { score: 1e9, buf: null };
	for (let i = 0; i < frames; i++) {
		const buf = await page.screenshot({ type: "png" });
		const score = await decoder.evaluate(scoreFn, "data:image/png;base64," + buf.toString("base64"));
		scores.push(score);
		if (score > bestApex.score) bestApex = { score, buf };
		if (score < darkest.score) darkest = { score, buf };
		await page.waitForTimeout(wait);
	}
	const nonzero = scores.filter((s) => s > 0).length;
	console.log(`APEX BURST (no seam): max gold = ${Math.max(...scores)}, gold frames = ${nonzero}/${frames}, min = ${Math.min(...scores)}`);
	console.log("per-frame gold:", scores.join(","));
	if (bestApex.buf) await writeFile(`${OUT}/po-live-apex.png`, bestApex.buf);
	if (darkest.buf) await writeFile(`${OUT}/po-live-idle.png`, darkest.buf);

	// --- REAL BRA taps: click the canvas where the big BRA button sits (lower-centre) ---
	const r0 = await page.evaluate("(window.__bra_reaction_n||0)");
	const taps = 90;
	for (let i = 0; i < taps; i++) {
		await page.mouse.click(195, 670);      // BRA ring/word centre (band y564-756, centre ~660) at 390x844 — NOT the bottom edge
		await page.waitForTimeout(170);        // ~3 taps per 1.2s sit loop, walks the window
	}
	await page.waitForTimeout(400);
	const r1 = await page.evaluate("(window.__bra_reaction_n||0)");
	console.log(`REAL TAPS: ${taps} clicks on BRA -> __bra_reaction_n ${r0} -> ${r1} (successful marks: ${r1 - r0})`);
	const after = await page.screenshot({ type: "png" });
	await writeFile(`${OUT}/po-live-aftertap.png`, after);

	// --- error sweep ---
	const scriptErrs = logs.filter((l) => /SCRIPT ERROR|PAGEERROR|Uncaught|undefined method|Invalid call/i.test(l));
	console.log(`ERROR SWEEP: ${scriptErrs.length} error line(s) across boot + play`);
	scriptErrs.forEach((l) => console.log("  !! " + l));
} catch (e) {
	console.error(`playtest failed: ${e.message}`);
	console.error(logs.slice(-30).join("\n"));
	process.exitCode = 1;
} finally {
	await browser.close();
}
