/**
 * scripts/shoot-hud.mjs — thin shim kept for backward compatibility.
 * The loop and any other callers depend on this file producing:
 *   /tmp/bra-initial.png  (before BRA taps)
 *   /tmp/bra-active.png   (after 24 BRA taps)
 *
 * Implementation delegates to the parametric scripts/shoot.mjs helper.
 */

// Nix glibc leaks in; let chromium use system libs.
delete process.env.LD_LIBRARY_PATH;

import { chromium } from 'playwright-core';

const browser = await chromium.launch({
  executablePath: process.env.PW_CHROME,
  args: ['--no-sandbox', '--disable-gpu'],
});
const ctx = await browser.newContext({ viewport: { width: 390, height: 844 } });
const page = await ctx.newPage();

await page.goto('http://localhost:5173/', { waitUntil: 'networkidle' });
await page.waitForTimeout(800);
await page.screenshot({ path: '/tmp/bra-initial.png' });
console.log('Screenshot saved: /tmp/bra-initial.png');

// Tap BRA repeatedly to exercise the HUD (flash, confused state, bar movement).
const btn = page.locator('#hud-bra-btn');
for (let i = 0; i < 24; i++) {
  await btn.dispatchEvent('pointerdown');
  await page.waitForTimeout(220);
}
await page.screenshot({ path: '/tmp/bra-active.png' });
console.log('Screenshot saved: /tmp/bra-active.png');

// Report bar fill + last result for verification.
const barWidth = await page.locator('#hud-bar-fill').evaluate((el) => el.style.width);
const lastResult = await page.locator('#hud-result').getAttribute('data-result');
console.log('bar fill width:', barWidth, '| last result attr:', lastResult);

await browser.close();
