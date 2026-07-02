# 079 — FEATURE: wire the collect-and-train loop — adopt (spend coins) + persisted owned-breeds roster + switch active breed

**Type:** FEATURE (game-logic TDD + Visual Review) · **Phase:** 3 (current) · **Source:** PO Review
2026-07-02 `po-review.md` **Change 3** ("The collection loop is disconnected — Phase 3's whole point
isn't playable yet (P3-1 / P3-D3 / P3-4) … earned coins buy nothing and the two dogs never meet in
the running game") · **Priority:** P3 for this phase — the phase's *point*, but gated behind the
core-loop payoff bug (077) and the world-cohesion pass (078) in priority order.

## What it addresses

The pieces exist but are disconnected:
- Coins accrue and persist (`CoinPurse` + `TrickStore` save schema — 068).
- A real 2nd breed exists with **no owner asset** — the chocolate Lab (076), reachable **only** via
  the `?bra_breed=chocolate` debug URL (`_query_breed`, `scripts/main.gd:337`).
- But the save persists **no owned-breeds roster**, there is **no in-game way to adopt or select** a
  breed, so earned coins buy nothing and the two dogs never meet in the running game.

Good (PO, buildable now, no owner model — the pieces already exist): wire a **minimal adopt + select
spine** — spend earned coins to **adopt the already-built chocolate Lab**, persist an **owned-breeds
roster** alongside the coins, and let the player **switch which owned breed is active**, persisted
across sessions. That turns the disconnected economy + 2nd breed + menu into the actual
collect-and-train loop.

**Explicitly out of scope (stays owner-gated — do NOT fake):** the spotlit select-screen *polish*
(P3-1 appearance / P3-4 showcase visuals beyond basic legibility) and any *additional* breed models
(Border Collie / French Bulldog / Husky — P3-D1 / D2). Keep those as flags, not this task. This is the
functional spine; render it with the two real breeds we have (yellow + chocolate Lab).

## Technical approach

Reuse the existing seams — this is spine wiring, not new architecture.

### 1. Persisted owned-breeds roster (TDD, pure — `scripts/trick_store.gd` + a small roster model)

Extend the ONE save blob (do not add a second save file). `TrickStore.encode/decode` already ride
`tricks` + `coins` in one JSON; add an `owned` breeds list (+ the `active` breed id) the same way.

**Before** (`scripts/trick_store.gd`):
```gdscript
static func encode(tricks: Dictionary, coins: int = 0) -> String:
	return JSON.stringify({"version": SCHEMA_VERSION, "tricks": tricks, "coins": coins})
```
**After** — roster rides the same blob (default = just the starter Labrador owned + active), so every
legacy save decodes to "owns the Labrador" and never crashes:
```gdscript
static func encode(tricks: Dictionary, coins: int = 0, roster: Dictionary = {}) -> String:
	return JSON.stringify({"version": SCHEMA_VERSION, "tricks": tricks, "coins": coins,
		"roster": roster})   # roster = {"owned": ["labrador"], "active": "labrador"}
```
Add `decode_roster(text) -> Dictionary` mirroring `decode_coins`: a missing/corrupt/legacy roster
degrades to `{"owned": ["labrador"], "active": "labrador"}` (the starter breed is always owned) — a
broken save never strands the player with no dog. Introduce a small pure **`BreedRoster`** model
(like `CoinPurse`): `owned` set + `active` id, with `adopt(id)`, `owns(id)`, `set_active(id)`
(only among owned), `to_dict()/restore()`. Breed ids are the existing `BreedPersonality` keys
(`labrador`, `chocolate`).

TDD (RED first, `tests/test_trick_store.gd` + new `tests/test_breed_roster.gd`):
- `test_roster_rides_the_same_save_blob` — encode→decode round-trips owned + active alongside coins
  and tricks.
- `test_legacy_save_defaults_to_starter_owned` — a coins/tricks-only (pre-079) blob decodes to
  owning + active = the Labrador (never empty).
- `test_adopt_adds_to_owned` / `test_set_active_only_among_owned` / `test_restore_clamps_garbage` —
  the `BreedRoster` invariants (can't activate an unowned breed; corrupt restore → starter only).

### 2. Adopt = spend coins (TDD — reuse `CoinPurse.spend`)

Adopting the chocolate Lab spends a fixed price via the existing `CoinPurse.spend(cost)` (already
no-debt, no-op-if-unaffordable). Home the price in a named constant. On a successful spend, the
roster `adopt("chocolate")`; an unaffordable adopt is a no-op (button stays in the locked/priced
state). Persist coins + roster atomically (same `_save_progress` path that already saves coins).

TDD:
- `test_adopt_spends_coins_and_adds_breed` — enough coins → spend succeeds, chocolate now owned,
  balance debited by the price.
- `test_adopt_unaffordable_is_noop` — too few coins → no spend, chocolate NOT owned, balance
  unchanged.

### 3. Adopt + select surface (Visual Review — extend the existing `TrickMenu`)

The completion menu (`scripts/trick_menu.gd`, 072) is the natural home — it already pops on mastery
and shows learned/available/locked tricks + coins + a reopen button. Add a small **breeds** section:
each owned breed selectable (tap → set active, persisted, dog re-tints on next load/switch); the
chocolate Lab shown with its **coin price + a clear locked state** until adopted (P3-D3 acceptance:
"adopt UI shows the coin price + a clear locked state + a breed thumbnail"). Switching the active
breed applies the existing `CoatTint` / `BreedPersonality` for that breed (076/075) so the running
game shows the chosen dog with its coat + temperament, persisted across sessions.

Keep it minimal and legible at 390×844 — this is the functional spine, not the showcase polish. Use
the two real breeds (yellow + chocolate Lab); a "thumbnail" can be an honest small render/tint swatch
of the real coat, **not** a faked breed image. Retire the `?bra_breed=` debug URL as the only path
(keep it as a dev seam, but the in-game select must work without it).

### Visual Review (blocking)

Spawn a Visual-Review subagent on the local licensed bundle at 390×844: adopt the chocolate Lab with
earned coins, confirm the active breed switches and the coat changes, reload and confirm the roster +
active breed persist. Verify by eye. Findings blocking.

## Acceptance criteria

- [ ] TDD (RED→GREEN): roster round-trips in the same save blob; legacy saves default to owning the
      starter Labrador; `BreedRoster` invariants (adopt/owns/set_active-only-among-owned/restore-clamp)
      hold; adopt spends coins via `CoinPurse` (affordable succeeds & debits; unaffordable is a no-op).
- [ ] The owned-breeds roster + active breed **persist across sessions** in the one `user://` save
      blob alongside coins + tricks; corrupt/legacy saves degrade to "owns the Labrador," never a crash
      and never a dog-less player.
- [ ] In the running game (no debug URL) the player can **spend earned coins to adopt the chocolate
      Lab** and **switch which owned breed is active**; the active dog shows its coat (076) + personality
      (075); the adopt UI shows the **price + a clear locked state**.
- [ ] Visual Review PASS (phone-portrait): adopt → switch → coat changes → reload persists; frames
      verified by eye; findings blocking. Evidence under `.screenshots/`.
- [ ] Additional breed *models* (Border Collie / French Bulldog / Husky) and the spotlit
      select-screen *polish* remain owner-gated flags — NOT faked here.
- [ ] Placeholder check clean (no faked breed thumbnail/image; honest real-coat swatch only).
- [ ] `nix develop -c bash verify.sh` green (import·boot·test·export).

## Notes

Depends on nothing owner-gated: both breeds (yellow + chocolate) are already real and in-repo. This
closes the P3-D3 "spend to adopt" loop and the P3-4 "persistent roster" spine using only what exists,
leaving the *showcase* visuals and *new* breed models as the honest residual flags.
