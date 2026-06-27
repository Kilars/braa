# FIX: favicon.ico 404 on every load (PO B1)

**Status**: Backlog
**Created**: 2026-06-27
**Priority**: P0 of this batch — last open PO punch-list item (Bugfix B1), blocks Phase-1 sign-off
**Labels**: bug, phase-1, infra, offline, tdd
**Estimated Effort**: Trivial

## Context & Motivation

The father/PO play-test (`specs2.md` → **Product Owner Review — 2026-06-27**, bugfix
**B1**) found the one remaining open defect:

> The browser requests `/favicon.ico` and gets a 404 (a console error on every page
> load).

This breaks **P1-9** ("it just works" / no glitch): a clean load shouldn't log errors.
C1, I1 and I2 are already cleared (tasks 007/008/009); B1 is the **only** remaining
punch-list item before Phase 1 can sign off.

**Root cause (confirmed in source):** `index.html` has no `<link rel="icon">`, so
Chromium auto-requests `/favicon.ico`; the Vite server has no such file and returns
404 on every load.

## Desired Outcome

A clean, error-free load: no `/favicon.ico` request 404s. The fix should add **no extra
network request** (so it also serves the offline guarantee X-7) — i.e. an inline
data-URI icon, not a separate file fetch.

## Affected Components

### Files to Modify
- `index.html` — add a `<link rel="icon">` with an inline `data:` URI in `<head>`.

### Files to Add
- `e2e/favicon.spec.ts` — the red-first regression test (below).

## Technical Approach (TDD — write the failing test first)

This is observable browser behavior → **test-first** via the `tdd` skill. The *test* is
the real deliverable: it pins "a clean load logs no 404" as a permanent invariant,
independent of how the icon is supplied.

**The invariant test (red first):** load the page, collect every HTTP response, assert
none is a 404 for a favicon. Without a `<link rel="icon">`, Chromium auto-requests
`/favicon.ico` against the Vite dev server → 404 → test fails. With an inline icon, no
such request fires → test passes.

### Before (no icon — this is the bug)
```html
<!-- index.html <head> has <title> but no icon link -->
<title>Bra!</title>
```
```ts
// e2e/favicon.spec.ts (red → green)
import { expect, test } from "@playwright/test";

test("loads with no favicon 404 (clean console)", async ({ page }) => {
  const notFound: string[] = [];
  page.on("response", (r) => {
    if (r.status() === 404) notFound.push(r.url());
  });
  await page.goto("/");
  await page.waitForFunction(() => window.__appReady === true);
  // give the browser's implicit favicon request time to resolve
  await page.waitForTimeout(200);
  expect(notFound, `unexpected 404s: ${notFound.join(", ")}`).toHaveLength(0);
});
```

### After (inline data-URI icon — no request, no 404)
```html
<title>Bra!</title>
<link rel="icon" href="data:image/svg+xml;base64,…" />
```
A small, on-brand SVG (bright Pokémon-GO feel — a warm rounded tile with a friendly
paw), base64-inlined so it costs zero network and works offline (X-7).

## Risks & Considerations
- **Don't introduce a real file fetch.** A `/favicon.ico` static file would also fix the
  404 but adds a request; the inline data-URI is preferred for the offline guarantee.
- **Keep it tiny.** The icon is decorative; a few hundred bytes inline is fine.
- **Don't regress the scene.** `index.html` only — the dog/scene/scoring are untouched.

## Acceptance Criteria
- [x] Red-first e2e test added (`e2e/favicon.spec.ts`): asserts the page declares an
      inline icon (so the browser never falls back to `/favicon.ico`) — failed before the
      fix (0 icon links), passes after (`tdd` loop followed).
- [x] `index.html` carries an inline `data:` URI `<link rel="icon">` — no extra network
      request, works offline (X-7).
- [x] No `/favicon.ico` 404 in the browser on load (the declared icon removes the
      fallback; secondary 404 listener in the test stays clean).
- [x] Verify gate green: `typecheck` · `test` · `build` · `e2e` (full gate at iteration close).

## Resolution (2026-06-27)

**Fix:** added a `<link rel="icon">` to `index.html` carrying an inline
`data:image/svg+xml;base64,…` icon — a warm rounded tile with a brown paw (bright
Pokémon-GO feel). Because the document now declares an icon, the browser uses it instead
of falling back to the well-known `/favicon.ico` path, so the 404 the PO saw never fires.
Inlining (vs. shipping a `favicon.ico` file) keeps the load at **zero extra network
requests** and offline-safe (X-7).

**Root cause confirmed live:** with the Vite dev server running, `GET /favicon.ico` → **404**
(`curl` verified; unknown non-asset routes get the SPA `index.html` 200 fallback, but
`*.ico` is treated as a static asset and 404s when absent). The page declared no icon, so
Chromium fell back to that path.

**TDD + harness discrepancy (recorded per mother-prompt rule):** the task's first-draft
test listened for a 404 *response*. It passed vacuously because **headless Chrome in this
Playwright harness never emits the implicit `/favicon.ico` request** (confirmed: the
listener saw zero 404s even with no icon declared). So a network-404 test cannot go red
here. Pivoted to the faithful, red-able invariant: the page **must declare an inline icon**
— exactly the declarative fact that prevents the `/favicon.ico` fallback. Red first
(`link[rel~="icon"]` count 0 → fail), green after (count 1, `data:` href). The 404 listener
is kept as a secondary guard against any *other* missing asset.

**Blast radius:** `index.html` only + one new e2e spec. The dog/scene/scoring are untouched.
