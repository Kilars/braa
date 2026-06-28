# GATE: Phase-2 close-out sign-off — every trick passes its own Visual Review (P2-3 / X-6)

**Status**: Backlog
**Created**: 2026-06-27
**Priority**: P1 — the hard done-gate for Phase 2. Runs **last**, after 018 + 019.
**Labels**: phase-2, gate, visual-review, qa
**Depends on**: 018 (Legg deg — the last trick), 019 (light anti-mash — the last gameplay
story). **Do not start until both are Done.**

## Context & Motivation

Mirrors **011** (the Phase-1 close-out). Phase 2 ("more tricks, same quality bar") only
*counts* as done when the quality bar is **proven**, not assumed. Story **P2-3** is explicit:
*"Each trick passes its own Visual Review before it counts as done,"* and **X-6** demands
every visual task close by Visual Review and every piece of logic by TDD — so "it compiles /
tests pass" is never mistaken for done. This task is that hard gate for the whole phase: walk
every Phase-2 story against the **running app** on a phone-portrait viewport and record
evidence.

Phase 2 stories to verify: **P2-1** pick-a-trick (014), **P2-2** distinct animation per trick
— now **Sitt + Ligg + Legg deg** (013, 018), **P2-3** per-trick polish gate (this), **P2-4**
learned bar → mastery (016), **P2-5** leave & come back (017), **P2-6** light anti-mash (019).

## Desired Outcome

A single, honest sign-off pass that produces evidence (not claims) that Phase 2 holds the
Phase-1 quality bar, and unlocks Phase 3 — recorded in `.docs/tech-decisions.md` (the spec is
read-only). After this, the next scan targets Phase 3 (which still has unresolved owner
decisions — see spec P3-D1…P3-D4 — so expect a thinner, decision-gated slice).

## Tasks (run as one pass)

1. **Full verify gate, captured green:**
   - `bun run typecheck` → 0 errors
   - `bun run test` → all green (note the count)
   - `bun run build` → no warnings
   - `bun run e2e` → all green (note the count)
2. **Regenerate capture frames** for every trick + UI beat (`_capture.spec.ts` writes
   `.screenshots/`): Sitt, Ligg, **Legg deg**, the selector, the learned bar, mastery.
3. **Run `polish`** on the visual surface (selector chips, learned bar, BRA + nudge, tier
   readout) — apply only safe fixes that regress no frame; log anything deferred.
4. **Independent review agents (≥2)** look at the **real** `.screenshots/` on a 390×844
   portrait viewport and confirm, per the P2-3 gate:
   - **Each trick reads and is distinct** — Sitt (proud sit), Ligg (alert sphinx), Legg deg
     (relaxed settle) are mutually distinguishable at the apex; none is a reused generic pose.
   - Per trick: clean motion (no foot-slide / clip / T-pose / loop snap), honest apex tell
     (lit on that trick's apex, dark in IDLE), grounded paws (D12), mark feels good
     (OK < PERFECT), reduced-motion still reads by pose.
   - Selector (P2-1): one-page, portrait, one-verb — not a second gameplay button.
   - Learned bar (P2-4): fills per-trick, mastery beat fires at 100%, no fail state.
   - Anti-mash (P2-6): a dead tap reads as gently discouraged, never punishing.
   - **No regression** to any Phase-1 guarantee (P1-1…P1-9): dog reads, no primitive flash,
     centered, audio gated correctly.
   Cross-check every reviewer claim against the actual PNGs — **never accept a fabricated
   frame** (this gate exists because "looks done" lied before).
5. **Walk P2-1…P2-6** with a one-line evidence note each (screenshot path / test name).

## Acceptance Criteria
- [ ] Verify gate captured green: `typecheck` 0 · `test` (count) · `build` no-warnings ·
      `e2e` (count).
- [ ] `.screenshots/` regenerated for Sitt, Ligg, **Legg deg**, selector, learned bar, mastery.
- [ ] `polish` run on the visual surface; safe fixes applied without regressing any frame;
      deferrals logged.
- [ ] **≥2 independent reviewers** confirm on real screenshots: the three tricks are distinct
      and each passes its own Visual Review (P2-3); selector/bar/anti-mash read correctly; no
      Phase-1 regression. Blocking findings fixed.
- [ ] P2-1…P2-6 each walked with an evidence note.
- [ ] Sign-off recorded in `.docs/tech-decisions.md` (§ Phase 2 close-out); Phase 3 unlocked.
      **(The spec `specs2.md` stays untouched — read-only.)**
- [ ] Final verify gate green after any polish/fixes.
