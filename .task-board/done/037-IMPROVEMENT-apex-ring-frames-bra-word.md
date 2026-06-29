# IMPROVEMENT: 037 — The apex ring frames the "BRA" word (P1-4 polish)

**Status**: Backlog
**Created**: 2026-06-30
**Priority**: High — open **PO directive** (Improvements) on the Phase-1 Visual-Review
sign-off path (P1-10). Now actionable because the live apex tell was re-fixed in **036**
(the tell is no longer invisible in real play), so its peak framing can finally be tuned.
The only-remaining-gap override applies (visual domain is saturated 030–034, but this is
one of just three open Phase-1 PO findings).
**Labels**: visual, ui, phase-1, po-directive, p1-4
**Estimated Effort**: Small

## What it addresses (PO directive, `.docs/specs/po-review.md` → Improvements)

> **The apex ring buries the "BRA" word at peak (P1-4 polish).** In the forced-tell
> reference the gold ring is centered tightly over the button and partially occludes the
> "BRA" text. When the live tell is fixed, size/position the ring to frame the marker
> without hiding the word.

Confirmed in code (2026-06-30):
- The marker is a **200×200** square (`TELL_HALF_WIDTH = 100`), centred on the BRA button
  band (`main.gd:458-474`). In `_draw`, `unit = min(size)*0.5 = 100`.
- The crisp ring is drawn at radius `unit*(0.62 + 0.12*intensity)` = **62–74 px**
  (`apex_tell_marker.gd:64`), width `RING_WIDTH = 10`.
- The "BRA" text is `font_size = 96`, centred in the button → its glyph run is roughly
  **±85 px** half-width about the same centre. A 62–74 px ring therefore cuts straight
  through the "B" and "A" — exactly the PO's "partially occludes the 'BRA' text".

The peak is centred correctly; it is just **too small** — it crosses the word instead of
encircling it. Fix = enlarge the ring so its inner edge clears the word, keeping it
centred on the button.

## Technical Approach

Make the marker (and thus `unit`) large enough that the ring's inner edge clears the "BRA"
glyph run with margin, and **keep the marker square and centred on the button centre** so
the ring stays concentric with the word. Two coupled edits:

1. **Give `ApexTellMarker` an owned target size + named radius math** (kills the magic
   numbers, cf. 029, and makes the geometry render-free testable). The ring/halo fractions
   move into named constants and a pure helper; a documented `WORD_HALF_WIDTH` records the
   clearance the ring must beat.
2. **Re-centre the marker on the button centre** in `main.gd` and size it from
   `ApexTellMarker.SIZE` (single source of truth), instead of stretching it across the
   button band (which forced a 200-tall square).

**Before** (`scripts/apex_tell_marker.gd`, lines 29–31 + `_draw` 56–65):

```gdscript
const HALO_ALPHA := 0.40   ## soft bloom disc (base alpha)
const RING_ALPHA := 1.0    ## the crisp "now" ring (base alpha) — opaque at peak
const RING_WIDTH := 10.0   ## ring line width in px at the pinned 720-wide viewport
...
func _draw() -> void:
	if intensity <= 0.0:
		return
	var center := size * 0.5
	var unit := minf(size.x, size.y) * 0.5
	draw_circle(center, unit * (0.78 + 0.18 * intensity), Color(GLOW, HALO_ALPHA))
	draw_arc(center, unit * (0.62 + 0.12 * intensity), 0.0, TAU, 64,
		Color(GLOW, RING_ALPHA), RING_WIDTH, true)
```

**After** (named radius math + an owned square size that frames the word):

