extends "res://tests/test_case.gd"
## TDD for the 8-dog kennel catalog (103, Phase 8 K-1/K-2/K-6/K-8-data). KennelDog is a pure
## value object — the Resource-shaped record the kennel cell/modal are fed per dog. These tests
## pin the exact spec data (phase8.md:147-159) so a typo in the table fails loudly, and prove the
## K-8 asset gate against the REAL clip resolver (every offered trick resolves to a real rig clip).

# The licensed Labrador's clip leaves that resolve the shared core, AS GODOT IMPORTS THEM (the
# glTF importer strips "loop": Sitting_loop_1 -> Sitting_1, Lie_loop_1 -> Lie_1, etc.). All three
# core tricks (Sitt / Ligg / Legg deg) build+hold on this list, so has_trick() is true for each.
const RIG := [
	"Arm_Labrador|Idle_1",
	"Arm_Labrador|Sitting_start", "Arm_Labrador|Sitting_1", "Arm_Labrador|Sitting_end",
	"Arm_Labrador|Lie_start", "Arm_Labrador|Lie_1", "Arm_Labrador|Lie_end",
	"Arm_Labrador|Lie_belly_start", "Arm_Labrador|Lie_belly_1", "Arm_Labrador|Lie_belly_end",
]

# The spec table (phase8.md:147-159), the single source of truth this catalog must reproduce.
# id, name, breed, rarity, price, [stats], unique_trait
const EXPECTED := [
	["bella",  "Bella",  "Labrador retriever", KennelDog.Rarity.OWNED,  0,   [4, 3, 4, 3], "Godbit-radar"],
	["nova",   "Nova",   "Border collie",      KennelDog.Rarity.EPIC,   900, [5, 5, 4, 5], "Øyet"],
	["balder", "Balder", "Schäferhund",        KennelDog.Rarity.RARE,   650, [4, 4, 5, 4], "Vaktpost"],
	["sol",    "Sol",    "Golden retriever",   KennelDog.Rarity.RARE,   500, [4, 3, 4, 3], "Alles venn"],
	["pontus", "Pontus", "Gravhund",           KennelDog.Rarity.COMMON, 350, [2, 3, 4, 2], "Gravemaskin"],
	["lykke",  "Lykke",  "Spisshund",          KennelDog.Rarity.COMMON, 300, [3, 4, 3, 2], "Alarmen"],
	["sniff",  "Sniff",  "Beagle",             KennelDog.Rarity.COMMON, 320, [3, 4, 3, 2], "Nesa styrer"],
	["trulte", "Trulte", "Malchi",             KennelDog.Rarity.SECRET, 0,   [3, 2, 1, 2], "Skjelver som et aspeløv"],
]

func test_catalog_has_the_eight_spec_dogs_in_order() -> void:
	var cat := KennelDog.catalog()
	assert_eq(cat.size(), 8, "the kennel lists exactly 8 dogs (phase8.md 'Profesjonell fasilitet · 8 plasser')")
	for i in EXPECTED.size():
		var dog: KennelDog = cat[i]
		assert_eq(dog.id, EXPECTED[i][0], "dog %d id in spec order" % i)

func test_starter_is_bella_and_ids_are_unique_kebab() -> void:
	var cat := KennelDog.catalog()
	assert_eq((cat[0] as KennelDog).id, KennelDog.STARTER_ID, "the first dog is the starter")
	assert_eq(KennelDog.STARTER_ID, "bella", "the starter the player owns from run 1 is Bella")
	var seen := {}
	for d in cat:
		var dog: KennelDog = d
		assert_true(dog.id != "" and dog.id == dog.id.to_lower(), "id is a non-empty lowercase string: '%s'" % dog.id)
		assert_false(seen.has(dog.id), "no duplicate id: '%s'" % dog.id)
		seen[dog.id] = true

