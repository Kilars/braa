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

func test_reaction_prefers_a_joyful_bounce_over_a_lone_bark() -> void:
	# 034 / P1-6: on the licensed pack the only reaction-vocab leaf used to be `Bark`, so a
	# successful mark fired a lone bark (no read of joy). A joyful in-place hop must outrank
	# it. Uses the REAL licensed leaf names (Step 0): `Jump_Place_IP` is the complete in-place
	# bounce; `Bark` is the standing bark. The hop must win.
	var names := ["Arm_Labrador|Idle_1", "Arm_Labrador|Bark",
		"Arm_Labrador|Jump_Place_IP", "Arm_Labrador|Sitting_start", "Arm_Labrador|Sitting_1"]
	var c := DogClips.resolve(PackedStringArray(names))
	assert_eq(c.reaction, "Arm_Labrador|Jump_Place_IP", "the joyful hop outranks the lone Bark")
	assert_ne(c.reaction, "Arm_Labrador|Bark", "a successful mark is no longer a lone bark")
	assert_true(c.has_reaction(), "the licensed dog still has a reaction")

func test_cc0_generic_jump_is_never_a_reaction() -> void:
	# 034 / P1-6: the joyful terms ("jump_place"/"jumpair") must stay specific enough that the
	# CC0 placeholder's bare `Jump` is NOT mistaken for a celebration (else the 024f asset gate
	# breaks and the idle-only dog fakes a hop). A list whose only jump-ish leaf is a bare
	# `Jump` must resolve no reaction.
	var names := ["AnimalArmature|Idle", "AnimalArmature|Walk", "AnimalArmature|Jump"]
	var c := DogClips.resolve(PackedStringArray(names))
	assert_eq(c.reaction, "", "a bare generic Jump is not a joyful reaction")
	assert_false(c.has_reaction(), "the idle-only dog still can't react (asset gate holds)")

func test_walk_resolves_the_locomotion_clip() -> void:
	# 050 / P2-8 locomotion: the ambient wander rides a REAL walk clip (no faked gait). The
	# licensed Labrador ships `Walk_F_IP` — an IN-PLACE walk (root motion stripped), exactly
	# what we want since main drives the root translation itself and the clip just moves the legs.
	var c := DogClips.resolve(PackedStringArray(LAB))
	assert_eq(c.walk, "Arm_Labrador|Walk_F_IP", "the in-place walk clip resolves for locomotion")
	assert_true(c.has_walk(), "the Labrador can amble (has a walk clip)")

func test_cc0_also_has_a_walk_clip() -> void:
	# The CC0 fallback ships a plain `Walk` too, so the local verify/export build can still show
	# the dog roaming (the licensed dog isn't in public CI).
	var c := DogClips.resolve(PackedStringArray(CC0))
	assert_eq(c.walk, "AnimalArmature|Walk", "the CC0 dog's plain Walk resolves")
	assert_true(c.has_walk(), "even the CC0 fallback can amble")

func test_a_dog_with_no_walk_clip_cannot_amble() -> void:
	# Honest gate (mirrors has_sit / has_reaction): a dog with no walk clip resolves none, so
	# main skips the wander rather than faking a glide-while-standing (CLAUDE.md "no faked gait").
	var c := DogClips.resolve(PackedStringArray(
		["Arm|Idle_1", "Arm|Sitting_start", "Arm|Sitting_1"]))
	assert_eq(c.walk, "", "no walk clip resolves to nothing")
	assert_false(c.has_walk(), "a dog with no walk clip can't amble (skip, never fake)")

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
		# 034 / P1-6: the joyful reaction must resolve to the real in-place hop on the asset
		# (Step 0 confirmed `Jump_Place_IP` exists), NOT the lone Bark.
		assert_true(c.has_reaction(), "the licensed Labrador must resolve a positive reaction")
		assert_eq(c.reaction, "Arm_Labrador|Jump_Place_IP", "reaction is the joyful in-place hop, not Bark")
		assert_true(ap.has_animation(c.reaction), "resolved reaction must be a real clip on the dog")
	dog.free()
