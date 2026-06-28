extends RefCounted
## Base class for Bra! headless tests (task 023 — the Godot verify gate).
##
## Subclass in res://tests/test_*.gd, write `test_*` methods, and assert via the
## helpers below. Failures are COLLECTED (not fatal) so a single run reports every
## failing assertion, not just the first. The runner (test_runner.gd) reads
## `failures` after each test method and fails the gate if any are present.

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