func test_each_dog_matches_the_spec_table_exactly() -> void:
	for row in EXPECTED:
		var dog := KennelDog.by_id(row[0])
		assert_eq(dog.dog_name, row[1], "%s name" % row[0])
		assert_eq(dog.breed, row[2], "%s breed" % row[0])
		assert_eq(dog.rarity, row[3], "%s rarity" % row[0])
		assert_eq(dog.price, row[4], "%s price" % row[0])
		assert_eq(dog.stats, row[5], "%s stats [Læreevne, Energi, Mot, Fokus]" % row[0])
		assert_eq(dog.unique_trait, row[6], "%s Unikt trekk" % row[0])

func test_stats_are_four_values_in_one_to_five() -> void:
	for d in KennelDog.catalog():
		var dog: KennelDog = d
		assert_eq((dog.stats as Array).size(), 4, "%s has 4 stats" % dog.id)
		for v in dog.stats:
			assert_true(v >= 1 and v <= 5, "%s stat %d is in 1..5" % [dog.id, v])

func test_only_bella_and_trulte_are_free_with_distinct_rarity() -> void:
	# price==0 covers BOTH the owned starter and the gratis easter dog; rarity disambiguates the chip.
	assert_eq(KennelDog.by_id("bella").price, 0, "Bella shows no price (owned)")
	assert_eq(KennelDog.by_id("bella").rarity, KennelDog.Rarity.OWNED, "Bella is the owned dog")
	assert_eq(KennelDog.by_id("trulte").price, 0, "Trulte is gratis (K-6 easter dog)")
	assert_eq(KennelDog.by_id("trulte").rarity, KennelDog.Rarity.SECRET, "Trulte is the hidden/secret dog")
	for d in KennelDog.catalog():
		var dog: KennelDog = d
		if dog.id != "bella" and dog.id != "trulte":
			assert_true(dog.price > 0, "%s is a priced dog" % dog.id)

func test_band_tint_matches_spec_for_each_dog() -> void:
	# phase8.md:158 — the per-dog cell-band bg tint (NOT the coat).
	var expected := {
		"bella": Color(0.29, 0.565, 0.886),  "nova": Color(0.298, 0.322, 0.357),
		"balder": Color(0.663, 0.498, 0.310), "sol": Color(0.886, 0.741, 0.463),
		"pontus": Color(0.529, 0.337, 0.212), "lykke": Color(0.878, 0.643, 0.373),
		"sniff": Color(0.757, 0.584, 0.369),  "trulte": Color(0.902, 0.863, 0.796),
	}
	for id in expected:
		assert_true(KennelDog.by_id(id).band_tint.is_equal_approx(expected[id]), "%s band tint" % id)

func test_is_known_and_by_id_resolution() -> void:
	for d in KennelDog.catalog():
		assert_true(KennelDog.is_known((d as KennelDog).id), "catalog id is known: %s" % (d as KennelDog).id)
	assert_false(KennelDog.is_known("husky"), "an unshipped ghost breed is not known")
	assert_false(KennelDog.is_known(""), "the empty id is not known")
	assert_eq(KennelDog.by_id("nova").dog_name, "Nova", "by_id resolves the right dog")
	assert_eq(KennelDog.by_id("husky").id, KennelDog.STARTER_ID, "an unknown id falls back to the starter (never dog-less)")

func test_every_offered_trick_resolves_on_the_real_rig() -> void:
	# K-8 asset gate: never offer a trick the rig has no clean clip for (phase8.md:99-101). Prove
	# each offered trick_id against the REAL clip resolver, not a bare string.
	var clips := DogClips.resolve(PackedStringArray(RIG))
	for d in KennelDog.catalog():
		var dog: KennelDog = d
		assert_false((dog.trick_ids as Array).is_empty(), "%s offers at least one trick" % dog.id)
		for tid in dog.trick_ids:
			assert_true(clips.has_trick(tid), "%s offers '%s' which resolves on the rig" % [dog.id, tid])

