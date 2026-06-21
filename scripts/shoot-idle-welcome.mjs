/**
 * scripts/shoot-idle-welcome.mjs — capture the idle "welcome back" toast
 * (task 115) for Visual Review.
 *
 * Shoots phone-portrait PNGs of:
 *   1. idle-welcome           — the green "Velkommen tilbake! +N 🪙" toast on the
 *                               select screen (the kennel idle trickle on return)
 *   2. idle-welcome-reduced   — the same toast under prefers-reduced-motion
 *                               (no slide; the pill simply appears, D13)
 *
 *   PW_CHROME=".../chrome" node scripts/shoot-idle-welcome.mjs
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

async function showToast(page, coins) {
  await page.waitForFunction(() => typeof window.__showIdleWelcome === 'function');
  await page.evaluate(c => window.__showIdleWelcome(c), coins);
  await page.waitForTimeout(450); // let the entrance animation settle
}

function toastReport(page) {
  return page.evaluate(() => {
    const t = document.getElementById('hud-idle-welcome');
    const cs = t ? getComputedStyle(t) : null;
    return {
      present: !!t,
      gated: t?.classList.contains('hud-gated') ?? null,
      text: t?.textContent ?? null,
      ariaLive: t?.getAttribute('aria-live') ?? null,
      opacity: cs?.opacity ?? null,
      visibility: cs?.visibility ?? null,
    };
  });
}

// ── 1. idle-welcome toast on the select screen ───────────────────────────────
{
  const ctx = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const page = await ctx.newPage();
  await page.goto(URL, { waitUntil: 'networkidle' });
  await showToast(page, 37);
  await page.screenshot({ path: `${OUT_DIR}/idle-welcome-1.png` });
  console.log(`idle-welcome        ${JSON.stringify(await toastReport(page))}`);
  await ctx.close();
}

// ── 2. idle-welcome toast under reduced motion ───────────────────────────────
{
  const ctx = await browser.newContext({
    viewport: { width: 390, height: 844 },
    reducedMotion: 'reduce',
  });
  const page = await ctx.newPage();
  await page.goto(URL, { waitUntil: 'networkidle' });
  await showToast(page, 37);
  await page.screenshot({ path: `${OUT_DIR}/idle-welcome-2-reduced.png` });
  console.log(`reduced-motion      ${JSON.stringify(await toastReport(page))}`);
  await ctx.close();
}

await browser.close();
