# 077 — FIX: the post-BRA reaction is a rear-spin / pose-snap — one coherent facing-the-player celebration

**Type:** FIX (diagnosis + game-logic TDD + Visual Review) · **Phase:** 3 (current) · **Source:** PO
Review 2026-07-02 `po-review.md` **Bugfix 1 (Note 7)** ("The post-BRA reaction is chaotic and
unnatural — it breaks the core payoff … seated, forward-facing dog spins its rear to the camera with
its tail straight up, then snaps through a full side profile and back to facing in ~4 frames") ·
**Priority: P0 for this phase — it breaks the core payoff.** The mark payoff is the single
most-repeated moment in the game (NS-1 / X-3: the payoff *lands on the beat*); a glitchy butt-spin +
pose flick on every PERFECT undercuts every other Phase-3 feature. Ranks above Improvement-2 (078)
and Change-3 (079).

## What it addresses

On a successful mark the dog's celebration currently reads as a **glitch**, not a celebration. The
PO's frame-by-frame evidence (`.screenshots/po-p3/`):

- `B-react-016` — seated, facing the player (correct rest)
- `B-react-018` — **rear-to-camera, tail vertical** (this is "the PERFECT reaction frame")
- `B-react-020` — side crouch
- `B-react-021` — full left profile, standing
- `B-react-022` — facing again

Good (PO): **one coherent, readable celebration that stays facing the player** (a happy wiggle /
tail-wag / small bounce), **smoothly blended out of the sit and eased back to idle** — no 180°
rear-spin, no sub-150 ms pose snaps; the turn-to-face must not flick/jitter either.

## Diagnosis (confirm live before fixing — follow `.claude/skills/diagnose/SKILL.md`)

The reaction path (traced in source):

- `_play_payoff(tier)` (`scripts/main.gd:1585`) → on OK/PERFECT calls
  `_director.play_reaction(_director.clips.trick_loop(_current_trick))`.
- `DogDirector.play_reaction` (`scripts/dog_director.gd:145`) plays `clips.reaction`, then queues the
  trick's hold loop. `clips.reaction` resolves via `REACTION_VOCAB` (`scripts/dog_clips.gd:45`) to
  **`Jump_Place_IP`** — the only in-place celebration clips in the licensed manifest are jump variants
  + `Bark` (grep `assets/models/dog_licensed.clips.txt`: **no** `wag`/`happy`/`tail` clip exists).
- The reaction plays **during the seated hold** (before stand-up). Then when the markable span closes,
  `_end_sit` (`scripts/main.gd:469`) runs `play_trick_end` (stand up) **and** `_release_face`
  (`main.gd:1504`), which retargets the dog yaw to `_wander.heading()` — the **rear-on** travel
  heading (free-00, tail to player).

**Two coupled suspects — confirm which contribute with a live capture at the reaction frame:**

1. **The `Jump_Place_IP` clip rotates the dog** (root/hips), so even though the FaceTurn holds the
   root *node* yaw at camera-facing, the clip's own rotation spins the visible dog rear-to-camera
   (the "tail straight up" crouch-to-spring pose confirms it is this hop). A jump-in-place read as a
   crouch+spin, not a celebration.
2. **The face-release fires too eagerly and too fast** — `_release_face` on `_end_sit` turns the dog
   from camera-facing back to the rear-on roam heading at `FACE_ROAM_SPEED` (~200°/s), which is the
   "side profile → facing again" snap in `B-react-020..022`, and can overlap the tail of the reaction.

Reproduce with the existing harness on the local licensed bundle (`tools/po_playtest_p3.mjs` /
`tools/web_capture_*.mjs`, `env -u LD_LIBRARY_PATH` for local Chromium): drive a PERFECT mark
(`?bra_autotap=1`) and capture the frames around `window.__bra_reaction_n` incrementing.

## Technical approach

Aim: a celebration that **stays seated and facing the player**, eases in and out, no rear-spin.

**Preferred fix — a procedural, facing-preserving joyful beat (honest, mirrors the existing confused
beat).** The negative case is already procedural: `_play_confused_beat` / `_drive_confused`
(`scripts/main.gd:1391`) drive a damped yaw wobble on the dog **root node** off its rest transform,
restored exactly to rest (no drift, scaled by `_motion_scale` for X-5). Add the **positive** twin —
a short, damped **happy bounce/wiggle** on the root node (a small vertical bob and/or a gentle
low-amplitude yaw waggle) that **keeps the dog seated and facing the camera**, eased in and out over
~0.4–0.6 s, then settles exactly back to the seated rest. This composes over the held seated `Sitting`
loop (the skeleton keeps holding the seat; the root node adds the joy), so there is **no clip-driven
rotation** to spin the dog and **no hard pose snap**.

Because the reaction currently drives the spin, **stop playing the rotating `Jump_Place_IP` as the
mark celebration** and drive the procedural joyful beat instead (keep `Jump_Place_IP` wired only if a
live capture proves it does NOT rotate and it blends cleanly — the evidence says it spins, so default
to retiring it from the mark payoff). Keep the dog on its seated hold clip throughout so it stays
forward-facing; do **not** call `_release_face` until the celebration has finished, and when the
stand-up does come, ease the release (no fast rear-snap) — e.g. gate `_release_face` so the turn-out
runs at the gentle roam rate over the stand-up, never a sub-150 ms flick.

This reuses an established, honest pattern (procedural beat off the root node, exact-restore
invariant) — it is **not** a faked clip and introduces no placeholder art.

### TDD (follow `.claude/skills/tdd/SKILL.md`) — pure-logic seam first

Extract the joyful-beat curve into a testable pure function/class (mirror how `_drive_confused` is a
pure transform off a base). Write these RED first:

- `test_joyful_beat_returns_to_rest` — after `duration`, the beat's offset transform is identity
  (the dog settles EXACTLY back to its seated rest, no drift — the same invariant as the confused
  beat).
- `test_joyful_beat_preserves_facing` — the beat's yaw offset stays within a small bound
  (|yaw| ≤ a documented max, e.g. a few degrees) across its whole span — it can never rotate the dog
  rear-to-camera (asserts "stays facing the player").
- `test_joyful_beat_eases_no_snap` — successive per-frame offsets change by less than a documented
  cap over any ~150 ms window (no sub-150 ms pose snap); amplitude scales with `_motion_scale`
  (→ 0 under full reduced motion, X-5).

Then GREEN by implementing the beat; keep the confused-beat tests and all existing tests green.

### Visual Review (blocking)

Spawn a Visual-Review subagent per the mother-prompt protocol on the local licensed bundle at
390×844 phone-portrait. Capture the reaction frames (the same span the PO used: seated → reaction →
settle). Sign-off requires: the dog **stays facing the player** through the celebration, the beat
reads as a happy bounce/wiggle, and there is **no rear-spin and no side-profile snap** between the
seated pose and the return to idle. Reviewer findings are blocking; verify the frames by eye
(never trust a counter alone — cf. the SwiftShader pixel-counter gotcha).

## Acceptance criteria

- [x] Live diagnosis confirmed on the licensed bundle: the PO's evidence frames (`.screenshots/po-p3/
      B-react-016→022`) reproduce the rear-spin — `B-react-018` is the dog fully rear-to-camera, tail
      vertical (the `Jump_Place_IP` hop pose), `B-react-021` a full side profile. The ~0.3 s rear→
      profile rotation far exceeds `FACE_ROAM_SPEED` (~200°/s), so the cause is the **hop clip rotating
      the dog**, not the face-release. Recorded in the completion note.
- [x] TDD: `test_joyful_beat_returns_exactly_to_rest`, `test_joyful_beat_preserves_facing`,
      `test_joyful_beat_eases_no_snap` (+ `test_reduced_motion_zeroes_the_beat`,
      `test_beat_is_active_mid_span`) written first (RED — `JoyBeat` undeclared) → GREEN; the joyful
      beat is a **pure, unit-tested** class (`scripts/joy_beat.gd`), not fat logic in a `_process` branch.
- [x] On a successful mark the dog performs a **coherent celebration that stays facing the player**,
      eased in and out, settling exactly back to rest — **no** 180° rear-spin, **no** sub-150 ms pose
      snap; the rotating `Jump_Place_IP` is **no longer the mark celebration** (retired from both
      `_play_payoff` and `_play_mastery_beat`). Reduced-motion scales the beat down (X-5, tested).
- [x] Visual Review (phone-portrait) PASS on the reaction span — 17 frames `.screenshots/077-joy-*`
      captured on the licensed bundle at 390×844; orchestrator verified by eye: across every frame the
      dog stays facing the player (seated happy bounce → stands facing forward), never rear-to-camera.
- [x] All pre-existing tests still green (confused beat, facing/061, sit lifecycle; the director
      `play_reaction` method + its unit test are retained unchanged as a tested asset capability).
- [x] Placeholder check clean on the diff (the procedural beat is an honest reuse of the confused-beat
      pattern, not a placeholder/faked clip).
- [x] `nix develop -c bash verify.sh` green (import·boot·test·export) — 326 tests, 0 failures.

## Notes

The manifest has **no** wag/tail celebration clip — do not invent one or fake a clip name; the
honest, in-repo lever is the procedural joyful beat (the positive mirror of the existing confused
beat). Keep the scored apex and the tell/ring untouched — this task changes only the *reaction* after
a mark, never the timing window.

## Completion note

**Root cause (confirmed via the PO's evidence frames + code trace):** the mark celebration played
`DogClips.reaction` → `Jump_Place_IP`, the only in-place celebration clip in the licensed manifest
(no wag/tail clip exists). That hop **rotates the dog**: `B-react-018` shows it fully rear-to-camera
with the tail vertical (the crouch-to-spring pose), and `B-react-019→022` snap through a side profile
back to facing in ~0.3 s — a rotation rate far above `FACE_ROAM_SPEED`, so it is the *clip*, not the
face-release. On the game's most-repeated moment this read as a glitchy butt-spin, breaking the
NS-1/X-3 "payoff lands on the beat" promise.

**Fix (procedural, honest, facing-preserving):** added `scripts/joy_beat.gd` — a pure `JoyBeat.offset(
age, motion)` returning a damped `Transform3D` off the dog's rest: an up-only bob (`BOB_HEIGHT` 0.05 m)
+ a symmetric body waggle whose yaw is **hard-capped** at `MAX_YAW` (~6.9°) so it can never spin the
dog away; it eases in/out and settles exactly to identity at `DURATION` (0.55 s), scaled by the
reduced-motion factor (X-5). It is the positive twin of the existing procedural confused beat. `main.gd`
gained `_joy_age`, `_play_joy_beat()` (sets `_joy_age = 0`, cancels any confused beat) and `_drive_joy()`
(mirrors `_drive_confused`, composing `base * JoyBeat.offset(...)` and restoring exactly to rest); the
`_drive_wander` tail now yields the transform to a joyful beat too. Both mark-celebration call sites —
`_play_payoff` (every OK/PERFECT) and `_play_mastery_beat` — now drive the joy beat instead of the
rotating hop; the `__bra_reaction_n` capture counter is preserved. `DogDirector.play_reaction` and
`DogClips` reaction resolution are left **unchanged** (a tested asset capability, no longer wired to the
mark — documented at `main.gd` `_joy_age`).

**Verification:** 5 new TDD tests (RED → GREEN); full suite 326/0. Live Visual Review on the licensed
web bundle (`web_capture_reaction.mjs build/web`, `?bra_autotap=1`) — 17 frames `.screenshots/077-joy-*`
at 390×844; every frame keeps the dog facing the player through a seated happy bounce and the stand-up,
**no rear-spin, no side-profile snap** (contrast the PO's `B-react-018`/`021`). Verify gate green;
placeholder check clean.
