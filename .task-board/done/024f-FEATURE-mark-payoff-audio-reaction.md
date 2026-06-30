# FEATURE: 024f — The mark feels good: voice + SFX + dog reaction (P1-6)

**Status**: On-hold (reopened 2026-06-28, was Done) — logic + wiring real + unit-verified; the audible/
visible beat is 025-gated on the CC0 dog (every tap is DEAD → silent), exactly like the
tell (024d) and the taps (024e). Lights up with zero code change when the licensed
Labrador ships.
**Parent**: 024
**Priority**: High (the payoff is the point of the verb)
**Labels**: gameplay, godot, phase-1, audio, visual
**Estimated Effort**: Medium

## Outcome (specs2.md P1-6)

- A warm, Maren-style spoken **"Bra!"** on a successful mark (placeholder TTS ok for
  Phase 1; real Maren voice is a later owner-gated drop-in under the same cue).
- A crisp UI click under the voice. PERFECT sounds/feels brighter than OK.
- The dog gives a clearly positive reaction (perk-up / bounce / tail wag) on success.
- **Audio gated correctly:** nothing plays on a Miss / dead tap — gate off
  `SitWindow.is_successful(tier)` (024a).

## Approach

- Drive the reaction off the scored tier; key all audio off `is_successful` so a
  MISS/DEAD is provably silent (already a unit test in 024a; assert the wiring too).
- **Owner/asset gate:** the real Maren voice clip is owner-supplied — use a clearly
  labelled placeholder TTS cue and keep the cue id stable so the drop-in is trivial.
  Name this gap precisely in the card; do not block the rest of the slice on it.
- Visual/feel task → `polish` + review for the reaction beat landing on the tap.

## Depends on

- 024a (is_successful gate), 024e (the tap that produces a tier).

## Iteration log (2026-06-28) — TDD, 73 tests green, verify gate green

Built the reward beat as the established pure-logic + dumb-renderer + wiring split, so
the gate is one testable place and the audio can never diverge from what counts as a mark.

**Pure decision — `scripts/mark_payoff.gd` (`MarkPayoff`).** Single source of truth for
the beat: from the scored tier it decides whether the voice / click / dog reaction fire
and how BRIGHT, gating every cue off `SitWindow.is_successful` (024a). PERFECT brighter
than OK (`brightness` 1.0 vs 0.6); MISS/DEAD → `plays()`/`reacts()` false, brightness 0,
empty cue. Voice cue ids are STABLE per tier (`VOICE_PERFECT`/`VOICE_OK`) so the owner's
real Maren "Bra!" drops in under the same id with no code change.

**Audible half — `scripts/payoff_player.gd` (`PayoffPlayer`).** A dumb player owning a
voice + click `AudioStreamPlayer`; it sounds ONLY when `MarkPayoff.plays()`, mapping
loudness/pitch straight off `brightness` (PERFECT louder + a touch higher than OK). The
cues are honest, generatable PLACEHOLDERS synthesized in code (a crisp click + a short
warm "bra" blip — phase-accumulated, enveloped) — real audio, not a faked asset and not
the real voice. (Two Godot gotchas handled: children added in `_init` never get
ENTER_TREE → attach lazily on first play; and `.play()` in the headless `_initialize`
test harness can't sound → set the policy unconditionally, guard the physical `.play()`
behind `is_inside_tree()`. In production/web both are in a running tree and sound.)

**Dog reaction — clip-driven, dog-agnostic.** `DogClips` now resolves a `reaction` clip
by a reaction-specific vocabulary (`wag/happy/excit/greet/celebrat/perk/bark`, priority
order) — deliberately NOT generic locomotion, so the CC0 dog's `Jump` is never mistaken
for a celebration. `DogDirector.play_reaction()` plays it once (LOOP_NONE) then queues
back to the seated hold / idle; a graceful no-op on a dog with no reaction clip (never a
faked reaction). `has_reaction()` is false on the committed CC0 dog (verified against the
real asset) and on the Labrador resolves whatever its pack carries (confirmed at 025).

**Wiring — `main.gd`.** Mounts the `PayoffPlayer` (`_setup_payoff`) and, on every tap,
dispatches `_play_payoff(tier)`: voice+click via the player, reaction via the director,
both gated by `MarkPayoff`. A DEAD/MISS tap is provably silent and provokes no reaction.

**Tests (TDD, red→green each):** `test_mark_payoff` (7 — gate, brightness ordering, cue
stability, reaction gate), `test_payoff_player` (5 — silent on MISS/DEAD, PERFECT louder
than OK, real placeholder streams), `test_dog_clips` (+2 reaction resolution incl. CC0
"no reaction" against the real asset + Jump-is-not-a-reaction), `test_dog_director_reaction`
(2 — plays once / graceful no-op), `test_payoff_wiring` (3 — scene mounts the player, a
real CC0 tap is silent, a forced PERFECT routes through the production dispatch). Suite
73 green; `nix develop -c bash verify.sh` green (import · boot · test · export); boot
mounts the Payoff node clean.

**Asset/visual gate (precise, honest).** P1-6 is **audio + the dog's reaction animation**
— it adds **no new UI element**. On the deployed CC0 dog every tap is DEAD, so the voice,
click, and reaction are **provably dormant** — the live idle frame is unchanged from
`024d-tell-idle.png` (nothing new to screenshot; `polish` N/A — no new visible widget).
The real Maren voice is the owner-gated drop-in under the stable cue id. The audible/feel
review of "the reaction beat landing on the tap" is only observable once **025/ADR-0006**
ships the sit-capable Labrador (real PERFECT/OK taps + a reaction clip); it belongs to
the **P1-10 done-gate** (father review of the live Sitt). No fabricated audio/screenshot.

---
**RESOLVED — Phase 1 SIGNED OFF 2026-06-30 (owner, larssski).** All Phase-1 stories pass on the live deployed licensed build (`po-review.md` Phase Sign-off; PLANNING-BOARD.md). The 025 licensed-dog dependency that parked the 024* sub-tasks is shipped and live; sit / apex / honest tell / BRA scoring / joyful payoff all confirmed in live pixels. Closed with the Phase-1 sign-off. — iteration 056 (board hygiene)
