/**
 * scripts/gen-icons.mjs — Generate PWA icons using headless Chromium + playwright-core
 *
 * Usage:
 *   PW_CHROME=/usr/bin/google-chrome node scripts/gen-icons.mjs
 *
 * Produces:
 *   public/icon-192.png
 *   public/icon-512.png
 *   public/icon-512-maskable.png
 */

// Nix glibc leaks; let chromium use system libs.
delete process.env.LD_LIBRARY_PATH;

import { chromium } from 'playwright-core';
import { mkdirSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const publicDir = join(__dirname, '..', 'public');
mkdirSync(publicDir, { recursive: true });

/**
 * Build the SVG art for the icon.
 * @param {number} size - total canvas size (192 or 512)
 * @param {boolean} maskable - if true, apply ~10% safe-zone padding
 */
function buildSvg(size, maskable) {
  // For maskable icons the safe zone is 80% of the icon diameter
  // (i.e. 10% padding each side). We shrink the art so it fits inside that zone.
  const pad = maskable ? size * 0.1 : size * 0.04;
  const inner = size - pad * 2;

  // Rounded square background
  const r = inner * 0.22; // corner radius relative to inner box
  const x = pad;
  const y = pad;
  const w = inner;
  const h = inner;

  // Paw — a central pad + 4 toes, placed in the lower half
  const cx = size / 2;
  const cy = size / 2 + inner * 0.06;

  // Central pad
  const padRx = inner * 0.175;
  const padRy = inner * 0.14;

  // Toes: 4 small ellipses arranged in an arc above the central pad
  const toeRx = inner * 0.08;
  const toeRy = inner * 0.095;
  const toeSpreadX = inner * 0.175;
  const toeOffsetY = inner * 0.19;
  const toeAngleLR = 0.35; // radians for outer toes

  const toes = [
    // left outer
    {
      tx: cx - toeSpreadX * Math.cos(toeAngleLR),
      ty: cy - toeOffsetY - toeSpreadX * Math.sin(toeAngleLR) * 0.4,
    },
    // left inner
    { tx: cx - toeSpreadX * 0.38, ty: cy - toeOffsetY - inner * 0.02 },
    // right inner
    { tx: cx + toeSpreadX * 0.38, ty: cy - toeOffsetY - inner * 0.02 },
    // right outer
    {
      tx: cx + toeSpreadX * Math.cos(toeAngleLR),
      ty: cy - toeOffsetY - toeSpreadX * Math.sin(toeAngleLR) * 0.4,
    },
  ];

  const toeSvg = toes
    .map(
      ({ tx, ty }) =>
        `<ellipse cx="${tx.toFixed(1)}" cy="${ty.toFixed(1)}" rx="${toeRx.toFixed(1)}" ry="${toeRy.toFixed(1)}" fill="white" opacity="0.92"/>`
    )
    .join('\n    ');

  return `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 ${size} ${size}">
  <!-- Background gradient: grass green to sky green -->
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#4cde80"/>
      <stop offset="100%" stop-color="#2bb05a"/>
    </linearGradient>
  </defs>
  <!-- Rounded square background -->
  <rect x="${x.toFixed(1)}" y="${y.toFixed(1)}" width="${w.toFixed(1)}" height="${h.toFixed(1)}" rx="${r.toFixed(1)}" ry="${r.toFixed(1)}" fill="url(#bg)"/>
  <!-- Paw toes -->
  ${toeSvg}
  <!-- Central pad -->
  <ellipse cx="${cx.toFixed(1)}" cy="${cy.toFixed(1)}" rx="${padRx.toFixed(1)}" ry="${padRy.toFixed(1)}" fill="white" opacity="0.92"/>
  <!-- "Bra!" text label beneath paw -->
  <text x="${cx.toFixed(1)}" y="${(cy + inner * 0.29).toFixed(1)}" text-anchor="middle" font-family="system-ui, -apple-system, sans-serif" font-weight="800" font-size="${(inner * 0.13).toFixed(1)}" fill="white" opacity="0.85">Bra!</text>
</svg>`;
}

async function generateIcons() {
  const executablePath = process.env.PW_CHROME || '/usr/bin/google-chrome';
  console.log(`Launching Chromium: ${executablePath}`);

  const browser = await chromium.launch({
    executablePath,
    args: ['--no-sandbox', '--disable-setuid-sandbox'],
  });

  const page = await browser.newPage();

  const icons = [
    { size: 192, maskable: false, file: 'icon-192.png' },
    { size: 512, maskable: false, file: 'icon-512.png' },
    { size: 512, maskable: true, file: 'icon-512-maskable.png' },
  ];

  for (const { size, maskable, file } of icons) {
    const svg = buildSvg(size, maskable);
    const dataUrl = `data:image/svg+xml;charset=utf-8,${encodeURIComponent(svg)}`;

    await page.setViewportSize({ width: size, height: size });
    await page.setContent(`
      <!DOCTYPE html>
      <html>
        <head>
          <style>
            * { margin: 0; padding: 0; }
            html, body { width: ${size}px; height: ${size}px; background: transparent; overflow: hidden; }
            img { display: block; width: ${size}px; height: ${size}px; }
          </style>
        </head>
        <body>
          <img src="${dataUrl}" width="${size}" height="${size}" />
        </body>
      </html>
    `);

    // Wait for the SVG image to render
    await page.waitForSelector('img');
    await page.waitForTimeout(200);

    const outPath = join(publicDir, file);
    await page.screenshot({ path: outPath, clip: { x: 0, y: 0, width: size, height: size } });
    console.log(`  Written: ${outPath} (${size}x${size}, maskable=${maskable})`);
  }

  await browser.close();
  console.log('Done.');
}

generateIcons().catch((err) => {
  console.error(err);
  process.exit(1);
});
