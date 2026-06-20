# QUALITY: DRY the two bootstrap saves behind a `persistBootstrap()` helper

**Status**: Backlog
**Created**: 2026-06-17
**Priority**: Medium
**Labels**: quality, refactor, main, tdd
**Estimated Effort**: XS

## Context & Motivation

`main.ts` has **three** `buildGameSave({...})` call-sites. `persist()` (the live
one) is fine, but the two **bootstrap** saves — the idle-income reset save and the
daily-streak update save — both inline the full `buildGameSave({...})` arg shape.
They run *before* `markAudio` and `persist()` exist, so they use `savedMuted`
instead of `markAudio.isMuted()` and omit the active-round fields. That residual
duplication is the last of the `main.ts` save-shape copy-paste (089 cleared the
rest). A tiny `persistBootstrap()` helper removes it.

## Current State

`src/main.ts` (≈ lines 129 and 159) — two identical-shaped literals:

```ts
// idle-income reset
const resetSave = buildGameSave({
  profile, roster, kennelUpgradeIds, difficultyMode: MODE,
  unlockedPhraseIds, prestigePoints, idleTimestamp: Date.now(),
  muted: savedMuted, bestCombo, streak, lastPlayedYmd,
});
storage.save(resetSave).catch(() => {});
// ...
// daily-streak update — same eleven fields again
storage.save(buildGameSave({
  profile, roster, kennelUpgradeIds, difficultyMode: MODE,
  unlockedPhraseIds, prestigePoints, idleTimestamp: Date.now(),
  muted: savedMuted, bestCombo, streak, lastPlayedYmd,
})).catch(() => {});
```

## Desired Outcome

One `persistBootstrap()` closure (declared once the bootstrap locals exist) that
captures the shared snapshot and is called from both sites. The bootstrap saves
never carry active-round state (no round is in progress during load), so the
helper deliberately omits those fields — keeping it distinct from `persist()`.

## Technical Approach

### Before → After

```ts
// AFTER — one helper, two call-sites
function persistBootstrap(): void {
  storage.save(buildGameSave({
    profile, roster, kennelUpgradeIds, difficultyMode: MODE,
    unlockedPhraseIds, prestigePoints, idleTimestamp: Date.now(),
    muted: savedMuted, bestCombo, streak, lastPlayedYmd,
  })).catch(() => {});
}
// idle-income reset:
if (earned > 0) { profile = award(...); persistBootstrap(); }
// daily-streak update:
streak = updated.streak; lastPlayedYmd = updated.lastPlayedYmd; persistBootstrap();
```

Because `profile`/`streak`/`lastPlayedYmd` are mutable bootstrap locals read at
call time, the helper always snapshots the latest values — same behaviour as the
inlined literals.

### TDD note

This is a `main.ts` wiring change with no new pure logic — `buildGameSave` is
already TDD-covered in `gameHelpers.test.ts`. Guard the refactor with the existing
**e2e** (`bun run e2e`) + a `grep` proving only one bootstrap save shape remains.
No behaviour change → no new unit test required; if any extractable pure piece
appears, TDD it per `.claude/skills/tdd/SKILL.md`.

## Risks & Considerations

- **Ordering**: declare `persistBootstrap` only after `savedMuted`/`streak`/
  `lastPlayedYmd` are in scope. It must NOT be confused with `persist()` (which
  uses `markAudio.isMuted()` and carries active-round fields).
- Keep both `.catch(() => {})` no-ops (save failure stays non-fatal).

## Acceptance Criteria

- [ ] Both bootstrap saves call one `persistBootstrap()` helper; no inlined
      `buildGameSave({...})` literal remains at the two bootstrap sites
      (`grep -c` proof).
- [ ] `persist()` is unchanged (still `markAudio.isMuted()` + active-round fields).
- [ ] Idle-income double-grant guard still works (reset timestamp persisted on
      grant) and streak still persists on load.
- [ ] `bun run verify` (typecheck + tests + build) green and `bun run e2e` PASS.
