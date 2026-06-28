# FEATURE: 024b — A legible sit with a clear apex (P1-3)

**Status**: Backlog
**Parent**: 024
**Priority**: High (next after 024a; the dog must visibly sit before the tap matters)
**Labels**: gameplay, godot, phase-1, visual
**Estimated Effort**: Medium

## Outcome (specs2.md P1-3)

- The loaded dog plays a **distinct sit animation** that builds to a **clear apex**
  (the fully-seated instant), readable on the dog itself — not just the UI.
- Unmistakably a *sit*, not a generic idle. No foot-sliding, ground clipping, or snap.

## Approach

- Drive from the loaded dog's AnimationPlayer/AnimationTree (ADR-0002 shared rig).
- Mark the apex as a single source of truth (clip keyframe time) and hand it to
  `SitWindow.from_clip(length, apex, …)` (024a) so the band, tell, and pose agree.
- Visual task → run `polish`, spawn phone-portrait screenshot review; findings block.
  Read the pixels directly per the visual-review-divergence rule; don't trust a vote.

## Depends on

- 024a (scoring math, done). Blocks 024d (tell on the apex) and 024e (tap during sit).

## Iteration findings — asset/licensing gate (2026-06-28)

**Discrepancy surfaced while picking this up (recorded per loop rule; spec is
read-only).** The committed/deployed dog `assets/models/dog.glb` is the **CC0
placeholder** and its clip library is `Death, Headbutt, Idle, Idle_Eating, Jump,
Jump_Start, Run, Walk` — **there is no Sitt clip**. The real `Sitting_start /
loop_1 / loop_2 / end` clips live only in the **licensed Labrador**
(`models-build/out_anim.glb`, 19 MB, 100+ clips), which `.gitignore` marks
*NEVER commit* and ADR-0006 ships **only as an encrypted `.pck` built in CI from
a secret-injected glb** — a pipeline that is **not built yet**.

Consequence: the dog the **live site serves (and the father reviews) cannot
perform Sitt**. Faking a sit on the CC0 rig would be the documented
"un-generatable asset" dodge — non-shippable + invisible to pixel-only review.

**This iteration (Option C — keep work moving around the gate):**
- Built a **clip-driven, dog-agnostic** sit architecture (`scripts/dog_clips.gd`
  + `scripts/dog_director.gd`): `DogClips.resolve()` maps idle/sit clips by
  leaf-name across both naming schemes; the apex is the **single source of truth**
  = end of `Sitting_start`, fed to `SitWindow.from_sit_clips()` (024a). On a dog
  with no sit clip it degrades gracefully (idle only, logged — never a faked sit).
- Wired the deployed CC0 dog's **real `Idle` clip** via the director so it is
  *alive*, not a static rest pose (advances P1-2 as a side effect of the shared
  AnimationPlayer wiring).
- TDD: `tests/test_dog_clips.gd` (resolution incl. a `Crouch_Idle_loop` decoy, an
  empty-list case, and a binding to the REAL committed dog) + a new
  `from_sit_clips` apex test in `tests/test_sit_window.gd`. **17 tests green.**

**Verified honestly (not fabricated):**
- A headless bone-delta probe confirmed the CC0 `Idle` genuinely **animates the
  rig** — a real head look-around (~0.18 rad over 120 frames); it is not a frozen
  pose. (The Tail/Body tracks are near-static; the motion is head + a front paw.)
- A **real web-build screenshot** (headless Chrome on the verify export, gated on
  `window.__appReady`) shows the dog **centered-ish, recognizable, on the bright
  backdrop, mid-idle** — saved at `.screenshots/godot-web-idle.png`. It shows
  **idle only**: the CC0 dog cannot sit, which is exactly the gate.
- The **Labrador Sitt was NOT rendered** this iteration — `models-build/` carries
  a `.gdignore` (ADR-0006: the licensed asset must never enter the public `.pck`),
  so it is not loadable from `res://` and I did not circumvent that. The clip
  architecture is validated against the Labrador's **real clip names** (read from
  the glb) via unit tests, not against rendered pixels.

**Observed P1-1 scaffold gaps (not this task — for a future P1-1 card):** the dog
sits high in the portrait frame (empty space below — vertical framing), and there
is **no contact shadow** under it.

**Still gated (why 024b stays in-progress):** P1-3's "the dog plays a distinct
sit animation, readable on the dog" is **not visible on the live deploy** until
either the **ADR-0006 encrypted-licensed-asset CI pipeline** lands (real Labrador
ships, with its authored Sitt) or the owner authorizes a CC0 Sitt. Recommend a new
task for the ADR-0006 pipeline; this is an **owner/asset decision**, not a
technical block.
