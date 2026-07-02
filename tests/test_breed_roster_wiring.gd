extends "res://tests/test_case.gd"
## Scene-level wiring for the collect-and-train loop (079, PO 2026-07-02 Change 3 / P3-1·D3·P3-4). The
## unit tests pin BreedRoster's invariants, TrickStore's roster blob, and TrickMenu's breed classify /
## hit-map / signals in isolation; these prove the RUNNING scene (a) boots owning + active the starter
## Labrador, (b) spends earned coins through the production CoinPurse to adopt the chocolate Lab and
## persists coins+roster atomically, (c) refuses an unaffordable adopt (no debt, breed not owned),
## (d) switches which owned breed is active and persists it, and (e) restores the roster on a fresh boot.
## Save is local user:// (IndexedDB on web) — X-7 offline. Hermetic: clear the shared save before/after.
##
## CC0-safe: the committed idle-only dog needs no trick to exercise the economy/roster spine — coins are
## driven directly onto the purse (dog-agnostic), exactly as test_coin_purse_wiring drives mastery.

const CHOC := "chocolate_labrador"

func _clear_save() -> void:
	if FileAccess.file_exists(TrickStore.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TrickStore.SAVE_PATH))

func test_fresh_player_owns_and_runs_the_starter_labrador() -> void:
	_clear_save()
	var main := instantiate_main()
	assert_true(main._roster.owns("labrador"), "a first-run player owns the starter Labrador")
	assert_false(main._roster.owns(CHOC), "the chocolate Lab is not owned until adopted")
	assert_eq(main._roster.active, "labrador", "the starter Labrador is the active breed on a fresh boot")
	assert_eq(main._breed.id, "labrador", "the running dog is the active (starter) breed")
	main.queue_free()
	_clear_save()

func test_adopt_spends_coins_adds_breed_and_persists() -> void:
	_clear_save()
	var a := instantiate_main()
	a._purse.balance = 100                      # earned coins (the earn path is proven in coin-purse wiring)
	a._on_breed_adopt(CHOC)
	assert_true(a._roster.owns(CHOC), "a funded adopt records ownership of the chocolate Lab")
	assert_eq(a._purse.balance, 100 - a.BREED_ADOPT_COST, "the adopt debits exactly the breed price")
	a.queue_free()
	# A fresh boot restores the adopted roster AND the debited balance from the one save blob.
	var b := instantiate_main()
	assert_true(b._roster.owns(CHOC), "the adopted breed survives a reload (persisted roster)")
	assert_eq(b._purse.balance, 100 - b.BREED_ADOPT_COST, "the debited balance survives the reload too")
	b.queue_free()
	_clear_save()

func test_unaffordable_adopt_is_a_noop() -> void:
	_clear_save()
	var main := instantiate_main()
	main._purse.balance = main.BREED_ADOPT_COST - 1   # one coin short
	main._on_breed_adopt(CHOC)
	assert_false(main._roster.owns(CHOC), "an unaffordable adopt never grants the breed")
	assert_eq(main._purse.balance, main.BREED_ADOPT_COST - 1, "an unaffordable adopt never debits (no debt)")
	main.queue_free()
	_clear_save()

func test_switch_active_breed_applies_and_persists() -> void:
	_clear_save()
	var a := instantiate_main()
	a._purse.balance = 100
	a._on_breed_adopt(CHOC)
	a._on_breed_chosen(CHOC)
	assert_eq(a._roster.active, CHOC, "choosing an owned breed makes it active")
	assert_eq(a._breed.id, CHOC, "the running dog switches to the chosen breed (coat + temperament)")
	a.queue_free()
	# The active breed persists: a fresh boot runs the chocolate Lab.
	var b := instantiate_main()
	assert_eq(b._roster.active, CHOC, "the active breed survives a reload")
	assert_eq(b._breed.id, CHOC, "a returning player boots straight into their chosen breed")
	b.queue_free()
	_clear_save()

func test_cannot_switch_to_an_unowned_breed() -> void:
	_clear_save()
	var main := instantiate_main()
	main._on_breed_chosen(CHOC)   # never adopted
	assert_eq(main._roster.active, "labrador", "an unowned breed can never be made active")
	assert_eq(main._breed.id, "labrador", "the running dog stays the owned starter breed")
	main.queue_free()
	_clear_save()