func test_every_dog_offers_the_shared_core() -> void:
	# The core (Sitt / Ligg / Legg deg) is shared by all breeds (phase8.md K-8); breed-specific
	# distinctness is owner-gated on a signature clip (P3-2 flag) and not faked here.
	for d in KennelDog.catalog():
		var dog: KennelDog = d
		assert_true(dog.trick_ids.has(DogClips.TRICK_SITT), "%s can train Sitt" % dog.id)
		assert_true(dog.trick_ids.has(DogClips.TRICK_LIGG), "%s can train Ligg" % dog.id)
		assert_true(dog.trick_ids.has(DogClips.TRICK_LEGG_DEG), "%s can train Legg deg" % dog.id)

func test_trick_ids_are_independent_arrays() -> void:
	# No shared-array aliasing: mutating one dog's list must not leak to another dog in the same
	# catalog, nor to a freshly-built catalog (guards a shared `const CORE_TRICKS` reference).
	var cat := KennelDog.catalog()
	(cat[0] as KennelDog).trick_ids.append("__scratch__")
	assert_false((cat[1] as KennelDog).trick_ids.has("__scratch__"), "mutating one dog's list never leaks to another in the same catalog")
	assert_false((KennelDog.catalog()[0] as KennelDog).trick_ids.has("__scratch__"), "a fresh catalog is unpolluted by an earlier mutation (trick_ids duplicated, not a shared const)")

# --- classify_kennel_dogs tests (104, Phase 8 K-1/K-3 foundation) ---

func test_bella_is_owned_by_default() -> void:
	# K-1: Bella is the starter and is always in the owned array (owned == ["bella"]).
	# Row should show owned == true, status_label == "Din hund", price_label == "Din".
	var rows := KennelDog.classify_kennel_dogs(["bella"], "bella", 1000)
	assert_eq(rows.size(), 8, "classify returns exactly 8 rows")
	var bella_row = rows[0]
	assert_eq(bella_row["id"], "bella", "first row is Bella")
	assert_true(bella_row["owned"], "Bella's owned == true when in the owned array")
	assert_eq(bella_row["status_label"], "Din hund", "Bella's status_label is 'Din hund'")
	assert_eq(bella_row["price_label"], "Din", "Bella's price_label is 'Din'")

func test_adopted_dog_flips_to_owned() -> void:
	# K-1/K-4: when Sol is added to the owned array, her row flips to owned treatment.
	# owned should flip to true, price_label should show "Din", and affordable should be true
	# regardless of balance (spec says owned overrides price).
	var rows := KennelDog.classify_kennel_dogs(["bella", "sol"], "bella", 0)
	assert_eq(rows.size(), 8, "classify returns exactly 8 rows")
	var sol_row = rows[3]  # Sol is at index 3 in the catalog order
	assert_eq(sol_row["id"], "sol", "row is Sol")
	assert_true(sol_row["owned"], "Sol's owned == true when in the owned array")
	assert_eq(sol_row["price_label"], "Din", "Sol's price_label is 'Din' (owned overrides rarity price)")
	assert_true(sol_row["affordable"], "Sol is affordable == true even at balance 0 (owned are always affordable)")

func test_active_flag_set_on_the_active_dog() -> void:
	# K-1/K-5: the active dog (the one currently being trained) has active == true.
	# With active == "bella", only Bella's row should have active == true.
	var rows := KennelDog.classify_kennel_dogs(["bella"], "bella", 1000)
	var bella_row = rows[0]
	assert_true(bella_row["active"], "Bella row has active == true when active == 'bella'")
	for i in range(1, rows.size()):
		var row = rows[i]
		assert_false(row["active"], "dog %d (%s) has active == false (only Bella active)" % [i, row["id"]])

