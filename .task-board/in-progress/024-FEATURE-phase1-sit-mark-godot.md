# FEATURE: Phase 1 — the perfect single mark, in Godot (idle → sit+apex → BRA → payoff)

**Status**: In Progress (epic — decomposed into per-story slices 024a–024g)
**Created**: 2026-06-28
**Priority**: High (the Phase 1 bet — but build on the live Godot deploy, after 022)
**Labels**: gameplay, godot, phase-1, tdd, visual
**Estimated Effort**: Large (decompose per story)

## Decomposition (this is the epic; build one slice per iteration, not a monolith)

- [x] **024a** — apex-band / scoring-window math (pure GDScript, TDD). **Done**
      2026-06-28: `scripts/sit_window.gd` + 12 unit tests; verify gate green.
- [~] **024b** — a legible sit with a clear apex (P1-3) [visual] **— architecture
      landed, BLOCKED on asset.** 2026-06-28: the deployed dog
      (`assets/models/dog.glb`) is the CC0 placeholder and has **no Sitt clip**;
      the real `Sitting_*` clips live only in the licensed Labrador
      (`models-build/out_anim.glb`, `.gdignore`'d per ADR-0006, ships as an
      encrypted `.pck` — pipeline not built). Built the clip-driven, dog-agnostic
      sit (`dog_clips.gd` + `dog_director.gd`, apex = single source of truth),
      wired the CC0 **idle** so the deployed dog is alive (P1-2), 17 tests green,
      verify green, web screenshot inspected. **Visible Sitt on the live deploy is
      gated** → needs an **ADR-0006 encrypted-licensed-asset CI** task (owner
      decision). See `024b-FEATURE-...md` findings.
- [x] **024c** — alive at rest: ambient idle loop (P1-2) [visual] **Done** 2026-06-28:
      probed the CC0 idle (imports loop NONE → `play_idle()` makes it `LOOP_LINEAR`;
      wrap seam 0.0007 rad, zero AABB drift — alive + seamless). Fixed the 024b "dog
      high in frame" gap: new pure `scripts/dog_framing.gd` centres the camera on the
      dog's real AABB and fits distance to its bounds (model-agnostic → Labrador too);
      `main.gd` frames from node-local transforms so it's correct on frame 1. 42 tests
      green (`test_dog_framing` + `test_idle_loop`), verify green, phone-portrait
      screenshot inspected (`.screenshots/024c-idle-framing.png`). See 024c card.
- [x] **024d** — the apex tell (P1-4) [visual] **Done** 2026-06-28: honest
      single-source-of-truth tell — pure `scripts/apex_tell.gd` (`ApexTell`) cosine-bell
      envelope peaking **exactly at the apex** (built via `from_window` off the same
      `SitWindow`), reduced-motion damping that dampens-not-removes (P1-8 seam for 024g),
      + `scripts/apex_tell_marker.gd` (`ApexTellMarker`) mouse-transparent warm pulse
      over the BRA button, driven each frame off the sit clock in `main.gd`. 54 tests
      green (8 envelope + 4 wiring), verify green, real phone-portrait web screenshot
      shows the tell **dormant during idle** (`.screenshots/024d-tell-idle.png`). The
      visible apex pulse is **025-gated** on the CC0 dog (no Sitt) — lights up when the
      licensed Labrador ships, like 024e's taps. See 024d card.
- [x] **024e** — BRA button + wire scoring to taps (P1-5) [interaction; uses 024a]
      **Done** 2026-06-28: `scripts/sit_session.gd` (pure open/advance/tap seam,
      9 TDD tests) + a big bottom-anchored BRA `Button` in `main.gd` wired through
      the session (fires on pointerup; emits `marked(tier)` for 024f/024g). On the
      CC0 dog every live tap is **DEAD** (no Sitt) — PERFECT/OK/MISS is unit-verified
      and lights up when **025** ships the sit-capable Labrador. 32 tests green,
      verify gate green, real phone-portrait screenshot of the button on the live
      web export (`.screenshots/bra-button-portrait.png`). See 024e card.
- [x] **024f** — the mark feels good: voice + SFX + dog reaction (P1-6) [audio/visual]
      **Done** 2026-06-28: the reward beat as pure decision + dumb player + wiring —
      `scripts/mark_payoff.gd` (`MarkPayoff`, the single gate: PERFECT brighter than OK,
      MISS/DEAD silent, stable Maren cue id) + `scripts/payoff_player.gd` (`PayoffPlayer`,
      voice+click off honest synthesized placeholder cues, loudness from brightness) +
      clip-driven dog reaction (`DogClips.reaction`/`DogDirector.play_reaction`,
      dog-agnostic, graceful no-op on CC0) wired through `main._play_payoff`. 73 tests
      green, verify green. Adds **no new UI**; on the CC0 dog every tap is DEAD so the
      voice/click/reaction are **provably dormant** (silent live, live frame unchanged
      from 024d) — lights up with **025**. See 024f card.
