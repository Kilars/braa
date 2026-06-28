extends SceneTree
## Headless test runner for Bra! (task 023 — replaces the bun/vitest gate).
##
## Run:  godot --headless --script res://tests/test_runner.gd
## Exits 0 when every test passes, 1 when any assertion fails. This is the unit
## leg of verify.sh and the per-story TDD loop for Phase 1 (task 024).
##
## Discovery: every res://tests/test_*.gd (this runner excepted) is loaded and
## instantiated, and each of its `test_*` methods runs on a FRESH instance (so
## tests don't leak state). Tests extend res://tests/test_case.gd and record
## failures through its assert_* helpers — no addon, no network dependency.

const TESTS_DIR := "res://tests"

func _initialize() -> void:
	var total := 0
	var failures: Array[String] = []

	for path in _discover():
		var script: GDScript = load(path)
		# A parse error makes load() return a NON-null but un-instantiable script;
		# without this guard the file is silently skipped and the gate reads a
		# hollow green. Treat un-loadable / un-parseable test files as failures.
		if script == null or not script.can_instantiate():
			failures.append("%s — failed to load/parse test script" % path)
			continue
		for method in script.get_script_method_list():
			var method_name: String = method.name
			if not method_name.begins_with("test_"):
				continue
			total += 1
			var test_case: Object = script.new()
			test_case.call(method_name)
			for failure in test_case.failures:
				failures.append("%s::%s — %s" % [path.get_file(), method_name, failure])
			# A test that recorded ZERO assertions either is empty or aborted on a
			# runtime SCRIPT ERROR before asserting — `call()` returns regardless, so
			# this is the only signal an abort even happened. Fail it, never hollow-pass. (026)
			if test_case.assertions == 0:
				failures.append("%s::%s — ran but made 0 assertions (empty test, or a runtime error aborted it before any assert)" % [path.get_file(), method_name])

	print("\n── Bra! test gate ─────────────────────────")
	print("  ran %d test(s), %d failure(s)" % [total, failures.size()])
	for failure in failures:
		print("  FAIL  %s" % failure)
	if failures.is_empty() and total > 0:
		print("  OK    all green")
	elif total == 0:
		failures.append("no tests discovered in %s" % TESTS_DIR)
		print("  FAIL  no tests discovered")
	print("───────────────────────────────────────────\n")

	quit(1 if failures.size() > 0 else 0)

func _discover() -> Array[String]:
	var found: Array[String] = []
	var dir := DirAccess.open(TESTS_DIR)
	if dir == null:
		push_error("[test] cannot open %s" % TESTS_DIR)
		return found
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if entry.begins_with("test_") and entry.ends_with(".gd") and entry != "test_runner.gd":
			found.append("%s/%s" % [TESTS_DIR, entry])
		entry = dir.get_next()
	dir.list_dir_end()
	found.sort()
	return found
