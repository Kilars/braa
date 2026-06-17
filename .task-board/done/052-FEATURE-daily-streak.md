# FEATURE: Daily Streak (TDD + display)

**Status**: Done
**Created**: 2026-06-14
**Priority**: Medium
**Labels**: core, retention, tdd
**Estimated Effort**: Simple

## Context & Motivation

A daily-play streak is a gentle "come back tomorrow" hook (fits the idle/retention
theme). Track consecutive days played; show it in the stats.

## Affected Components
- Create: `src/core/streak.ts` + test (pure — dates passed in as `YYYY-MM-DD` strings; NO `Date.now()` inside)
- Modify: `src/state/save.ts` (`GameSave` gains `streak: number` (default 0) + `lastPlayedYmd: string` (default '')) + test; `src/app/gameHelpers.ts` `buildGameSave`; ALL GameSave literals in save.test.ts/storage.test.ts (run `bun run typecheck` to find every one — a required field breaks literals)
- Modify: `src/main.ts` (on load, compute today's `YYYY-MM-DD` from `new Date()`, call `updateStreak`, persist; show streak in the settings stats readout), `src/ui/hud.ts` (a "🔥 N-day streak" stat line)
- Dependencies: `save.ts`, settings panel (038); Blocking: 038

## Interface (signatures — bodies test-first)

```ts
// pure — dates are 'YYYY-MM-DD' strings
export function updateStreak(lastPlayedYmd: string, todayYmd: string, currentStreak: number): { streak: number; lastPlayedYmd: string };
```

Rules: same day (lastPlayed === today) → streak unchanged; exactly the next calendar day → streak + 1; a gap of ≥2 days (or no prior play) → streak reset to 1. Always returns `lastPlayedYmd = todayYmd`.

## Behaviors to test (each RED first)
- No prior play (`''`) → streak 1.
- Same day → streak unchanged.
- Consecutive day (e.g. 2026-06-14 → 2026-06-15) → +1. Test across a month/year boundary too.
- A 2+ day gap → reset to 1.
- `GameSave.streak`/`lastPlayedYmd` backward-compat defaults.

## Visual Review (required — reuse the running dev server; do NOT pkill; never fake a screenshot)
- Open the settings panel; screenshot /tmp/bra-streak.png; VIEW it; confirm the streak line renders in the stats. (Fresh save shows streak 1 after first load.)

## Progress Log
- 2026-06-14 — Task created (iteration 18)

## Resolution

**Streak rules (implemented in `src/core/streak.ts`):**
- No prior play (`''`) → streak 1
- Same day → streak unchanged
- Exactly next calendar day → streak + 1
- Gap ≥ 2 days → reset to 1
- Always returns `lastPlayedYmd = todayYmd`
- Date parsing uses `Date.UTC(y, m-1, d)` to handle month/year boundaries correctly (tested: 2026-06-30→2026-07-01, 2026-12-31→2027-01-01)
- No `Date.now()` / `new Date()` inside `streak.ts`

**GameSave literals updated** (added `streak: number` + `lastPlayedYmd: string`):
- `src/state/save.ts` — interface + `deserialize` backward-compat defaults (streak→0, lastPlayedYmd→'')
- `src/state/save.test.ts` — 6 existing literals + 2 new backward-compat tests
- `src/state/storage.test.ts` — 5 existing literals
- `src/app/gameHelpers.ts` — `buildGameSave` params + return value

**main.ts wiring:**
- Import `updateStreak` from `./core/streak`
- On load: restore `streak`/`lastPlayedYmd` from save; call `updateStreak(lastPlayedYmd, todayYmd, streak)` where `todayYmd = new Date().toISOString().slice(0,10)`; persist result immediately
- `persist()` and idle-income `resetSave` both carry `streak`/`lastPlayedYmd`
- `getStats()` exposes `streak`

**hud.ts wiring:**
- `getStats` return type extended with `streak: number`
- `refreshSettingsPanel` adds `['Streak', '🔥 N-day streak']` item

**Results:**
- `bun run typecheck`: 0 errors
- `bun run test`: 418 tests, all pass (7 new streak.test.ts + 2 new save.test.ts backward-compat)
- `bun run build`: clean build
- `bun run e2e`: E2E SMOKE PASS
- Screenshot `/tmp/bra-streak.png`: Settings panel shows "Streak | 🔥 1-day streak" on fresh load ✓

## Acceptance Criteria
- [x] `streak.ts` written test-first; same-day/consecutive/gap rules + a date-boundary case
- [x] `GameSave.streak` + `lastPlayedYmd` persist (backward-compat); ALL literals + buildGameSave updated (typecheck 0)
- [x] main.ts updates the streak on load from today's date; settings shows "🔥 N-day streak"
- [x] Screenshot reviewed (real)
- [x] `bun run test` green; `bun run typecheck` **0**; `bun run build` ok; `bun run e2e` PASS
