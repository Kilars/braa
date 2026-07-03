extends "res://tests/test_case.gd"
## Scene-level wiring for ADR-0007 telemetry call-sites (084, X-8 / Phase-3 Instrumentation).
##
## This proves that each of the four Phase-3 telemetry events fires with the correct event name
## and properties when the corresponding game action occurs:
##   - session_start on boot
##   - bra_tapped at each mark (with trick, bucket, latency, attempt_number)
##   - trick_mastered when a trick reaches 100% learned (with trick)
##   - breed_adopted on a successful spend (with breed)
##   - session_end on app pause (with last_trick, attempts, best_progress, mastered_count)
##
## The Telemetry node is a recording sink: captured events (before the enabled/tree guards)
## are stored in `_telemetry.captured` even while telemetry is disabled in tests, so the
## wiring tests assert the event shape + props with no network. (ADR-0007, X-8)
##
## Hermetic: any test that drives mastery (which calls _save_progress) clears the shared
## save file before and after — the same pattern as test_coin_purse_wiring.gd — so later
## tests (e.g. test_trainer_wiring) don't load stale mastered state off disk.

## Remove the shared save file (same guard as test_coin_purse_wiring). Called around any
## test that drives progress to mastery so mastered state does not leak into later tests.
func _clear_save() -> void:
	if FileAccess.file_exists(TrickStore.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TrickStore.SAVE_PATH))


# ===== Pure (no scene) tests for SitWindow and SitSession helper APIs =====

func test_bucket_perfect() -> void:
	## SitWindow.bucket converts Tier.PERFECT to the "perfect" bucket string.
	assert_eq(SitWindow.bucket(SitWindow.Tier.PERFECT, 0.0), "perfect")


func test_bucket_ok_is_good() -> void:
	## SitWindow.bucket converts Tier.OK to the "good" bucket string.
	assert_eq(SitWindow.bucket(SitWindow.Tier.OK, 0.0), "good")


func test_bucket_miss_before_apex_is_early() -> void:
	## SitWindow.bucket converts Tier.MISS with signed_offset < 0.0 to "early".
	assert_eq(SitWindow.bucket(SitWindow.Tier.MISS, -0.3), "early")


func test_bucket_miss_after_apex_is_late() -> void:
	## SitWindow.bucket converts Tier.MISS with signed_offset >= 0.0 to "late".
	assert_eq(SitWindow.bucket(SitWindow.Tier.MISS, 0.3), "late")


func test_bucket_dead_is_miss() -> void:
	## SitWindow.bucket converts Tier.DEAD (and any default) to "miss".
	assert_eq(SitWindow.bucket(SitWindow.Tier.DEAD, 0.0), "miss")


func test_apex_offset_zero_when_no_sit_open() -> void:
	## SitSession.apex_offset returns 0.0 when no sit window is open.
	var s := SitSession.new()
	assert_eq(s.apex_offset(), 0.0, "no open window → apex_offset is 0.0")


func test_apex_offset_is_signed_seconds_from_apex() -> void:
	## SitSession.apex_offset returns (_elapsed - _window.apex) when a sit window is open.
	## A window with apex at 1.0 s, and the clock advanced to 1.25 s, should yield 0.25 s offset.
	var w := SitWindow.new(1.0, 0.15, 0.4, 0.0, 3.0)
	var s := SitSession.new()
	s.open(w)
	s.advance(1.25)
	assert_true(
		absf(s.apex_offset() - 0.25) < 0.001,
		"apex_offset = elapsed (1.25) - apex (1.0) ≈ 0.25, within 0.001 s tolerance"
	)


# ===== Wiring tests (scene-based, using instantiate_main) =====

func test_boot_emits_session_start() -> void:
	## Boot emits 'session_start' with 'platform' and 'viewport' props.
	var main := instantiate_main()
	var e: Dictionary = main._telemetry.last("session_start")
	assert_false(e.is_empty(), "boot emits session_start event")
	assert_true(e["props"].has("platform"), "session_start includes 'platform' prop")
	assert_true(e["props"].has("viewport"), "session_start includes 'viewport' prop")
	main.queue_free()


func test_bra_tap_emits_bra_tapped() -> void:
	## A BRA tap emits 'bra_tapped' with props: trick, bucket, latency_ms_from_apex, attempt_number.
	var main := instantiate_main()
	main._on_bra_pressed()
	var e: Dictionary = main._telemetry.last("bra_tapped")
	assert_false(e.is_empty(), "bra_tapped event emitted on tap")
	assert_eq(e["props"]["trick"], main._current_trick, "bra_tapped.trick matches main._current_trick")
	assert_true(e["props"].has("bucket"), "bra_tapped includes 'bucket' prop")
	assert_true(e["props"].has("latency_ms_from_apex"), "bra_tapped includes 'latency_ms_from_apex' prop")
	assert_eq(e["props"]["attempt_number"], 1, "first accepted tap is attempt_number 1")
	main.queue_free()


func test_mastery_emits_trick_mastered() -> void:
	## Reaching trick mastery emits 'trick_mastered' with the trick prop.
	## Hermetic: clears the shared save before/after so mastered state does not leak into
	## later tests (e.g. test_trainer_wiring's live-sit test reads teach_strength which is
	## 0 at mastery, leaving the trainer ring dark).
	_clear_save()
	var main := instantiate_main()
	# Drive to mastery by applying PERFECT tiers directly until mastered.
	for i in range(60):
		main._apply_progress(SitWindow.Tier.PERFECT)
		if main._progress.mastered:
			break
	assert_true(main._progress.mastered, "reached mastery via repeated PERFECT tiers")
	var e: Dictionary = main._telemetry.last("trick_mastered")
	assert_false(e.is_empty(), "trick_mastered event emitted on mastery")
	assert_eq(e["props"]["trick"], main._current_trick, "trick_mastered.trick matches the mastered trick")
	main.queue_free()
	_clear_save()


func test_breed_adopt_emits_breed_adopted() -> void:
	## A successful breed adoption emits 'breed_adopted' with the breed prop.
	## Hermetic: clears the shared save before/after so the adopted roster does not persist
	## into later tests.
	_clear_save()
	var main := instantiate_main()
	# Earn enough coins to afford the adoption (breed cost is 30, each reward is 10).
	main._purse.earn(100)
	main._on_breed_adopt("chocolate_labrador")
	var e: Dictionary = main._telemetry.last("breed_adopted")
	assert_false(e.is_empty(), "breed_adopted event emitted on successful adopt")
	assert_eq(e["props"]["breed"], "chocolate_labrador", "breed_adopted.breed matches adopted breed id")
	main.queue_free()
	_clear_save()


func test_session_end_on_pause() -> void:
	## App pause emits 'session_end' with last_trick, attempts, best_progress, mastered_count.
	var main := instantiate_main()
	main._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	var e: Dictionary = main._telemetry.last("session_end")
	assert_false(e.is_empty(), "session_end event emitted on app pause")
	assert_true(e["props"].has("last_trick"), "session_end includes 'last_trick' prop")
	assert_true(e["props"].has("attempts"), "session_end includes 'attempts' prop")
	assert_true(e["props"].has("best_progress"), "session_end includes 'best_progress' prop")
	assert_true(e["props"].has("mastered_count"), "session_end includes 'mastered_count' prop")
	main.queue_free()