func test_affordability_gate_k3_nova_900_coins() -> void:
	# K-3: Nova costs 900 coins. Test affordability at various balances.
	# balance 100 → affordable == false
	# balance 900 → affordable == true
	# balance 1000 → affordable == true
	var rows_100 := KennelDog.classify_kennel_dogs(["bella"], "bella", 100)
	var nova_100 = rows_100[1]  # Nova is at index 1
	assert_eq(nova_100["id"], "nova", "row is Nova")
	assert_eq(nova_100["price"], 900, "Nova price is 900")
	assert_false(nova_100["affordable"], "Nova is affordable == false at balance 100")

	var rows_900 := KennelDog.classify_kennel_dogs(["bella"], "bella", 900)
	var nova_900 = rows_900[1]
	assert_true(nova_900["affordable"], "Nova is affordable == true at balance 900 (balance >= price)")

	var rows_1000 := KennelDog.classify_kennel_dogs(["bella"], "bella", 1000)
	var nova_1000 = rows_1000[1]
	assert_true(nova_1000["affordable"], "Nova is affordable == true at balance 1000")

func test_trulte_easter_egg_secret_rarity() -> void:
	# K-6: Trulte is the easter-egg hidden dog. When unowned, she should show:
	# secret == true, price == 0, price_label == "Gratis", status_label == "Påskeegg"
	# (no U+2605 star glyph — the star is drawn as geometry in the view, task 106),
	# and affordable == true (free) even at balance 0.
	var rows := KennelDog.classify_kennel_dogs(["bella"], "bella", 0)
	var trulte_row = rows[7]  # Trulte is at index 7 (last)
	assert_eq(trulte_row["id"], "trulte", "row is Trulte")
	assert_true(trulte_row["secret"], "Trulte has secret == true (rarity == Rarity.SECRET)")
	assert_eq(trulte_row["price"], 0, "Trulte price is 0")
	assert_eq(trulte_row["price_label"], "Gratis", "Trulte price_label is 'Gratis'")
	assert_eq(trulte_row["status_label"], "Påskeegg", "Trulte status_label is 'Påskeegg' (no star glyph, 106)")
	assert_true(trulte_row["affordable"], "Trulte is affordable == true even at balance 0 (free easter egg)")

func test_trulte_status_label_no_star_glyph() -> void:
	# 106 — FIX: the U+2605 BLACK STAR has no glyph in Baloo 2 / Nunito and renders as a tofu
	# box. The star must be drawn as geometry in the view; the data string must be clean.
	# Asserts: status_label contains NO "★" (U+2605) AND still contains "Påskeegg".
	var rows := KennelDog.classify_kennel_dogs([], "", 0)
	var trulte_row: Dictionary = {}
	for row in rows:
		if row["id"] == "trulte":
			trulte_row = row
			break
	assert_false(trulte_row.is_empty(), "trulte row found in classify result")
	assert_true(not trulte_row["status_label"].contains("★"), "no U+2605 tofu char in easter status_label")
	assert_true(trulte_row["status_label"].contains("Påskeegg"), "easter status_label still names Påskeegg")

func test_row_count_and_catalog_order() -> void:
	# K-1: the function returns exactly 8 rows in the same order as the catalog (Bella first).
	var rows := KennelDog.classify_kennel_dogs(["bella"], "bella", 1000)
	assert_eq(rows.size(), 8, "returns exactly 8 rows")
	var expected_ids := ["bella", "nova", "balder", "sol", "pontus", "lykke", "sniff", "trulte"]
	for i in expected_ids.size():
		assert_eq(rows[i]["id"], expected_ids[i], "row %d id is '%s' (catalog order)" % [i, expected_ids[i]])

func test_purity_no_aliasing_into_dogs_const() -> void:
	# The row's stats and band_tint arrays must be independent copies; mutating one call's
	# returned row must not bleed into KennelDog.DOGS or a fresh classify() call.
	var rows1 := KennelDog.classify_kennel_dogs(["bella"], "bella", 1000)
	var bella_row1 = rows1[0]
	var original_stats = KennelDog.DOGS[0][5].duplicate()  # DOGS[0] is Bella; [5] is the stats array

	# Mutate the stats array in the returned row
	(bella_row1["stats"] as Array).append(99)

	# Check that KennelDog.DOGS[0][5] is unchanged
	assert_eq(KennelDog.DOGS[0][5], original_stats, "mutating returned stats doesn't mutate KennelDog.DOGS")

	# Get a fresh call and verify the stats are clean
	var rows2 := KennelDog.classify_kennel_dogs(["bella"], "bella", 1000)
	var bella_row2 = rows2[0]
	assert_eq(bella_row2["stats"], original_stats, "a fresh classify() returns clean stats (no aliasing from the prior mutation)")
	assert_eq((bella_row2["stats"] as Array).size(), 4, "fresh stats have 4 elements, not 5 from the mutated row")

