/**
 * scripts/shoot.mjs — parametric Playwright screenshot helper
 *
 * Usage:
 *   node scripts/shoot.mjs [options]
 *
 * Options (processed IN ORDER so click/wait/force interleave correctly):
 *   --url  <u>                  Base URL (default: http://localhost:5173)
 *   --out  <path>               Output PNG path (default: /tmp/bra-shot.png)
 *   --vp   <WxH>                Viewport (default: 390x844)
 *   --click "<text>"            Click first button containing this text; repeatable
 *   --wait  <ms>                Sleep ms; repeatable
 *   --force "<sel>{<cssDecls>}" Inject !important style; repeatable
 *   --eval  "<jsExpr>"          Run arbitrary JS in the page (dev hooks/gestures); repeatable
 *   --poll  "<jsExpr>"          waitForFunction(() => <jsExpr>) before shooting
 *   --report "<selector>"       Log textContent + computed opacity; repeatable (output after screenshot)
 *
 * Example:
 *   PW_CHROME="$HOME/.cache/ms-playwright/chromium-1169/chrome-linux/chrome" \
 *   node scripts/shoot.mjs --click Sitt --wait 400 --out /tmp/shot.png --report "#hud-trick-label"
 */

// Nix glibc leaks in; let chromium use system libs.
delete process.env.LD_LIBRARY_PATH;

import { chromium } from 'playwright-core';

// ── Arg parse ────────────────────────────────────────────────────────────────

const argv = process.argv.slice(2);

let url = 'http://localhost:5173';
let out = '/tmp/bra-shot.png';
let vpWidth = 390;
let vpHeight = 844;

// Ordered action list: { type, value }
// Processed after page.goto() in the order they appear on the command line.
const actions = [];
// Report selectors (collected, run after screenshot)
const reports = [];
// Poll expression (last one wins; run before screenshot)
let pollExpr = null;

for (let i = 0; i < argv.length; i++) {
  const flag = argv[i];
  const val = argv[i + 1];

  switch (flag) {
    case '--url':
      url = val;
      i++;
      break;
    case '--out':
      out = val;
      i++;
      break;
    case '--vp': {
      const [w, h] = val.split('x').map(Number);
      vpWidth = w;
      vpHeight = h;
      i++;
      break;
    }
    case '--click':
      actions.push({ type: 'click', value: val });
      i++;
      break;
    case '--wait':
      actions.push({ type: 'wait', value: Number(val) });
      i++;
      break;
    case '--force':
      actions.push({ type: 'force', value: val });
      i++;
      break;
    case '--eval':
      // Run arbitrary JS in the page (e.g. call a dev hook or dispatch a gesture).
      actions.push({ type: 'eval', value: val });
      i++;
      break;
    case '--poll':
      // Store for pre-screenshot waitForFunction; last one wins.
      pollExpr = val;
      i++;
      break;
    case '--report':
      reports.push(val);
      i++;
      break;
    default:
      console.warn(`Unknown flag: ${flag}`);
  }
}

// ── Browser setup ─────────────────────────────────────────────────────────────

const browser = await chromium.launch({
  executablePath: process.env.PW_CHROME,
  args: ['--no-sandbox', '--disable-gpu'],
});
const ctx = await browser.newContext({ viewport: { width: vpWidth, height: vpHeight } });
const page = await ctx.newPage();

await page.goto(url, { waitUntil: 'networkidle' });

// ── Ordered actions ───────────────────────────────────────────────────────────

for (const action of actions) {
  switch (action.type) {
    case 'click':
      await page.locator(`button:has-text("${action.value}")`).first().click();
      break;

    case 'wait':
      await page.waitForTimeout(action.value);
      break;

    case 'eval':
      // eslint-disable-next-line no-new-func
      await page.evaluate(action.value);
      break;

    case 'force': {
      // Parse "selector{cssDecls}" — selector is everything before the first '{'
      const braceIdx = action.value.indexOf('{');
      if (braceIdx === -1) {
        console.warn(`--force value has no '{': ${action.value}`);
        break;
      }
      const sel = action.value.slice(0, braceIdx).trim();
      // cssDecls is what's inside the braces; append !important to each declaration.
      const rawDecls = action.value.slice(braceIdx + 1).replace(/}$/, '').trim();
      const importantDecls = rawDecls
        .split(';')
        .map((d) => d.trim())
        .filter(Boolean)
        .map((d) => (d.includes('!important') ? d : `${d} !important`))
        .join('; ');
      await page.addStyleTag({ content: `${sel}{${importantDecls};}` });
      break;
    }

    default:
      break;
  }
}

// ── Pre-screenshot poll ───────────────────────────────────────────────────────

if (pollExpr) {
  // eslint-disable-next-line no-new-func
  await page.waitForFunction(new Function(`return (${pollExpr})`));
}

// ── Screenshot ────────────────────────────────────────────────────────────────

await page.screenshot({ path: out });
console.log(`Screenshot saved: ${out}`);

// ── Reports ───────────────────────────────────────────────────────────────────

for (const sel of reports) {
  const result = await page.evaluate((s) => {
    const el = document.querySelector(s);
    if (!el) return { selector: s, found: false };
    const cs = getComputedStyle(el);
    return {
      selector: s,
      found: true,
      textContent: el.textContent?.trim() ?? '',
      opacity: cs.opacity,
    };
  }, sel);
  console.log(`report ${result.selector}:`, JSON.stringify(result));
}

await browser.close();
