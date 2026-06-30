# FEATURE: 045 — Learned bar + mastery (P2-4, "feel the dog learning")

**Status**: Backlog
**Created**: 2026-06-30
**Type**: FEATURE (game logic — **test-first / TDD**; the on-screen bar + confused beat get a
Visual Review)
**Priority**: P0 for Phase 2 — the spine of the phase. "Feel the dog learning" is the core
Phase-2 verb; the trick selector (P2-1), persistence (P2-5), and the fading timing trainer
(P2-9) all hang off a learned-progress model, so it lands first.
**Labels**: phase-2, logic, progression, mastery, tdd, p2-4
**Estimated Effort**: Medium (one focused session)

## What it addresses (spec gap)

`.docs/specs/phase2.md` **P2-4 — Feel the dog learning** is entirely unimplemented. There is
no learned-progress model anywhere in `scripts/` — a BRA mark fires the payoff and flashes the
tier readout (`main.gd:526` `_on_bra_pressed`), but nothing accumulates toward mastery and a
mistimed tap has no consequence. Phase 2's whole point ("breadth of tricks, **feel the dog
learning**") rests on this.

Acceptance from the spec (P2-4, as amended by the 2026-06-29 PO directive on negative learning):

- A well-timed BRA fills a **learned** bar toward mastery; **PERFECT fills more than OK**.
- **Wrong timing removes learning** — a mistimed tap (MISS) or a tap with no real apex (a
  feint / ambient moment → currently a DEAD tap; P2-8 will add real feints) **erodes** the bar.
- **No hard fail, but progress is erodible:** good play always **nets forward** (a PERFECT adds
  clearly more than a bad tap removes), the bar **floors at 0**, and a bad tap can't end the
  game. Early game is **gentle** (harsher erosion is a Phase-4 knob, P4-2).
- A bad tap also **reads on the dog** — a brief **confused beat**, the mirror of the joyful mark
  — so the setback is *felt*, not a silent number dropping.