```gdscript
const HALO_ALPHA := 0.40   ## soft bloom disc (base alpha)
const RING_ALPHA := 1.0    ## the crisp "now" ring (base alpha) — opaque at peak
const RING_WIDTH := 10.0   ## ring line width in px at the pinned 720-wide viewport

## The pulse square's edge, at the pinned 720-wide viewport. Sized so the ring ENCIRCLES
## the BRA word rather than crossing it (P1-4 polish, 037): unit = SIZE*0.5 = 160, so the
## resting ring radius is 160*RING_BASE ≈ 99 px — outside WORD_HALF_WIDTH. main.gd sizes
## and centres the marker from this single constant.
const SIZE := 320.0
## Half-width of the "BRA" glyph run at the button's font_size 96 — the clearance the ring
## must beat so it frames the word. The invariant test below locks ring radius > this.
const WORD_HALF_WIDTH := 90.0

## Radius growth: a soft halo and a crisp ring that each bloom slightly toward the apex.
const HALO_BASE := 0.78
const HALO_GROW := 0.18
const RING_BASE := 0.62
const RING_GROW := 0.12

## Pure radius helpers (render-free, so the framing geometry is unit-testable).
static func ring_radius(unit: float, intensity: float) -> float:
	return unit * (RING_BASE + RING_GROW * intensity)
static func halo_radius(unit: float, intensity: float) -> float:
	return unit * (HALO_BASE + HALO_GROW * intensity)

func _draw() -> void:
	if intensity <= 0.0:
		return
	var center := size * 0.5
	var unit := minf(size.x, size.y) * 0.5
	draw_circle(center, halo_radius(unit, intensity), Color(GLOW, HALO_ALPHA))
	draw_arc(center, ring_radius(unit, intensity), 0.0, TAU, 64,
		Color(GLOW, RING_ALPHA), RING_WIDTH, true)
```

**Before** (`scripts/main.gd`, lines 261–264 + the marker offsets 465–472):

```gdscript
const TELL_RING_MARGIN := 4.0
const TELL_HALF_WIDTH := 100.0  ## half of the 200px-wide pulse square, centred on the band
const TELL_OFFSET_TOP := BRA_OFFSET_TOP - TELL_RING_MARGIN
const TELL_OFFSET_BOTTOM := BRA_OFFSET_BOTTOM + TELL_RING_MARGIN
...
	marker.anchor_top = 1.0
	marker.anchor_bottom = 1.0
	marker.offset_left = -TELL_HALF_WIDTH
	marker.offset_right = TELL_HALF_WIDTH
	marker.offset_top = TELL_OFFSET_TOP
	marker.offset_bottom = TELL_OFFSET_BOTTOM
```

**After** (a square centred on the button centre, sized from `ApexTellMarker.SIZE` so the
ring encircles the word; offsets derived from the button band so it still tracks the verb):

```gdscript
const TELL_HALF_WIDTH := ApexTellMarker.SIZE * 0.5  ## 160 — half the pulse square (037)
## Button-band centre above the bottom edge (anchor_*=1.0 space): keep the ring concentric
## with the centred "BRA" glyphs so it frames the word instead of crossing it (P1-4, 037).
const BRA_CENTER_Y := (BRA_OFFSET_TOP + BRA_OFFSET_BOTTOM) * 0.5
const TELL_OFFSET_TOP := BRA_CENTER_Y - TELL_HALF_WIDTH
const TELL_OFFSET_BOTTOM := BRA_CENTER_Y + TELL_HALF_WIDTH
...
	marker.anchor_top = 1.0
	marker.anchor_bottom = 1.0
	marker.offset_left = -TELL_HALF_WIDTH
	marker.offset_right = TELL_HALF_WIDTH
	marker.offset_top = TELL_OFFSET_TOP
	marker.offset_bottom = TELL_OFFSET_BOTTOM
```

`TELL_RING_MARGIN` is now unused — remove it. The marker stays square (320×320), so
`unit = 160` and the resting ring radius `160*0.62 ≈ 99 px` clears the ~90 px word
half-width with margin; the halo (`160*0.78 ≈ 125 px`) is a soft transparent bloom behind.
Do **not** touch the live-intensity application (036) or `set_intensity`.

