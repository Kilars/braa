/**
 * e2e/full-loop.mjs — Deep e2e: play a trick to mastery and assert payout + return-to-select.
 *
 * Prerequisites:
 *   1. Dev server must be running: `bun run dev` (http://localhost:5173)
 *   2. PW_CHROME env must point to the cached Chromium binary.
 *
 * Usage:
 *   PW_CHROME="$HOME/.cache/ms-playwright/chromium-1169/chrome-linux/chrome" \
 *     bun run e2e
 *
 * Strategy:
 *   - Apex timing: the DEV hook window.__bra.nextPeak() returns the performance.now()
 *     timestamp of the soonest upcoming attempt peak. We schedule the BRA tap AT that
 *     instant with an in-browser setTimeout, so the tap lands exactly on the apex →
 *     PERFECT/OK and the bar fills.
 *   - Why not the visual data-tell signal? Headless Chromium software-renders the
 *     Babylon WebGL scene (no GPU), which throttles requestAnimationFrame to ~3 fps
 *     under load. The rAF-driven data-tell is then too stale to time a ~400 ms window,
 *     so every tap missed. setTimeout is NOT rAF-bound, so peak-timed taps are reliable
 *     regardless of render rate. Scoring itself runs synchronously on pointerup, so it's
 *     unaffected by the frame rate.
 *   - Assert mastery via: app returns to 'select' (window.__bra.screen()).
 *   - Assert payout: window.__bra.coins() before vs. after mastery.
 */

// Nix glibc leaks in; let Chromium use system libs.
delete process.env.LD_LIBRARY_PATH;

import { chromium } from 'playwright-core';

const BASE_URL = process.env.E2E_URL ?? 'http://localhost:5173';

// Overall deadline (ms) to drive a trick from fresh to mastery
const MASTERY_DEADLINE_MS = 90_000;
// How long to wait after a tap before scheduling the next (avoid re-tapping same apex)
const POST_TAP_COOLDOWN_MS = 250;
// Cap on how far ahead we'll wait for a peak in one scheduling step (ms). Keeps the
// outer loop responsive (peaks are ~attemptInterval apart, well under this).
const MAX_PEAK_WAIT_MS = 4000;
// How long to wait after mastery fires for the select screen to appear
const POST_MASTERY_WAIT_MS = 3000;

/** Poll fn until it returns true, or throw after timeoutMs. */
async function poll(fn, timeoutMs, intervalMs = 100) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    if (await fn()) return;
    await new Promise((r) => setTimeout(r, intervalMs));
  }
  throw new Error('poll timed out');
}

/**
 * Read the current coin balance.
 * Prefers the DEV-only window.__bra.coins() hook (always current, survives screen transitions).
 * Falls back to scraping #hud-coins text ("🪙 42" → 42) for safety.
 */
async function readCoins(page) {
  return page.evaluate(() => {
    // DEV hook: always reflects the live profile.coins even when #hud is hidden
    const hook = (window).__bra;
    if (hook && typeof hook.coins === 'function') return hook.coins();
    // Fallback: DOM scrape
    const text = document.querySelector('#hud-coins')?.textContent ?? '';
    const match = text.match(/(\d+)/);
    return match ? parseInt(match[1], 10) : 0;
  });
}

/** Returns true when #hud-select is visible (display != none, not hidden). */
async function isSelectVisible(page) {
  return page.evaluate(() => {
    const el = document.querySelector('#hud-select');
    if (!el) return false;
    const s = getComputedStyle(el);
    return s.display !== 'none' && s.visibility !== 'hidden' && s.opacity !== '0';
  });
}

let browser = null;

