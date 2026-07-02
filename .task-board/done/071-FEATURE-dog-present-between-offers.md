# 071 — FEATURE: dog reads present between offers — centred, facing the player, scratch feint

**Type:** FEATURE (mixed: TDD logic + Visual Review) · **Phase:** 3 (current) · **Source:** PO
Review 2026-07-02 `po-review.md` **Actionable note 3** ("Its also out of the screen center and
looking away too much, it should just not be completely static. Use the scratch as a feint, its
funny") + PO sharpening ("keep it framed and generally facing the player between offers … never a
long rear-on stretch; add a scratch as one of the feints"). · **Priority:** P1 for this phase.

## What it addresses

Between offers the dog ambles a bounded patch (`WanderField`, radius 0.32 m) and faces **where it
walks** — so it regularly stands **rear-on** (`free-00`, tail to the player) and drifts off the
screen centre. The owner wants the dog, between offers, to (a) stay reasonably **centred**, (b)
**generally face the player** (alive, not a statue, but never a long rear-on stretch), and (c)
add a **scratch** as one of its funny feints.

The asset already holds a `Arm_Labrador|Scratching` clip (manifest `dog_licensed.clips.txt`) — so
the scratch feint is a **BUILD** task, not owner-gated (behavior ≠ inventory).

Feint **rate** is a separate task (070, ~90/10); this task adds a scratch **variety** of feint and
fixes between-offer framing/facing. The one-active-trick + completion menu is 072.

## Technical approach

Three cohesive parts — the dog's between-offer *presence*.

### 1. Generally face the player between offers (fix "looking away")

Today `_dog_yaw()` returns the `FaceTurn` heading only while a trick engages/releases, else the
raw `WanderField.heading()` (travel direction → often rear-on). Bias the **resting** heading toward
the camera so a paused dog faces the player, while a *moving* dog still faces its travel direction
(reads as roaming, not moon-walking). Reuse the existing `_camera_facing_heading()` +
`FaceTurn` machinery (061) — no new turning math.

**Before** (`scripts/main.gd`, `_drive_wander` picks clip by movement; yaw follows travel):
```gdscript
if _wander.is_moving() and not _ambling:
    _director.play_walk(); _ambling = true
elif not _wander.is_moving() and _ambling:
    _director.play_idle(); _ambling = false
# ... _dog_yaw() → _wander.heading() when not in a trick (rear-on while paused)
```
**After** — when the wander pauses at a target, ease the yaw to the camera-facing heading (so the
dog looks at the player during the pause); when it starts moving again, hand yaw back to the travel
heading. Implement via the existing `_face`/`_advance_facing` path (engage a gentle roam-speed
`FaceTurn` to `_camera_facing_heading()` on pause; retarget to `_wander.heading()` on move) so the
turn is bounded and eased, never a snap. Keep it subtle — "not completely static", never rigidly
locked front-on.

### 2. Keep the dog centred (fix "out of the screen center")

Tighten the roam so the dog never drifts far off centre. `WanderField.DEFAULT_RADIUS` 0.32 m →
a smaller value (Visual-Review-tuned, ~0.20 m) so it still ambles with life but stays framed.

**Before** (`scripts/wander_field.gd`): `const DEFAULT_RADIUS := 0.32`
**After:** `const DEFAULT_RADIUS := 0.20   ## tighter patch so the dog stays screen-centred (PO note 3)`

### 3. Scratch feint (the funny one)

Add a `Scratching` clip to the resolver + a `play_scratch()` to the director, and make a feint
*sometimes* a scratch instead of a trick-dip. All three keep the never-fake gate: a dog without a
scratch clip falls back to the existing trick-dip feint.

**`scripts/dog_clips.gd`** — resolve the clip + capability:
```gdscript
var scratch: String    ## a self-scratch, used as a funny ambient feint (071); "" if the dog has none
# in resolve(): c.scratch = _pick_scratch(names)
static func _pick_scratch(names: PackedStringArray) -> String:
    for n in names:
        if _leaf(n).to_lower().contains("scratch"):   # licensed `Scratching`
            return n
    return ""
func has_scratch() -> bool:
    return scratch != ""
```

**`scripts/dog_director.gd`** — play it once, then settle to idle (a one-shot, never a loop; the
same honest reuse pattern as `play_trick_feint`):
```gdscript
func has_scratch() -> bool:
    return clips.has_scratch()
func play_scratch() -> void:
    if _ap == null or not has_scratch():
        return
    _set_loop(clips.scratch, Animation.LOOP_NONE)
    _ap.play(clips.scratch)
    if clips.idle != "":
        _ap.queue(clips.idle)   # stand back to the ambient idle after the scratch
```

**`scripts/sit_loop.gd`** — when an offer is a feint, seeded coin-flip whether it's a *scratch*
feint (still opens NO markable window):
```gdscript
const SCRATCH_FEINT_CHANCE := 0.5   ## of feints, ~half are a scratch (rest are the trick-dip)
var _feint_is_scratch := false
# in tick() when entering FEINTING:
_feint_is_scratch = _rng.randf() < SCRATCH_FEINT_CHANCE
# public read (valid while FEINTING):
func is_scratch_feint() -> bool:
    return _state == State.FEINTING and _feint_is_scratch
```

**`scripts/main.gd`** — dispatch in `_begin_feint()` (falls back to the trick-dip if the dog can't
scratch, so the CC0 gate holds):
```gdscript
func _begin_feint() -> void:
    _pause_wander()
    if _loop.is_scratch_feint() and _director.has_scratch():
        _director.play_scratch()          # the funny scratch — still no scoring window (P2-8)
    else:
        _director.play_trick_feint(_current_trick)
```

### TDD (follow `.claude/skills/tdd/SKILL.md`) — the pure/logic parts, RED first

- `tests/test_dog_clips.gd`: extend the LAB fixture with `"Arm_Labrador|Scratching"` and assert
  `resolve(...).scratch` leaf contains "scratch" and `has_scratch()` is true; assert the CC0 fixture
  resolves `scratch == ""` / `has_scratch()` false (never fakes a scratch).
- `tests/test_dog_director_feint.gd` (or a new `test_dog_director_scratch.gd`): `play_scratch()`
  plays the scratch clip once and queues idle on a scratch-capable stub; no-ops (no error, stays
  idle) on a scratch-less stub. Reuse the existing AnimationPlayer test stub.
- `tests/test_sit_loop.gd`: over many seeded feints, `is_scratch_feint()` is true for ~half and
  false for the rest (both scratch and trick-dip feints occur); `is_scratch_feint()` is false while
  SITTING/IDLE. A scratch feint still opens no markable window (loop stays FEINTING, not SITTING).

Parts 1 & 2 (framing/facing feel) are **Visual Review** — verify in pixels at 390×844.

## Acceptance criteria

- [x] TDD: failing tests first for scratch clip resolution + `has_scratch()` (LAB true, CC0 false),
      `play_scratch()` (plays once + queues idle; no-op scratch-less), and `is_scratch_feint()`
      distribution (~half of feints, false outside FEINTING) — RED → GREEN.
- [x] A feint is sometimes a **scratch** (via `Scratching`) and sometimes the trick-dip; both open
      no markable window (a tap during either is DEAD, no penalty). CC0 dog never scratches.
- [x] `WanderField.DEFAULT_RADIUS` tightened so the dog stays screen-centred; still ambles (not static).
- [x] Between offers the dog **generally faces the player** (never a long rear-on stretch) yet stays
      alive (eased, subtle — not rigidly locked front-on); a moving dog still faces its travel dir.
- [x] Visual Review at 390×844 (licensed bundle, headless Chromium, `env -u LD_LIBRARY_PATH`):
      capture a between-offers burst — dog centred + facing the player, and a scratch feint frame;
      no rear-on hold. Boot clean, zero console errors. Screenshots under `.screenshots/071-*`.
- [x] Placeholder check clean on the diff; `nix develop -c bash verify.sh` green.

## Resolution (2026-07-02)

Shipped all three parts. **Part 1 (facing)** — reused the 061 `FaceTurn`/`_advance_facing` path: a
paused dog eases (roam rate) to `_camera_facing_heading()` (`_engage_resting_face` on the amble→pause
transition); a moving dog hands yaw back to its travel heading (`_release_resting_face`). Restructured
`_advance_facing` so only the trick turn-IN (`_facing`) eases while the roam is paused; the ambient
resting turn + the trick turn-OUT ease only while `_wander_active` — keeping the 045 confused-beat
"no drift" invariant and the frozen offer base intact. **Part 2 (centring)** — `WanderField.DEFAULT_RADIUS`
0.32 → 0.20. **Part 3 (scratch feint)** — `DogClips.scratch`/`has_scratch()`/`_pick_scratch` (licensed
`Scratching`, absent on CC0), `DogDirector.play_scratch()` (one-shot then queue idle),
`SitLoop.is_scratch_feint()` (a second seeded coin-flip, `SCRATCH_FEINT_CHANCE 0.5`, when a feint
opens), dispatched in `main._begin_feint` (`_loop`-null-guarded; falls back to the trick-dip if the
dog has no scratch clip). Feint knobs made instance vars (defaulting to the consts) so a web-only
`?bra_force_scratch=1` capture seam can pin every offer to a scratch feint (the brief scratch is
otherwise ~5% of offers — same idiom as `?bra_force_tell`).

TDD: 7 new failing tests → green (`test_dog_clips` scratch resolution + real-asset binding,
`test_dog_director_scratch`, `test_sit_loop` scratch-feint distribution / flag-outside-feint /
no-markable-window). Two 061 scene tests (`test_face_wiring`) updated to the new note-3 contract —
they asserted "no facing between offers", now superseded; the surviving 061 invariants (a real trick
turns to the camera; a feint never engages the *trick* turn-in; the release hands facing back to the
roam) are still asserted. Full suite 297 tests, 0 failures. `verify.sh` green (import·boot·test·export).

Visual Review (390×844, licensed bundle, headless Chromium): default-play burst
(`.screenshots/071-play-00..19`) — dog centred, 18/20 frames facing the player; the one rear-on frame
is a brief mid-amble pivot (13→14→15), not a stationary hold. Forced-scratch burst
(`.screenshots/071-scratch-00..13`) — a distinct scratch dip/bow + hind-leg raise, then settle to
idle. Boot clean, zero console errors. Review verdict: PASS. Placeholder check clean (only the
legitimate "CC0 placeholder" asset name + honest never-fake documentation).

## Notes

Reuses the existing `FaceTurn` (061) for the resting face-the-player turn and the honest
one-shot-then-idle clip pattern (`play_trick_feint`/`play_reaction`) for the scratch — no new
turning math, no new asset. Keep facing subtle: the owner wants "not completely static," not a
front-locked statue.
