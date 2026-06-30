# FEATURE: 048 — A dog with a mind of its own: variable cadence + feints (P2-8 logic core)

**Status**: Backlog
**Created**: 2026-06-30
**Type**: FEATURE (round-loop logic — **test-first / TDD**; the feint dip-and-abort pose gets a
Visual Review)
**Priority**: High — the keystone of Phase 2's "read the dog, not a beat." Its prerequisite (the
garden ground, P2-10) just landed in 047, and its consumers are already wired: TrickProgress
(045) already erodes on a DEAD tap "a feint/ambient moment, P2-8", and the future fading trainer
(P2-9) is specified to stay dark during feints. Nothing generates feints or varies the cadence
yet — this builds the generator.
**Labels**: phase-2, logic, dog-behavior, feint, cadence, tdd, p2-8
**Estimated Effort**: Medium (one focused session)

## What it addresses (spec gap)

`.docs/specs/phase2.md` **P2-8 — A dog with a mind of its own** is unimplemented. Today the round
loop (`scripts/sit_loop.gd`) offers a sit on a **fixed metronome** (`DEFAULT_INTER_SIT_GAP := 1.2`)
and **always** opens a markable window — there is no feint. The spec wants the skill to be reading
the dog, not tapping a beat:

- The gap between trick offers **varies** — no metronome cadence to game.
- The dog sometimes **feints**: it starts a sit then aborts. Only a **real, completed** Sitt has a
  markable apex; a feint (or ambient moment) opens **no scoring window**, so tapping it is a
  wrong-moment tap (→ P2-4 negative learning, already built in 045's DEAD erosion).

**Scope of THIS task = the two logic bullets above** (variable gap + feints), as a pure TDD
extension of `SitLoop` plus minimal guarded `main.gd` glue. The third P2-8 bullet — the dog
**wandering** a bounded patch and turning at the edges — is 3D locomotion (render glue on the
now-ready garden ground) and is deferred to its **own sibling task** (visual-domain, Visual
Review) so this one stays a clean, headless-testable logic slice. Note that split in the new
task's header.

## Technical approach

The loop is already a clean pure intent-emitter (`SitLoop.tick()` → Intent; `main._advance_loop`
acts). We extend it in place: a feint is a **new intent + state** that plays a visible dip but
**never opens the session**, so the existing scoring/erosion/tell paths treat a tap during it as
DEAD with zero new branches downstream.

### 1. `SitLoop` — variable gap + feint intents (TDD: write the failing tests first)

Determinism for tests comes from an **injected, seeded `RandomNumberGenerator`** (Godot RNG with a
set seed is fully deterministic); production constructs one with a random seed. Keeps the class
pure + unit-testable exactly like today's `test_sit_loop.gd`.

**Before (`scripts/sit_loop.gd`):**

```gdscript
enum State { IDLE, SITTING }
enum Intent { NONE, START_SIT, END_SIT }

const DEFAULT_INTER_SIT_GAP := 1.2
const DEFAULT_SIT_HOLD := 0.5

var inter_sit_gap: float
...
func _init(p_inter_sit_gap := DEFAULT_INTER_SIT_GAP, p_sit_hold := DEFAULT_SIT_HOLD) -> void:
	inter_sit_gap = p_inter_sit_gap
	sit_hold = p_sit_hold
```

**After (sketch — final shape decided in the red-green loop):**

```gdscript
enum State { IDLE, SITTING, FEINTING }
enum Intent { NONE, START_SIT, END_SIT, START_FEINT, END_FEINT }

const MIN_INTER_SIT_GAP := 0.8    ## shortest idle beat before the next offer
const MAX_INTER_SIT_GAP := 2.0    ## longest — the spread is what kills the metronome
const DEFAULT_SIT_HOLD := 0.5
const FEINT_CHANCE := 0.35        ## fraction of offers that abort instead of completing
const FEINT_HOLD := 0.45          ## seconds the aborted dip is held before standing back up

var _rng: RandomNumberGenerator
var _next_gap: float               ## this cycle's gap, drawn fresh from [MIN, MAX] each idle

func _init(rng: RandomNumberGenerator = null, p_sit_hold := DEFAULT_SIT_HOLD) -> void:
	_rng = rng if rng != null else RandomNumberGenerator.new()
	if rng == null:
		_rng.randomize()
	sit_hold = p_sit_hold
	_draw_next_gap()

func _draw_next_gap() -> void:
	_next_gap = _rng.randf_range(MIN_INTER_SIT_GAP, MAX_INTER_SIT_GAP)
```

In `tick()`: when an idle gap elapses, decide **feint vs real** via `_rng.randf() < FEINT_CHANCE`.
A real offer → `START_SIT` (unchanged downstream). A feint → enter `FEINTING`, emit `START_FEINT`,
hold for `FEINT_HOLD`, then `END_FEINT` back to IDLE and `_draw_next_gap()` for the next cycle.
Preserve the **`has_sit == false` invariant**: a dog that can't sit (CC0) still parks in IDLE and
emits neither `START_SIT` nor `START_FEINT` — never a faked behavior (P1-1 / 024b).

### 2. `DogDirector.play_feint()` — visible dip-and-abort (render glue, no window)

A feint plays the **front** of the real sit and bails — honest reuse of the licensed `Sitting_start`
clip, no new asset. It must NOT queue the seated loop (that would look like a completed sit).

```gdscript
## Begin a sit then abort it (P2-8 feint): play the build-in, then fall straight back to idle
## WITHOUT holding the seated apex. No scoring window opens for a feint (main keeps the session
## closed), so a tap during it is DEAD → gentle erosion (P2-4). No-op on a dog that can't sit.
func play_feint() -> void:
	if _ap == null or not has_sit():
		return
	_set_loop(clips.sit_start, Animation.LOOP_NONE)
	_ap.play(clips.sit_start)
	_ap.queue(clips.idle)   # stand back up — never reach the seated hold
```

### 3. `main.gd` — act on the feint intents, keep the session CLOSED

**Before (`scripts/main.gd:_advance_loop`):**

```gdscript
match _loop.tick(delta, _director.has_sit(), _session.elapsed(), sit_end):
	SitLoop.Intent.START_SIT:
		_begin_sit()
	SitLoop.Intent.END_SIT:
		_end_sit()
```

**After:**

```gdscript
match _loop.tick(delta, _director.has_sit(), _session.elapsed(), sit_end):
	SitLoop.Intent.START_SIT:
		_begin_sit()
	SitLoop.Intent.END_SIT:
		_end_sit()
	SitLoop.Intent.START_FEINT:
		_begin_feint()   # play the dip; do NOT open _session/_window/_tell
	SitLoop.Intent.END_FEINT:
		_end_feint()     # _director.play_idle()
```

`_begin_feint()` calls `_director.play_feint()` and **leaves `_window`/`_tell` null and the session
closed** — so the apex tell stays dark (P1-4 honest, the same path P2-9 will fade), and a tap
during the feint flows through the existing `_on_bra_pressed` → `_session.tap()` → **DEAD** →
`TrickProgress.apply(DEAD)` gentle erosion + the confused beat (`_drive_confused`), with **zero new
downstream branches**. Guard any `.play()` on `is_inside_tree()` (headless harness gotcha).

## TDD — behaviors to test first (`tests/test_sit_loop.gd`, extend)

Per `.claude/skills/tdd/SKILL.md` — red first. Drive the loop with a **seeded** RNG so the
sequence is deterministic, and assert through the public Intent/state surface:

1. **Variable gap** — across consecutive idle cycles the gap is drawn from `[MIN, MAX]` and is
   **not constant** (seeded RNG yields differing gaps; each lands in range).
2. **A feint emits `START_FEINT`, never `START_SIT`**, and opens **no markable window** — assert
   the loop reports `is_feinting()` (not `is_sitting()`), i.e. main would keep the session closed.
3. **Feint ends and resumes** — after `FEINT_HOLD` the loop emits `END_FEINT`, returns to IDLE,
   and the next cycle proceeds (to a real sit or another feint).
4. **Real sits still happen** — over N seeded cycles assert at least one `START_SIT` (feints don't
   replace all sits; `FEINT_CHANCE < 1`).
5. **No faked behavior on a sit-less dog** — `has_sit == false` emits neither `START_SIT` nor
   `START_FEINT`; parks in IDLE (P1-1 invariant preserved).
6. **Wiring (scene-level, in the spirit of `test_payoff_wiring.gd`):** a tap during a feint scores
   **DEAD** and erodes the learned bar (session stayed closed) — the apex tell stays dark through a
   feint.

## Acceptance criteria

- [ ] **Red first:** the new `SitLoop` feint/variable-gap assertions in `tests/test_sit_loop.gd` are
  written and failing before the implementation lands.
- [ ] `SitLoop` draws each idle gap from `[MIN_INTER_SIT_GAP, MAX_INTER_SIT_GAP]` (named constants,
  no scattered literals — cf. 029) via an injectable seeded RNG; behaviors 1, 3, 4 pass green.
- [ ] `SitLoop` emits `START_FEINT`/`END_FEINT` and a feint **opens no scoring window**; behaviors
  2, 5 pass green. The `has_sit == false` (CC0) park-in-idle invariant is preserved (no faked feint).
- [ ] `DogDirector.play_feint()` plays the sit build-in and returns to idle without the seated hold;
  no-op on a sit-less dog (a new `test_dog_*`/director assertion or wiring test covers the no-window
  contract).
- [ ] `main.gd` acts on both feint intents and keeps `_session`/`_window`/`_tell` untouched during a
  feint, so a tap during it is DEAD → gentle erosion + confused beat (existing paths, no new
  branches). Proven by a wiring test (behavior 6).
- [ ] **Out of scope, noted:** the bounded-wander locomotion (the 3rd P2-8 bullet) is filed as its
  own sibling render task — not built here.
- [ ] **Placeholder check** clean on the diff (the feint reuses the real `Sitting_start` clip — no
  stand-in pose).
- [ ] Visual Review (phone-portrait 390×844, licensed Labrador in the local bundle) of a feint: the
  dog visibly dips toward a sit and **stands back up** without holding the seated apex, the apex
  ring stays **dark** through it, and a tap during it shows the confused beat — PASS.
- [ ] `nix develop -c bash verify.sh` green (import · boot · test · export).
