# FEATURE: 058 — A timing trainer that fades (P2-9 "tap when it lands")

**Status**: Backlog
**Created**: 2026-07-01
**Type**: FEATURE (hybrid — a PURE approach-cue envelope is **TDD**, like `ApexTell`; the node
renderer + `main.gd` glue is **Visual Review**, like `ApexTellMarker`)
**Priority**: High — the **last buildable Phase-2 story**. The 2026-07-01 PO review names exactly
two non-owner-gated stories left: P2-8 (now landed across 048 + 050) and **P2-9** (this). The
trick-roster stories P2-1/P2-2/P2-3 stay **owner-gated** on additional licensed animation clips —
do not touch them. After this lands, Phase 2 awaits the PO's sign-off pass (incl. the live-pixel
erosion / confused-beat catch the PO still wants), not more construction.
**Labels**: phase-2, visual, timing, trainer, approach-ring, fade, p2-9

## What it addresses (spec gap)

`.docs/specs/phase2.md` **P2-9 — A timing trainer that fades**, and the **2026-07-01 PO review**
(`.docs/specs/po-review.md`, Improvements): *"With an empty bar (a brand-new trick) the player
gets no 'now' teaching cue beyond the brief apex ring already at the button … P2-9 wants a bold
approach cue — a ring that **shrinks onto the BRA button and lands exactly at the apex** ('tap
when it lands') — shown while the trick is new, **fading as the learned bar fills** and **gone at
mastery**, and riding the same `SitWindow` so it stays dark during feints/ambient. Not present."*

Today the only "now" cue is the **apex tell** (P1-4, `ApexTell` + `ApexTellMarker`): a soft gold
pulse that *builds to* the apex and is the same boldness every play, mastered or not. P2-9 is a
**distinct, additional** cue — a big approach ring that *contracts onto* the button to land at the
apex, and whose prominence **decays with the learned bar** so an experienced player is weaned off
it. The PO explicitly distinguishes the two ("beyond the brief apex ring already at the button"),
so this is a new element, not a tweak to the tell.

## Technical approach

Mirror the proven **pure-envelope + dumb-renderer** split that P1-4 used (`ApexTell` is unit-tested;
`ApexTellMarker` just draws the number; `main.gd` wires them). The honesty (lands at the *real*
apex, dark off-window) lives in the pure class and is test-first; the pixels are Visual-Review-gated.

### 1. `scripts/trainer_ring.gd` — `class_name TrainerRing extends RefCounted` (PURE, TDD)

The approach-cue envelope. Built from the SAME `SitWindow` the score and tell use (single source of
truth), plus a `teach` strength in [0,1] derived from learned progress. Three pure outputs, all
keyed off `elapsed` seconds-into-the-current-sit:

- **`radius_scale(elapsed) -> float`** in [0,1]: the ring's normalized radius during the approach —
  **1.0 (fully expanded, far out) at `sit_start`, shrinking monotonically to 0.0 (landed on the
  button) at `apex`**. This is the "shrinks onto the BRA button and lands exactly at the apex". A
  simple honest map: `1.0 - approach_fraction`, where
  `approach_fraction = clampf((elapsed - sit_start) / (apex - sit_start), 0, 1)`. After the apex the
  ring has landed (radius 0 → handed off to the apex tell / the tap).
- **`opacity(elapsed) -> float`** in [0,1]: `0` outside the approach span `[sit_start, apex]`
  (so it is dark during idle, feints, and after it lands), otherwise scaled by `teach`. Because
  `teach` is the only thing gating prominence, **`teach == 0` ⇒ opacity is 0 everywhere** — gone at
  mastery, exactly as the spec wants.
- **`static teach_strength(value: float, mastered: bool) -> float`**: the fade law, homed on the
  class next to the curve that uses it (no scattered literals, cf. 029). **`1.0` at a brand-new
  trick (`value == 0`), decreasing monotonically as the bar fills, `0.0` at mastery.** Simplest
  honest law that hits both endpoints: `0.0 if mastered else 1.0 - value`. (A `mastered` trick
  latches `value == 1.0` anyway, but pass the flag so the safe-checkpoint stays explicit.)
- **`static from_window(window: SitWindow, teach: float) -> TrainerRing`** — stores
  `window.sit_start`, `window.apex`, and `teach`, so the ring can never drift off the scored apex.

```gdscript
# BEFORE: no trainer cue exists — a new trick gives the player no shrinking "now" ring.

# AFTER (scripts/trainer_ring.gd, sketch):
class_name TrainerRing
extends RefCounted

static func teach_strength(value: float, mastered: bool) -> float:
    return 0.0 if mastered else clampf(1.0 - value, 0.0, 1.0)

func radius_scale(elapsed: float) -> float:
    if elapsed < sit_start or elapsed > apex:
        return 0.0
    var f := clampf((elapsed - sit_start) / maxf(apex - sit_start, EPSILON), 0.0, 1.0)
    return 1.0 - f               # 1 (far) at sit_start → 0 (landed) at apex

func opacity(elapsed: float) -> float:
    if teach <= 0.0 or elapsed < sit_start or elapsed > apex:
        return 0.0               # gone at mastery; dark off the approach span (feints/idle)
    return teach
```

### 2. `scripts/trainer_ring_marker.gd` — `class_name TrainerRingMarker extends Control` (render glue)

A dumb renderer, twin of `ApexTellMarker`: `mouse_filter = MOUSE_FILTER_IGNORE` (never eat a BRA
tap), `self_modulate.a` driven by `opacity`, draws **one bold ring** whose pixel radius =
`landed_radius + radius_scale * approach_span` — large and outside the word when far, contracting to
frame the button as it lands. Keep it visually **distinct from the gold apex tell** (e.g. a cooler /
outlined "approach" ring, thicker line) so the two cues read as two things. Factor the pixel-radius
map into a `static` render-free helper so the framing geometry is unit-testable (as 037 did for the
tell's `ring_radius`). Centre it on the BRA button via the same anchor math `_setup_tell_marker`
uses (`ApexTellMarker.SIZE` / `TELL_HALF_WIDTH`).

### 3. `scripts/main.gd` — wiring (parallels the tell exactly)

- Hold `_trainer: TrainerRing` and `_trainer_marker: TrainerRingMarker`; `_setup_trainer_marker(ui)`
  alongside `_setup_tell_marker` (added on top of the button, below/above the tell as Visual Review
  decides reads best).
- In `_open_sit()` (where `_tell = ApexTell.from_window(...)` is built): build
  `_trainer = TrainerRing.from_window(_window, TrainerRing.teach_strength(_progress.value,
  _progress.mastered))` — so each sit's ring reflects the **current** learned level (fresh trick →
  bold ring; nearly-mastered → faint; mastered → none).
- In `_process()` (where the tell marker is driven): while `_session.is_open()` drive
  `_trainer_marker` from `_trainer.radius_scale(elapsed)` + `_trainer.opacity(elapsed)`; else set it
  to 0 — so a **feint never opens `_window`/`_trainer`, leaving the ring dark** (it rides the same
  `SitWindow`, the P2-9 honesty bullet). Clear it in `_end_sit()` / the feint path like `_tell`.
- Add a `?bra_force_trainer=1` Visual-Review seam (mirror `_query_force_tell` / `_force_tell`): pin
  the ring to a mid-approach radius at full `teach` for one deterministic phone-portrait screenshot,
  since the live ring sweeps in ~0.2 s per sit and a strobe burst can miss it (the same reason 030
  added `?bra_force_tell=1`). Web-only seam, no effect on normal play.

### Honesty / placeholder notes
- **No new asset** — the ring is drawn in-engine (`_draw`), like the tell. No primitive dog, no
  faked clip; nothing for the placeholder check to catch beyond allowlisted board/test meta-text.
- **Rides the real scored apex** via `from_window` — the cue physically cannot land off the band.
- This is additive: the apex tell (P1-4) and learned bar (P2-4) are untouched in behavior; only the
  new ring reads `_progress` to decide its own fade.

## Acceptance criteria

- [x] **TDD (write the failing test first** — `tests/test_trainer_ring.gd`, per `.claude/skills/tdd/SKILL.md`):
  - [x] `radius_scale` is **1.0 at `sit_start`, 0.0 at `apex`**, and **monotonically decreasing**
    across the approach (the ring shrinks onto the button and *lands* at the apex).
  - [x] `teach_strength` is **1.0 at `value == 0`, 0.0 when `mastered`**, and monotonically
    decreasing as `value` rises (fades as the learned bar fills; gone at mastery).
  - [x] `opacity` is **0 outside `[sit_start, apex]`** (dark during idle / after landing) and **0
    whenever `teach == 0`** (mastery), else equals `teach` inside the span.
  - [x] Built `from_window`, the ring's `apex`/`sit_start` **equal the SitWindow's** (single source
    of truth — it can't drift off the scored apex).
- [x] **Wiring test** (`tests/test_trainer_wiring.gd`, render-free, the `test_*_wiring` pattern):
  a real sit opens the trainer and drives the marker; a **feint opens no window so the ring stays
  dark** (rides the same `SitWindow` as the tell/score); a **mastered** trick's ring opacity is 0.
- [x] **Placeholder check** clean — drawn in-engine, no stub/fake/primitive (allowlist: tests + board meta).
- [x] **Visual Review — local render proof PASS** (phone-portrait 390×844, real Web GL build via
  `?bra_force_trainer=1`): the forced approach ring **renders as a bold cyan ring framing the "BRA"
  button**, visually distinct from the gold apex tell (`.screenshots/058-trainer-ring.png`, 4937
  cyan px in the lower band, `tools/web_capture_trainer.mjs`). This is the binding render proof that
  guards the 030/036-class failure (the apex tell once read green in tests yet was invisible in live
  pixels). The **behavioral sweep** — ring *shrinking* through a real sit, *fading* as the bar fills,
  *gone* at mastery, *dark* during feints — is comprehensively unit + wiring tested (above) and
  rides the **PO's deployed-build sign-off** pass, since it needs the **licensed sit-capable dog**
  (CI-only locally — the local "Web" preset bundles the CC0 idle dog) and multiple progress states.
  Mirrors how po-review.md scopes the P2-4 erosion live-pixel catch to the same sign-off pass.
- [x] `nix develop -c bash verify.sh` green (import · boot · test · export).

## Results

**Shipped:**
- `scripts/trainer_ring.gd` — pure RefCounted envelope (54 LOC). Fields: `sit_start`, `apex`, `teach`. Static helpers: `teach_strength(value, mastered)`, `from_window(window, teach)`. Methods: `radius_scale(elapsed)`, `opacity(elapsed)`.
- `scripts/trainer_ring_marker.gd` — dumb Control renderer (86 LOC). `_init` sets `mouse_filter = IGNORE`, starts dark. `set_opacity(v)` + `set_radius_scale(v)` drive `self_modulate.a` + `queue_redraw()`. `is_showing()` predicate. `_draw()` renders one bold cyan/blue outlined ring (no halo, 14px width — visually distinct from the gold apex tell). Static `ring_radius(unit, radius_scale)` for unit-testable geometry.
- `scripts/main.gd` — wired in parallel to the tell: `_trainer`/`_trainer_marker`/`_force_trainer` fields; `_setup_trainer_marker(ui)` added after `_setup_tell_marker`; `_begin_sit()` builds `_trainer = TrainerRing.from_window(...)` alongside `_tell`; `_end_sit()` clears `_trainer = null`; `_process()` drives both markers; `_query_force_trainer()` reads the STRING sentinel `?bra_force_trainer=1` (same web gotcha guard as the tell).

- `tools/web_capture_trainer.mjs` — Visual-review capture: boots the real Web GL build (SwiftShader
  Chromium, 390×844) with `?bra_force_trainer=1`, scores the lower band for the ring's cyan, fails
  closed if it doesn't render. Mirrors `web_capture_readout.mjs`.

**Test count:** 218 tests, 0 failures (up from 190 after task 050 — exactly the +28 new trainer
tests, confirmed running not skipped; orchestrator re-ran the gate independently).
**Verify gate:** green — import · boot · test · export all passed. No SCRIPT ERROR or Parse Error in logs.
**Visual Review (local render proof):** PASS — `.screenshots/058-trainer-ring.png` shows a bold cyan
approach ring framing the BRA word, distinct from the gold tell (4937 cyan px). Orchestrator eyeballed
the frame. The live behavioral sweep (shrink/fade-with-bar/gone-at-mastery/dark-on-feint) is unit-locked
and rides the PO deployed sign-off (licensed sit-capable dog is CI-only locally).
