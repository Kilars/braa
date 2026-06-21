/**
 * scripts/shoot-disengage.mjs — capture the disengagement walk-off + call-back
 * states (task 107) for Visual Review.
 *
 * Shoots phone-portrait PNGs of:
 *   1. engaged      — normal play (baseline, full meter)
 *   2. disengaged   — empty meter: dog trots to the frame edge, sits back-turned,
 *                     cool tint; the "tap to call back" pill shows
 *   3. called-back  — after a real BRA tap: dog re-engages, hint gone, combo broken
 *   4. disengaged-reduced-motion — same walk-off under prefers-reduced-motion
 *
 *   PW_CHROME=".../chrome" node scripts/shoot-disengage.mjs
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

async function enterDisengageRound(page) {
  await page.goto(URL, { waitUntil: 'networkidle' });
  await page.waitForFunction(
    () => typeof window.__setTrick === 'function' && typeof window.__setEngagement === 'function',
  );
  await page.evaluate(() => {
    window.__setTrick('sitt');
    document.getElementById('hud-stats')?.classList.remove('hud-gated');
    document.getElementById('hud-engagement')?.classList.remove('hud-gated');
  });
  await page.waitForTimeout(700);
}

function report(page) {
  return page.evaluate(() => {
    const hud = document.getElementById('hud');
    const hint = document.getElementById('hud-callback-hint');
    const eng = document.getElementById('hud-engagement');
    return {
      dogState: hud?.dataset.dog ?? null,
      hintVisible: hint?.classList.contains('visible') ?? false,
      engagementBeat: eng?.getAttribute('data-beat') ?? null,
      ariaValueNow: eng?.getAttribute('aria-valuenow') ?? null,
    };
  });
}

// ── Pass 1: full-motion engaged → disengaged → called-back ───────────────────
{
  const ctx = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const page = await ctx.newPage();
  await enterDisengageRound(page);

  // 1. engaged baseline
  await page.evaluate(() => window.__setEngagement(1.0));
  await page.waitForTimeout(500);
  await page.screenshot({ path: `${OUT_DIR}/disengage-1-engaged.png` });
  console.log(`engaged       ${JSON.stringify(await report(page))}`);

  // 2. disengaged (empty meter → walk-off)
  await page.evaluate(() => window.__setEngagement(0.0));
  await page.waitForTimeout(600);
  await page.screenshot({ path: `${OUT_DIR}/disengage-2-walkoff.png` });
  console.log(`walk-off      ${JSON.stringify(await report(page))}`);

  // 3. called-back — a real BRA tap (pointerdown+up) should call the dog back
  await page.evaluate(() => {
    const btn = document.getElementById('hud-bra-btn');
    if (!btn) return;
    const opts = { bubbles: true, cancelable: true, pointerId: 1, pointerType: 'touch' };
    btn.dispatchEvent(new PointerEvent('pointerdown', opts));
    btn.dispatchEvent(new PointerEvent('pointerup', opts));
  });
  await page.waitForTimeout(600);
  await page.screenshot({ path: `${OUT_DIR}/disengage-3-calledback.png` });
  console.log(`called-back   ${JSON.stringify(await report(page))}`);

  await ctx.close();
}

// ── Pass 2: reduced-motion walk-off ──────────────────────────────────────────
{
  const ctx = await browser.newContext({
    viewport: { width: 390, height: 844 },
    reducedMotion: 'reduce',
  });
  const page = await ctx.newPage();
  await enterDisengageRound(page);
  await page.evaluate(() => window.__setEngagement(0.0));
  await page.waitForTimeout(600);
  await page.screenshot({ path: `${OUT_DIR}/disengage-4-walkoff-reduced.png` });
  console.log(`walk-off (rm) ${JSON.stringify(await report(page))}`);
  await ctx.close();
}

await browser.close();
console.log('\nDone — PNGs in', OUT_DIR);
