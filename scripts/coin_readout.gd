class_name CoinReadout
extends Control
## The coin readout (069, Phase-3 P3-D3): a small purpose-bearing balance widget — a DRAWN gold
## coin disc + the earned-coin count + a "coins" caption — pinned on its OWN top line, clear of the
## P2-1 selector chip row. It replaces the 068 emoji Label, whose coin emoji (U+1FA99) rendered as a
## missing-glyph "tofu" box in Godot's fallback font (PO Review 2026-07-01, bug 1). Drawing the coin
## as a disc removes the font-glyph dependency entirely, and the caption makes the collection axis
## legible (P3-D3, "the collection axis is visible" — bug 3).
##
## Same dumb-renderer split the rest of the HUD uses (TierReadout / LearnedBar / TrickSelector):
## main owns the balance and feeds it in via set_balance(); this node only draws it. So the
## balance→text mapping is unit-testable render-free (balance_text) with no framebuffer.

const HEIGHT := 40.0

## Coin disc + text metrics, homed here (no scattered literals — cf. 029). The number matches the
## LearnedBar/coin gold; the disc is a filled gold face with a darker rim so it reads as a coin on
## any device with no font glyph.
const COIN_R := 11.0                            ## the coin disc radius
const NUMBER_SIZE := 28                         ## px font for the balance digits
const CAPTION := "coins"                        ## the purpose caption (P3-D3 collection axis)
const CAPTION_SIZE := 15                         ## px font for the caption
const GAP := 6.0                                ## gutter between coin · number · caption
const OUTLINE := 1.5                            ## dark-stroke offset so text pops over sky AND grass

const COIN_GOLD := Color(1.0, 0.84, 0.29)       ## the coin face
const COIN_RIM := Color(0.72, 0.53, 0.10)       ## the darker coin edge + inner ring
const NUMBER_COLOR := Color(1.0, 0.92, 0.45)    ## the balance digits — warm coin-gold (matches 068)
const CAPTION_COLOR := Color(1.0, 0.95, 0.78, 0.92)  ## the caption — a recessive light gold
const SHADOW := Color(0.06, 0.05, 0.02, 0.92)   ## the dark stroke behind text

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

## A dark 4-way stroke behind the glyphs, then the fill — the same "reads over bright sky and grass"
## trick the other HUD text uses, done by hand since draw_string has no outline.
func _draw_text_outlined(font: Font, pos: Vector2, text: String, fsize: int, color: Color) -> void:
	for o in [Vector2(-OUTLINE, 0), Vector2(OUTLINE, 0), Vector2(0, -OUTLINE), Vector2(0, OUTLINE)]:
		draw_string(font, pos + o, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, SHADOW)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, color)

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var num := balance_text(_balance)
	var num_w := font.get_string_size(num, HORIZONTAL_ALIGNMENT_LEFT, -1, NUMBER_SIZE).x
	var cap_w := font.get_string_size(CAPTION, HORIZONTAL_ALIGNMENT_LEFT, -1, CAPTION_SIZE).x
	var coin_d := 2.0 * COIN_R
	# Right-align the whole [coin · number · caption] group to the widget's right edge, so it stays
	# tucked in the corner and grows leftward as the balance gets more digits.
	var total := coin_d + GAP + num_w + GAP + cap_w
	var x := maxf(0.0, size.x - total)
	var cy := size.y * 0.5
	# The coin: a gold face with a darker rim + a subtle inner ring, so it reads as a coin — no glyph.
	var cc := Vector2(x + COIN_R, cy)
	draw_circle(cc, COIN_R, COIN_RIM)
	draw_circle(cc, COIN_R - 2.0, COIN_GOLD)
	draw_arc(cc, COIN_R * 0.55, 0.0, TAU, 24, COIN_RIM, 1.5)
	x += coin_d + GAP
	# The balance number, then the "coins" caption — both baseline-centred in the band, outlined.
	var num_baseline := cy + font.get_ascent(NUMBER_SIZE) * 0.5 - font.get_descent(NUMBER_SIZE) * 0.5
	_draw_text_outlined(font, Vector2(x, num_baseline), num, NUMBER_SIZE, NUMBER_COLOR)
	x += num_w + GAP
	var cap_baseline := cy + font.get_ascent(CAPTION_SIZE) * 0.5 - font.get_descent(CAPTION_SIZE) * 0.5
	_draw_text_outlined(font, Vector2(x, cap_baseline), CAPTION, CAPTION_SIZE, CAPTION_COLOR)
