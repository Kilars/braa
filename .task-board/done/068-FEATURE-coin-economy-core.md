# FEATURE: 068 — The coin economy core: master a trick → earn coins (P3-D3)

**Status**: Backlog
**Created**: 2026-07-01
**Type**: FEATURE (economy logic — **test-first / TDD**; a minimal coin readout is the only
render glue, no full Visual Review — the adopt/select UI it feeds waits on breed models)
**Priority**: High — the **one owner-decided** Phase-3 story (P3-D3 is ✅ DECIDED: "unlock breeds
via a light economy"), and the strongest slice that builds with **no** owner action: it depends
on neither which breeds ship (P3-D1) nor which tricks are signature (P3-D2).
**Labels**: phase-3, logic, economy, coins, persistence, offline, tdd, p3-d3
**Estimated Effort**: Small–Medium (one focused session)
**Source / gate**: routed from **BUST-068** (`.task-board/FLAGS.md`) — Phase 3 was asserted
"owner-gated on breed assets," but the manifest bust found only the breed *models* are gated; the
decided **light economy** builds now.

## What it addresses (spec gap)

`.docs/specs/phase3.md` **P3-D3 — How breeds are acquired** is **DECIDED** (owner): breeds
**unlock via a light economy** — "master tricks → earn coins … spend to adopt a breed. Keep it
light." Nothing of that economy exists yet: `grep` finds no coin / currency / purse code. The
mastery signal it hooks onto already exists — `TrickProgress.just_mastered(delta)` is a one-shot
that fires on the tap that FIRST reaches mastery (and, being a safe-checkpoint latch, never fires
again → no coin farming), and `TrickStore` already persists player state to `user://` (offline,
X-7). This task builds the **earning + balance + persistence** core; the **adopt/select UI**
(coin price + locked state + breed thumbnail, PO-Improvement-4) is deferred — it needs the
owner-gated extra breed models (BUST-068 residual), so it can't ship honestly yet.

## Technical approach

Pure model + persistence, mirroring the 045/049 pattern (a unit-testable RefCounted model that
owns its own shape; the store stays dumb). Wire the earn hook into the existing mastery path.

### 1. New class `CoinPurse` (TDD — failing tests first)

`scripts/coin_purse.gd`, `class_name CoinPurse extends RefCounted`. Pure integer economy:
- `balance: int` (starts 0, never negative).
- `earn(amount: int) -> void` — add coins; ignores `amount <= 0` (no negative earn).
- `can_afford(cost: int) -> bool` — `cost >= 0 and balance >= cost`.
- `spend(cost: int) -> bool` — spend only if affordable, returns success; **never goes into
  debt** (an unaffordable spend is a no-op returning false). This is the adopt hook the UI will
  call once breed models land.
- `to_dict()` / `restore(d)` — model owns its shape (like `TrickProgress`), so the store stays
  dumb. `restore` clamps a garbage/negative saved balance to `>= 0`.

### 2. `TrickStore` — carry coins alongside the trick map (backward-compatible)

The one player save file should restore tricks **and** coins atomically. Extend `TrickStore`
without breaking the 049 contract (all existing callers/tests pass just a tricks map):
- `encode(tricks, coins := 0)` → `{version, tricks, coins}` (defaulted param — existing callers
  unchanged; `decode(text)` still returns the tricks map exactly as before).
- `save(tricks, coins := 0)`.
- add `decode_coins(text) -> int` / `load_coins() -> int` — corrupt/empty/wrong-version → 0.

### 3. `main.gd` — earn on mastery, persist, show a coin count

- `var _purse := CoinPurse.new()`; `const COIN_REWARD_MASTERY := 10` (light — 3 tricks = 30).
- `_load_coins()` in `_ready` (restore balance before the HUD builds); a returning player's
  coins survive a reload just like their learned bar.
- In `_apply_progress`, at the existing `_progress.just_mastered(delta)` branch: `_purse.earn(
  COIN_REWARD_MASTERY)` and refresh the coin readout. (Restored mastery on boot does NOT re-fire
  `just_mastered`, and the balance is restored from disk → mastery is rewarded exactly once.)
- `_save_progress` also saves coins: `_store.save(out, _purse.balance)`.
- `_setup_coin_readout(ui)` — a small unobtrusive coin count label in the HUD so earning is
  observable (not an invisible logic seam). Additive; does not disturb the PO-signed Phase-2 look.

## TDD — behaviors to test first

`tests/test_coin_purse.gd` (new), extend `tests/test_trick_store.gd`, + a wiring test:

1. **Starts empty** — a fresh `CoinPurse.balance == 0`.
2. **Earn adds; non-positive ignored** — `earn(10)` → 10; `earn(0)`/`earn(-5)` → unchanged.
3. **can_afford** — true iff `balance >= cost` and `cost >= 0`.
4. **spend** — affordable spend deducts and returns true; unaffordable spend is a no-op returning
   false (never negative).
5. **Round-trip** — `restore(to_dict())` preserves balance; `restore` clamps a negative/garbage
   balance to `>= 0`.
6. **TrickStore coins** — `decode_coins(encode(map, 42)) == 42`; a coins-less (049-era) blob and a
   corrupt/wrong-version blob → `decode_coins` returns 0; `decode(text)` still returns the tricks
   map unchanged (049 contract intact). Disk round-trip: `save(map, 7)` then `load_coins() == 7`.
7. **Wiring (scene-level)** — mastering a trick awards `COIN_REWARD_MASTERY`; a fresh boot restores
   the saved balance (not re-awarded); re-practice after mastery awards no further coins.

## Acceptance criteria

- [ ] **Red first:** `tests/test_coin_purse.gd` written and failing before `coin_purse.gd` exists.
- [ ] `scripts/coin_purse.gd`: `earn`/`can_afford`/`spend`/`to_dict`/`restore`; balance never
  negative, no debt; behaviors 1–5 green.
- [ ] `TrickStore` carries coins backward-compatibly (behavior 6); **all existing 049 TrickStore
  tests stay green**.
- [ ] `main.gd` earns `COIN_REWARD_MASTERY` once per trick mastered, restores balance on boot,
  persists after every change; coin readout reflects the balance. Proven by the wiring test (7).
- [ ] **No coin farming / no double-award:** mastery's safe-checkpoint latch means `just_mastered`
  fires once; a reload restores the balance rather than re-earning (behavior 7).
- [ ] **X-7 honored:** coins persist locally (`user://` / IndexedDB), no backend/account/network.
- [ ] `spend`/`can_afford` are the adopt hook — noted as awaiting the adopt UI (owner-gated extra
  breed models, BUST-068 residual); covered by tests, not a dead/faked seam.
- [ ] **Placeholder check** clean on the diff.
- [ ] `nix develop -c bash verify.sh` green (import · boot · test · export).

## Results (done 2026-07-01)

Built exactly to the plan, test-first. The economy core — earn on mastery, a persistent balance,
and the spend/afford model for the future adopt UI — is complete; the adopt UI itself is deferred
(owner-gated extra breed models, BUST-068 residual).

- **`scripts/coin_purse.gd`** (new, `class_name CoinPurse extends RefCounted`): pure integer wallet.
  `earn(n)` (ignores `n <= 0`), `can_afford(cost)`, `spend(cost) -> bool` (no-op + false when
  unaffordable — never debt), `to_dict()`/`restore()` (clamps a garbage/negative saved balance to
  `>= 0`). The model owns its shape so `TrickStore` stays dumb, mirroring `TrickProgress`.
- **`scripts/trick_store.gd`**: coins now ride the SAME save blob as the trick map, backward-
  compatibly — `encode(tricks, coins := 0)` → `{version, tricks, coins}` (defaulted param → every
  049-era caller unchanged; `decode(text)` still returns exactly the tricks map). Added
  `decode_coins(text)` / `load_coins()` (coins-less legacy / corrupt / empty / wrong-version /
  negative → 0). All existing 049 TrickStore tests stay green.
- **`scripts/main.gd`**: `_purse := CoinPurse.new()` + named `COIN_REWARD_MASTERY := 10`;
  `_load_coins()` runs in `_ready` (before the HUD builds) so a returning player sees their coins;
  `_apply_progress` earns `COIN_REWARD_MASTERY` at the existing `just_mastered(delta)` one-shot and
  refreshes the readout; `_save_progress` now persists coins too (`_store.save(out, _purse.balance)`).
  New `_setup_coin_readout()` mounts a small coin-gold, dark-outlined, mouse-transparent balance
  label in the top-right corner (clear of the selector chips + learned bar), so earning is observable
  without disturbing the PO-signed Phase-2 top-band stack.
- **No coin farming / no double-award:** mastery's safe-checkpoint latch means `just_mastered` fires
  once per trick; a reload restores the balance from disk rather than re-earning (wiring test proves
  re-practice after mastery and a fresh boot both leave the balance unchanged).
- **Tests:** `tests/test_coin_purse.gd` (empty start, earn/ignore-non-positive, can_afford, spend
  no-debt, round-trip + clamp), `tests/test_coin_purse_wiring.gd` (fresh player = 0 coins; mastering
  through the production `_apply_progress` path awards once; earned coins survive a reload and are not
  re-awarded), + 3 cases in `tests/test_trick_store.gd` (coins round-trip alongside tricks; legacy/
  corrupt/wrong-version → 0 coins with the tricks contract intact; disk round-trip carries coins).
  Wiring tests are hermetic (clear the shared `user://` save before/after).
- **X-7 honored:** coins persist locally (`user://` / IndexedDB on web) — no backend, account, or
  network. `spend`/`can_afford` are the adopt hook, unit-covered and ready for the adopt UI when the
  owner supplies extra breed models — not a dead/faked seam (a purse without a spend API would be the
  incomplete thing; the model is cohesive and fully tested).

**Acceptance:** all criteria met. `nix develop -c bash verify.sh` → `✓ verify gate green`
(import · boot · test · export); **284 tests, 0 failures**. Placeholder check clean (the lone
"later" hit is the forward-reference comment naming the owner-gated adopt UI — allowlisted, an open
flag names it — not a stub). The `Parse JSON failed` lines in the test leg are the intended
negative-path assertions (garbage/empty fed to `decode`/`decode_coins`, which return `{}`/`0`) — the
same benign pattern the pre-existing corrupt-save tests already emit; the gate is green.