func test_two_calls_return_independent_arrays() -> void:
	# Two separate calls should return independent arrays; mutating one doesn't affect the other.
	var rows1 := KennelDog.classify_kennel_dogs(["bella"], "bella", 1000)
	var rows2 := KennelDog.classify_kennel_dogs(["bella"], "bella", 1000)

	# Mutate the first array
	rows1.clear()

	# Check that rows2 is unaffected
	assert_eq(rows2.size(), 8, "second array unaffected by clearing the first")
	assert_eq(rows2[0]["id"], "bella", "rows2 still has Bella at index 0")

func test_unknown_owned_id_harmless() -> void:
	# If the owned array contains an id like "ghost" that doesn't exist in the catalog,
	# it should not crash and should not mark any real dog as owned.
	# In particular, Bella should NOT be owned (the caller is responsible for seeding the starter).
	var rows := KennelDog.classify_kennel_dogs(["ghost"], "bella", 1000)
	assert_eq(rows.size(), 8, "classify doesn't crash with unknown owned id")
	var bella_row = rows[0]
	assert_false(bella_row["owned"], "Bella is not owned when owned array contains only 'ghost' (unknown id harmless)")
	var all_owned := false
	for row in rows:
		if row["owned"]:
			all_owned = true
	assert_false(all_owned, "no dog is marked owned when owned array contains only unknown ids")

# --- detail_for tests (108, Phase 8 K-2 — inspect modal data) ---

func test_each_dog_has_a_blurb_and_traits() -> void:
	# Every dog must carry a non-empty blurb String and at least one trait chip (Array entry).
	# Guards a missing transcription in the DOGS table or _from_row wiring.
	for d in KennelDog.catalog():
		var dog: KennelDog = d
		assert_true(dog.blurb is String and dog.blurb.length() > 0,
			"%s must have a non-empty blurb" % dog.id)
		assert_true(dog.traits is Array and (dog.traits as Array).size() >= 1,
			"%s must have at least one trait chip" % dog.id)

func test_detail_for_carries_stats_trait_and_trick_list() -> void:
	# detail_for("nova") must expose stats (4 values), unique_trait, trick_ids (K-8),
	# blurb, and traits — everything the modal reads from one call.
	var detail: Dictionary = KennelDog.detail_for("nova")
	assert_true(detail is Dictionary, "detail_for returns a Dictionary")
	assert_eq(detail["id"], "nova", "detail_for('nova') id is 'nova'")
	assert_eq((detail["stats"] as Array).size(), 4, "detail carries 4 stats")
	assert_true(detail["unique_trait"] is String and (detail["unique_trait"] as String).length() > 0,
		"detail carries a non-empty unique_trait")
	assert_true(detail["trick_ids"] is Array and (detail["trick_ids"] as Array).size() >= 1,
		"detail carries at least one trick_id (K-8)")
	assert_true(detail["blurb"] is String and (detail["blurb"] as String).length() > 0,
		"detail carries a non-empty blurb")
	assert_true(detail["traits"] is Array and (detail["traits"] as Array).size() >= 1,
		"detail carries at least one trait chip")

func test_detail_for_unknown_id_falls_back_to_starter() -> void:
	# An unknown id must resolve to Bella (the starter) — never a dog-less modal.
	# Mirrors the by_id() no-dog-less-resolve contract (103).
	var detail: Dictionary = KennelDog.detail_for("ghost_dog_99")
	assert_true(detail is Dictionary, "detail_for unknown id still returns a Dictionary")
	assert_eq(detail["id"], KennelDog.STARTER_ID,
		"detail_for an unknown id falls back to the starter (Bella)")

