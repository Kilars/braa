class_name LearnedBar
extends Control
## The on-screen learned bar (045, P2-4). A composite meter near the top of the portrait frame:
## a trick-name label (left) + percentage (right) row, then a horizontal track that fills as the
## trick is learned and visibly DROPS on a bad tap. It is a deliberately dumb renderer, the same
## split TierReadout uses: TrickProgress decides the value, this node just draws it.
##
## 097 (Phase 6): restyled to consume DesignSystem tokens exclusively. The label row is drawn
## above the track (label_row_h px, set from main's LEARNED_BAR_LABEL_ROW constant), the track
## uses a BLUE fill on a light BORDER track (no ad-hoc literals), and the gold mastery latch is
## kept via DesignSystem.GOLD.
##
## Reduced-motion-safe by construction (X-5 / P1-8): the learned amount reads off the FILL
## LENGTH, a static quantity — no motion is required to read it. The brief red setback flash
## on erosion is a secondary cue layered on top of the length drop, so the setback is still
## legible with motion reduced.
##
## The flash is stepped by main each frame via advance(delta) (like TierReadout.advance and
## the tell marker), so it is fully deterministic and render-free to test — value + flash
## state are read off public fields, no framebuffer needed.

## A brief red wash on a setback, fading over this long (no hold — the drop in length is the
## primary read; the wash just punctuates it).
const FLASH_FADE := 0.45

## Track radius — fully rounded ends, consistent with the pill language (097 design system).
const TRACK_RADIUS := DesignSystem.R_PILL
const CORNER_INSET := 2.0     ## fill sits just inside the track edge

## 145 (PO father-pass-10, X-4/X-6): the readout washed into 143's brighter sky. The label/%
## were mid-grey SLATE (~sky luminance) and the track was BORDER @ .9 — a translucent cream
## that dissolved into the sky and let the sun disc bleed through and bleach its midsection.
## Fix: dark INK text (AA on the pale sky), an OPAQUE PAPER rail (the sun can't show through),
## and a subtle light scrim behind the whole readout so the label text also has backing and
## nothing bleaches — matching the goal art's legible readout + soft top halo.
##
## 159 (PO father-pass-23, X-4): 145 left the backing panel TRANSLUCENT (alpha 0.55), so the
## sky bled blue through its edges and the sun bled warm-yellow through its middle — a see-through
## film sitting next to the crisp OPAQUE-white nav/coin pills on the same HUD. Fix: raise the
## panel to fully opaque DS PAPER — the exact surface the nav (Triks/Kennel) + coin pills use —
## and give it the pills' soft drop shadow, so the whole HUD reads as one set of solid floating
## chips and nothing behind the bar (sky or sun) shows through. This EXTENDS 145's opacity work
## from the text scrim to the whole panel; it does not revert 145 (dark INK labels, opaque inner
## track, backing behind the text all kept).
const LABEL_COLOR := DesignSystem.INK        ## dark slate «Sitt» label — reads on sky/sun
const PCT_COLOR   := DesignSystem.BLUE_INK    ## blue «%» readout — tied to the blue fill, per goal art (180); AA-safe on the opaque 159 PAPER panel
## 179 (PO father-pass-50, X-4/X-6): 145/159 made BOTH the track rail AND the backing panel
## opaque PAPER — the same white — so the unfilled channel was invisible against its own panel
## and the meter never read as a meter (no track at 0 %, a fill floating in nothing when partly
## filled). Repoint the track to the DS BORDER groove: still opaque + light (luminance ≈ 0.89 >
## 0.80, so the blue fill reads and no sky/sun bleeds through — 145/159 kept), but ≈0.095 darker
## than the PAPER panel, so the full rounded track reads as a defined empty channel per goal art.
const TRACK_COLOR := DesignSystem.BORDER      ## opaque light groove, darker than the PAPER panel (179)
const SCRIM_COLOR := DesignSystem.PAPER       ## 159: fully OPAQUE backing panel (was PAPER @ 0.55)
## The pills' soft drop shadow lifts the opaque panel off the scene (matches CoinReadout's 100
## deepened HUD-pill shadow, INK @ 0.20, so no sky/sun shows through and it reads as one chip).
const PANEL_SHADOW := Color(DesignSystem.INK.r, DesignSystem.INK.g, DesignSystem.INK.b, 0.20)
const SCRIM_PAD_X := 14.0     ## scrim padding beyond the label/track, horizontal
const SCRIM_PAD_Y := 6.0      ## scrim padding beyond the readout, vertical

var value: float = 0.0      ## learned fraction in [0, 1] — the fill length
var mastered: bool = false  ## drawn as a full gold bar
var _flash := 0.0           ## current setback-wash intensity in [0, 1]

## Label-row geometry (set from main's constants so there is one source of truth).
var _label_row_h := 24.0     ## height of the trick name + % row above the track
var _label_gap   := 4.0      ## vertical gap between label row bottom and track top
var _trick_id    := "sitt"   ## the trick id whose display name is shown left