### TDD steps (geometry seam) — follow `.claude/skills/tdd/SKILL.md`

1. **Red** — in `tests/test_apex_tell_marker.gd` (new, or extend the marker's existing
   tests) assert the framing invariant on the production size:
   `ring_radius(ApexTellMarker.SIZE*0.5, 0.0) - RING_WIDTH*0.5 >= WORD_HALF_WIDTH`
   (the resting ring's inner edge clears the word). Run → fails at the old 200 px size.
2. **Green** — land `SIZE = 320` (+ helpers) → passes.
3. **Guards** — assert `ring_radius` is monotonic in intensity (peak ≥ resting) and that
   the mounted marker is **square** (in `test_tell_wiring.gd`: `size.x == size.y` after
   layout). Keep the existing tell-dark-during-idle / never-eats-a-tap tests green.

## Visual Review (the real gate)

Run `polish`, then capture the forced-tell composite on the running **local licensed web
export** at 390×844 via the existing seam: `tools/web_capture_apex.mjs` with `BRA_FORCE=1`
(`?bra_force_tell=1`). The gold ring must **encircle** the "BRA" word with the whole word
clearly legible inside it — no arc crossing a glyph — still reading as a warm "now" pulse
centred on the button. Save the proof frame under `.screenshots/037-ring-frames-bra.png`.
Findings are blocking.

## Acceptance Criteria

- [x] Failing geometry test written first (resting ring inner edge < `WORD_HALF_WIDTH` at
      the old size) per `tdd`.
- [x] Ring/halo radius math extracted to named constants + pure `ring_radius`/`halo_radius`
      helpers (no scattered literals; cf. 029).
- [x] `ring_radius(SIZE*0.5, 0.0) - RING_WIDTH*0.5 >= WORD_HALF_WIDTH` holds; `ring_radius`
      monotonic in intensity; mounted marker is square.
- [x] Existing tell wiring tests stay green (dark during idle on CC0; never eats a BRA tap;
      036 live-intensity path untouched).
- [x] Visual Review on the running 390×844 licensed export: the ring frames the "BRA" word,
      word fully legible, captured proof in `.screenshots/037-ring-frames-bra.png`.
- [x] `nix develop -c bash verify.sh` green (import → boot → test → export).

## Resolution (2026-06-30)

Enlarged the apex-tell pulse so the ring **encircles** the "BRA" word instead of crossing it.
`ApexTellMarker` now owns its size: `SIZE = 320` (unit 160) with named radius math
(`RING_BASE/GROW`, `HALO_BASE/GROW`) and pure `ring_radius`/`halo_radius` helpers; `_draw`
calls them (no scattered literals). `main.gd` sizes the marker from `ApexTellMarker.SIZE` and
re-centres it on the button centre (`BRA_CENTER_Y`), keeping it a 320×320 square concentric
with the centred glyphs; removed the now-unused `TELL_RING_MARGIN`. The live-intensity path
(036) and `set_intensity` are untouched.

Resting ring radius ≈ 99 px (was 62–74 px) clears the ~90 px word half-width with margin.
6 new tests in `tests/test_apex_tell_marker.gd` (framing invariant, ring monotonic, halo
encloses ring at rest+peak, size sanity); existing tell-wiring tests stay green.

**Visual Review — PASS.** `env -u LD_LIBRARY_PATH BRA_FORCE=1 node tools/web_capture_apex.mjs
build/web .screenshots/037-ring-frames-bra.png` → max gold **3290 px**, 6/6 frames (vs the old
~1647 px tight ring). Eyeballed `.screenshots/037-ring-frames-bra.png` (licensed Labrador, 390×844):
the gold ring rings the button and **frames "BRA" — all three letters fully legible inside, no
arc crossing a glyph** — reading as a warm "now" pulse. P1-4 ring-framing polish closed.

Gate: `nix develop -c bash verify.sh` green (import · boot · test · export), 123 tests, 0 failures.
