// PO father-pass-16 composite play-test.
// Verifies 151 (owned-dog «Trener nå» + «Tren med [navn]» status pills now clear WCAG AA
// with a dark C_TAG_INK label on the muted green wash / green button) landed on the local
// licensed bundle, re-checks the signed-off surfaces, and hunts for new polish defects.
//
// Usage: env -u LD_LIBRARY_PATH node tools/po_pass16_drive.mjs http://localhost:8099/index.html

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
async function openCell(id) {
	const cells = await page.evaluate(() => window.__bra_kennel_cells || []);
	const cell = cells.find(c => c.id === id);
	if (!cell) { console.log(`SKIP ${id}`); return false; }
	await tapVp(cell.x, cell.y);
	await page.waitForTimeout(1100);
	return true;
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

	await page.screenshot({ path: ".screenshots/P16-01-training.png" });

	await openKennel();
	await page.screenshot({ path: ".screenshots/P16-02-kennel-grid.png" });
	const cells = await page.evaluate(() => window.__bra_kennel_cells || []);
	console.log(`cells (${cells.length}): [${cells.map(c => c.id).join(", ")}]`);

	// (A) Owned + active dog Bella → «Trener nå» pill (151 focus)
	if (await openCell("bella")) {
		await page.screenshot({ path: ".screenshots/P16-modal-bella-active.png" });
		await tapVp(40, 60); await page.waitForTimeout(700);
	}

	// (B) Free-adopt Trulte (secret easter egg) so a SECOND dog is owned + becomes active,
	//     then re-open Bella to surface the owned-but-not-active «Tren med Bella» switch pill.
	if (await openCell("trulte")) {
		await page.screenshot({ path: ".screenshots/P16-modal-trulte.png" });
		// «Adopter gratis ♥» CTA sits in the modal bottom action slot (~ y 1120 in godot space).
		await tapVp(360, 1120);
		await page.waitForTimeout(1200);
		await page.screenshot({ path: ".screenshots/P16-after-adopt-trulte.png" });
		await tapVp(40, 60); await page.waitForTimeout(700);
	}

	// Re-open Bella — now owned-but-not-active → «Tren med Bella» switch button (151 focus)
	if (await openCell("bella")) {
		await page.screenshot({ path: ".screenshots/P16-modal-bella-switch.png" });
		await tapVp(40, 60); await page.waitForTimeout(700);
	}

	// Close kennel → completion menu
	await tapVp(40, 60); await page.waitForTimeout(700);
	await tapVp(70, 32);
	await page.waitForTimeout(1200);
	await page.screenshot({ path: ".screenshots/P16-05-menu.png" });

	code = 0;
	console.log(`console errors: ${errs.length}`);
	if (errs.length) console.log(errs.slice(0, 8).join("\n"));
} catch (e) {
	console.error(`FAILED: ${e.message}`);
	await page.screenshot({ path: ".screenshots/P16-FAIL.png" }).catch(() => {});
} finally {
	await browser.close();
	process.exit(code);
}
