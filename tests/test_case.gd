extends RefCounted
## Base class for Bra! headless tests (task 023 — the Godot verify gate).
##
## Subclass in res://tests/test_*.gd, write `test_*` methods, and assert via the
## helpers below. Failures are COLLECTED (not fatal) so a single run reports every
## failing assertion, not just the first. The runner (test_runner.gd) reads
## `failures` after each test method and fails the gate if any are present.

var failures: Array[String] = []

func assert_true(cond: bool, msg := "") -> void:
	if not cond:
		failures.append("expected true — %s" % msg)

func assert_false(cond: bool, msg := "") -> void:
	if cond:
		failures.append("expected false — %s" % msg)

func assert_eq(actual, expected, msg := "") -> void:
	if actual != expected:
		failures.append("expected %s == %s — %s" % [str(actual), str(expected), msg])

func assert_ne(actual, unexpected, msg := "") -> void:
	if actual == unexpected:
		failures.append("expected %s != %s — %s" % [str(actual), str(unexpected), msg])
