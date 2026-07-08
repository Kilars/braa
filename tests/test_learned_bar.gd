extends "res://tests/test_case.gd"
## TDD for the on-screen learned bar (045, P2-4). LearnedBar is a dumb renderer driven by
## TrickProgress's value; these assert its render-free behaviour (value clamp, mastered
## state, the setback wash firing + fading) without a framebuffer — the same approach
## TierReadout's tests use (visibility read off public fields, not pixels).

func test_fresh_bar_is_empty_and_not_flashing() -> void:
	var bar := LearnedBar.new()
	assert_eq(bar.value, 0.0, "a fresh bar starts empty")
	assert_false(bar.is_flashing(), "nothing tapped yet — no setback wash")

func test_set_value_clamps_to_unit_range() -> void:
	var bar := LearnedBar.new()
	bar.set_value(1.5)
	assert_eq(bar.value, 1.0, "value clamps to 1.0")
	bar.set_value(-0.3)
	assert_eq(bar.value, 0.0, "value clamps to 0.0")

func test_mastered_state_is_carried() -> void:
	var bar := LearnedBar.new()
	bar.set_value(1.0, true)
	assert_true(bar.mastered, "the bar shows a mastered trick when told so")

func test_setback_wash_fires_then_fades() -> void:
	var bar := LearnedBar.new()
	bar.pulse_setback()
	assert_true(bar.is_flashing(), "a setback lights the red wash")
	bar.advance(LearnedBar.FLASH_FADE)  # a full fade window
	assert_false(bar.is_flashing(), "the wash fades fully out so it never lingers")

func test_advance_is_inert_without_a_setback() -> void:
	var bar := LearnedBar.new()
	bar.advance(1.0)
	assert_false(bar.is_flashing(), "advancing with no pending setback does nothing")

# ── 145 (PO father-pass-10, X-4/X-6): the readout must READ on 143's bright sky ──────
# The label/% washed into the pale sky (mid-grey SLATE) and the track was translucent
# (BORDER @ .9) so the sun bled through it. These render-free asserts lock the fix:
# dark ink text, an opaque light rail, and a scrim behind the readout.

func test_label_and_percent_are_dark_ink_for_contrast_on_sky() -> void:
	# INK on the pale sky (~luminance 0.52) clears AA; mid-grey SLATE (the old value,
	# luminance ~0.16) did not. Guard the label + % stay dark.
	assert_true(LearnedBar.LABEL_COLOR.get_luminance() < 0.20,
		"the trick label is dark ink, not a pale sky grey")
	assert_true(LearnedBar.PCT_COLOR.get_luminance() < 0.20,
		"the percentage is dark ink, legible against the bright sky")

func test_track_is_opaque_and_light_so_the_sun_cannot_bleed_through() -> void:
	assert_eq(LearnedBar.TRACK_COLOR.a, 1.0,
		"the track is opaque — a translucent track let the sun bleach its midsection")
	assert_true(LearnedBar.TRACK_COLOR.get_luminance() > 0.80,
		"the track is a light rail so the blue fill reads against it")

func test_a_scrim_backs_the_readout_against_the_sun() -> void:
	assert_true(LearnedBar.SCRIM_COLOR.a > 0.0,
		"a light scrim sits behind the readout so the label reads and the sun cannot bleach it")
	assert_true(LearnedBar.SCRIM_COLOR.get_luminance() > 0.80,
		"the scrim is a light DS surface (dark ink text reads on it)")

# ── 159 (PO father-pass-23, X-4): the backing panel must be FULLY OPAQUE, not a film ──
# 145 made the panel light (luminance > 0.80) but left it translucent (alpha 0.55), so on
# 143's bright HUD the sky bled blue through its edges and the sun bled warm-yellow through
# its middle — it read as a see-through tinted film next to the crisp opaque white nav/coin
# pills on the same HUD. Fix: raise the panel to fully opaque so it reads one neutral colour
# regardless of what is behind it (sky or sun), matching the nav/coin pill surface exactly.

func test_backing_panel_is_fully_opaque_like_the_nav_and_coin_pills() -> void:
	assert_eq(LearnedBar.SCRIM_COLOR.a, 1.0,
		"the backing panel is fully opaque — a translucent panel let the sky/sun bleed through it")

func test_backing_panel_is_the_same_paper_surface_as_the_pills() -> void:
	# The nav (Triks/Kennel) + coin pills are DesignSystem.PAPER; the learned bar's panel
	# must be the same surface so the whole HUD reads as one set of opaque chips.
	assert_eq(LearnedBar.SCRIM_COLOR, DesignSystem.PAPER,
		"the backing panel is the DS PAPER surface the nav/coin pills use, at full opacity")

# ── 179 (PO father-pass-50, X-4/X-6): the empty track must READ as a groove ───────────
# 145/159 made BOTH the track rail AND the backing panel opaque PAPER (the same white), so
# the unfilled channel was invisible against its own panel — at 0 % there was no visible
# track and when partly filled the blue fill floated with no channel around it, so the meter
# never read as a meter. The empty track must be a visibly darker groove inset into the panel
# (while staying opaque + light — 145/159 kept, asserted above).

func test_empty_track_channel_reads_as_a_distinct_groove_in_the_panel() -> void:
	assert_true(LearnedBar.TRACK_COLOR != LearnedBar.SCRIM_COLOR,
		"the empty track is a distinct groove, not the same white as its own panel")
	assert_true(LearnedBar.SCRIM_COLOR.get_luminance() - LearnedBar.TRACK_COLOR.get_luminance() >= 0.04,
		"the track is a groove visibly darker than the panel (was identical PAPER — invisible)")
