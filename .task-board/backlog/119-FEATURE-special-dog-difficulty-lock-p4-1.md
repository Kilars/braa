# 119 — FEATURE — Special dogs lock difficulty (P4-1)

**Phase:** 9 (Difficulty) — current. **Depends on:** 118 (the selector must exist).
**Story:** P4-1 "For special dogs difficulty should be locked (kennel)."
**Type:** FEATURE (logic, TDD) + Visual Review (locked-state read).

## What it addresses

P4-1 has two halves: normal dogs let the player choose difficulty (118); **special
dogs lock it**. The kennel already models rarity — `KennelDog` `enum Rarity { OWNED,
COMMON, RARE, EPIC, SECRET }`. "Special" = a non-COMMON, non-OWNED-starter dog (the
collectible/easter dogs: RARE/EPIC/SECRET). When such a dog is the **active training
dog**, the difficulty selector (118) must be **locked** to a fixed mode — the player
can't trade the challenge away on a special dog.

## Technical approach

1. **Model the lock on `KennelDog`** (TDD): a pure predicate + the locked mode.

```gdscript
# BEFORE — rarity exists but nothing reads it for difficulty
enum Rarity { OWNED, COMMON, RARE, EPIC, SECRET }

# AFTER — KennelDog.locks_difficulty() : bool  and  KennelDog.locked_difficulty_id() : String
func locks_difficulty() -> bool:
	# special = the collectible/secret dogs; the starter Bella (OWNED) and plain
	# COMMON adoptables stay player-choosable.
	return rarity == Rarity.RARE or rarity == Rarity.EPIC or rarity == Rarity.SECRET

func locked_difficulty_id() -> String:
	return "hard"   # special dogs are a fixed challenge; exact mode is a product knob
```

Confirm the intended mapping against `phase8.md` rarity rows before finalizing which
rarities lock — if the table is ambiguous, lock the SECRET/EPIC tier and record the
assumption in this file. (Do not lock Bella the starter or plain COMMON dogs.)

2. **Wire the lock into the active-dog path.** Determine the active training dog's
KennelDog (via the roster / active breed id → `KennelDog.by_id` or the existing
active-dog seam). Expose `main._difficulty_locked() -> bool` and, when locked, force
`_difficulty` to the locked mode on adopt/switch-to-training and re-apply levers.

3. **Reflect the lock in the selector (118).** `TrickMenu.classify_difficulty`
gains a `locked` flag; locked rows render non-selectable with a clear "Låst" read,
and `_on_difficulty_chosen` no-ops while locked. Keep the section visible (so the
player understands *why* it's fixed), just non-interactive.

```gdscript
# classify_difficulty(catalog, active_id, locked := false, locked_id := "")
# when locked: every row non-selectable, the locked_id row marked active + a "Låst" badge
```

## Acceptance criteria

- [ ] RED first: `KennelDog.locks_difficulty()` true for the special tier, false for
  the starter (OWNED Bella) and COMMON dogs; `locked_difficulty_id()` returns a known
  `Difficulty` id.
- [ ] RED first: `TrickMenu.classify_difficulty(..., locked=true, locked_id=...)` marks
  every row non-selectable and flags the locked mode active; `TrickMenu.is_difficulty_selectable`
  false for all rows when locked.
- [ ] RED first: `main._on_difficulty_chosen(x)` is a no-op while the active dog locks
  difficulty (mode stays the locked one).
- [ ] GREEN: switching a special dog into training forces + shows the locked difficulty;
  switching back to a normal dog restores the player's chosen mode.
- [ ] Normal dogs (Bella + COMMON adoptables) keep the free 118 selector — no regression.
- [ ] Visual Review (390×844): a special dog's menu shows the difficulty section as
  clearly **locked** (fixed mode + "Låst" read), a normal dog's shows it selectable.
- [ ] `nix develop -c bash verify.sh` green; placeholder check clean; committed + pushed.
