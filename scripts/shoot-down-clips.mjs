/**
 * scripts/shoot-down-clips.mjs — Visual Review for task 120: the imported Labrador's
 * markable apex must read as a distinct lie-down for the down-family tricks
 * (Ligg / Legg deg / Sov) and stay an upright sit for Sitt. Rull is captured as a
 * known-distinct control (it already played a clearly different pose pre-task).
 *
 * For each trick: force it (__setTrick re-enters a fresh round), wait for the dog to
 * be in `offering` (the markable window), let the skeletal clip pose for a beat, then
 * shoot. The licensed packed Labrador loads by default in DEV (renderConfig.importedDog
 * = true, _licensed forced on), so this captures the REAL rig — the only place the clip
 * fix is visible (the CC0 placeholder has neither Sitting nor Lie clips).
 *
 * HEADLESS NOTE: swiftshader renders only a handful of frames in the production 800 ms
 * offering window, too few for the Sitting/Lie clip to pose from bind → seated/lying.
 * To Visual-Review in headless, temporarily widen BASE_SCHEDULER_TIMING (src/core/
 * tuning.ts) to e.g. { attemptInterval: 5000, activeSpan: 4000 } and bump the imported
 * MODEL_BUDGET_MS so the 19MB pack always settles in time — then REVERT both. A real
 * 60 fps browser poses the clip well inside 800 ms, so production needs no change.
 *
 *   PW_CHROME=/usr/bin/google-chrome node scripts/shoot-down-clips.mjs
 */
delete process.env.LD_LIBRARY_PATH;

import { chromium } from 'playwright-core';

const URL = process.env.URL ?? 'http://localhost:5173';
const OUT_DIR = process.env.OUT_DIR ?? '/tmp';
const PW_CHROME = process.env.PW_CHROME ?? '/usr/bin/google-chrome';

const browser = await chromium.launch({
  executablePath: PW_CHROME,
  args: ['--no-sandbox', '--disable-gpu', '--use-gl=swiftshader'],
});

const ctx = await browser.newContext({ viewport: { width: 390, height: 844 } });
const page = await ctx.newPage();

await page.goto(URL, { waitUntil: 'networkidle' });
await page.waitForFunction(() => typeof window.__setTrick === 'function');
// The imported licensed Labrador (19MB pack: fetch + AES decrypt + glTF parse of 113
// clips / 60 bones) settles in ~10s under headless swiftshader. The spinner starts
// `display:none`, so polling "hidden" returns immediately and races the procedural dog
// — wait a generous fixed window for the swap to land instead.
await page.waitForTimeout(15000);

async function waitForDog(want, timeoutMs = 6000) {
  try {
    await page.waitForFunction(
      (w) => document.getElementById('hud')?.dataset.dog === w,
      want,
      { timeout: timeoutMs, polling: 60 },
    );
    return true;
  } catch {
    return false;
  }
}

async function shootTrick(trickId, file, label) {
  await page.evaluate((id) => window.__setTrick(id), trickId);
  // The offering window is ~800ms (activeSpan) then ~1200ms idle. The sit/lie clips
  // are LOOPS (frame 0 ≈ the posed steady state), so a short settle inside the window
  // is enough — but we must SHOOT while still in offering. Retry across cycles until a
  // ~420ms-settled frame is confirmed still-offering, so the screenshot never lies.
  let captured = 'idle';
  for (let attempt = 0; attempt < 6; attempt++) {
    if (!(await waitForDog('offering'))) continue;
    // Widened offering window (review aid) gives the skeletal clip ample headless
    // frames to pose from bind → seated/lying before the shot.
    await page.waitForTimeout(900);
    captured = await page.evaluate(
      () => document.getElementById('hud')?.dataset.dog ?? null,
    );
    if (captured === 'offering') break;
  }
  await page.screenshot({ path: `${OUT_DIR}/${file}` });
  console.log(`${label.padEnd(12)} captured-as=${captured} -> ${file}`);
}

await shootTrick('sitt', 'down-0-sitt.png', 'Sitt');
await shootTrick('ligg', 'down-1-ligg.png', 'Ligg');
await shootTrick('legg-deg', 'down-2-leggdeg.png', 'Legg deg');
await shootTrick('rull', 'down-3-rull.png', 'Rull (ctrl)');

await ctx.close();
await browser.close();
console.log('\nDone — PNGs in', OUT_DIR);
