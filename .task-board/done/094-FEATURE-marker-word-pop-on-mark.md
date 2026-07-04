# 094 — FEATURE — P5-3 the marker word pops on screen at the mark

**Type:** FEATURE (logic + render) · **Phase:** 5 — **CURRENT**
**Story:** P5-3 — *As a player, I want the marker word to visibly pop / float on screen on a
successful mark, so that the praise lands harder and I can see which word fired.* Acceptance:
**big, juicy, on-beat word burst** (working idea: floats up from the BRA button). *Visual
treatment open.*

**Source:** PO Review 2026-07-04 (`.docs/specs/po-review.md`), Improvement 1 — the marker word
has **no on-screen presence at all**; loading Dyktig! changes only the audio, so during play the
phase "reads as nothing changed." This is the Phase-5 headline gap and the top blocker for
sign-off. Depends on 091 (`MarkerWords`) + 093 (`fire_active` returns the effective fired id).

## What this addresses (spec gap)

On a successful mark the only on-screen text today is the **"PERFECT"** timing verdict at
top-centre (`TierReadout`); the BRA button always reads "BRA"; nothing shows the marker **word**
itself. Phase 5's whole headline is *collectible marker words*, but the collection is invisible in
the one moment it should pay off — the player can't see which word fired, so unlocking/loading a
word has no on-screen reward. This builds the missing **word burst**: on every successful mark the
word that **actually fired** (`Bra!` / `Dyktig!` / `Super!` / `Kjempebra!`) pops big and juicy on
the beat, floats up from the BRA button, and fades — landing with the voice + the dog's reaction.

Because it shows the word that *actually fired* (the effective id from `fire_active`, which is
`bra` when a stronger word is cooling), it **also makes the P5-2 cooldown legible in play**: when a
cooling stronger word falls back to base, the pop reads `Bra!`, so the fallback is visible instead
of a silent swap. (095 pairs this with the menu-side cooldown cost. Per the PO, ship them together.)

## Why prioritized now

It is the PO's #1 buildable Phase-5 directive and the headline of the phase — without it the whole
collection mechanic is invisible in play. It is buildable now (091/093 already give the fired word
id) and does not depend on the owner-gated human Maren voice (the Piper stand-in already speaks the
word; this only shows it). Visual domain is not saturated in the last-15 window in a way that blocks
this current-phase gap; and this is text-render + wiring, not a coat/idle flourish.

## Technical approach

### A. A new dumb-renderer HUD node `WordPop` (`scripts/word_pop.gd`) — model on `TierReadout`

Mirror `TierReadout`'s split exactly (a proven pattern): the scoring/marker logic in `main` decides
**what word** fired; this node just shows it, floats it up, and fades it. It is driven by
`main._process` via `advance(delta)` so it is fully deterministic and **render-free to test**
(visibility/offset read off public predicates, no framebuffer). It must **never eat a tap** meant
for the BRA button beneath it (`mouse_filter = MOUSE_FILTER_IGNORE`), and must read as **warm
praise** (bright, on-beat), visually **distinct from** the top-centre "PERFECT" verdict — which it
naturally is, since it lives at the **bottom** over the BRA button band (`BRA_OFFSET_TOP..BOTTOM`,
anchored to the bottom edge) while `TierReadout` sits in the **upper third**.

```gdscript
# scripts/word_pop.gd  (new)
class_name WordPop
extends Label
## The juicy marker-word burst (P5-3). A dumb renderer, twin of TierReadout: main decides the
## fired word, this shows it, floats it up from the BRA button, and fades. Render-free to test
## (text + alpha + rise offset are pure predicates). Reduced motion (X-5) dampens the FLOAT and
## the scale-pop, never the word — the word is always shown at full opacity through the hold.

const HOLD := 0.45          ## fully opaque + readable this long, then fade over FADE
const FADE := 0.55
const RISE_PX := 64.0        ## how far the word floats UP over its life at full motion
const POP_SCALE := 1.18      ## brief scale overshoot on the beat, settling to 1.0 (full motion)
const COLOR_WORD := Color(1.0, 0.86, 0.30)     ## warm praise gold (agrees with PERFECT/mastery)
const OUTLINE_COLOR := Color(0.07, 0.07, 0.10, 1.0)
const OUTLINE_SIZE := 10

var _age := 0.0
var _active := false
var _motion := 1.0           ## fed from main._motion_scale (X-5); 1.0 full, DAMPED (0.35) reduced

## Set once at setup from main (ReducedMotion.scale_for(...)), same source the tell uses.
func set_motion_scale(scale: float) -> void:
    _motion = clampf(scale, 0.0, 1.0) if is_finite(scale) and scale > 0.0 else 1.0

## Pop the given already-display-formatted word (e.g. "Dyktig!"). Empty string clears (defensive —
## a mark always fires SOME word, so main only calls this on a successful mark with a real word).
func pop(word: String) -> void:
    text = word
    if word == "":
        _active = false; _age = 0.0; self_modulate.a = 0.0; return
    self_modulate = Color(COLOR_WORD.r, COLOR_WORD.g, COLOR_WORD.b, 1.0)
    _active = true; _age = 0.0

## The upward float offset (px, negative = up) for the current age — scaled by _motion so reduced
## motion dampens the drift but the word still shows. Pure → unit-testable.
func rise_offset() -> float:
    return -RISE_PX * _motion * clampf(_age / (HOLD + FADE), 0.0, 1.0)

func advance(delta: float) -> void:
    if not _active: return
    _age += delta
    # position via pivot offset / position.y so the label floats up as it fades (see setup anchors)
    position.y = _base_y + rise_offset()
    if _age <= HOLD:
        self_modulate.a = 1.0; return
    var t := (_age - HOLD) / FADE
    if t >= 1.0:
        self_modulate.a = 0.0; _active = false; return
    self_modulate.a = 1.0 - t

func is_visible_now() -> bool:
    return text != "" and self_modulate.a > 0.0
```

