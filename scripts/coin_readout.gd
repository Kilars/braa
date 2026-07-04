class_name CoinReadout
extends Control
## The coin readout (069, Phase-3 P3-D3): a small purpose-bearing balance widget — a DRAWN gold
## coin disc + the earned-coin count — pinned on its OWN top line in the HUD, clear of the top-left
## Tricks button. It replaces the 068 emoji Label, whose coin emoji (U+1FA99) rendered as a
## missing-glyph "tofu" box in Godot's fallback font (PO Review 2026-07-01, bug 1). Drawing the coin
## as a disc removes the font-glyph dependency entirely.
##
## 097 (Phase 6): redesigned as a white PAPER rounded pill (design-system) — a draw_rect pill
## background, gold coin disc, SLATE number in Baloo 2. The "coins" caption is dropped; the goal
## screen shows just coin + number inside the pill.
##
## Same dumb-renderer split the rest of the HUD uses (TierReadout / LearnedBar / TrickMenu):
## main owns the balance and feeds it in via set_balance(); this node only draws it. So the
## balance→text mapping is unit-testable render-free (balance_text) with no framebuffer.

const HEIGHT := 40.0

## Pill padding and coin metrics — all expressed as constants, no ad-hoc literals.
const PILL_PAD_H := 12.0                        ## horizontal padding inside the pill
const PILL_PAD_V := 6.0                         ## vertical padding inside the pill
const COIN_R := 11.0                            ## the coin disc radius
const NUMBER_SIZE := 22                         ## px font for the balance digits (fits the pill)
const GAP := 8.0                                ## gutter between coin and number

var _balance := 0

func _init() -> void:
	# Purely a readout — it must never eat a tap (P1-5), like the other HUD labels.
	mouse_filter = Control.MOUSE_FILTER_IGNORE

## Set the balance to show and request a redraw. Clamped >= 0 (a purse never goes negative).
func set_balance(n: int) -> void:
	_balance = maxi(0, n)
	queue_redraw()

## The balance currently shown — the render-free predicate the wiring test reads.
func balance() -> int:
	return _balance

## Pure, render-free: the digits the readout shows for a balance. ASCII digits ONLY — NEVER the
## coin emoji (U+1FA99), so the tofu-box bug can never come back through this seam.
static func balance_text(n: int) -> String:
	return "%d" % maxi(0, n)

func _draw() -> void:
	var font := DesignSystem.font_display()
	var num := balance_text(_balance)
	var coin_d := 2.0 * COIN_R
	var num_w := font.get_string_size(num, HORIZONTAL_ALIGNMENT_LEFT, -1, NUMBER_SIZE).x
	# Pill width shrinks to content + padding; pill height = full widget height.
	var content_w := coin_d + GAP + num_w
	var pill_w := content_w + PILL_PAD_H * 2.0
	var pill_h := size.y
	# Right-align the pill to the widget's right edge (widget is right-anchored in main).
	var pill_x := maxf(0.0, size.x - pill_w)
	var pill_rect := Rect2(pill_x, 0.0, pill_w, pill_h)
	# Draw PAPER pill background with DesignSystem radius + card shadow (097 design system).
	var sb := DesignSystem.panel(DesignSystem.PAPER, DesignSystem.R_PILL)
	sb.draw(get_canvas_item(), pill_rect)
	# Coin: gold face + darker rim + inner ring — no font glyph (069 lesson).
	var cy := pill_h * 0.5
	var cx := pill_x + PILL_PAD_H + COIN_R
	var cc := Vector2(cx, cy)
	draw_circle(cc, COIN_R, DesignSystem.GOLD_DARK)
	draw_circle(cc, COIN_R - 2.0, DesignSystem.GOLD)
	draw_arc(cc, COIN_R * 0.55, 0.0, TAU, 24, DesignSystem.GOLD_DARK, 1.5)
	# Number: slate in Baloo 2, baseline-centred in the pill.
	var tx := cx + COIN_R + GAP
	var num_baseline := cy + font.get_ascent(NUMBER_SIZE) * 0.5 - font.get_descent(NUMBER_SIZE) * 0.5
	draw_string(font, Vector2(tx, num_baseline), num, HORIZONTAL_ALIGNMENT_LEFT, -1, NUMBER_SIZE, DesignSystem.SLATE)
