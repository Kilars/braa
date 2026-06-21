/**
 * scripts/shoot-beats.mjs — capture the intermediate disengage beats on the dog
 * (task 112) for Visual Review: itch → flop → bark, plus the engaged baseline and
 * the empty-meter walk-off, on a phone-portrait viewport.
 *
 * The intermediate beats replace the dog's IDLE state only (they never mask an active
 * correct offering), so each capture polls `#hud[data-dog]` until the dog is actually
 * in the beat (i.e. an idle lull in the timeline) before shooting — otherwise we'd
 * catch an `offering` frame and the screenshot would lie.
 *
 *   PW_CHROME=".../chrome" node scripts/shoot-beats.mjs
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

async function enterRound(page) {
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
    const eng = document.getElementById('hud-engagement');
    return {
      dogState: hud?.dataset.dog ?? null,
      engagementBeat: eng?.getAttribute('data-beat') ?? null,
      ariaValueNow: eng?.getAttribute('aria-valuenow') ?? null,
    };
  });
}

/** Wait until the dog is in `want` (an idle-lull beat), up to timeoutMs. */
async function waitForDog(page, want, timeoutMs = 4000) {
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

async function shootBeat(page, level, want, file, label, twoPhase = false) {
  await page.evaluate((l) => window.__setEngagement(l), level);
  // The intermediate beats (itch/flop/bark) only show in the timeline's idle gap and
  // flip back to `offering` when the next attempt opens. Wait for `offering` FIRST, then
  // for the beat, so we land at the START of the gap with the full lull ahead — otherwise
  // the screenshot can race the cycle and catch an `offering` frame.
  if (twoPhase) await waitForDog(page, 'offering', 4000);
  const reached = want === null ? true : await waitForDog(page, want);
  await page.screenshot({ path: `${OUT_DIR}/${file}` });
  const r = await report(page);
  const ok = want === null || r.dogState === want;
  console.log(`${label.padEnd(14)} reached=${reached} captured-as=${r.dogState} ${ok ? 'OK' : '** MISSED **'} ${JSON.stringify(r)}`);
}

// ── Pass 1: full-motion engaged → itch → flop → bark → walk-off ──────────────
{
  const ctx = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const page = await ctx.newPage();
  await enterRound(page);

  await shootBeat(page, 1.0, 'idle', 'beats-0-engaged.png', 'engaged', true);
  await shootBeat(page, 0.6, 'itch', 'beats-1-itch.png', 'itch', true);
  await shootBeat(page, 0.4, 'flop', 'beats-2-flop.png', 'flop', true);
  await shootBeat(page, 0.15, 'bark', 'beats-3-bark.png', 'bark', true);
  await shootBeat(page, 0.0, 'disengaged', 'beats-4-walkoff.png', 'walk-off');

  await ctx.close();
}

// ── Pass 2: reduced-motion (each beat must still read via pose + tint, D13) ───
{
  const ctx = await browser.newContext({
    viewport: { width: 390, height: 844 },
    reducedMotion: 'reduce',
  });
  const page = await ctx.newPage();
  await enterRound(page);

  await shootBeat(page, 0.6, 'itch', 'beats-rm-1-itch.png', 'itch (rm)', true);
  await shootBeat(page, 0.4, 'flop', 'beats-rm-2-flop.png', 'flop (rm)', true);
  await shootBeat(page, 0.15, 'bark', 'beats-rm-3-bark.png', 'bark (rm)', true);

  await ctx.close();
}

await browser.close();
console.log('\nDone — PNGs in', OUT_DIR);
