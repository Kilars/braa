# FEATURE: 024g — Honest timing readout + reduced motion (P1-7, P1-8)

**Status**: Backlog
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
## Closes the epic

When 024b–024g are done, run the P1-10 done-gate (all P1 stories, `polish`,
independent visual review on the live deploy, TDD coverage) before 024 → done.
