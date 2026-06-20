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
 *   - Apex signal: #hud[data-tell] attribute (tellStrength float 0→1, written every rAF by hud.ts:948).
 *     No production code changes needed — this attribute is already in the live DOM.
 *   - Tap BRA when data-tell >= APEX_THRESHOLD (near peak) to earn OK/PERFECT and fill the bar.
 *   - Assert mastery via: #hud-select becomes visible (app returns to select after mastery).
 *   - Assert payout: #hud-coins text before vs. after mastery.
 */

// Nix glibc leaks in; let Chromium use system libs.
delete process.env.LD_LIBRARY_PATH;

import { chromium } from 'playwright-core';

const BASE_URL = process.env.E2E_URL ?? 'http://localhost:5173';

// How close to the apex we need to be before tapping (0..1, 1 = perfect peak)
const APEX_THRESHOLD = 0.65;
// Overall deadline (ms) to drive a trick from fresh to mastery
const MASTERY_DEADLINE_MS = 90_000;
// How long to wait after a tap before polling again (avoid double-tapping same apex)
const POST_TAP_COOLDOWN_MS = 400;
// Poll interval inside the apex loop
const APEX_POLL_MS = 40;
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

/** Read tellStrength from the data-tell attribute on #hud (written every rAF). */
async function readTellStrength(page) {
  const val = await page.evaluate(() => document.querySelector('#hud')?.getAttribute('data-tell') ?? '0');
  return parseFloat(val) || 0;
}

/** Read current bar fill width (0..100). */
async function readBarWidth(page) {
  const val = await page.evaluate(() => {
    const fill = document.querySelector('#hud-bar-fill');
    return parseFloat(fill?.style.width ?? '0') || 0;
  });
  return val;
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

  // ── 5. Play to mastery by timing taps to the apex ─────────────────────────
  // Poll data-tell on #hud (tellStrength 0→1); tap BRA when near peak (>= APEX_THRESHOLD).
  // Loop until #hud-select is visible (mastery triggers showSelect) or deadline expires.
  let masteryReached = false;
  let maxBarWidth = 0;
  let tapCount = 0;
  let lastTapAt = 0;

  const masteryDeadline = Date.now() + MASTERY_DEADLINE_MS;

  while (Date.now() < masteryDeadline) {
    // Check if mastery already happened (select screen appeared)
    const selectNow = await isSelectVisible(page);
    if (selectNow) {
      masteryReached = true;
      break;
    }

    // Read current bar width (track max for diagnostics)
    const barW = await readBarWidth(page);
    if (barW > maxBarWidth) maxBarWidth = barW;

    // Read apex signal
    const tell = await readTellStrength(page);

    const now = Date.now();
    const sinceLastTap = now - lastTapAt;

    if (tell >= APEX_THRESHOLD && sinceLastTap >= POST_TAP_COOLDOWN_MS) {
      // Tap BRA at the apex
      await page.evaluate(() => {
        const btn = document.querySelector('#hud-bra-btn');
        if (btn) {
          // BRA is press-then-release: the mark commits on pointerup (so a horizontal
          // swipe can swap the phrase). A zero-movement down→up is a tap.
          btn.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true, cancelable: true }));
          btn.dispatchEvent(new PointerEvent('pointerup', { bubbles: true, cancelable: true }));
        }
      });
      tapCount++;
      lastTapAt = Date.now();
      // Brief pause after tap (avoid double-tapping same window)
      await new Promise((r) => setTimeout(r, POST_TAP_COOLDOWN_MS));
    } else {
      await new Promise((r) => setTimeout(r, APEX_POLL_MS));
    }
  }

  // Give select screen time to render after the mastery transition
  if (!masteryReached) {
    await new Promise((r) => setTimeout(r, POST_MASTERY_WAIT_MS));
    masteryReached = await isSelectVisible(page);
  }

  if (!masteryReached) {
    const finalBar = await readBarWidth(page);
    console.error(
      `E2E FULL-LOOP FAIL: trick never mastered within ${MASTERY_DEADLINE_MS / 1000}s. ` +
      `Max bar width reached: ${maxBarWidth.toFixed(1)}%, final bar: ${finalBar.toFixed(1)}%, taps: ${tapCount}`
    );
    process.exit(1);
  }

  console.log(`  mastery reached after ${tapCount} apex tap(s); max bar: ${maxBarWidth.toFixed(1)}%`);

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
