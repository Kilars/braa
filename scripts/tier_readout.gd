class_name TierReadout
extends Label
## The honest timing readout (specs2.md P1-7), task 024g.
##
## The big word that flashes the moment you tap BRA — PERFECT / OK / MISS — so the
## player learns the timing. It is a deliberately dumb renderer, the same split the
## apex tell uses: the scoring (SitWindow.Tier) decides WHAT, this node just shows it
## and fades it. The two acceptance criteria are kept test-first by being pure:
##
##   - HONEST, NEVER CONTRADICTS THE AUDIO: a DEAD tap (no sit open) shows nothing —
##     empty text, fully transparent — exactly as the payoff stays silent (P1-5). A
##     MISS shows "MISS" (a learning signal) while the audio stays silent; that's not
##     a contradiction, it's the same "you missed" read in two channels. PERFECT reads
##     brighter than OK so the emphasis agrees with the louder reward (MarkPayoff).
##   - IMMEDIATE THEN GONE: full opacity on the tap (readable at once), a brief hold,
##     then a smooth fade to nothing, so the next sit starts on a clean slate — no
##     stale tier lingering on screen.
##
## The fade is stepped by main each frame via advance(delta) (like the tell marker is
## driven from main._process), so it's fully deterministic and render-free to test —
## visibility is read off the text and self_modulate.a, no framebuffer needed.

## Hold fully opaque for this long after the tap (readable), then fade over FADE.
const HOLD := 0.6
const FADE := 0.5

## Tier colours. PERFECT is a bright triumphant gold; OK a calmer green; MISS a muted
## grey. PERFECT.v >= OK.v keeps the readout's emphasis agreeing with the reward gate.
const COLOR_PERFECT := Color(1.0, 0.86, 0.30)
const COLOR_OK := Color(0.55, 0.85, 0.55)
const COLOR_MISS := Color(0.72, 0.72, 0.74)

var _age := 0.0       ## seconds since the current tier was displayed
var _active := false  ## a tier is showing (or fading); false once fully faded / cleared

func _init() -> void:
	# Big, centred, non-interactive — it floats over the stage and must never eat a tap
	# meant for the BRA button below it.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_theme_font_size_override("font_size", 88)
	self_modulate.a = 0.0  # start blank — nothing tapped yet

## The on-screen word for a scored tier — empty for DEAD (a dead tap shows nothing,
## matching the silent audio). Pure so the mapping is unit-locked.
static func text_for(tier: SitWindow.Tier) -> String:
	if tier == SitWindow.Tier.DEAD:
		return ""
	return SitWindow.tier_name(tier)

## The colour for a scored tier. PERFECT brighter than OK so the emphasis tracks the
## reward; MISS muted. DEAD never renders, so its colour is moot (returns MISS grey).
static func color_for(tier: SitWindow.Tier) -> Color:
	match tier:
		SitWindow.Tier.PERFECT: return COLOR_PERFECT
		SitWindow.Tier.OK: return COLOR_OK
		_: return COLOR_MISS

## Flash a scored tier: set the word + colour and reset the fade clock so it shows at
## full opacity immediately (P1-7). A DEAD tap clears the readout to blank — nothing on
## screen, no penalty, consistent with the silent payoff.
func display(tier: SitWindow.Tier) -> void:
	var label := text_for(tier)
	text = label
	if label == "":
		_active = false
		_age = 0.0
		self_modulate.a = 0.0
		return
	var col := color_for(tier)
	self_modulate = Color(col.r, col.g, col.b, 1.0)
	_active = true
	_age = 0.0

## Step the fade by one frame's delta (driven from main._process). Full opacity through
## HOLD, then a linear fade over FADE down to fully transparent, after which the readout
## is inert until the next display() — so a tier never goes stale on screen.
func advance(delta: float) -> void:
	if not _active:
		return
	_age += delta
	if _age <= HOLD:
		self_modulate.a = 1.0
		return
	var t := (_age - HOLD) / FADE
	if t >= 1.0:
		self_modulate.a = 0.0
		_active = false
		return
	self_modulate.a = 1.0 - t

## True while a tier is actually visible — non-empty text and some opacity. The
## render-free predicate the tests use to prove a DEAD tap shows nothing and a flashed
## tier fades fully out.
func is_visible_now() -> bool:
	return text != "" and self_modulate.a > 0.0