func _init() -> void:
	# Float over the stage; never eat a tap meant for the BRA button below.
	mouse_filter = Control.MOUSE_FILTER_IGNORE

## Feed the trick id and label-row geometry from main so the bar shows the right name.
## Called from _setup_learned_bar() and select_trick() (097, Phase 6).
func set_trick(id: String, label_row_h: float, label_gap: float) -> void:
	_trick_id    = id
	_label_row_h = label_row_h
	_label_gap   = label_gap
	queue_redraw()

## Set the learned fraction (and mastered state) and request a redraw. Clamped defensively
## so a caller can pass the raw model value without pre-clamping.
func set_value(v: float, is_mastered := false) -> void:
	value = clampf(v, 0.0, 1.0)
	mastered = is_mastered
	queue_redraw()

## Punctuate a setback with a brief red wash (the bar already drops in length via set_value).
func pulse_setback() -> void:
	_flash = 1.0
	queue_redraw()

## Step the setback wash one frame's delta (driven from main._process). Linear fade to 0.
func advance(delta: float) -> void:
	if _flash <= 0.0:
		return
	_flash = maxf(0.0, _flash - delta / FLASH_FADE)
	queue_redraw()

## True while the setback wash is still showing — the render-free predicate the tests use.
func is_flashing() -> bool:
	return _flash > 0.0

## Map a trick id to its display name (Norwegian).
static func _display_name(id: String) -> String:
	match id:
		"sitt":    return "Sitt"
		"ligg":    return "Ligg"
		"legg_deg": return "Legg deg"
		_:         return id.capitalize()

func _draw() -> void:
	var w := size.x
	var h := size.y
	# ── Backing panel: an OPAQUE PAPER chip behind the whole readout (145 → 159) ───
	# Backs the label text and — now fully opaque (159) — defeats BOTH the sky and the sun
	# disc bleeding through, so it reads as one solid floating chip matching the nav/coin
	# pills. Padded beyond the readout so it frames the readout cleanly, with the pills'
	# soft drop shadow lifting it off the scene.
	var scrim := Rect2(-SCRIM_PAD_X, -SCRIM_PAD_Y, w + 2.0 * SCRIM_PAD_X, h + 2.0 * SCRIM_PAD_Y)
	var panel_sb := DesignSystem.panel(SCRIM_COLOR, TRACK_RADIUS)
	panel_sb.shadow_color = PANEL_SHADOW
	panel_sb.draw(get_canvas_item(), scrim)
	# ── Label row: trick name left, percentage right ──────────────────────────
	var font_label := DesignSystem.font_body_bold()
	var label_size := DesignSystem.T_HEAD  ## 18px — readable without eating too much height
	var name_str   := _display_name(_trick_id)
	var pct_str    := "%d%%" % roundi(value * 100.0)
	if mastered:
		pct_str = "100%"
	# Vertically centre text in the label row.
	var label_y := _label_row_h * 0.5 + font_label.get_ascent(label_size) * 0.5 - font_label.get_descent(label_size) * 0.5
	# Dark INK (145): reads on the bright sky / behind the sun where the old SLATE washed out.
	draw_string(font_label, Vector2(0.0, label_y), name_str,
		HORIZONTAL_ALIGNMENT_LEFT, -1, label_size, LABEL_COLOR)
	draw_string(font_label, Vector2(0.0, label_y), pct_str,
		HORIZONTAL_ALIGNMENT_RIGHT, w, label_size, PCT_COLOR)
	# ── Track: rounded rect, starts at label row bottom + gap ────────────────
	var track_y := _label_row_h + _label_gap
	var track_h := maxf(0.0, h - track_y)
	if track_h <= 0.0:
		return
	var track := Rect2(0.0, track_y, w, track_h)
	# Rounded background track — use StyleBoxFlat.draw() for rounded corners.
	# OPAQUE PAPER (145): an opaque light rail so the sun can't bleach it and the blue fill
	# reads. The pill shape makes it look like a slider rail (097).
	var track_sb := DesignSystem.pill(TRACK_COLOR, TRACK_RADIUS)
	track_sb.draw(get_canvas_item(), track)
	# Fill.
	var fill_w := maxf(0.0, (w - 2.0 * CORNER_INSET) * value)
	if fill_w > 0.0:
		var fill := Rect2(CORNER_INSET, track_y + CORNER_INSET,
			fill_w, track_h - 2.0 * CORNER_INSET)
		var fill_color := DesignSystem.GOLD if mastered else DesignSystem.BLUE
		var fill_sb := DesignSystem.pill(fill_color, TRACK_RADIUS)
		fill_sb.draw(get_canvas_item(), fill)
	# Setback wash.
	if _flash > 0.0:
		var wash := Color(DesignSystem.DANGER.r, DesignSystem.DANGER.g,
			DesignSystem.DANGER.b, DesignSystem.DANGER.a * _flash)
		draw_rect(track, wash, true)
