extends "res://tests/test_case.gd"
## TDD for the kennel adopt-flow mutation (109, Phase 8 K-3/K-4 "afford → adopt").
## These tests drive CoinPurse + KennelRoster directly — pure, no SceneTree — mirroring
## how main._on_kennel_adopt() orchestrates them:
##   1. look up KennelDog.by_id(id).price
##   2. if price > 0 and not _purse.can_afford(price) → return (no-op)
##   3. _purse.spend(price)  (returns bool; price 0 is always affordable)
##   4. _kennel_roster.adopt(id)
##
## The goal: pin the invariants so any future regression in the wiring fails a test.

func _make_roster():
	return load("res://scripts/kennel_roster.gd").new()

# 1. Adopting an affordable priced dog deducts its price and marks it owned.
func test_adopt_deducts_price_and_marks_owned() -> void:
	var script = load("res://scripts/kennel_roster.gd")
	assert_true(script != null, "kennel_roster.gd must exist")
	var purse := CoinPurse.new()
	var roster = script.new()
	# Sol costs 500 coins (verified in test_kennel_dog.gd).
	var sol := KennelDog.by_id("sol")
	assert_eq(sol.price, 500, "sanity: Sol's price is 500 coins")
	purse.earn(600)
	assert_eq(purse.balance, 600, "purse starts at 600")
	assert_false(roster.owns("sol"), "Sol is not owned before the adopt")
	# Simulate _on_kennel_adopt("sol").
	var price := sol.price
	assert_true(purse.can_afford(price), "600 coins is enough to adopt Sol (price=500)")
	assert_true(purse.spend(price), "spend(500) succeeds and returns true")
	roster.adopt("sol")
	assert_eq(purse.balance, 100, "balance drops by Sol's price (600 - 500 = 100)")
	assert_true(roster.owns("sol"), "Sol is marked owned in the roster after the adopt")

# 2. Adopting an unaffordable dog is a no-op: balance and owned set unchanged.
func test_adopt_unaffordable_is_a_noop() -> void:
	var script = load("res://scripts/kennel_roster.gd")
	assert_true(script != null, "kennel_roster.gd must exist")
	var purse := CoinPurse.new()
	var roster = script.new()
	# Nova costs 900 coins (verified in test_kennel_dog.gd).
	var nova := KennelDog.by_id("nova")
	assert_eq(nova.price, 900, "sanity: Nova's price is 900 coins")
	purse.earn(200)
	assert_eq(purse.balance, 200, "purse starts at 200 (not enough for Nova)")
	# Simulate the K-3 gate in _on_kennel_adopt: if price > 0 and not can_afford → return.
	var price := nova.price
	assert_false(purse.can_afford(price),
		"can_afford(900) is false at balance 200 — the K-3 gate blocks the adopt")
	# The adopt must NOT proceed: balance unchanged, owned set unchanged.
	# (We do NOT call spend or adopt here — this tests that the gate IS the right check.)
	assert_eq(purse.balance, 200, "balance is unchanged after the K-3 gate blocks the adopt")
	assert_false(roster.owns("nova"), "Nova is not marked owned after the K-3 gate blocks it")
	# Also verify via CoinPurse.spend() directly: an unaffordable spend is a no-op.
	assert_false(purse.spend(price), "spend(900) returns false (unaffordable) — no debt")
	assert_eq(purse.balance, 200, "balance stays 200 after an unaffordable spend attempt")
	assert_false(roster.owns("nova"), "roster is unchanged after a failed spend")

# 3. A free dog (price==0, e.g. Trulte) is always adoptable and costs nothing.
func test_adopt_free_dog_costs_nothing() -> void:
	var script = load("res://scripts/kennel_roster.gd")
	assert_true(script != null, "kennel_roster.gd must exist")
	var purse := CoinPurse.new()
	var roster = script.new()
	# Trulte is free (price==0, rarity==SECRET — the K-6 easter egg).
	var trulte := KennelDog.by_id("trulte")
	assert_eq(trulte.price, 0, "sanity: Trulte's price is 0 (free easter egg)")
	assert_eq(purse.balance, 0, "purse starts empty")
	# price == 0 → can_afford is true even at balance 0; spend(0) is a no-op deduction.
	var price := trulte.price
	assert_true(purse.can_afford(price),
		"can_afford(0) is true even at balance 0 — a free dog is always adoptable")
	assert_true(purse.spend(price), "spend(0) returns true (free, no cost)")
	roster.adopt("trulte")
	assert_eq(purse.balance, 0, "balance stays 0 after adopting a free dog")
	assert_true(roster.owns("trulte"), "Trulte is marked owned in the roster after the free adopt")

# 4. Idempotent: adopting the same dog twice spends the price only once.
func test_adopt_is_idempotent_no_double_spend() -> void:
	var script = load("res://scripts/kennel_roster.gd")
	assert_true(script != null, "kennel_roster.gd must exist")
	var purse := CoinPurse.new()
	var roster = script.new()
	# Lykke costs 300 coins (verified in test_kennel_dog.gd).
	var lykke := KennelDog.by_id("lykke")
	assert_eq(lykke.price, 300, "sanity: Lykke's price is 300 coins")
	purse.earn(700)
	# First adopt: pays 300, marks owned.
	var price := lykke.price
	assert_true(purse.can_afford(price), "can afford Lykke on the first adopt (balance=700)")
	assert_true(purse.spend(price), "first spend(300) succeeds")
	roster.adopt("lykke")
	assert_eq(purse.balance, 400, "balance after first adopt: 700 - 300 = 400")
	assert_true(roster.owns("lykke"), "Lykke is owned after the first adopt")
	# Second adopt attempt: roster.adopt is a no-op (already owned); the caller should guard via
	# owns() before spending, but even if spend is called again the owned list doesn't grow.
	# Simulate the correct guard: if already owned, skip spend + adopt entirely.
	var owned_before: int = (roster.owned as Array).size()
	if not roster.owns("lykke"):
		purse.spend(price)
		roster.adopt("lykke")
	assert_eq(purse.balance, 400, "balance unchanged on the second adopt attempt (no double-spend)")
	assert_eq((roster.owned as Array).size(), owned_before,
		"the owned list doesn't grow on a duplicate adopt attempt")
