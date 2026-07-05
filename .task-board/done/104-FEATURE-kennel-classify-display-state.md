# 104 — FEATURE: `classify_kennel_dogs` display-state logic (Phase 8 K-1/K-3 foundation)

**Type:** FEATURE (pure logic, **test-first / TDD**)
**Phase:** 8 (Kennel — current)
**Stories:** K-1 (browse the roster), K-3 (see what I can afford). Foundation for K-2/K-4/K-6.

## What this addresses

The gap analysis (2026-07-05) found **zero kennel screen** — `KennelDog` (task 103) is a pure
8-dog catalog wired into nothing. Before the grid renderer (task 105) and the detail modal can
draw cells, they need one **pure, dumb-renderer-ready** function that turns the raw catalog + the
player's live economy state into per-dog **display rows** — exactly mirroring how
`TrickMenu.classify_breeds` (`scripts/trick_menu.gd:209`) feeds the Phase-3 breeds section so the
renderer itself stays dumb.

This is the **logic half** of the kennel-grid slice, split out so it is unit-testable in isolation
(the project pattern: pure logic in its own class, tested; rendering gets Visual Review). It does
**not** render anything and does **not** touch the save format / roster id-space (that migration is
deferred to the later adopt/switch task, K-4/K-5, where it is actually needed — do **not** migrate a
working save format before the feature that needs it).

## Why now

- Phase 8 is current (Phase 6 signed off `aa3577a`); the kennel is the current phase's headline.
- The grid (105) can't render owned/secret/affordable states without this classification.
- Pure logic → test-first, green in isolation, zero regression risk to the signed-off training page.

## Technical approach (test-first)

Add a static `classify_kennel_dogs(...)` to `scripts/kennel_dog.gd` (it already owns the catalog, so
the classifier lives beside its data — no new file needed). It returns one plain `Dictionary` row per
dog, carrying **everything both the cell (K-1) and the modal (K-2/K-3) need**, so neither renderer
re-derives state.

**Signature (stable — the modal will reuse it unchanged):**

```gdscript
# owned  : Array[String] of kennel ids the player owns (caller passes the roster's owned set,
#          always including STARTER_ID "bella"). active : the one active kennel id. balance : coins.
static func classify_kennel_dogs(owned: Array, active: String, balance: int) -> Array:
```

Each row (built from `catalog()` internally so callers pass no catalog):

```gdscript
{
  "id": d.id, "name": d.dog_name, "breed": d.breed, "rarity": d.rarity,
  "price": d.price, "stats": d.stats, "unique_trait": d.unique_trait,
  "band_tint": d.band_tint, "trick_ids": d.trick_ids,
  "owned": bool,        # owned.has(id)  — the starter is always in `owned`
  "active": bool,       # id == active   (the dog currently trained)
  "secret": bool,       # rarity == SECRET (Trulte)
  "affordable": bool,   # owned OR price == 0 OR balance >= price
  "status_label": String,   # owned → "Din hund" · secret → "★ Påskeegg" · else "" (cell may show "N dager her" later)
  "price_label": String,    # owned → "Din" · (secret & !owned) → "Gratis" · else str(price)
}
```

**Rules to pin with tests** (each a `assert_*` in `tests/test_kennel_dog.gd`, extending the existing
571-green suite — RED first, then implement):

- **Bella is owned by default:** with `owned == ["bella"]`, the Bella row has `owned == true`,
  `status_label == "Din hund"`, `price_label == "Din"`.
- **An adopted dog flips to owned:** with `owned == ["bella", "sol"]`, Sol's row `owned == true`,
  `price_label == "Din"` (the owned treatment overrides her rarity price — K-4), and Sol is
  `affordable == true` regardless of balance.
- **Active flag:** with `active == "bella"`, only Bella's row has `active == true`.
- **Affordability gate (K-3):** Nova (price 900) with `balance == 100` → `affordable == false`;
  with `balance == 900` → `affordable == true`; with `balance == 1000` → `affordable == true`.
- **Trulte the easter egg (K-6):** unowned Trulte → `secret == true`, `price == 0`,
  `price_label == "Gratis"`, `status_label == "★ Påskeegg"`, `affordable == true` even at
  `balance == 0` (free).
- **Row count & order:** returns exactly 8 rows in catalog order (Bella first).
- **Purity / no aliasing:** two calls return independent arrays; mutating a returned `stats`/`band_tint`
  never bleeds into `KennelDog.DOGS` (the row `stats` is a duplicate — reuse `_from_row`'s `.duplicate()`).
- **Unknown owned id is harmless:** `owned == ["ghost"]` never crashes and never marks a real dog owned
  (Bella included — the caller is responsible for seeding the starter; the function does not inject it).

**Before** (no classifier — only the raw catalog exists):

```gdscript
# scripts/kennel_dog.gd — catalog() returns bare KennelDog objects; no display state.
static func catalog() -> Array: ...
```

**After** (dumb-renderer-ready rows the grid/modal read directly):

```gdscript
static func classify_kennel_dogs(owned: Array, active: String, balance: int) -> Array:
	var rows: Array = []
	for d in catalog():
		var is_owned: bool = owned.has(d.id)
		var is_secret: bool = d.rarity == Rarity.SECRET
		var affordable: bool = is_owned or d.price == 0 or balance >= d.price
		var price_label := "Din" if is_owned else ("Gratis" if is_secret else str(d.price))
		var status_label := "Din hund" if is_owned else ("★ Påskeegg" if is_secret else "")
		rows.append({
			"id": d.id, "name": d.dog_name, "breed": d.breed, "rarity": d.rarity,
			"price": d.price, "stats": d.stats, "unique_trait": d.unique_trait,
			"band_tint": d.band_tint, "trick_ids": d.trick_ids,
			"owned": is_owned, "active": d.id == active, "secret": is_secret,
			"affordable": affordable, "status_label": status_label, "price_label": price_label,
		})
	return rows
```

Follow the `tdd` skill (`.claude/skills/tdd/SKILL.md`): RED (new failing tests in
`tests/test_kennel_dog.gd`) → GREEN (implement) → REFACTOR. No rendering, no `main.gd` change, no
save-format change.

## Acceptance criteria

- [x] New failing tests added to `tests/test_kennel_dog.gd` FIRST covering every rule above (RED).
- [x] `KennelDog.classify_kennel_dogs(owned, active, balance)` implemented; all new tests GREEN.
- [x] Returns exactly 8 rows in catalog order; each row carries id/name/breed/rarity/price/stats/
      unique_trait/band_tint/trick_ids + owned/active/secret/affordable/status_label/price_label.
- [x] Owned overrides rarity for `price_label` ("Din"); Trulte reads "Gratis" + "★ Påskeegg" + free.
- [x] Affordability = owned OR free OR balance ≥ price (K-3 gate).
- [x] Returned rows are independent copies (no aliasing into `DOGS`); two calls don't share state.
- [x] No change to `main.gd`, `main.tscn`, the save format, or the roster id-space (deferred to the adopt task).
- [x] Placeholder check clean; `nix develop -c bash verify.sh` green (import·boot·test·export).
