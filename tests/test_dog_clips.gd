extends "res://tests/test_case.gd"
## TDD for clip resolution (024b). The sit director must be dog-agnostic across the
## CC0 placeholder (assets/models/dog.glb — no Sitt) and the licensed Labrador
## (ADR-0002 shared clip library — real Sitting_* clips). The logic is pure
## name-list matching; one test also binds to the REAL committed dog so "idle
## resolves" can't read a hollow green against an empty/stale list.

# The committed CC0 dog's actual clip leaves (verified from the glb).
const CC0 := ["AnimalArmature|Idle", "AnimalArmature|Walk", "AnimalArmature|Run",
	"AnimalArmature|Jump", "AnimalArmature|Idle_Eating", "AnimalArmature|Death"]

# The licensed Labrador's relevant clip leaves AS GODOT IMPORTS THEM (verified from the
# imported dog_licensed.glb): the glTF importer renames `Sitting_loop_1/2` to `Sitting_1/2`
# (strips "loop"), so the resolver must match the hold loop by exclusion, not "loop". Note
# the decoy `Crouch_Idle_loop_1`: it has "idle" and "loop" but is NOT a sit.
const LAB := ["Arm_Labrador|Idle_1", "Arm_Labrador|Idle_2",
	"Arm_Labrador|Crouch_Idle_loop_1",
	"Arm_Labrador|Sitting_start", "Arm_Labrador|Sitting_1",
	"Arm_Labrador|Sitting_2", "Arm_Labrador|Sitting_end",
	"Arm_Labrador|Walk_F_IP"]

func test_cc0_resolves_plain_idle_and_has_no_sit() -> void:
	var c := DogClips.resolve(PackedStringArray(CC0))
	assert_eq(c.idle, "AnimalArmature|Idle", "the exact 'Idle' leaf is the idle clip")
	assert_false(c.has_sit(), "the CC0 placeholder ships no Sitt clip")
	assert_eq(c.sit_start, "", "no sit start on the CC0 dog")

func test_labrador_resolves_idle_and_sit_clips() -> void:
	var c := DogClips.resolve(PackedStringArray(LAB))
	assert_eq(c.idle, "Arm_Labrador|Idle_1", "first Idle-prefixed leaf when no exact 'Idle'")
	assert_true(c.has_sit(), "the Labrador has a real Sitt")
	assert_eq(c.sit_start, "Arm_Labrador|Sitting_start", "sit build-in clip")
	assert_eq(c.sit_loop, "Arm_Labrador|Sitting_1", "first sit hold-loop clip (Godot strips 'loop')")
	assert_eq(c.sit_end, "Arm_Labrador|Sitting_end", "sit stand-up clip")

func test_crouch_idle_is_not_mistaken_for_idle_or_sit() -> void:
	var c := DogClips.resolve(PackedStringArray(LAB))
	assert_ne(c.idle, "Arm_Labrador|Crouch_Idle_loop_1", "crouch-idle is not the idle clip")
	assert_ne(c.sit_loop, "Arm_Labrador|Crouch_Idle_loop_1", "crouch-idle is not the sit loop")

func test_empty_list_resolves_to_nothing() -> void:
	var c := DogClips.resolve(PackedStringArray([]))
	assert_eq(c.idle, "", "no idle from an empty clip set")
	assert_false(c.has_sit(), "no sit from an empty clip set")
	assert_false(c.has_reaction(), "no reaction from an empty clip set")

func test_reaction_resolves_a_positive_clip_when_present() -> void:
	# 024f: the happy reaction on a successful mark is clip-driven too, so the director
	# stays dog-agnostic. Illustrative clip set (NOT the verified LAB list): a dog whose
	# pack carries a positive-reaction clip must resolve it so play_reaction has a clip.
	var names := ["Arm_Labrador|Idle_1", "Arm_Labrador|Tail_wag",
		"Arm_Labrador|Sitting_start", "Arm_Labrador|Sitting_loop_1"]
	var c := DogClips.resolve(PackedStringArray(names))
	assert_eq(c.reaction, "Arm_Labrador|Tail_wag", "the positive-reaction clip resolves")
	assert_true(c.has_reaction(), "a dog with a reaction clip can react on a mark")

func test_cc0_has_no_positive_reaction_clip() -> void:
	# The CC0 placeholder ships only locomotion + idle — no authored celebration — so it
	# can't react and stays idle; the real reaction ships with the licensed Labrador, the
	# same asset gate as the Sitt (024b). Generic Jump/Walk must NOT be read as a reaction.
	var c := DogClips.resolve(PackedStringArray(CC0))
	assert_false(c.has_reaction(), "the CC0 dog has no positive-reaction clip")
	assert_eq(c.reaction, "", "no reaction clip resolved on the CC0 dog (Jump is not a reaction)")

func test_committed_dog_exposes_a_real_idle_clip() -> void:
	# Binds to the REAL committed asset (mirrors test_smoke): after --import the dog
	# must yield an AnimationPlayer whose resolved idle is an actual clip on it.
	var packed := load("res://assets/models/dog.glb") as PackedScene
	assert_true(packed != null, "the committed dog glb must load as a PackedScene")
	if packed == null:
		return
	var dog := packed.instantiate()
	var ap := DogClips.find_animation_player(dog)
	assert_true(ap != null, "the committed dog must have an AnimationPlayer")
	if ap != null:
		var c := DogClips.resolve(ap.get_animation_list())
		assert_ne(c.idle, "", "the committed dog must expose an idle clip")
		assert_true(ap.has_animation(c.idle), "the resolved idle must be a real clip on the dog")
		# The committed dog is the CC0 placeholder, which has no Sitt (the gate
		# behind 024b). Pins the discrepancy so a future asset swap is deliberate.
		assert_false(c.has_sit(), "the committed CC0 dog has no Sitt clip (see task 024b)")
		# Same gate for the payoff reaction (024f): no authored celebration on CC0, so
		# the live dog can't react until the licensed Labrador ships (025).
		assert_false(c.has_reaction(), "the committed CC0 dog has no reaction clip (see 024f)")
	dog.free()

func test_licensed_dog_if_present_resolves_a_real_sit() -> void:
	# Binds to the REAL imported licensed Labrador against Godot's ACTUAL clip names — the
	# guard that would have caught the importer renaming Sitting_loop_1 -> Sitting_1. The
	# asset is gitignored, so it's absent in public CI: skip cleanly there (the assert_true
	# keeps this from tripping the 0-assertion gate), and verify for real in local dev. (025)
	var p := "res://assets/models/dog_licensed.glb"
	if not ResourceLoader.exists(p):
		assert_true(true, "licensed dog absent (e.g. public CI) — skipped")
		return
	var packed := load(p) as PackedScene
	assert_true(packed != null, "the licensed dog glb must load as a PackedScene")
	if packed == null:
		return
	var dog := packed.instantiate()
	var ap := DogClips.find_animation_player(dog)
	assert_true(ap != null, "the licensed dog must have an AnimationPlayer")
	if ap != null:
		var c := DogClips.resolve(ap.get_animation_list())
		assert_true(c.has_sit(), "the licensed Labrador must resolve a real Sitt (start + hold loop)")
		assert_true(ap.has_animation(c.sit_start), "resolved sit_start must be a real clip on the dog")
		assert_true(ap.has_animation(c.sit_loop), "resolved sit_loop must be a real clip on the dog")
	dog.free()
