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