# ---------------------------------------------------------------------------
## True iff KennelDog (the class) has a method with this name.
func _kd_has(method_name: String) -> bool:
	return KennelDog.new().has_method(method_name)

# ---------------------------------------------------------------------------
# portrait_tint() — the kennel-portrait coat modulate (117, PO 2026-07-05 Improvement #1).
# The 116 portrait renders the dog at a neutral grey coat, then modulates per breed. That
# modulate is the dog's NATURAL COAT hue — decoupled from the raw band_tint (which is the
# rarity/ownership BAND background, not a coat colour). The starter Bella sits on a BLUE
# owned-rarity band but is the real warm-cream yellow Labrador, so her portrait_tint must be
# a warm coat (NOT her blue band). The other 7 dogs' bands are already plausible dog hues, so
# their portrait_tint stays their band_tint.
func test_portrait_tint_bella_is_a_warm_coat_not_her_blue_band() -> void:
	assert_true(_kd_has("portrait_tint"), "KennelDog.portrait_tint() method must be implemented")
	if not _kd_has("portrait_tint"):
		return
	var bella := KennelDog.by_id("bella")
	var pt: Variant = bella.call("portrait_tint")
	assert_true(pt is Color, "portrait_tint() returns a Color")
	var c := pt as Color
	# Warm coat: red the strongest channel, blue the weakest (the opposite of her blue band).
	assert_true(c.r > c.g and c.g > c.b, "Bella portrait_tint is a warm coat (R>G>B)")
	assert_true(c.b < 0.5, "Bella portrait_tint is not blue-dominant")
	assert_false(c.is_equal_approx(bella.band_tint),
		"Bella portrait_tint is decoupled from her blue band_tint")

func test_portrait_tint_non_starter_dogs_track_their_band_hue() -> void:
	assert_true(_kd_has("portrait_tint"), "KennelDog.portrait_tint() method must be implemented")
	if not _kd_has("portrait_tint"):
		return
	for id in ["nova", "balder", "sol", "pontus", "lykke", "sniff", "trulte"]:
		var d := KennelDog.by_id(id)
		var pt: Variant = d.call("portrait_tint")
		assert_true(pt is Color, "%s portrait_tint() returns a Color" % id)
		assert_true((pt as Color).is_equal_approx(d.band_tint),
			"%s portrait_tint tracks its (already plausible) band hue" % id)

# ---- 119 (P4-1): special dogs LOCK the difficulty; the starter + COMMON dogs stay choosable ----

func test_special_dogs_lock_difficulty() -> void:
	# The collectible/secret tier (RARE/EPIC/SECRET) locks difficulty — the player can't trade the
	# challenge away on a special dog. Nova EPIC, Balder + Sol RARE, Trulte SECRET all lock.
	assert_true(_kd_has("locks_difficulty"), "KennelDog.locks_difficulty() must be implemented")
	if not _kd_has("locks_difficulty"):
		return
	for id in ["nova", "balder", "sol", "trulte"]:
		assert_true(KennelDog.by_id(id).call("locks_difficulty"),
			"%s (RARE/EPIC/SECRET) locks difficulty" % id)

func test_starter_and_common_dogs_do_not_lock_difficulty() -> void:
	if not _kd_has("locks_difficulty"):
		return
	# Bella is the OWNED starter — never locked. Pontus/Lykke/Sniff are plain COMMON adoptables — free.
	for id in ["bella", "pontus", "lykke", "sniff"]:
		assert_false(KennelDog.by_id(id).call("locks_difficulty"),
			"%s (starter or COMMON) keeps the free difficulty selector" % id)

func test_locked_difficulty_id_is_a_known_mode() -> void:
	assert_true(_kd_has("locked_difficulty_id"), "KennelDog.locked_difficulty_id() must be implemented")
	if not _kd_has("locked_difficulty_id"):
		return
	var locked_id: String = KennelDog.by_id("nova").call("locked_difficulty_id")
	assert_true(Difficulty.is_known(locked_id),
		"locked_difficulty_id returns a known Difficulty mode id (never a ghost)")
