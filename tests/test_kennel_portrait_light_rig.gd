extends "res://tests/test_case.gd"
## TDD for the kennel portrait light rig (187, PO father-pass-61 X-6). Grid + modal share
## _build_one_portrait; the ONLY difference between them is yaw (grid = PORTRAIT_YAW_SPREAD[i],
## modal = MODAL_PORTRAIT_YAW 0.0). At the modal's front-on angle Nova's flank faced straight
## into the −34/−38 key light (energy 1.2) and blew ~2× brighter than the side-yaw grid cell,
## and the COOL ambient (0.72,0.74,0.78) tinted the shadowed grid flank so the same dog flipped
## cool→warm between the two views. The rig is retuned so the yaw-invariant flat illumination
## dominates the yaw-variant key, and the ambient is hue-neutral so no cool→warm flip.
##
## These are pure invariants on the named rig consts (the render itself is Visual-Review'd).

const KennelScreen := preload("res://scripts/kennel_screen.gd")

func test_ambient_is_hue_neutral() -> void:
	# A hue-neutral ambient (r==g==b) means the shadowed side is a plain grey, not a cool cast —
	# so a dark coat can't flip cool (shadow) ⇄ warm (key-lit) between the grid and the modal.
	var a: Color = KennelScreen.PORTRAIT_AMBIENT_COLOR
	assert_true(is_equal_approx(a.r, a.g) and is_equal_approx(a.g, a.b),
		"portrait ambient must be hue-neutral (r==g==b) so coat hue can't flip with yaw; got " + str(a))

func test_key_to_fill_ratio_softened() -> void:
	# Old rig: key 1.2 / fill 0.35 = 3.43 — a hard key the front-on modal washed into. Softening
	# the ratio (<= 2.0) keeps the front-lit flank from blowing out at MODAL_PORTRAIT_YAW.
	var ratio := KennelScreen.PORTRAIT_KEY_ENERGY / KennelScreen.PORTRAIT_FILL_ENERGY
	assert_true(ratio <= 2.0,
		"portrait key-to-fill ratio must be softened to <= 2.0 (was 3.43); got " + str(ratio))

func test_flat_illumination_dominates_the_key() -> void:
	# The key is the ONLY yaw-variant term; fill + ambient are flat across yaw. When the flat
	# baseline outweighs the key, the coat's apparent value holds constant as the dog turns —
	# grid side-yaw and modal front-on read the same brightness.
	var flat := KennelScreen.PORTRAIT_FILL_ENERGY + KennelScreen.PORTRAIT_AMBIENT_ENERGY
	assert_true(KennelScreen.PORTRAIT_KEY_ENERGY < flat,
		"yaw-variant key must not dominate the flat fill+ambient baseline; key=" \
		+ str(KennelScreen.PORTRAIT_KEY_ENERGY) + " flat=" + str(flat))

func test_key_energy_brought_down_from_old_blowout() -> void:
	# Regression guard: don't re-inflate the key back to the 1.2 that blew the modal hero out.
	assert_true(KennelScreen.PORTRAIT_KEY_ENERGY < 1.2,
		"portrait key energy must stay below the old 1.2 blowout; got " + str(KennelScreen.PORTRAIT_KEY_ENERGY))