- **100% masters** the trick with a **celebratory beat** and is a **safe checkpoint**
  (re-practice can't un-master it); mastered tricks stay **re-practiceable**.

## Scope / non-goals (keep it tight)

- **One trick (Sitt) for now.** `P2-2` (Ligg / Legg deg and the rest) is **asset-gated** — the
  licensed Labrador pack ships only `Sitting_*` (see `tests/test_dog_clips.gd` clip list: no
  lie-down clip), so there is exactly one real trick today. Build the model **keyed by a trick
  id** so the selector (P2-1) and persistence (P2-5) drop in later, but only wire the Sitt bar.
- **No persistence here** — `P2-5` (IndexedDB save/restore) is a separate task. The bar resets
  per session for now; the model just exposes a clean value to serialize later.
- **Confused beat = a procedural beat, not a new clip.** There is no "confused" clip in the
  pack, so do **not** fake one. The dog's setback reads as a brief honest **recoil/settle**
  (a small procedural transform nudge) plus the bar visibly dropping — the mirror of the
  existing joyful hop. No primitive/stub stand-in.

## Technical approach

### 1. New pure class `TrickProgress` (TDD — write the failing tests first)

A `RefCounted` holding **one trick's** learned value in `[0, 1]`, mirroring the existing
pure-logic + test pattern (`scripts/sit_session.gd` ↔ `tests/test_sit_session.gd`). All tuning
lives in **named constants** (cf. task 029 — no scattered literals).

**Before:** _(no file)_

**After — `scripts/trick_progress.gd`:**

```gdscript
class_name TrickProgress
extends RefCounted
## Per-trick learned progress (P2-4). One instance = one trick's bar in [0, 1].
## Pure + unit-testable; main.gd feeds it the scored SitWindow.Tier on every tap.

## Tuning (homed, not scattered — cf. 029). Invariant the tests pin:
## PERFECT_GAIN > max(MISS_EROSION, DEAD_EROSION) so good play always nets forward.
const PERFECT_GAIN := 0.20
const OK_GAIN := 0.08
const MISS_EROSION := 0.10   ## a real apex, mistimed
const DEAD_EROSION := 0.05   ## a tap with no open window (feint / ambient) — gentler
const MASTERY := 1.0
const FLOOR := 0.0

var value: float = 0.0       ## learned fraction in [0, 1]
var mastered: bool = false   ## latches true at value >= MASTERY; never un-latches (safe checkpoint)

## Apply a scored tap. Returns the SIGNED delta actually applied (after clamping) so main
## can drive feedback: delta > 0 → fill; delta < 0 → confused beat; mastered-now → celebrate.
func apply(tier: int) -> float:
	var before := value
	var was_mastered := mastered
	match tier:
		SitWindow.Tier.PERFECT: value += PERFECT_GAIN
		SitWindow.Tier.OK:      value += OK_GAIN
		SitWindow.Tier.MISS:    value -= MISS_EROSION
		SitWindow.Tier.DEAD:    value -= DEAD_EROSION
	# Mastery is a safe checkpoint: once mastered, re-practice can't drop below MASTERY.
	var low := MASTERY if mastered else FLOOR
	value = clampf(value, low, MASTERY)
	if value >= MASTERY:
		mastered = true
	return value - before

## True only on the tap that first reaches mastery (drives the one-shot celebratory beat).
func just_mastered(applied_delta: float) -> bool:
	return mastered and applied_delta > 0.0 and (value - applied_delta) < MASTERY
```

_(If `just_mastered` reads awkwardly, fold the "newly mastered" signal into `apply`'s return as
a small result struct/dict — pick the cleanest expression during green; the behavior, not the
shape, is what the tests pin.)_

### 2. Wire it into the mark flow (`main.gd`)

**Before (`scripts/main.gd:526`):**

```gdscript
func _on_bra_pressed() -> void:
	var tier := _session.tap()
	marked.emit(tier)
	_play_payoff(tier)
	if _readout != null:
		_readout.display(tier)  # flash PERFECT/OK/MISS now; DEAD shows nothing (024g/P1-7)
	...
```

**After:**

```gdscript
func _on_bra_pressed() -> void:
	var tier := _session.tap()
	marked.emit(tier)
	_play_payoff(tier)
	if _readout != null:
		_readout.display(tier)
	var delta := _progress.apply(tier)        # P2-4 learned bar
	if _learned_bar != null:
		_learned_bar.set_value(_progress.value)
	if delta < 0.0:
		_play_confused_beat()                 # mirror of the joyful mark — felt, not silent
	elif _progress.just_mastered(delta):
		_play_mastery_beat()                  # one-shot celebratory beat at 100%
	...
```

### 3. The on-screen learned bar (UI — Visual Review)

A thin progress bar (top of the portrait viewport, clear of the dog's crown and the readout
band — mind 038's "clear sky" lift) that fills toward mastery and **visibly drops** on erosion.
Follow `scripts/tier_readout.gd`'s node-glue pattern (lazy attach, `is_inside_tree()`-guarded
`.play()` per the headless gotcha). Legible under reduced motion (X-5 / P1-8 — the drop reads by
**length**, not only motion). At mastery it shows a full/"mastered" state.

### 4. The confused beat + mastery beat (Visual Review, procedural — no new clip)

- **Confused beat:** a brief procedural recoil/settle on the dog (small transform nudge back to
  the resting pose), the mirror of the joyful hop, plus the bar's visible drop. Honest no-op-safe
  if the director can't run it headless. **Not** a faked "confused" clip.
- **Mastery beat:** reuse the existing joyful reaction (`_director.play_reaction()`) one-shot at
  100%, paired with the bar's mastered state.

## TDD — behaviors to test first (`tests/test_trick_progress.gd`)

Per `.claude/skills/tdd/SKILL.md` — red first, then green, then refactor. Each test asserts
observable behavior through `TrickProgress`'s public surface (no internals):

1. **Starts empty, not mastered** — `value == 0.0`, `mastered == false`.
2. **PERFECT fills more than OK** — apply PERFECT vs OK from 0; PERFECT's value > OK's value.
3. **Mistimed taps erode** — MISS and DEAD each *decrease* `value` from a mid-bar start.
4. **DEAD erodes less than MISS** — gentler for a no-window tap than a real mistime.
5. **Net-forward invariant** — a PERFECT then a MISS leaves `value` strictly above the start
   (good play always nets forward); assert `PERFECT_GAIN > MISS_EROSION` and `> DEAD_EROSION`.
6. **Floors at 0** — erode repeatedly from a low bar; `value` never goes below 0.
7. **Caps + masters at 1.0** — fill past 1.0; `value == 1.0`, `mastered == true`.
8. **Mastery is a safe checkpoint** — after mastery, applying MISS/DEAD keeps `value == 1.0`
   and `mastered == true` (re-practice can't un-master).
9. **`just_mastered` is one-shot** — true only on the tap that first crosses MASTERY, false on
   subsequent taps.

(Pure-logic only — the bar UI and the two beats are Visual Review, not unit tests. Wiring into
`_on_bra_pressed` gets a thin wiring test in the spirit of `tests/test_payoff_wiring.gd` if it
can assert observably without a live tree; otherwise it's covered by the Visual Review.)

## Results (landed 2026-06-30, iteration 056)

**Shipped, TDD-first:**
- `scripts/trick_progress.gd` — the pure learned-progress model. PERFECT +0.20, OK +0.08,
  MISS −0.10, DEAD −0.05 (all homed constants); net-forward invariant (PERFECT > both
  erosions); floors at 0, caps + latches `mastered` at 1.0; mastery is a safe checkpoint
  (erosion floor rises to MASTERY once mastered); `just_mastered(delta)` is one-shot.
- `scripts/learned_bar.gd` — the on-screen meter (`LearnedBar extends Control`). Reads by
  FILL LENGTH (reduced-motion-safe), green while learning → gold at mastery, with a brief
  red **setback wash** on erosion. Dumb renderer driven by main, render-free-testable.
- `scripts/main.gd` wiring — `_progress` + `_learned_bar` mounted in the UI layer at the
  readout's proven-safe top edge; `_apply_progress(tier)` in `_on_bra_pressed` fills/erodes
  the bar, fires the **mastery beat** (reuses the real joyful reaction clip — no faked clip)
  on the crossing tap, and the **confused beat** on a bad tap; `_drive_confused` runs a damped
  yaw recoil restored EXACTLY to the dog's rest transform (no drift).

**Tests (TDD red→green, 142 total, 0 failures, no SCRIPT ERRORs):** `test_trick_progress.gd`
(11 — the 9 behaviors + bounds + re-practiceable), `test_learned_bar.gd` (5 — clamp, mastered
state, setback wash fires+fades), `test_learned_bar_wiring.gd` (3 — scene mounts the bar; a
DEAD CC0 tap floors at 0; the confused beat restores the dog to rest).

**Live visual proof (real licensed Labrador, local Web build, `?bra_autotap=1`, 390×844
SwiftShader == the deployed GL Compatibility renderer):** `.screenshots/045-learnbar-{00,04,12}.png`
— frame 00 empty track → frame 04 ~45% **green** (learning) → frame 12 **full gold (mastered)**
with the joyful reaction + a gold "PERFECT" readout. Fill→mastery + the mastery beat work on the
actual shipped asset; the bar sits clear of the dog and doesn't break the Phase-1 layout.

**Deferred to the deployed-PO Visual Review** (no local seam drives a scored MISS/DEAD through
the model): the *feel* of erosion + the **confused beat's live visibility on the skinned dog**
(the procedural root-node yaw may be overwritten if a clip animates the root — if so the PO
notes it and it routes to a fix; the bar's red setback wash is the guaranteed-visible felt cue
either way). A literal *confused clip* (true mirror of the joyful hop) is **asset-gated** like
the P2-2 trick clips — out of scope here, never faked.

## Acceptance criteria

- [x] **Red first:** `tests/test_trick_progress.gd` written and failing before `trick_progress.gd` exists.
- [x] `scripts/trick_progress.gd` implements the model; all 9 behaviors above pass (green).
- [x] PERFECT fills more than OK; MISS and DEAD erode; DEAD erodes ≤ MISS; all tuning in named constants (no scattered literals).
- [x] Net-forward holds: a PERFECT after a bad tap nets strictly forward; bar floors at 0, caps at 1.0.
- [x] 100% latches `mastered`; mastery is a safe checkpoint (re-practice can't drop a mastered trick); mastered trick stays re-practiceable (taps still score + pay off).
- [x] Model is keyed/instantiable per trick (ready for P2-1 selector + P2-5 persistence), wired for the Sitt trick in `main.gd:_on_bra_pressed`.
- [x] On-screen learned bar fills on good taps (green→gold) and **visibly drops** on erosion (red wash + length drop); legible under reduced motion (reads by length); clear of the dog + readout band — proven live (`.screenshots/045-learnbar-*`).
- [x] Bad tap triggers a brief **procedural** confused beat on the dog (no faked clip) + the bar setback; 100% triggers a one-shot celebratory beat (the real joyful clip). Honest no-ops where unavailable. *(Live visibility of the dog recoil → deployed-PO Visual Review; a confused clip is asset-gated.)*
- [x] **Placeholder check** clean on the diff (only honest explanatory comments — "NOT a faked clip" / "would be a stub" — no deliverable stubs).
- [~] Visual Review (phone-portrait 390×844): the **fill→mastery** path is proven live on the licensed build (`.screenshots/045-learnbar-*`); the **erosion/confused feel** rides the deployed-PO play-test (no local MISS/DEAD seam) — per the Phase-1 split.
- [x] `nix develop -c bash verify.sh` green (import · boot · test · export).