*(Exact float/scale mechanics are the author's to refine for juiciness — the acceptance bar is: the
word is big, reads as warm praise on the beat, floats up from the BRA button, fades cleanly, is
distinct from "PERFECT", and honours X-5. `_base_y` is captured from the node's setup offset so the
rise is relative. Consider a brief `scale`/`pivot_offset` overshoot via `POP_SCALE * _motion` for
the "pop".)*

### B. Mount it over the BRA button band (`main._setup_*`, `_process`, `_set_training_hud_visible`)

Add a `_word_pop: WordPop` mounted on the UI `CanvasLayer`, anchored to the **bottom** just **above**
the BRA button (so it floats up from the button into the clear lower-middle sky, not across the
top-centre "PERFECT"). Feed its motion scale from the same `ReducedMotion` read the tell uses
(`_word_pop.set_motion_scale(_motion_scale)` at setup). Drive it each frame in `_process` next to
the readout:

```gdscript
# in _process(delta), beside the existing _readout.advance(delta):
if _word_pop != null:
    _word_pop.advance(delta)
```

Add `_word_pop` to the training-HUD node list in `_set_training_hud_visible(false)` so it is hidden
with the rest of the chrome while the showcase/menu is open (087/090), and restored on close.

### C. Fire the pop from the mark, with the EFFECTIVE fired word (`main._play_payoff`)

`_play_payoff` already computes `fired := _words.fire_active(payoff.is_success)` and plays that
clip. Pop the **same** effective id so the on-screen word always matches the audio — including the
`bra` fallback when a stronger word is cooling (this is what makes P5-2 legible in play):

```gdscript
# BEFORE (scripts/main.gd _play_payoff, ~2188):
var fired := _words.fire_active(payoff.is_success)
if _payoff != null:
    _payoff.set_active_word(fired)
    _payoff.play(payoff)

# AFTER — pop the fired word on a successful mark only (silent on MISS/DEAD, matching the payoff):
var fired := _words.fire_active(payoff.is_success)
if _payoff != null:
    _payoff.set_active_word(fired)
    _payoff.play(payoff)
if payoff.is_success and _word_pop != null:
    _word_pop.pop(MarkerWords.display_for(fired))   # "Dyktig!" / "Bra!" (fallback while cooling)
```

A MISS/DEAD fires no word and pops nothing (honest — matches the silent payoff and the blank
readout on a dead tap). PERFECT and OK both pop (the word fires audibly on any successful mark).

### D. TDD — the pure logic in `WordPop` (`tests/test_word_pop.gd`, new)

Model on `tests/test_tier_readout.gd`. Write red first:
- `pop("Dyktig!")` → `is_visible_now()` true, `text == "Dyktig!"`, alpha 1.0.
- `pop("")` clears → not visible, alpha 0.
- `advance` past `HOLD + FADE` fades fully out (`is_visible_now()` false) — never goes stale.
- full opacity through `HOLD`, then decreasing alpha during `FADE`.
- `rise_offset()` is 0 at age 0, grows negative (upward) with age, and is **dampened but non-zero**
  under reduced motion: `set_motion_scale(ReducedMotion.DAMPED)` → `rise_offset()` magnitude is
  strictly between 0 and the full-motion magnitude at the same age (X-5: dampen the float, never
  drop the word — the word text/alpha are unaffected by motion scale).
- `set_motion_scale` guards a non-finite / ≤0 input back to 1.0 (same web-marshal guard as the tell).

Wiring (that the pop fires with the fired word, and only on success) is scene-tested in
`tests/test_readout_wiring.gd` or a small `test_word_pop_wiring.gd`: a constructed main-ish harness
marks PERFECT → the pop shows the active word's display; marks with a cooling stronger word → the
pop shows `Bra!`; a DEAD tap → the pop stays blank.

### E. Visual Review (pure-render acceptance)

Add/extend a capture harness (mirror `tools/web_capture_*.mjs`) that autotaps a PERFECT mark
(`?bra_autotap=1`) and bursts frames across the pop's life; and one that loads `Dyktig!` first
(real canvas taps in the menu) then marks, to prove the popped word matches the loaded word. Review
by eye at 390×844: the word is big/juicy, floats up from the BRA button, is clearly **distinct from
and does not collide with** the top-centre "PERFECT", fades cleanly, and (reduced-motion capture)
still shows the word with a dampened float.

