/**
 * scripts/shoot-engagement.mjs — capture the HUD engagement mood meter at each
 * disengage beat (engaged → itch → flop → bark → walk-off) for Visual Review.
 *
 * Enters a Sitt round, force-reveals the (economy-gated) meter, and drives
 * window.__setEngagement to each level, shooting one phone-portrait PNG per beat.
 *
 *   PW_CHROME=".../chrome" node scripts/shoot-engagement.mjs
 */
delete process.env.LD_LIBRARY_PATH;

import { chromium } from 'playwright-core';

const URL = process.env.URL ?? 'http://localhost:5173';
const OUT_DIR = process.env.OUT_DIR ?? '/tmp';

const BEATS = [
  { name: 'engaged', level: 1.0 },
  { name: 'itch', level: 0.6 },
  { name: 'flop', level: 0.35 },
  { name: 'bark', level: 0.1 },
  { name: 'walkoff', level: 0.0 },
];

const browser = await chromium.launch({
  executablePath: process.env.PW_CHROME,
  args: ['--no-sandbox', '--disable-gpu'],
});
const ctx = await browser.newContext({ viewport: { width: 390, height: 844 } });
const page = await ctx.newPage();
await page.goto(URL, { waitUntil: 'networkidle' });

// Wait for the dev hooks (registered after the Babylon scene import resolves).
await page.waitForFunction(() => typeof window.__setTrick === 'function' && typeof window.__setEngagement === 'function');

// Enter a training round and un-gate the stats cluster (stats + meter reveal
// together at the economy stage in real play) so it renders for review.
await page.evaluate(() => {
  window.__setTrick('sitt');
  document.getElementById('hud-stats')?.classList.remove('hud-gated');
  document.getElementById('hud-engagement')?.classList.remove('hud-gated');
});
await page.waitForTimeout(500);

for (const beat of BEATS) {
  await page.evaluate((lvl) => window.__setEngagement(lvl), beat.level);
  await page.waitForTimeout(450); // let the fill width/colour transition settle
  const out = `${OUT_DIR}/engagement-${beat.name}.png`;
  await page.screenshot({ path: out });
  const report = await page.evaluate(() => {
    const el = document.getElementById('hud-engagement');
    const fill = document.getElementById('hud-engagement-fill');
    if (!el || !fill) return { found: false };
    return {
      found: true,
      beat: el.getAttribute('data-beat'),
      ariaValueNow: el.getAttribute('aria-valuenow'),
      fillWidth: fill.style.width,
      fillColor: getComputedStyle(fill).backgroundColor,
      pillOpacity: getComputedStyle(el).opacity,
    };
  });
  console.log(`${beat.name.padEnd(8)} → ${out}  ${JSON.stringify(report)}`);
}

await browser.close();
