# FEATURE: 024g — Honest timing readout + reduced motion (P1-7, P1-8)

**Status**: Done (2026-06-28) — readout + reduced motion built test-first, 88 tests green,
verify gate green, dormant idle frame visually verified. See findings.
**Parent**: 024
**Priority**: Medium (the learn-the-timing feedback + accessibility)
**Labels**: gameplay, godot, phase-1, visual, a11y
**Estimated Effort**: Small

## Outcome (specs2.md P1-7, P1-8)

- Clear on-screen tier feedback per tap: **PERFECT / OK / MISS** (use
  `SitWindow.tier_name`, 024a). Immediate on `pointerup`, never contradicting audio.
- **Reduced motion (P1-8):** idle / apex / reaction cues are **dampened, not
  removed** — the sit, the apex, and the happy reaction stay distinguishable by pose.

## Approach

- Read `prefers-reduced-motion` (web: media query via JavaScriptBridge; provide a
  sensible default off-web) and route animation intensity through one damping factor
  so every cue honors it consistently.
- Visual task → `polish` + phone-portrait review (blocking), including a
  reduced-motion pass confirming every cue still reads.

## Depends on

- 024a (tier_name), 024d (tell to dampen), 024e (tier to display), 024f (reaction).

## Iteration findings — DONE (2026-06-28)

Built test-first (RED → GREEN), two pure components + thin wiring, no new asset deps:

- **P1-7 honest readout.** `scripts/tier_readout.gd` (`TierReadout extends Label`) — a
  dumb renderer split from the scoring, same pattern as the tell marker: `text_for(tier)`
  maps PERFECT/OK/MISS to the word and **DEAD → "" (shows nothing)**, so a dead tap stays
  "does nothing" and never contradicts the silent audio (P1-5/P1-7). `color_for` makes
  **PERFECT brighter than OK** (emphasis agrees with the louder reward). `display(tier)`
  flashes it at full opacity immediately on the tap; `advance(delta)` (driven from
  `main._process`, like the marker) holds then fades it fully out so a tier never goes
  stale. Mounted in `main` upper-third, mouse-transparent (never eats a BRA tap).
- **P1-8 reduced motion, wired for real.** `scripts/reduced_motion.gd` (`ReducedMotion`):
  pure `scale_for(reduced)` → `1.0` full / `DAMPED=0.35` (strictly in (0,1) — **dampened,
  not removed**), and `query()` reads the live `prefers-reduced-motion` web media query
  (false off-web). `main._apply_reduced_motion()` runs **first in `_ready`** so
  `_motion_scale` is set before `_start_dog` builds the tell — the seam that was a stub
  is now actually fed by the preference. Test seam `reduced_motion_override` + getter
  `motion_scale()` prove the chain without a browser. Pose-driven cues (sit/apex/reaction)
  are never scaled, so they always read by pose; only the authored overlay intensity dampens.
- **TDD.** `test_reduced_motion.gd` (4) + `test_tier_readout.gd` (6) + `test_readout_wiring.gd`
  (4) = **14 new**; confirmed RED first (parse-fail on the missing symbols), then GREEN.
  **88 tests green** (was 74). Full verify gate green (import · boot · test · export).
- **Visual (phone-portrait, live web export).** `.screenshots/024g-readout-idle.png`
  (headless Chrome on the verify build, COOP/COEP server): the readout is **correctly
  invisible at rest** (no stray PERFECT/OK/MISS), BRA button intact — the new node does
  not regress the idle frame. The readout's *lit* appearance is locally exercisable (the
  licensed dog **can Sitt**), unlike 024d/024f which are fully CC0-gated; a precise
  apex-timed live click-capture is deferred (needs CDP click tooling, not a blocker —
  the mapping/visibility/fade are unit-locked).

**Discovered (OUT of 024g scope, recorded on 024c):** the same live screenshot shows the
**licensed Labrador is badly mis-framed** (head cut off, only lower torso/legs in frame).
`DogFraming`'s "model-agnostic" claim holds for the CC0 dog (024c shot) but **fails for the
licensed dog**. 024c's framing screenshot (15:33) predates the licensed-dog wiring (025-wire
~17:19), so it only ever verified CC0. Logged on 024c with the evidence — a real framing
regression on the Phase-1 critical path, not caused by this task.

## Closes the epic

When 024b–024g are done, run the P1-10 done-gate (all P1 stories, `polish`,
independent visual review on the live deploy, TDD coverage) before 024 → done.
