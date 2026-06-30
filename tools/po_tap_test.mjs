// Focused: do the taps really score on the live site? Re-aim at the BRA button centre (y~670)
// and try BOTH a blind cadence AND apex-synced taps (tap when the gold ring is up).
import { writeFile } from "node:fs/promises";
import { chromium } from "playwright";
const SITE = process.env.BRA_SITE || "https://kilars.github.io/braa/";

const goldFn = (dataUrl) => new Promise((resolve) => {
	const img = new Image();
	img.onload = () => {
		const c = document.createElement("canvas"); c.width = img.width; c.height = img.height;
		const x = c.getContext("2d"); x.drawImage(img, 0, 0);
		const y0 = Math.floor(img.height * 0.62);
		const d = x.getImageData(0, y0, img.width, img.height - y0).data;
		let gold = 0;
		for (let i = 0; i < d.length; i += 4) { const r=d[i],g=d[i+1],b=d[i+2];
			if (r>180&&g>120&&g<230&&b<110&&(r-b)>90) gold++; }
		resolve(gold);
	};
	img.onerror = () => resolve(-1); img.src = dataUrl;
});

const browser = await chromium.launch({ args: ["--no-sandbox","--disable-dev-shm-usage","--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
const decoder = await browser.newPage(); await decoder.goto("about:blank");
await page.goto(SITE, { waitUntil: "load", timeout: 90000 });
await page.waitForFunction("window.__appReady === true", { timeout: 120000 });
await page.waitForTimeout(1500);

// Pass A: blind cadence at corrected BRA centre.
let r0 = await page.evaluate("(window.__bra_reaction_n||0)");
for (let i=0;i<60;i++){ await page.mouse.click(195,670); await page.waitForTimeout(150); }
let rA = await page.evaluate("(window.__bra_reaction_n||0)");
console.log(`PASS A blind cadence @ (195,670): marks = ${rA - r0}`);

// Pass B: apex-synced — poll gold, tap the instant the ring shows.
let rB0 = rA, synced = 0;
for (let i=0;i<400;i++){
	const buf = await page.screenshot({ type: "png" });
	const gold = await decoder.evaluate(goldFn, "data:image/png;base64,"+buf.toString("base64"));
	if (gold > 300) { await page.mouse.click(195,670); synced++; await page.waitForTimeout(900); }
	else await page.waitForTimeout(40);
	if (synced >= 8) break;
}
const rB = await page.evaluate("(window.__bra_reaction_n||0)");
console.log(`PASS B apex-synced: ${synced} taps fired on a visible ring -> marks = ${rB - rB0}`);
const after = await page.screenshot({ type: "png" }); await writeFile(".screenshots/po-tap-after.png", after);
await browser.close();
