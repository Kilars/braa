# 127 — FEATURE — Completion menu: progressive disclosure with a narrative arc

**Type:** FEATURE (game logic — TDD on the pure reveal predicates)
**Priority:** SERIOUS (PO flagged high). Father-pass PO directive (`po-review.md` 2026-07-05,
Menu #2). Preempts Phase-10 scaffolding per X-4.
**Addresses:** "[SERIOUS] The completion menu is information overload — reveal it as a story, not
all at once." The menu currently stacks **every** system at full detail on the first open: the
trick list (Learned/Available + three never-trainable Locked roadmap rows), the Breeds section,
the five marker words, the Vanskelighet (difficulty) block, coins, and the actions — a settings
dump, not a reward moment. It breaks the North-Star "single satisfying tap" calm and buries
progression.

## Acceptance target (PO)

**Progressive disclosure with a narrative through-line** — sections appear as the player *earns*
their way to them, so the menu grows with the player. Hide/minimally-tease systems not yet reached;
each reveal is a small earned beat.

## Design — the reveal arc

The menu (`trick_menu.gd`) is already a **dumb renderer**: every section collapses to zero height
when fed an empty array (and the "Vis frem hundene" showcase row already hides with empty breeds).
So disclosure is driven entirely from **what `main.gd` feeds** — no menu-layout change needed.

Staggered so **one new beat lands per mastery**, never a dump:

| Section | Reveal when | Rationale |
|---|---|---|
| Trick list | always (the core reward) | but locked roadmap rows **teased to one**, not all three |
| Marker words | first alternate word unlocked (`unlocked_alt_count ≥ 1`) | the payoff of mastery #1 — "you earned a new word!" |
| Difficulty (Vanskelighet) | `mastered_count ≥ 2` | a tuning system, surfaced once the loop is understood — not on the first reward |
| Breeds (+ showcase) | can actually afford to adopt (`balance ≥ adopt_cost`) or owns > 1 breed | "adoption is actually meaningful" — naturally ~mastery #3 (3×10 coins) |

Locked roadmap tricks (`gi_labb`, `rull`, `snurr`): **tease exactly one** ("teased sparingly, not
fully enumerated") instead of enumerating all three future systems up front.

Brand-new first open: trick list (Sitt + reachable Ligg/Legg deg + one teased-locked) + coins +
actions. Each subsequent mastery reveals the next section — a genuine progression story.

## Technical Approach

New pure, unit-tested helper `scripts/menu_reveal.gd` (`MenuReveal`, `RefCounted`, static predicates):

```gdscript
class_name MenuReveal
extends RefCounted
static func reveal_words(unlocked_alt_count: int) -> bool:      return unlocked_alt_count >= 1
static func reveal_difficulty(mastered_count: int) -> bool:     return mastered_count >= 2
static func reveal_breeds(balance: int, owned_count: int, adopt_cost: int) -> bool:
	return owned_count > 1 or balance >= adopt_cost
static func teased_locked(all_locked: Array, max_tease := 1) -> Array:
	return all_locked.slice(0, max_tease)
```

`main.gd` — gate the feed in `_refresh_trick_menu` / `_menu_rows`:

**Before:**
```gdscript
_menu.set_breeds(_breed_rows())
_menu.set_words(_word_rows())
_menu.set_difficulty(_difficulty_rows())
# _menu_rows(): all_ids.append_array(ROADMAP_LOCKED_TRICKS)
```

**After:**
```gdscript
_menu.set_breeds(_breed_rows() if MenuReveal.reveal_breeds(_purse.balance, _roster.owned.size(), BREED_ADOPT_COST) else [])
_menu.set_words(_word_rows() if MenuReveal.reveal_words(_unlocked_alt_word_count()) else [])
_menu.set_difficulty(_difficulty_rows() if MenuReveal.reveal_difficulty(_count_mastered_tricks()) else [])
# _menu_rows(): all_ids.append_array(MenuReveal.teased_locked(ROADMAP_LOCKED_TRICKS))
```

Add a small `_unlocked_alt_word_count()` helper (count `_words` unlocked ids beyond `MarkerWords.BASE_ID`).
Reuse the existing `_count_mastered_tricks()`.

## Acceptance Criteria (TDD — write failing tests first, per `.claude/skills/tdd/SKILL.md`)

- [x] `tests/test_menu_reveal.gd`: `reveal_words` false at 0 alt words, true at ≥1.
- [x] `reveal_difficulty` false at <2 mastered, true at ≥2.
- [x] `reveal_breeds` true when `balance ≥ adopt_cost` OR `owned_count > 1`, else false.
- [x] `teased_locked` returns exactly one id from a three-id roadmap list (order preserved), and never
      more than the list size.
- [x] `main.gd` feeds empty arrays for not-yet-revealed sections; the menu renders them zero-height
      (existing renderer behaviour, unchanged).
- [x] Fresh player (0 mastered, base word, 1 breed, 0 coins): menu shows only trick list (one teased
      locked row) + coins + actions — no words / difficulty / breeds / showcase.
- [x] After thresholds are met the corresponding section appears (verified via a live capture or an
      integration assert on the fed rows).
- [x] No shared-token or menu-layout change; the signed-off menu geometry is byte-identical when a
      section IS fed.
- [x] `nix develop -c bash verify.sh` green (import · boot · test · export).
