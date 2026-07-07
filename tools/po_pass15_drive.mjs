// PO father-pass-15 composite play-test.
// Verifies 150 (modal header band now uses the calm _cell_surface, not the loud per-dog
// band_tint) landed on the local licensed bundle, re-checks the signed-off surfaces
// (training / kennel grid / modals / completion menu), and hunts for new polish defects.
//
// Usage: env -u LD_LIBRARY_PATH node tools/po_pass15_drive.mjs http://localhost:8099/index.html

import { chromium } from "playwright";
import { mkdir } from "node:fs/promises";

const base = process.argv[2] || "http://localhost:8099/index.html";
const W = 390, H = 844, GODOT_W = 720, GODOT_H = 1280;
await mkdir(".screenshots", { recursive: true });
const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport: { width: W, height: H } });
const errs = [];
page.on("console", m => { if (m.type() === "error") errs.push(m.text()); });

async function tapVp(x, y) {
	const box = await page.locator("canvas").boundingBox();
	const vp = await page.evaluate(() => window.__bra_viewport || null);
	const sx = box.width  / (vp ? vp[0] : GODOT_W);
	const sy = box.height / (vp ? vp[1] : GODOT_H);
	await page.mouse.click(box.x + x * sx, box.y + y * sy);
}
async function openKennel() {
	await tapVp(204, 32);
	await page.waitForFunction("window.__bra_kennel_open === true", undefined, { timeout: 12000 });
	await page.waitForTimeout(900);
}

let code = 1;
try {
	const url = base + (base.includes("?") ? "&" : "?") + "bra_autotap=1";
	await page.goto(url, { waitUntil: "load", timeout: 90000 });
	await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
	await page.waitForTimeout(2200);
	console.log("app ready");
	const boot = await page.evaluate(() => window.__bra_boot_log || null);
	if (boot) console.log("BOOT:", JSON.stringify(boot).slice(0, 300));

	await page.screenshot({ path: ".screenshots/P15-01-training.png" });

	await openKennel();
	await page.screenshot({ path: ".screenshots/P15-02-kennel-grid.png" });
	const cells = await page.evaluate(() => window.__bra_kennel_cells || []);
	console.log(`cells (${cells.length}): [${cells.map(c => c.id).join(", ")}]`);

	// Modals — one per rarity tier + owned + secret; the 150 band fix is the focus.
	const probe = ["bella", "nova", "sol", "trulte", "balder", "pontus", "sniff", "lykke"];
	for (const id of probe) {
		const cell = cells.find(c => c.id === id);
		if (!cell) { console.log(`SKIP ${id}`); continue; }
		await tapVp(cell.x, cell.y);
		await page.waitForTimeout(1100);
		await page.screenshot({ path: `.screenshots/P15-modal-${id}.png` });
		await tapVp(40, 60);   // close via backdrop
		await page.waitForTimeout(700);
	}

	// Close kennel → training → completion menu
	await tapVp(40, 60);
	await page.waitForTimeout(700);
	await tapVp(70, 32);       // Triks pill
	await page.waitForTimeout(1200);
	await page.screenshot({ path: ".screenshots/P15-05-menu.png" });

	code = 0;
	console.log(`console errors: ${errs.length}`);
	if (errs.length) console.log(errs.slice(0, 8).join("\n"));
} catch (e) {
	console.error(`FAILED: ${e.message}`);
	await page.screenshot({ path: ".screenshots/P15-FAIL.png" }).catch(() => {});
} finally {
	await browser.close();
	process.exit(code);
}
