# GATE: Phase-1 close-out sign-off — the hard done-gate (P1-10)

**Status**: Done (2026-06-27)
**Created**: 2026-06-27
**Priority**: P1 of this batch — the capstone; runs AFTER 010 (favicon) so the load is error-free
**Labels**: phase-1, gate, visual-review, polish
**Estimated Effort**: Medium

## Context & Motivation

The PO punch-list is now fully addressed: **C1** (007), **I1** (008), **I2** (009) and,
in this batch, **B1** (010). The spec's hard done-gate **P1-10** ("Phase 1 is provably
done") has **not yet been run as a single consolidated pass** over the finished loop — the
prior reviews were per-feature (003/006/008/009). This task is that final sign-off so
Phase 1 can close and the phasing rule unlocks Phase 2.

P1-10 acceptance (on a real phone-portrait viewport, e.g. 390×844):
1. All P1 stories pass their acceptance criteria.
2. The **`polish`** skill has been run on the visual work.
3. **Independent review agents** confirm on the running app that the dog reads, the sit +
   apex are legible, the mark feels good, and there are no visual bugs (Visual Review gate).
4. Game logic (timing/scoring, apex windowing) is covered **test-first** (already true:
   `mark`/`window`/`sitCycle`/`reaction` suites).

## Desired Outcome

A documented, evidence-backed Phase-1 sign-off: every P1 story checked against the running
app on a 390×844 portrait viewport, the `polish` pass run, and **two independent reviewers
PASS** on real screenshots (idle, mid-build, apex+tell, OK reaction, PERFECT reaction).
No fabricated artifacts — every claim tied to a real capture or test.

## Affected Components

### Files to Check / Use (not necessarily edited)
- `e2e/_capture.spec.ts` — regenerate the Visual-Review frames into `.screenshots/`.
- `src/render/{scene,dog,backdrop}.ts` — the visual surface under review.
- `specs2.md` Phase 1 (P1-0 … P1-10) — the checklist to verify against.

### Files to Add
- `.docs/tech-decisions.md` (or this task's Resolution) — the signed checklist + reviewer
  verdicts + screenshot evidence.

## Technical Approach

1. **Confirm the verify gate is green** (`typecheck` · `test` · `build` · `e2e`).
2. **Regenerate the capture frames** (`bun run e2e` runs `_capture.spec.ts`) so the review
   looks at *current* pixels, post-punch-list. Confirm the files exist on disk.
3. **Run the `polish` skill** over the visual work (alignment/spacing/readout/contrast),
   triaged at the Phase-1 quality bar; apply only safe, non-regressing tweaks.
4. **Spawn two independent Visual-Review agents** (phone-portrait, 390×844) that look at
   the real screenshots and rule on: dog reads as a Labrador, centered + shadow-anchored;
   idle alive-but-calm; sit builds to a clean apex (no lumpy mid-build — I2); honest apex
   tell; OK vs PERFECT reaction clearly distinct + grounded (I1); readout legible; no
   primitive flash / T-pose / float / clip. Their findings are **blocking**.
5. **Walk the P1 checklist** (P1-0 … P1-10) and mark each pass/fail with evidence.
6. **Record the sign-off** (checklist + verdicts) in the Resolution + `tech-decisions.md`.

## Risks & Considerations
- **Never fabricate a screenshot or verdict.** Verify every reviewer claim against the
  real artifact on disk (the mother-prompt rule).
- **A blocking finding re-opens the gate.** If a reviewer flags a real visual bug, fix it
  (or file a follow-up task) before signing off — don't rubber-stamp.
- **No scope creep into Phase 2.** This is sign-off only; later-phase polish (Phase 7) and
  features stay out.

## Acceptance Criteria
- [x] Verify gate green: `typecheck` (0) · `test` (44) · `build` (no warnings) · `e2e` (5).
- [x] Capture frames regenerated and confirmed on disk (real pixels, post-punch-list;
      `.screenshots/` rewritten 17:22 by `_capture.spec.ts`).
- [x] `polish` skill run on the visual work; one safe fix applied (BRA `:focus-visible`
      ring) without regressing — no capture frame changed; build + e2e green after.
- [x] **Two independent phone-portrait reviewers PASS** on the real screenshots; verdicts
      recorded in `.docs/tech-decisions.md` §2, cross-checked against the actual images.
- [x] P1-0 … P1-10 checklist walked, each marked pass with evidence (tech-decisions.md §2).
- [x] Phase-1 sign-off recorded (this Resolution + `tech-decisions.md` §2); planning board
      updated to "Phase 1 DONE — Phase 2 unlocked."

## Resolution (2026-06-27)

**Phase 1 is PROVABLY DONE — signed off. Phase 2 unlocked.**

Ran the consolidated P1-10 done-gate as a single pass on phone-portrait (390×844):

1. **Verify gate GREEN** — `typecheck` 0 errors · `test` 44 passed (mark/math/reaction/
   sitCycle/markCue) · `build` clean, no warnings · `e2e` 5 passed. Re-ran build + e2e
   after the polish edit; still green.
2. **Frames regenerated** — `bun run e2e` rewrote all 13 `.screenshots/` PNGs (idle,
   build-30/50/65/85, apex, OK/PERFECT reactions, three readouts, reduced-motion) at the
   current post-punch-list pixels; confirmed on disk by mtime.
3. **Polish run** — `polish` skill over `src/render/*`, `shell.ts`, `style.css`. UI already
   carried its prior Visual-Review fixes; the one real gap was a missing keyboard focus
   indicator on the BRA button → added `.bra-button:focus-visible` (dark ring matching the
   readout/title outline language). Safe, non-regressing, no apex-pose risk.
4. **Visual Review 2/2 PASS (blocking)** — two independent reviewers read the real PNGs and
   both returned PASS with **no blocking findings**; the PO I2 lumpy-mid-build defect was
   specifically hunted and confirmed fixed. Claims cross-checked against the actual images
   (no fabrication). Only cosmetic non-blocking notes (stiff tail, side-profile length).
5. **P1-0 … P1-10 walked** — every story PASS with evidence; full table in
   `.docs/tech-decisions.md` §2.

The PO punch-list (C1/007, I1/008, I2/009, B1/010) is fully cleared and the capstone gate
is signed. Backlog empty, no open Phase-1 items. Per the phasing rule, Phase 2 may now begin.
