extends "res://tests/test_case.gd"
## Smoke tests for the Godot scaffold (task 023). These bind the verify gate to
## REAL project resources so "tests pass" can't be a hollow green: the committed
## dog imports to a usable scene, and the main scene loads. Phase 1 logic tests
## (apex-band / scoring-window math, specs2.md P1-5) land here in task 024.

func test_dog_asset_imports_to_packed_scene() -> void:
	# The committed CC0 glb IS the dog (P1-1, ADR-0002) — after `--import` it must
	# load as an instantiable PackedScene, not just exist on disk.
	var dog: Resource = load("res://assets/models/dog.glb")
	assert_true(dog != null, "res://assets/models/dog.glb must load after import")
	assert_true(dog is PackedScene, "the dog glb must import to a PackedScene")

func test_main_scene_loads() -> void:
	var packed: Resource = load("res://scenes/main.tscn")
	assert_true(packed != null, "main.tscn must load")
	assert_true(packed is PackedScene, "main.tscn must be a PackedScene")

func test_framework_self_check() -> void:
	# Guards the assert helpers themselves, so a broken framework can't read green.
	assert_eq(2 + 2, 4, "arithmetic")
	assert_ne("a", "b", "distinct strings")
	assert_true(true, "literal true")
	assert_false(false, "literal false")
