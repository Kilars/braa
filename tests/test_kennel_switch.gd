extends "res://tests/test_case.gd"
## TDD for kennel-dog active switch + persistence (110, Phase 8 K-5/K-7).
## Active-switch logic persists the chosen dog id, coat tint resolves to the chosen dog's band_tint,
## and stats map from KennelDog stats (1-5 array) to the training-scene levers (BreedPersonality-style).
##
## K-5: «Tren med [navn]» button on an owned dog sets it active, closes the kennel, returns to training
## with the dog loaded (coat tint + stats applied).
## K-7: The active dog persists across a reload under the kennel save key; a returning player boots
## into their chosen dog.

## True iff TrickStore (the class) has a method with this name.
func _ts_has(method_name: String) -> bool:
	return TrickStore.new().has_method(method_name)

## True iff KennelDog (the class) has a method with this name.
func _kd_has(method_name: String) -> bool:
	return KennelDog.new().has_method(method_name)

# ---- 1. Active switch persists through TrickStore round-trip (K-7) ----
func test_active_kennel_dog_roundtrips_through_save() -> void:
	assert_true(_ts_has("decode_kennel"),
		"TrickStore.decode_kennel must exist to test kennel persistence")
	if not _ts_has("decode_kennel"):
		return
	# Adopt Nova, set her as active, encode via TrickStore, decode, verify active is Nova.
	var roster := KennelRoster.new()
	roster.adopt("nova")
	assert_true(roster.set_active("nova"),
		"set_active('nova') on an owned dog returns true")
	assert_eq(roster.active, "nova",
		"active dog is now 'nova' after set_active")
	# Encode the roster via TrickStore (with kennel as the 6th param).
	var kennel_dict := roster.to_dict()
	var blob: String = TrickStore.new().call("encode", {}, 0, {}, "normal", {}, kennel_dict)
	# Decode back via TrickStore.decode_kennel.
	var back: Dictionary = TrickStore.new().call("decode_kennel", blob)
	assert_eq(back.get("active"), "nova",
		"the active kennel dog 'nova' survives encode/decode_kennel round-trip")
	# Verify owned set also survives.
	var owned: Variant = back.get("owned")
	assert_true(owned is Array, "owned is an array after decode")
	assert_true((owned as Array).has("nova"), "nova is in owned after round-trip")
	assert_true((owned as Array).has("bella"), "bella is in owned after round-trip")

# ---- 2. Set active to an owned dog updates active (K-5) ----
func test_set_active_to_owned_dog_updates_active() -> void:
	var script = load("res://scripts/kennel_roster.gd")
	assert_true(script != null, "kennel_roster.gd must exist")
	var r = script.new()
	# Adopt Balder and set him active.
	r.adopt("balder")
	assert_true(r.set_active("balder"),
		"set_active on an owned dog returns true")
	assert_eq(r.active, "balder",
		"active dog switches to 'balder'")
	# Try to set active to an unowned dog — should fail and not change active.
	assert_false(r.set_active("nova"),
		"set_active on an unowned dog returns false")
	assert_eq(r.active, "balder",
		"active dog stays 'balder' when attempting to activate an unowned dog")

# ---- 3. Starter Bella coat tint is identity (K-5 honest stand-in: Bella = real yellow lab) ----
func test_starter_bella_coat_tint_is_identity() -> void:
	# KennelDog should expose a coat_tint() method that returns the band_tint color.
	var bella := KennelDog.by_id("bella")
	assert_true(bella != null, "KennelDog.by_id('bella') returns a dog")
	assert_eq(bella.id, "bella", "the resolved dog is Bella")
	# Guard: check if the method exists before calling.
	assert_true(_kd_has("coat_tint"), "KennelDog.coat_tint() method must be implemented")
	if not _kd_has("coat_tint"):
		return
	var coat_color: Variant = bella.call("coat_tint")
	assert_true(coat_color is Color, "coat_tint() returns a Color")
	# Bella's coat is the identity (no tint), so it should be ~Color(1,1,1).
	# Allow a small epsilon for floating-point comparison.
	assert_true((coat_color as Color).is_equal_approx(Color(1, 1, 1)),
		"Bella's coat_tint is identity Color(1,1,1) (the real yellow lab, unchanged)")

