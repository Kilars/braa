extends "res://tests/test_case.gd"
## TDD for the coin economy core (068, Phase-3 P3-D3 "unlock breeds via a light economy").
## CoinPurse is a pure integer wallet: master a trick -> earn coins -> spend to adopt a breed.
## The model owns its own shape (to_dict/restore) so the save store (TrickStore) stays dumb about
## the rules, exactly like TrickProgress. Balance is never negative and a spend never goes into
## debt: an unaffordable spend is a no-op. These are the earn + adopt hooks the UI will drive once
## breed models land (BUST-068 residual); the model is complete and tested now.

# 1. A fresh purse starts empty.
func test_starts_empty() -> void:
	var purse := CoinPurse.new()
	assert_eq(purse.balance, 0, "a fresh purse holds no coins")

# 2. earn adds coins; a non-positive earn is ignored (no negative / zero earn).
func test_earn_adds_and_ignores_non_positive() -> void:
	var purse := CoinPurse.new()
	purse.earn(10)
	assert_eq(purse.balance, 10, "earn(10) adds 10 coins")
	purse.earn(5)
	assert_eq(purse.balance, 15, "earn accumulates")
	purse.earn(0)
	purse.earn(-3)
	assert_eq(purse.balance, 15, "a zero or negative earn is ignored — coins can't be drained by earn")

# 3. can_afford is true iff the balance covers a non-negative cost.
func test_can_afford() -> void:
	var purse := CoinPurse.new()
	purse.earn(20)
	assert_true(purse.can_afford(20), "can afford exactly the balance")
	assert_true(purse.can_afford(0), "can always afford a free thing")
	assert_false(purse.can_afford(21), "cannot afford above the balance")
	assert_false(purse.can_afford(-1), "a negative cost is never affordable (nonsense guard)")

# 4. spend deducts only when affordable; an unaffordable spend is a no-op, never debt.
func test_spend_only_when_affordable_never_debt() -> void:
	var purse := CoinPurse.new()
	purse.earn(30)
	assert_true(purse.spend(12), "an affordable spend returns true")
	assert_eq(purse.balance, 18, "an affordable spend deducts the cost")
	assert_false(purse.spend(100), "an unaffordable spend returns false")
	assert_eq(purse.balance, 18, "an unaffordable spend is a no-op — the balance never goes negative")

# 5. Round-trip; a garbage / negative saved balance clamps to >= 0.
func test_round_trip_and_clamp_on_restore() -> void:
	var purse := CoinPurse.new()
	purse.earn(42)
	var fresh := CoinPurse.new()
	fresh.restore(purse.to_dict())
	assert_eq(fresh.balance, 42, "balance survives to_dict -> restore")
	var salvaged := CoinPurse.new()
	salvaged.restore({"balance": -7})
	assert_eq(salvaged.balance, 0, "a negative saved balance is clamped to 0 on restore (no debt from a bad save)")
	var defaulted := CoinPurse.new()
	defaulted.restore({})
	assert_eq(defaulted.balance, 0, "a missing balance key restores to 0")
