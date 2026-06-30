# FEATURE: 050 — The dog wanders the garden patch (P2-8 locomotion, sibling of 048)

**Status**: Backlog
**Created**: 2026-07-01
**Type**: FEATURE (3D locomotion render glue on the garden ground — **Visual Review**, not TDD;
any pure helper it factors out, e.g. the bounded-patch clamp, IS unit-tested)
**Priority**: High — the visible half of P2-8. Its logic sibling (048, variable cadence + feints)
just landed; the garden ground it rides (P2-10) landed in 047. Together they complete the PO's
P2-8 directive: "the dog roams and turns at the patch edges, the gap between offers varies, and a
feint/ambient moment opens no scoring window."
**Labels**: phase-2, visual, dog-behavior, locomotion, wander, p2-8

## What it addresses (spec gap)

`.docs/specs/phase2.md` **P2-8 — A dog with a mind of its own**, and the **2026-07-01 PO review**
(`.docs/specs/po-review.md`, Improvements): *"Across a 45 s run the dog never left dead-centre …
P2-8 wants a dog that **wanders** the bounded grass patch (turning back at the edges, camera
fixed)."* Task 048 delivered the variable gap + feints (no metronome, no window on a feint) but
explicitly deferred the **locomotion** to this sibling so the logic core stayed a clean,
headless-testable slice. Today the dog is stationary at world origin.

## Technical approach

The garden ground plane (047) and the camera framing (the look-down `_frame_camera`) are already
in place and stay FIXED — only the dog root translates within a bounded patch on the grass.

- **A bounded ambient wander** between trick offers: the dog ambles to a fresh point inside a
  bounded patch (a radius / rect centred on origin, well inside the 40×40 grass and the framed
  view so it never walks out of frame), pauses, picks another — turning to face its heading so it
  reads as *roaming*, not sliding. Camera does not follow (the PO's "camera fixed").
- **Turn back at the edges:** clamp the target to the patch; on reaching an edge the dog turns
  inward. Factor the clamp + next-target pick into a **pure** helper (e.g. `WanderField`) so the
  bounded-patch math is unit-tested headless (in range, turns at the edge, never leaves the
  patch), even though the node-driving glue is Visual-Review-gated.
- **Compose with 048 cleanly:** wander only while IDLE; when SitLoop offers a sit or a feint the
  dog should be settled/heading-neutral enough that the sit/feint reads. Simplest: pause wander on
  START_SIT/START_FEINT, resume on END_SIT/END_FEINT (main already routes those intents).
- **Honest motion only:** translate/rotate the dog ROOT (the AnimationPlayer drives the skeleton).
  Reuse a real walk/locomotion clip IF the licensed pack carries one; if it does NOT, do **not**
  fake a walk cycle — a smooth glide with a heading turn is acceptable ambient motion for now, OR
  spike whether a locomotion clip exists. Never a primitive or a faked gait (CLAUDE.md). If a clean
  walk clip is genuinely owner-gated, ship the glide and **flag** the gait gap.

## Acceptance criteria

- [ ] The dog wanders a bounded patch on the grass between offers and **turns back at the edges**;
  the camera stays fixed (the PO's P2-8 "camera fixed", "turning back at the edges").
- [ ] The bounded-patch helper is **pure + unit-tested** (target in range, edge turn, never leaves
  the patch); the node glue is Visual-Review-gated.
- [ ] Wander pauses for a real sit AND a feint (composes with 048) so both still read clearly; it
  never drags the dog out of frame or off the grass.
- [ ] **Placeholder check** clean — no faked walk cycle / no primitive; a reused real locomotion
  clip or an honest glide, with any owner-gated gait gap flagged (not silently stubbed).
- [ ] Visual Review (phone-portrait 390×844, licensed Labrador in the local bundle): the dog reads
  as *roaming* the garden and turning at the edges, stays centred-ish and fully framed, grounded by
  its contact shadow on the grass — PASS.
- [ ] `nix develop -c bash verify.sh` green (import · boot · test · export).

## Results (2026-07-01)

**Done — verify gate green (import · boot · test · export), 190 tests / 0 failures.**

What shipped:
- **`scripts/wander_field.gd`** — the PURE bounded-patch wander (TDD, `tests/test_wander_field.gd`):
  amble→pause→amble inside a disc, sqrt-area target sampling (always in range), `clamp_to_patch`
  edge turn-back, heading faces travel, seeded-RNG determinism. Five unit tests cover the three
  acceptance bullets (target in range · edge turn · never leaves the patch) plus heading + the
  amble/pause rhythm.
- **`scripts/dog_clips.gd`** — resolves a real `walk` clip + `has_walk()` (licensed `Walk_F_IP`
  in-place, CC0 `Walk`); honest gate when none. Tests in `test_dog_clips.gd`.
- **`scripts/dog_director.gd`** — `play_walk()` loops the gait (no-op without a walk clip);
  `tests/test_dog_director_walk.gd`.
- **`scripts/main.gd`** — glues it on: builds the wander only on a walk-capable dog, drives the
  dog ROOT from it each frame while idle, plays walk while stepping / idle while paused, PAUSES
  the roam during a sit/feint (composes with 048) and resumes after, slides the contact shadow to
  track the dog, and composes the confused beat (045) off the wander base instead of boot rest.
  `tests/test_wander_wiring.gd` pins the composition contract.

Honest-asset note: rides the **real** licensed `Walk_F_IP` clip (in-place, root motion stripped —
main owns the translation) — no faked gait, no primitive, no glide-while-standing.

Visual Review (PASS): captured 10 phone-portrait (390×844) frames off the local Web bundle (which
carries the licensed Labrador) at radius 0.32. The dog roams to distinct spots, turns to face its
heading (reads as roaming, not sliding), shows a real walk gait and a real sit, stays fully framed
and centred-ish, and is grounded by its contact shadow every frame; the camera/sun/UI stay fixed.
**Tuning:** a first pass at radius 0.55 walked the dog's head off the right edge — dropped to 0.32,
which keeps it fully framed at its widest while still reading clearly as a roam.

Incidental fix (NOT this task's scope, but it blocked the gate): `test_tell_wiring.gd`'s
`test_live_tell_…` was a **latent flake 048 introduced** — it drove a *random* `SitLoop.new()`, and
with 048's variable cadence + 35% feints a real sit didn't always open in the frame budget
(reproduced 2/4 fail across runs). Made it deterministic by opening the sit through the same
production `_begin_sit()` path with the random loop detached; every assertion preserved; now 5/5
green. `test_learned_bar_wiring`'s confused-beat test updated to assert no-drift off the **wander
base** (the dog now legitimately wanders off boot rest).
