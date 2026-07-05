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

const Main := preload("res://scripts/main.gd")

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

# 2. The K-3/K-4 gate is exercised THROUGH the real decision seam main._can_adopt(owned, price,
#    balance) — the exact predicate _on_kennel_adopt() branches on — not merely described in comments.
#    A bug in that predicate (e.g. `<` vs `<=`, or dropping the price>0 guard) fails these.
func test_can_adopt_gate_blocks_unaffordable_and_allows_at_price() -> void:
	# Nova costs 900 (verified in test_kennel_dog.gd) — pin the boundary around her price.
	assert_eq(KennelDog.by_id("nova").price, 900, "sanity: Nova's price is 900 coins")
	assert_false(Main._can_adopt(false, 900, 200), "far under price → K-3 gate blocks the adopt")
	assert_false(Main._can_adopt(false, 900, 899), "one coin short → still blocked (boundary)")
	assert_true(Main._can_adopt(false, 900, 900), "exactly the price → adoptable (boundary)")
	assert_true(Main._can_adopt(false, 900, 1200), "over the price → adoptable")

func test_can_adopt_free_dog_bypasses_affordability() -> void:
	# A price-0 dog (Trulte, K-6) is adoptable at ANY balance, including 0 — the gate must not
	# swallow the free path.
	assert_true(Main._can_adopt(false, 0, 0), "free dog adopts at balance 0 (K-6 easter path)")
	assert_true(Main._can_adopt(false, 0, 500), "free dog adopts with coins in hand too")

func test_can_adopt_already_owned_is_a_noop() -> void:
	# An already-owned dog never re-adopts, regardless of balance (no double-spend).
	assert_false(Main._can_adopt(true, 500, 700), "already owned → no-op even when affordable")
	assert_false(Main._can_adopt(true, 0, 0), "already owned free dog → no-op")

# 2b. End-to-end no-op invariant: an unaffordable adopt leaves purse + roster untouched (the whole
#     point of the gate), driven by the same _can_adopt predicate the handler uses.
func test_unaffordable_adopt_leaves_state_untouched() -> void:
	var purse := CoinPurse.new()
	var roster = load("res://scripts/kennel_roster.gd").new()
	var nova := KennelDog.by_id("nova")
	purse.earn(200)
	if Main._can_adopt(roster.owns("nova"), nova.price, purse.balance):
		purse.spend(nova.price)
		roster.adopt("nova")
	assert_eq(purse.balance, 200, "balance unchanged — the gate blocked the adopt")
	assert_false(roster.owns("nova"), "Nova not owned — the gate blocked the adopt")

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

# 5. K-6 free-adopt (task 111): the secret dog's full path — she is flagged `secret`, priced 0,
#    always affordable, and adopting her leaves the balance untouched while marking her owned.
#    Mirrors main._on_kennel_adopt's `affordable` expression (is_owned or price == 0 or ...).
func test_free_adopt_costs_nothing_and_marks_owned() -> void:
	var purse := CoinPurse.new()
	var roster = _make_roster()
	var detail := KennelDog.detail_for("trulte")
	assert_true(detail.get("secret", false), "Trulte carries the secret flag — the K-6 easter egg")
	assert_eq(int(detail.get("price", -1)), 0, "Trulte's price is 0 (Gratis)")
	# The modal's affordability expression: owned OR price==0 OR balance>=price. At balance 0
	# a free dog is affordable purely on the price==0 branch — no coins required.
	var affordable: bool = roster.owns("trulte") or detail["price"] == 0 or purse.balance >= detail["price"]
	assert_true(affordable, "a price-0 secret dog is affordable even at balance 0 — the coral free-adopt path")
	# Adopt: spend(0) is a no-op deduction, roster marks her owned.
	assert_true(purse.spend(int(detail["price"])), "spend(0) succeeds for the free adopt")
	roster.adopt("trulte")
	assert_eq(purse.balance, 0, "balance is unchanged (0) after the free adopt — nothing was spent")
	assert_true(roster.owns("trulte"), "Trulte is owned after the free adopt")

# 6. K-6 double-fire guard (task 111): a second press mid-adopt is swallowed by the busy flag,
#    so the free dog is never adopted twice / the owned list never double-grows. Models main's
#    `_kennel_adopt_busy` re-entrancy guard around the spend+adopt.
func test_free_adopt_still_guarded_against_double_fire() -> void:
	var purse := CoinPurse.new()
	var roster = _make_roster()
	# `state` is a Dictionary (reference type) so the closure mutates the shared flag — GDScript
	# lambdas capture locals by VALUE, so a plain `var busy` wouldn't reflect changes.
	var state := {"busy": false}
	var adopt_once := func() -> bool:
		# The guarded body of _on_kennel_adopt for Trulte (price 0).
		if state["busy"]:
			return false
		if roster.owns("trulte"):
			return false
		state["busy"] = true
		purse.spend(0)
		roster.adopt("trulte")
		state["busy"] = false
		return true
	# A re-entrant press WHILE busy is swallowed. Simulate by setting busy before the call.
	state["busy"] = true
	assert_false(adopt_once.call(), "a press while busy is swallowed — no adopt")
	assert_false(roster.owns("trulte"), "no adopt happened during the busy window")
	state["busy"] = false
	# The real first press adopts once; an immediate second press is an owned-noop, not a re-adopt.
	assert_true(adopt_once.call(), "the first real press adopts Trulte")
	assert_true(roster.owns("trulte"), "Trulte is owned after the first press")
	var owned_before: int = (roster.owned as Array).size()
	assert_false(adopt_once.call(), "the second press is an owned-noop (already owned)")
	assert_eq((roster.owned as Array).size(), owned_before, "the owned list never double-grows for the free dog")

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