# ---- 4. Non-starter dogs have distinct coat tints (K-5 honest stand-in: tinted rig) ----
func test_non_starter_dog_has_a_distinct_coat_tint() -> void:
	assert_true(_kd_has("coat_tint"), "KennelDog.coat_tint() method must be implemented")
	if not _kd_has("coat_tint"):
		return
	# Nova (Border collie) should have a distinct tint — not identity.
	var nova := KennelDog.by_id("nova")
	assert_eq(nova.id, "nova", "the resolved dog is Nova")
	var nova_tint: Variant = nova.call("coat_tint")
	assert_true(nova_tint is Color, "coat_tint() returns a Color")
	# Nova's tint should NOT be identity (she should be recolored at runtime).
	assert_false((nova_tint as Color).is_equal_approx(Color(1, 1, 1)),
		"Nova's coat_tint is NOT identity (a distinct, non-white tint for runtime recolor)")
	# Also check another dog to confirm the pattern.
	var pontus := KennelDog.by_id("pontus")
	var pontus_tint: Variant = pontus.call("coat_tint")
	assert_true(pontus_tint is Color, "coat_tint() returns a Color for Pontus")
	assert_false((pontus_tint as Color).is_equal_approx(Color(1, 1, 1)),
		"Pontus's coat_tint is NOT identity (a distinct tint)")

# ---- 5. Active kennel dog resolves stats for training levers (K-5 stats apply) ----
func test_active_kennel_dog_resolves_stats() -> void:
	# Each KennelDog has a stats array [Læreevne, Energi, Mot, Fokus], each 1-5.
	# The task hints at a KennelDog.to_personality() or a stat->lever mapping accessor.
	# This test verifies that a dog's stats can be read and map to expected lever values.
	var nova := KennelDog.by_id("nova")
	assert_true(nova.stats is Array, "KennelDog.stats is an array")
	assert_eq(nova.stats.size(), 4, "stats has 4 entries (Læreevne, Energi, Mot, Fokus)")
	# Nova is [5,5,4,5] — high Fokus (5) should yield a tight/expected window.
	# If the task defines a to_personality() method or lever mapping, test it.
	# For now, guard and verify the stats are readable.
	var fokus_stat: Variant = nova.stats[3]  # Fokus is the 4th entry (0-indexed)
	assert_true(fokus_stat is int, "Fokus stat is an int")
	assert_eq(fokus_stat, 5, "Nova's Fokus is 5 (highest)")
	# Verify Bella's stats are different.
	var bella := KennelDog.by_id("bella")
	var bella_fokus: Variant = bella.stats[3]
	assert_eq(bella_fokus, 3, "Bella's Fokus is 3 (medium)")
	assert_ne(bella_fokus, fokus_stat,
		"Bella's Fokus (3) differs from Nova's (5) — stats are distinct per dog")
	# If a to_personality() method exists, test that high-Fokus dogs return tighter levers.
	# First assert the method exists (RED when absent).
	assert_true(_kd_has("to_personality"),
		"KennelDog.to_personality() method should be implemented to map stats → levers")
	if _kd_has("to_personality"):
		var nova_personality: Variant = nova.call("to_personality")
		var bella_personality: Variant = bella.call("to_personality")
		assert_true(nova_personality is BreedPersonality,
			"KennelDog.to_personality() returns a BreedPersonality")
		assert_true(bella_personality is BreedPersonality,
			"Bella's to_personality() also returns a BreedPersonality")
		# High Fokus → tight window. window_stability is the lever for timing tightness.
		# Nova (Fokus=5) should have a higher window_stability than Bella (Fokus=3).
		var nova_window := (nova_personality as BreedPersonality).window_stability
		var bella_window := (bella_personality as BreedPersonality).window_stability
		assert_true(nova_window > bella_window,
			"High-Fokus dog (Nova) has higher window_stability than low-Fokus (Bella) — tighter timing")
