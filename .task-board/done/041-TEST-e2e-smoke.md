# TEST: Playwright E2E smoke test of the core flow

**Status**: Backlog
**Created**: 2026-06-14
**Priority**: Medium
**Labels**: test, e2e, quality
**Estimated Effort**: Medium

## Context & Motivation

The unit suite (349 tests) covers `src/core` logic, but `main.ts`'s integration
wiring (select→training, mark→bar, mastery, persistence) is only ever checked by
manual screenshots. A scripted E2E smoke test guards the core flow against the kind
of wiring regressions subagents have introduced. Use the existing `playwright-core`
+ headless Chromium.

## Affected Components
- Create: `e2e/smoke.mjs` (a node script using playwright-core; asserts + exit code)
- Modify: `package.json` (add `"e2e": "node e2e/smoke.mjs"`)
- Dependencies: `playwright-core` (devdep), a RUNNING dev server, `PW_CHROME` env; Blocking: none

## The smoke test (assert each, fail loudly with a clear message + non-zero exit)
1. `delete process.env.LD_LIBRARY_PATH`; launch chromium (`executablePath: process.env.PW_CHROME`), fresh context, viewport 390×844, goto localhost:5173.
2. SELECT screen present: `#hud-select` visible; the dog name + trick buttons (Sitt/Ligg/Legg deg) exist.
3. Click a trick (Sitt) → TRAINING: `#hud-trick-label` textContent contains "Sitt".
4. Tap the BRA button several times (dispatch pointerdown) timed across a couple of attempt windows; assert SOMETHING progressed — e.g. `#hud-bar-fill` width became > 0% at some point, OR a `#hud-result` data-result appeared. (Be tolerant of timing — poll over a few seconds.)
5. Print "E2E SMOKE PASS" and exit 0; on any failed assertion print "E2E SMOKE FAIL: <what>" and exit 1.

- Keep it ROBUST to timing (poll/retry where needed); a flaky e2e is worse than none.
- Document at the top: requires `bun run dev` running + `PW_CHROME` set.

## Verification
- Start/confirm the dev server (reuse it; do NOT pkill). Run `PW_CHROME=... bun run e2e` and confirm it prints PASS + exits 0. Run it twice to check it's not flaky.
- `bun run test` (unit) still green; `bun run typecheck` 0 (the e2e script is .mjs, not type-checked, but don't break tsconfig).

## Progress Log
- 2026-06-14 — Task created (iteration 14)

## Resolution

Implemented `e2e/smoke.mjs` and added `"e2e": "node e2e/smoke.mjs"` to `package.json`.

### Assertions (in order)
1. `#hud-select` is visible (display/visibility/opacity check) on page load.
2. At least one `<button>` with textContent `"Sitt"` exists on the select screen.
3. `pointerdown` dispatched on "Sitt" button → poll up to 3s until `#hud-trick-label` textContent includes `"Sitt"`.
4. 20 `pointerdown` events on `#hud-bra-btn`, 150ms apart (~3s span); track max `#hud-bar-fill` style.width and any `data-result` on `#hud-result`; then final 6s poll. Assert either `maxBarWidth > 0` OR `anyResult` is truthy.

### Run 1 output
```
$ node e2e/smoke.mjs
E2E SMOKE PASS
```

### Run 2 output
```
$ node e2e/smoke.mjs
E2E SMOKE PASS
```

### Unit tests
```
Test Files  23 passed (23)
     Tests  349 passed (349)
```

### Typecheck
`tsc --noEmit` — 0 errors.

## Acceptance Criteria
- [x] `e2e/smoke.mjs` asserts: select screen → click trick → training label → tapping BRA progresses the bar/result
- [x] `bun run e2e` script added; prints PASS/FAIL + correct exit code
- [x] Runs green twice (not flaky) against the dev server; documented prerequisites
- [x] Unit `bun run test` still green; `bun run typecheck` 0; no app code broken