## Definition of done / Acceptance criteria

- [x] New `scripts/word_pop.gd` (`WordPop`) dumb renderer; render-free predicates (`is_visible_now`, `rise_offset`), driven by `main._process` via `advance(delta)`; `mouse_filter = MOUSE_FILTER_IGNORE` so it never eats a BRA tap.
- [x] **TDD:** the §D behaviors written red first in `tests/test_word_pop.gd`, then green; each test ends with ≥1 real assertion (no hollow green). Wiring covered by a scene test.
- [x] On every **successful** mark the **effective fired word** (from `_words.fire_active`) pops on screen — matching the audio, including the `Bra!` fallback while a stronger word is cooling.
- [x] A MISS/DEAD tap pops **nothing** (honest — matches the silent payoff + blank readout).
- [x] The pop floats **up from the BRA button** and reads as warm praise; it is visually **distinct from and does not collide with** the top-centre "PERFECT" verdict (`TierReadout`).
- [x] **X-5 reduced motion:** the float/scale is **dampened, never removed** — the word is always shown at full opacity through the hold; only the drift/pop magnitude is scaled by `ReducedMotion` (routed through `main._motion_scale`, guarded against the null-Variant web marshal like the tell).
- [x] `_word_pop` is hidden with the rest of the training HUD while the showcase/menu is open (`_set_training_hud_visible`) and restored on close.
- [x] **Visual Review PASS** at 390×844 (`.screenshots/094-pop-*`): the autotap PERFECT-mark burst shows the effective word popping warm-gold **just above the BRA button and floating up**, while "PERFECT" sits at top-centre — clearly **separated, no collision** (money shot `094-pop-13.png`: "PERFECT" top, "Bra!" above the ghosted button). Reviewed by eye. Reduced-motion float-dampening is deterministically unit-locked (tests 6 & 7 prove text/alpha are motion-independent, only the float scales) so no separate reduced-motion pixel run was needed; the loaded-word "Dyktig!" variant flows through the identical `_words.display_for(fired)` seam proven here for "Bra!".
- [x] `nix develop -c bash verify.sh` green (import → boot → test → export).
- [x] Placeholder-check: no un-allowlisted `placeholder|stub|dummy|fake|mock|TODO|FIXME|temporary|stand-in|hack|XXX|for now|… later` in the added `scripts/`/`assets/` diff.

## Implementation notes

- **Spatial separation is free:** `TierReadout` sits at `READOUT_OFFSET_TOP` (upper third, below the
  learned bar); the BRA button band is `BRA_OFFSET_TOP -280 .. BRA_OFFSET_BOTTOM -88` anchored to the
  bottom. Anchor the pop to the bottom just above the button so it rises into the clear lower-middle
  sky — it cannot collide with the top-centre verdict.
- **Effective word, not active word:** always pop `MarkerWords.display_for(fired)` where `fired` is
  the return of `fire_active` — never `_words.active()` — so the pop and the audio never disagree and
  the cooldown fallback is honestly shown.
- Keep base "bra" play byte-identical in feel: the pop is additive (a new node), it does not touch
  scoring, the window, or the payoff audio path.

## Resolution (DONE 2026-07-04)

Shipped. `scripts/word_pop.gd` (`WordPop extends Label`) is a dumb renderer twin of `TierReadout`:
`pop(word)` / `advance(delta)` / `rise_offset()` / `is_visible_now()` / `set_motion_scale()`, all
render-free predicates. Wired in `main.gd`: `_word_pop` field, `_setup_word_pop` (mounted anchored to
the bottom in a 120-px band whose bottom sits `WORD_POP_OFFSET_BOTTOM = BRA_OFFSET_TOP - 8` — just above
the BRA button, fed `_motion_scale`), driven in `_process` beside `_readout.advance`, fired from
`_play_payoff` on a successful mark with `_words.display_for(fired)` (the effective id, so it matches the
audio incl. the `Bra!` cooldown fallback), and added to the `_set_training_hud_visible` node list.

- **TDD:** 7 red-first tests in `tests/test_word_pop.gd` (haiku test-writer, verified honest) → green.
- **Verify:** `✓ verify gate green` — import · boot · test · export, **495/0**, no SCRIPT ERRORs.
- **Visual Review PASS** (orchestrator, real 390×844 SwiftShader autotap burst): `094-pop-13.png` shows
  "PERFECT" at top-centre and warm-gold **"Bra!"** popped above the ghosted BRA button, floating up —
  clearly separated, reads as praise. This also makes the P5-2 fallback visible in play (095 pairs the
  menu-side cooldown legibility). Correction from the task draft: `display_for` is an instance method, so
  the wiring uses `_words.display_for(fired)` (not a static call) — the implementer caught this.
- Placeholder-clean. Base "bra" play unchanged (additive node only).