try {
  // ── 1. Launch ─────────────────────────────────────────────────────────────
  browser = await chromium.launch({
    executablePath: process.env.PW_CHROME,
    args: ['--no-sandbox', '--disable-gpu'],
  });
  const ctx = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const page = await ctx.newPage();

  await page.goto(BASE_URL, { waitUntil: 'networkidle' });

  // ── 2. Verify select screen is visible ──────────────────────────────────
  const selectVisible = await isSelectVisible(page);
  if (!selectVisible) {
    console.error('E2E FULL-LOOP FAIL: #hud-select not visible on load');
    process.exit(1);
  }

  // ── 3. Click "Sitt" to enter training ────────────────────────────────────
  const hasSitt = await page.evaluate(() =>
    Array.from(document.querySelectorAll('button')).some((b) => b.textContent?.trim() === 'Sitt')
  );
  if (!hasSitt) {
    console.error('E2E FULL-LOOP FAIL: trick button "Sitt" not found on select screen');
    process.exit(1);
  }

  await page.evaluate(() => {
    const btn = Array.from(document.querySelectorAll('button'))
      .find((b) => b.textContent?.trim() === 'Sitt');
    if (!btn) throw new Error('Sitt button not found');
    btn.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true, cancelable: true }));
  });

  // Wait for trick label to confirm we're in training
  try {
    await poll(async () => {
      const text = await page.evaluate(() =>
        document.querySelector('#hud-trick-label')?.textContent ?? ''
      );
      return text.includes('Sitt');
    }, 3000, 100);
  } catch {
    const labelText = await page.evaluate(() =>
      document.querySelector('#hud-trick-label')?.textContent ?? '(not found)'
    );
    console.error(`E2E FULL-LOOP FAIL: #hud-trick-label did not include "Sitt" within 3s. Got: "${labelText}"`);
    process.exit(1);
  }

  // ── 4. Read coins BEFORE mastery ─────────────────────────────────────────
  // Give HUD one render cycle to update coins display
  await new Promise((r) => setTimeout(r, 200));
  const coinsBefore = await readCoins(page);
  console.log(`  coins before mastery: ${coinsBefore}`);

  // ── 5. Play to mastery by timing taps to the exact apex ───────────────────
  // For each upcoming attempt, ask the DEV hook for its peak timestamp and schedule
  // a tap AT that instant inside the browser (setTimeout — not rAF-bound). This lands
  // a PERFECT/OK on each attempt and fills the learned bar, deterministically, even
  // when headless rendering crawls. Loop until the app returns to 'select' (mastery)
  // or the deadline expires.
  let masteryReached = false;
  let maxLearned = 0;
  let tapCount = 0;

  const masteryDeadline = Date.now() + MASTERY_DEADLINE_MS;

  while (Date.now() < masteryDeadline) {
    // Mastery returns the app to the select screen — check via the DEV hook.
    const screen = await page.evaluate(() => window.__bra?.screen?.() ?? 'training');
    if (screen === 'select') {
      masteryReached = true;
      break;
    }

    // Schedule + perform one peak-timed tap entirely inside the browser, so the tap
    // lands on the apex regardless of CDP latency or render frame rate.
    //
    // Precision matters: the PERFECT band is ±80 ms (it narrows to ±48 ms once a
    // FALSE_MARK triggers the 3 s confuse debuff), but a single software-WebGL frame
    // blocks the main thread for ~300 ms, so a plain setTimeout fires too late and the
    // tap overshoots the window → MISS/FALSE_MARK → confusion spiral. So we sleep most
    // of the gap with setTimeout (yields the thread, lets frames render), then BUSY-WAIT
    // the final SPIN_MS. SPIN_MS (350) > one frame (~300), so even a one-frame-late
    // setTimeout still hands off to the busy-wait before the peak; the busy-wait then
    // holds the single JS thread (no frame can preempt it) until the exact peak, landing
    // a reliable PERFECT.
    const SPIN_MS = 350;
    const tapped = await page.evaluate(async ({ maxWait, spinMs }) => {
      const hook = window.__bra;
      const peak = hook?.nextPeak?.() ?? null;
      if (peak === null) return { tapped: false, reason: 'no-peak' };
      const wait = peak - performance.now();
      if (wait > maxWait) return { tapped: false, reason: 'too-far' };
      if (wait < -spinMs) return { tapped: false, reason: 'passed' };
      const sleep = wait - spinMs;
      if (sleep > 0) await new Promise((r) => setTimeout(r, sleep));
      // Precise busy-wait to the exact peak (no yield → no frame can preempt).
      while (performance.now() < peak) { /* spin */ }
      const btn = document.querySelector('#hud-bra-btn');
      if (!btn) return { tapped: false, reason: 'no-btn' };
      // BRA is press-then-release: the mark commits on pointerup. A zero-movement
      // down→up is a tap (a horizontal drag would instead swap the phrase).
      btn.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true, cancelable: true }));
      btn.dispatchEvent(new PointerEvent('pointerup', { bubbles: true, cancelable: true }));
      return { tapped: true, learned: hook?.learnedBar?.() ?? 0, screen: hook?.screen?.() ?? 'training' };
    }, { maxWait: MAX_PEAK_WAIT_MS, spinMs: SPIN_MS });

    if (tapped.tapped) {
      tapCount++;
      if (typeof tapped.learned === 'number' && tapped.learned > maxLearned) maxLearned = tapped.learned;
      if (tapped.screen === 'select') { masteryReached = true; break; }
      // Cooldown so we don't re-tap the same window before the next peak appears.
      await new Promise((r) => setTimeout(r, POST_TAP_COOLDOWN_MS));
    } else {
      // No tappable peak right now (between timeline segments) — brief poll.
      await new Promise((r) => setTimeout(r, 60));
    }
  }

  // Give the select screen time to render after the mastery transition.
  if (!masteryReached) {
    await new Promise((r) => setTimeout(r, POST_MASTERY_WAIT_MS));
    masteryReached = (await page.evaluate(() => window.__bra?.screen?.() ?? 'training')) === 'select'
      || (await isSelectVisible(page));
  }

  if (!masteryReached) {
    const finalLearned = await page.evaluate(() => window.__bra?.learnedBar?.() ?? 0);
    console.error(
      `E2E FULL-LOOP FAIL: trick never mastered within ${MASTERY_DEADLINE_MS / 1000}s. ` +
      `Max learned: ${maxLearned.toFixed(1)}%, final learned: ${finalLearned.toFixed(1)}%, taps: ${tapCount}`
    );
    process.exit(1);
  }

  console.log(`  mastery reached after ${tapCount} apex tap(s); max learned: ${maxLearned.toFixed(1)}%`);

  // ── 6. Assert payout: coins increased ────────────────────────────────────
  // Give HUD a moment to re-render after mastery + select
  await new Promise((r) => setTimeout(r, 300));
  const coinsAfter = await readCoins(page);
  console.log(`  coins after mastery: ${coinsAfter}`);

  if (coinsAfter <= coinsBefore) {
    console.error(
      `E2E FULL-LOOP FAIL: coins did not increase after mastery. ` +
      `Before: ${coinsBefore}, after: ${coinsAfter}`
    );
    process.exit(1);
  }

  // ── 7. Assert return-to-select ────────────────────────────────────────────
  const selectAfterMastery = await isSelectVisible(page);
  if (!selectAfterMastery) {
    console.error('E2E FULL-LOOP FAIL: #hud-select is not visible after mastery');
    process.exit(1);
  }

  // ── All assertions passed ─────────────────────────────────────────────────
  console.log('E2E FULL-LOOP PASS');
  await browser.close();
  process.exit(0);
} catch (err) {
  console.error('E2E FULL-LOOP FAIL:', err?.message ?? err);
  if (browser) {
    try { await browser.close(); } catch { /* ignore close errors */ }
  }
  process.exit(1);
}
