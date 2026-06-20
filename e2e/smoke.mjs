/**
 * e2e/smoke.mjs — Playwright smoke test for the core training flow.
 *
 * Prerequisites:
 *   1. Dev server must be running: `bun run dev` (http://localhost:5173)
 *   2. PW_CHROME env must point to the cached Chromium binary, e.g.:
 *      PW_CHROME="$HOME/.cache/ms-playwright/chromium-1169/chrome-linux/chrome"
 *
 * Usage:
 *   PW_CHROME="$HOME/.cache/ms-playwright/chromium-1169/chrome-linux/chrome" \
 *     bun run e2e
 *   (or: node e2e/smoke.mjs)
 */

// Nix glibc leaks in; let Chromium use system libs.
delete process.env.LD_LIBRARY_PATH;

import { chromium } from 'playwright-core';

const BASE_URL = process.env.E2E_URL ?? 'http://localhost:5173';

/** Poll fn until it returns true, or throw after timeoutMs. */
async function poll(fn, timeoutMs, intervalMs = 100) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    if (await fn()) return;
    await new Promise((r) => setTimeout(r, intervalMs));
  }
  throw new Error('poll timed out');
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

  // ── 2. Select screen: #hud-select visible + trick buttons present ─────────
  const selectVisible = await page.evaluate(() => {
    const el = document.querySelector('#hud-select');
    if (!el) return false;
    const s = getComputedStyle(el);
    return s.display !== 'none' && s.visibility !== 'hidden' && s.opacity !== '0';
  });
  if (!selectVisible) {
    console.error('E2E SMOKE FAIL: #hud-select is not visible on load');
    process.exit(1);
  }

  const hasSitt = await page.evaluate(() => {
    const btns = Array.from(document.querySelectorAll('button'));
    return btns.some((b) => b.textContent?.trim() === 'Sitt');
  });
  if (!hasSitt) {
    console.error('E2E SMOKE FAIL: trick button "Sitt" not found on select screen');
    process.exit(1);
  }

  // ── 3. Click "Sitt" → #hud-trick-label should contain "Sitt" ─────────────
  // Find + click the Sitt trick button
  await page.evaluate(() => {
    const btn = Array.from(document.querySelectorAll('button'))
      .find((b) => b.textContent?.trim() === 'Sitt');
    if (!btn) throw new Error('Sitt button not found');
    btn.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true, cancelable: true }));
  });

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
    console.error(`E2E SMOKE FAIL: #hud-trick-label did not include "Sitt" within 3s. Got: "${labelText}"`);
    process.exit(1);
  }

  // ── 4. Tap BRA repeatedly; assert bar progressed or a result appeared ─────
  // Dispatch ~20 pointerdown events on #hud-bra-btn, ~150ms apart.
  // Track the max bar width and any data-result seen across the tapping loop.
  let maxBarWidth = 0;
  let anyResult = false;

  const TAPS = 20;
  const TAP_INTERVAL_MS = 150;

  for (let i = 0; i < TAPS; i++) {
    // Dispatch the tap
    await page.evaluate(() => {
      const btn = document.querySelector('#hud-bra-btn');
      if (btn) {
        // BRA is now press-then-release: the mark commits on pointerup (so a swipe
        // can swap the phrase instead). A zero-movement down→up is a tap.
        btn.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true, cancelable: true }));
        btn.dispatchEvent(new PointerEvent('pointerup', { bubbles: true, cancelable: true }));
      }
    });

    // Sample bar width and result after each tap
    const { barWidth, result } = await page.evaluate(() => {
      const fill = document.querySelector('#hud-bar-fill');
      const resultEl = document.querySelector('#hud-result');
      const widthStr = fill ? (fill.style.width || '0%') : '0%';
      const w = parseFloat(widthStr) || 0;
      const dr = resultEl?.getAttribute('data-result') ?? '';
      return { barWidth: w, result: dr };
    });

    if (barWidth > maxBarWidth) maxBarWidth = barWidth;
    if (result && result.length > 0) anyResult = true;

    await new Promise((r) => setTimeout(r, TAP_INTERVAL_MS));
  }

  // After all taps, do a final longer poll (up to 6s total from now) to
  // capture any deferred progress that lands slightly after the last tap.
  try {
    await poll(async () => {
      const { barWidth, result } = await page.evaluate(() => {
        const fill = document.querySelector('#hud-bar-fill');
        const resultEl = document.querySelector('#hud-result');
        const w = parseFloat(fill?.style.width ?? '0') || 0;
        const dr = resultEl?.getAttribute('data-result') ?? '';
        return { barWidth: w, result: dr };
      });
      if (barWidth > maxBarWidth) maxBarWidth = barWidth;
      if (result && result.length > 0) anyResult = true;
      return maxBarWidth > 0 || anyResult;
    }, 6000, 150);
  } catch {
    // timed out; we'll check the tracked values below
  }

  if (maxBarWidth <= 0 && !anyResult) {
    console.error(
      `E2E SMOKE FAIL: after ${TAPS} BRA taps, bar never moved (max width: ${maxBarWidth}%) and no data-result appeared`
    );
    process.exit(1);
  }

  // ── All assertions passed ─────────────────────────────────────────────────
  console.log('E2E SMOKE PASS');
  await browser.close();
  process.exit(0);
} catch (err) {
  console.error('E2E SMOKE FAIL:', err?.message ?? err);
  if (browser) {
    try { await browser.close(); } catch { /* ignore close errors */ }
  }
  process.exit(1);
}
