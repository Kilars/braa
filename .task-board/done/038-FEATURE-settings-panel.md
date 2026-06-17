# FEATURE: Settings / Options Panel (mute, reset, stats)

**Status**: Backlog
**Created**: 2026-06-14
**Priority**: Medium
**Labels**: ui, feature, tdd, visual-review
**Estimated Effort**: Medium

## Context & Motivation

No way to mute the audio, reset progress, or see overall stats. Add a small
settings panel reachable from the select screen.

## Affected Components
- Modify: `src/audio/markAudio.ts` (a `muted` flag + setter; `play` no-ops when muted) + test
- Modify: `src/state/save.ts` (`GameSave` gains `muted: boolean`, default false; backward-compat) + test
- Modify: `src/main.ts` (load muted → apply to MarkAudio; settings actions; reset = clear the IndexedDB save + reload), `src/ui/hud.ts`/`hud.css` (a ⚙ settings button on the select screen + a settings panel: Mute toggle, Reset progress (with confirm), and a small stats readout: prestige ★, coins, level, # tricks mastered)
- Dependencies: `markAudio.ts`, `save.ts`, `storage.ts`, `economy.ts`, `prestige.ts`; Blocking: 010, 019, 030

## Behaviors to test (each RED first)
- `MarkAudio` muted: `play()` does nothing when muted (track that no oscillator is created — or expose an `isMuted()` and a guard you can unit-test by checking the early return path; at minimum test the muted flag setter/getter).
- `GameSave` backward-compat: old save without `muted` → false.
- (Pure-where-possible) — the reset clears storage; you can test a `clear()` on `InMemoryStorage` if not present.

## UI / wiring
- ⚙ settings button on the select screen (corner, no overlap with roster/adopt/kennel/graduate).
- Panel (role=dialog): Mute audio toggle (persists to GameSave + applies to MarkAudio live), Reset progress button (confirm step → `storage.clear()` or delete the record → `location.reload()`), stats readout.
- Persist `muted` on toggle.

## Visual Review (required — reuse the running dev server; do NOT pkill; never fake a screenshot)
- Screenshot the settings panel open (click ⚙ via `scripts/shoot.mjs --click "⚙"` or by id). VIEW it; confirm the toggle/reset/stats render, no overlap. Note findings.

## Progress Log
- 2026-06-14 — Task created (iteration 13)
- 2026-06-14 — Implementation completed (iteration 14)

## Resolution

### Typecheck fix
`bun run typecheck` had 5 errors — all were `muted` property missing from `GameSave` literals:
- `src/app/gameHelpers.ts` (line 104): `buildGameSave` return literal missing `muted` — fixed by adding `muted?: boolean` to params and `muted: params.muted ?? false` to return.
- `src/state/save.test.ts` (lines 73, 108, 148, 222): 4 test `GameSave` literals missing `muted: false` — added to each.

### UI/Wiring
- Added ⚙ settings button (`#hud-settings-btn`, `aria-label="Settings"`) in the top-right corner of the select screen (fixed position, above kennel button, no overlap).
- Added `#settings-panel` (role=dialog, aria-modal=true, aria-label=Settings) with:
  - Mute audio checkbox toggle → `markAudio.setMuted(v)` live + `persist()` on change.
  - Reset progress button with 2-step confirm ("Tap again to confirm" after first tap, 3 s timeout to cancel) → `storage.clear()` → `location.reload()`.
  - Stats readout: Prestige ★N or —, Coins, Level, Tricks mastered (summed across roster).
- `main.ts`: on load, `savedMuted` is stashed from save then applied via `markAudio.setMuted(savedMuted)` after `MarkAudio` is created. `persist()` now includes `muted: markAudio.isMuted()`.
- New `HudCallbacks` fields: `isMuted`, `onToggleMute`, `onResetProgress`, `getStats`.
- CSS added to `hud.css`: settings button, panel header, mute row, reset row, stats rows.

### Screenshot
Real screenshot taken via Playwright (`scripts/shoot.mjs --click "⚙"`). Panel shows: Settings header + ✕ close, Mute audio + checkbox, Reset progress (red button), stats (Prestige —, Coins 🪙 0, Level 1, Tricks mastered 0). No element overlap within the panel.

### Verification
- `bun run typecheck` → 0 errors
- `bun run test` → 349 passed (23 test files)
- `bun run build` → success (dist generated, 12.91s)

## Acceptance Criteria
- [x] `MarkAudio` has a muted flag; `play` no-ops when muted (test-first)
- [x] `GameSave.muted` persists (backward-compat default false); restored + applied on load
- [x] Settings panel: Mute toggle (live + persisted), Reset progress (confirm → clears save → reload), stats readout
- [x] ⚙ button + panel render without overlap; screenshot reviewed (real)
- [x] `bun run test` green; `bun run typecheck` clean; `bun run build` succeeds
