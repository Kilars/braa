class_name CoinPurse
extends RefCounted
## The coin economy core (068, Phase-3 P3-D3: "unlock breeds via a light economy"). A pure integer
## wallet — master a trick -> earn coins -> spend to adopt a breed. It is the ONE owner-decided
## Phase-3 story, and builds with no owner action (it depends on neither which breeds ship nor which
## tricks are signature). Like TrickProgress, the model owns its own shape (to_dict/restore) so the
## save store (TrickStore) stays dumb about the rules.
##
## Invariants: the balance is never negative, and a spend never goes into debt — an unaffordable
## spend is a no-op returning false. earn/spend/can_afford are the hooks main.gd (earn on mastery)
## and, later, the adopt/select UI (spend to adopt) drive; the adopt UI waits on the owner-gated
## extra breed models (BUST-068 residual), but the model is complete and unit-tested now.

var balance: int = 0

## Add coins. A non-positive amount is ignored so earning can never drain the purse (coins only
## ever leave through spend()).
func earn(amount: int) -> void:
	if amount > 0:
		balance += amount

## True iff the purse covers a non-negative cost. A negative cost is nonsense and never affordable.
func can_afford(cost: int) -> bool:
	return cost >= 0 and balance >= cost

## Spend coins if affordable; returns whether the purchase went through. An unaffordable spend is a
## no-op (no debt) — the caller checks the return before granting whatever was bought.
func spend(cost: int) -> bool:
	if not can_afford(cost):
		return false
	balance -= cost
	return true

## Model -> save entry (TrickStore stays dumb about the rules; the purse owns its shape).
func to_dict() -> Dictionary:
	return {"balance": balance}

## Restore from a saved entry. A missing / garbage / negative balance clamps to 0 so a corrupt save
## can never hand the player debt or free coins — it just starts them fresh.
func restore(d: Dictionary) -> void:
	balance = maxi(0, int(d.get("balance", 0)))
