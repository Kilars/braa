/**
 * scripts/shoot-distractor-coach.mjs — capture the distractor-reveal coach pill
 * (task 109) for Visual Review.
 *
 * Shoots phone-portrait PNGs of:
 *   1. distractor-coach        — masteredCount === 1 band: the gold "ikke mark det
 *                                gale" pill is visible above the trick label
 *   2. core-verb-coach         — masteredCount === 0 band: the short core-verb pill
 *                                (proves the two pills are distinct + exclusive)
 *   3. distractor-dismissed     — after a real scoring BRA tap: the pill is gone
 *   4. no-coach-count2          — masteredCount === 2 band: no coach (self-limits)
 *   5. distractor-reduced-motion — the same pill under prefers-reduced-motion
 *
 *   PW_CHROME=".../chrome" node scripts/shoot-distractor-coach.mjs
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

async function enterRound(page, { masteredCount }) {
  await page.waitForFunction(
    () =>
      typeof window.__setTrick === 'function' &&
      typeof window.__setMasteredCount === 'function',
  );
  await page.evaluate(count => {
    window.__setTrick('sitt'); // enters training; trick label = "Sitt"
    window.__setMasteredCount(count); // sets onboarding band + refreshes coach
  }, masteredCount);
  await page.waitForTimeout(500);
}

function coachReport(page) {
  return page.evaluate(() => {
    const coach = document.getElementById('hud-coach');
    return {
      present: !!coach,
      gated: coach?.classList.contains('hud-gated') ?? null,
      wide: coach?.classList.contains('coach-wide') ?? null,
      text: coach?.textContent ?? null,
      ariaLive: coach?.getAttribute('aria-live') ?? null,
    };
  });
}

// ── 1. distractor coach (count 1) ────────────────────────────────────────────
{
  const ctx = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const page = await ctx.newPage();
  await page.goto(URL, { waitUntil: 'networkidle' });
  await enterRound(page, { masteredCount: 1 });
  await page.screenshot({ path: `${OUT_DIR}/distractor-1-coach.png` });
  console.log(`distractor-coach    ${JSON.stringify(await coachReport(page))}`);

  // ── 3. dismissed after a real scoring BRA tap ──────────────────────────────
  const peak = await page.evaluate(() => window.__bra?.nextPeak?.() ?? null);
  if (peak !== null) {
    const waitMs = await page.evaluate(p => Math.max(0, p - performance.now()), peak);
    await page.waitForTimeout(Math.min(waitMs, 4000));
    await page.evaluate(() => {
      const btn = document.getElementById('hud-bra-btn');
      const opts = { bubbles: true, cancelable: true, pointerId: 1, pointerType: 'touch' };
      btn?.dispatchEvent(new PointerEvent('pointerdown', opts));
      btn?.dispatchEvent(new PointerEvent('pointerup', opts));
    });
    await page.waitForTimeout(400);
    await page.screenshot({ path: `${OUT_DIR}/distractor-3-dismissed.png` });
    console.log(`after-scoring-mark  ${JSON.stringify(await coachReport(page))}`);
  } else {
    console.log('after-scoring-mark  (no pending peak — skipped)');
  }
  await ctx.close();
}

// ── 2. core-verb coach (count 0) — distinct, exclusive pill ───────────────────
{
  const ctx = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const page = await ctx.newPage();
  await page.goto(URL, { waitUntil: 'networkidle' });
  await enterRound(page, { masteredCount: 0 });
  await page.screenshot({ path: `${OUT_DIR}/distractor-2-coreverb.png` });
  console.log(`core-verb-coach     ${JSON.stringify(await coachReport(page))}`);
  await ctx.close();
}

// ── 4. no coach at count 2 (band self-limits) ─────────────────────────────────
{
  const ctx = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const page = await ctx.newPage();
  await page.goto(URL, { waitUntil: 'networkidle' });
  await enterRound(page, { masteredCount: 2 });
  await page.screenshot({ path: `${OUT_DIR}/distractor-4-count2.png` });
  console.log(`no-coach-count2     ${JSON.stringify(await coachReport(page))}`);
  await ctx.close();
}

// ── 5. distractor coach under reduced motion ──────────────────────────────────
{
  const ctx = await browser.newContext({
    viewport: { width: 390, height: 844 },
    reducedMotion: 'reduce',
  });
  const page = await ctx.newPage();
  await page.goto(URL, { waitUntil: 'networkidle' });
  await enterRound(page, { masteredCount: 1 });
  await page.screenshot({ path: `${OUT_DIR}/distractor-5-reduced-motion.png` });
  console.log(`reduced-motion      ${JSON.stringify(await coachReport(page))}`);
  await ctx.close();
}

await browser.close();
