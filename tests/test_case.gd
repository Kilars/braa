extends RefCounted
## Base class for Bra! headless tests (task 023 — the Godot verify gate).
##
## Subclass in res://tests/test_*.gd, write `test_*` methods, and assert via the
## helpers below. Failures are COLLECTED (not fatal) so a single run reports every
## failing assertion, not just the first. The runner (test_runner.gd) reads
## `failures` after each test method and fails the gate if any are present.

## The committed CC0 placeholder dog. Wiring tests pin this so a scene mount is
## deterministic whether or not the gitignored licensed Labrador is present locally
## (it changes the bounds/centre, and what a tap scores). (025)
const CC0_DOG := "res://assets/models/dog.glb"

## Mount the production main scene headlessly for a scene-level wiring test. `dog` pins
## which model loads (default CC0, per above). `reduced`: -1 leaves the scene's own
## reduced-motion resolution; 0/1 forces the prefers-reduced-motion seam.
##
## The headless test runner quits inside _initialize() before any process frame, so
## Godot defers _ready and the scene never builds itself — we invoke the real _ready
## path explicitly so tests assert against the *production* wiring, not a stub. (026)
func instantiate_main(dog := CC0_DOG, reduced := -1) -> Node:
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	main.dog_path_override = dog
	if reduced != -1:
		main.reduced_motion_override = reduced
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(main)
	if not main.is_node_ready():
		main._ready()
	return main

var failures: Array[String] = []

## Count of assertions actually executed in the current test method. The runner
## (test_runner.gd) treats a test_* method that finishes with ZERO assertions as a
## FAILURE — that means either an empty test or, more importantly, a method that
## **aborted on a runtime SCRIPT ERROR before reaching its asserts** (a GDScript
## runtime error stops the method but `call()` returns to the runner, so an abort
## is otherwise invisible and reads as a hollow green). Every assert bumps this. (026)
var assertions := 0

func assert_true(cond: bool, msg := "") -> void:
	assertions += 1
	if not cond:
		failures.append("expected true — %s" % msg)

func assert_false(cond: bool, msg := "") -> void:
	assertions += 1
	if cond:
		failures.append("expected false — %s" % msg)

func assert_eq(actual, expected, msg := "") -> void:
	assertions += 1
	if actual != expected:
		failures.append("expected %s == %s — %s" % [str(actual), str(expected), msg])

func assert_ne(actual, unexpected, msg := "") -> void:
	assertions += 1
	if actual == unexpected:
		failures.append("expected %s != %s — %s" % [str(actual), str(unexpected), msg])
