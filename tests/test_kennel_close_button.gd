extends "res://tests/test_case.gd"
## Task 189 (PO father-pass-63, X-6/X-4): the kennel had two ✕ dismiss controls styled
## oppositely — the grid CloseButton was a dark-ink glyph on a translucent light disc, the
## modal ModalClose was a WHITE glyph on a translucent-BLACK disc (a dark-bg treatment applied
## over the light hero portrait, so it washed out on light coats). Both were 36u, below the
## app's own 44u nav-pill standard. The fix unifies both onto ONE shared close-button component
## — an opaque light disc with a defined steel ring + a dark C_INK glyph, sized 44u — so the ✕
## reads on any band/portrait and both kennel screens match.
## These assert the shared spec (size / opaque light disc / dark-ink glyph / AA contrast) and
## that BOTH wired buttons carry that identical component.

func test_close_button_is_app_standard_44u() -> void:
	var spec := KennelScreen.close_button_style()
	assert_true(spec["size"] >= 44.0,
		"close button must reach the app's 44u control standard (got %.1f)" % spec["size"])

func test_close_disc_is_opaque_and_light() -> void:
	# The disc must be OPAQUE (no translucent wash that shifts with whatever is behind it) and
	# light, so a dark glyph reads on it over any coat.
	var spec := KennelScreen.close_button_style()
	var disc: Color = spec["disc"]
	assert_true(disc.a >= 0.99, "close disc must be opaque (got a=%.2f)" % disc.a)
	assert_true(KennelScreen._rel_luminance(disc) > 0.6, "close disc must be a light surface")

func test_close_glyph_clears_aa_on_its_own_disc() -> void:
	var spec := KennelScreen.close_button_style()
	var ratio := KennelScreen.wcag_contrast(spec["ink"], spec["disc"])
	assert_true(ratio >= 4.5,
		"close ✕ glyph must clear WCAG AA on the disc (got %.2f)" % ratio)

func test_defined_ring_separates_disc_from_a_light_coat() -> void:
	# A bare light disc on a light coat would vanish; the ring must contrast the disc so the
	# control's outline reads on light backgrounds too.
	var spec := KennelScreen.close_button_style()
	var ring_ratio := KennelScreen.wcag_contrast(spec["border"], spec["disc"])
	assert_true(ring_ratio >= 1.5,
		"close disc ring must be visibly darker than the disc (got %.2f)" % ring_ratio)

func test_white_on_black_modal_treatment_is_gone() -> void:
	# Document the defect: the OLD modal ✕ was white-on-translucent-black. The shared spec must
	# be the opposite — a dark glyph, not a white one.
	var spec := KennelScreen.close_button_style()
	var ink: Color = spec["ink"]
	assert_true(KennelScreen._rel_luminance(ink) < 0.2,
		"the shared ✕ glyph must be DARK ink, not the old white-on-dark treatment")

func test_both_kennel_close_buttons_share_the_component() -> void:
	# Wiring: both the grid CloseButton and the modal ModalClose must carry the identical shared
	# stylebox (disc + ring), ink, and size from close_button_style().
	var spec := KennelScreen.close_button_style()
	var ks := KennelScreen.new()

	ks._build_header()
	var grid_close := ks.find_child("CloseButton", true, false) as Button
	assert_true(grid_close != null, "grid CloseButton must exist")

	var detail := {
		"id": "nova", "name": "Nova", "breed": "Border collie",
		"band_tint": Color("3a3f47"), "coat_hue": Color("3a3f47"),
		"owned": false, "secret": false,
		"rarity": KennelDog.Rarity.RARE, "rarity_label": "Sjelden",
	}
	var band := ks._build_modal_band(detail)
	var modal_close := band.find_child("ModalClose", true, false) as Button
	assert_true(modal_close != null, "modal ModalClose must exist")

	for btn in [grid_close, modal_close]:
		var sb := btn.get_theme_stylebox("normal") as StyleBoxFlat
		assert_eq(sb.bg_color, spec["disc"], "close disc must be the shared spec disc")
		assert_eq(sb.border_color, spec["border"], "close ring must be the shared spec border")
		assert_eq(btn.get_theme_color("font_color"), spec["ink"], "✕ ink must be the shared spec ink")
		assert_true(btn.custom_minimum_size.x >= 44.0, "✕ must be 44u wide")
		assert_true(btn.custom_minimum_size.y >= 44.0, "✕ must be 44u tall")

	ks.free()