- [x] **024g** — honest timing readout + reduced motion (P1-7, P1-8) [visual] **Done**
      2026-06-28: pure `scripts/tier_readout.gd` (`TierReadout`, PERFECT/OK/MISS flash,
      DEAD shows nothing, PERFECT brighter than OK, immediate-then-fade) + pure
      `scripts/reduced_motion.gd` (`ReducedMotion.scale_for` → dampened-not-removed 0.35,
      `query()` reads prefers-reduced-motion); `main._apply_reduced_motion()` now actually
      feeds `_motion_scale` before the tell builds. 14 new tests (88 green), verify green,
      dormant idle frame visually verified (`.screenshots/024g-readout-idle.png`). See 024g
      card. **Found there:** licensed Labrador is mis-framed — logged on 024c (not 024g).
- [x] **024c framing regression** — **FIXED** 2026-06-28: the licensed Labrador was
      mis-framed (head cut off — its skinned mesh `get_aabb()` is centred below the floor,
      so the camera aimed under it). New pure `scripts/dog_bounds.gd` (`DogBounds.measure`)
      measures the skeleton **rest-pose bone span** (feet-on-floor, model-agnostic) instead
      of the mesh AABB; `main._dog_bounds()` delegates to it. 2 new tests (90 green), verify
      green, **pixel-verified on the licensed dog** (`.screenshots/024c-licensed-framing-fixed.png`
      — whole dog centred, head in frame). See 024c card "Framing regression — FIXED".

- [x] **027** — the loop actually **repeats** (P1-9) **Done** 2026-06-28: found that
      `main.gd._start_dog` played the sit **once** and stalled (session never closed, dog
      never stood, no second sit) — the stated core loop had never been wired end-to-end.
      New pure `scripts/sit_loop.gd` (`SitLoop`, IDLE/SITTING state machine → START_SIT /
      END_SIT intents, TDD, dog-agnostic); `main._advance_loop/_begin_sit/_end_sit` drive
      idle → sit → idle → sit indefinitely. 96 tests green, verify green, and a runtime
      probe on the **real licensed Labrador** logged 5 sit cycles over 22s (apex 1.250s
      each). Closes the last **non-owner-gated** Phase-1 functional gap. See 027 card.

Epic stays in-progress until 024b–024g land and the **P1-10 done-gate** (all P1
stories, `polish`, independent visual review on the live deploy, TDD coverage) passes.
**024b (visible Sitt on deploy) and the P1-10 live-deploy review remain gated on 025**
(the licensed dog ships only locally; the public deploy is still CC0).

## Context & Motivation

The scaffold (021) only proves the dog loads. Phase 1 (specs2.md §Phase 1, P1-1…P1-9)
is the whole bet: one page where a recognizable dog does a clean **Sitt** with a clear
apex, you tap **BRA** at the apex, and voice + SFX + the dog's reaction land on the
beat — crisp, fair timing feedback. Nothing past Phase 1 starts until it passes Visual
Review and is bug-free (phasing rule).

## Desired Outcome (acceptance, from specs2.md)

- **P1-1** centered, recognizable dog, contact shadow, bright Pokémon-GO backdrop;
  no bare primitive geometry, ever (hold hidden until the model is ready).
- **P1-2** ambient idle (breathing / look-around / tail), centered, seamless loop.
- **P1-3** distinct sit animation building to a clear, readable apex.
- **P1-4** subtle, honest apex tell (pulse/ring/glow) that marks the *actual* peak.
- **P1-5** one big thumb-friendly BRA button; scores PERFECT / OK / Miss by closeness
  to the apex; dead taps do nothing (no penalty in Phase 1).
- **P1-6** Maren-style "Bra!" voice (placeholder TTS ok) + UI click + positive dog
  reaction on a successful mark; nothing plays on a miss/dead tap.
- **P1-7..9** honest timing readout; clean, error-free load.

## Technical Approach

- Build vertically per story (TDD where logic is testable — the scoring window /
  apex-band math is pure and unit-testable via the Godot test runner from task 023;
  visuals via screenshot review on a phone-portrait viewport, findings blocking).
- Drive the pose from the **loaded dog's animations** (the committed glb / licensed
  pack share one rig + clip library, ADR-0002) — AnimationPlayer/AnimationTree.
- The committed glb is the dog (no primitive fallback as shipped product — P1-1).

## Notes / Dependencies

- Depends on 022 (Godot export live) and ideally 023 (Godot test gate) for the
  TDD loop. Until then, exercise scenes headless via `--quit-after`.
- Decompose into per-story cards (idle, sit+apex, tell, BRA+scoring, payoff, readout)
  when picked up — don't build it as one monolith.
