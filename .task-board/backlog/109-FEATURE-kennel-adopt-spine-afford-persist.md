# 109 — FEATURE: Kennel adopt spine — affordability gate + adopt + persistence

**Type:** FEATURE (TDD for the economy/roster logic → then **Visual Review** for the adopt button)
**Phase:** 8 (Kennel — current)
**Stories:** K-3 (see what I can afford), K-4 (adopt a dog), K-7 (remembered & offline — coins +
owned set). Sets up K-5 (switch, next task) and K-6 (easter free adopt).
**Depends on:** 108 (`open_detail(id)` modal + `_build_adopt_button()` seam), 104
(`classify_kennel_dogs`), `CoinPurse`/`TrickStore` (Phase-3 economy spine).
**Source:** PO Review 2026-07-05 — the deferred "adopt/switch/persist spine + the roster↔kennel
id-space reconciliation." This is the keystone: it makes coins actually *do* something in the kennel.

## What this addresses

The kennel is inspect-only. Tapping a dog opens the 108 modal but there is **no adopt button** and
**no way to spend coins** — the economy (`CoinPurse`, earned via training mastery) has no sink in the
kennel. This builds the core of the phase's loop: **afford → adopt → remember**.

**The id-space blocker.** `BreedRoster` (079) tracks *breed* ids (`labrador`, `chocolate`); the kennel
tracks *KennelDog* ids (`bella`, `nova`, `balder`…). They are separate spaces. `main._kennel_owned()`
/ `_kennel_active()` are STARTER-only stubs (return `["bella"]` / `"bella"`). This task reconciles them
by adding a **`KennelRoster`** pure value object persisted under a **new save key** (`kennel`), so the
signed-off Phase-6 save blob stays byte-compatible (a pre-109 save decodes to the Bella-only default).

## Why now

- First and most foundational unbuilt spine story — K-5 (switch) and K-6 (easter adopt) both build on
  the owned-set + adopt flow this establishes.
- Pure economy/roster logic → clean TDD; the only visual is the adopt button in the existing modal.

## Technical approach

### 1. `KennelRoster` — new pure value object (TDD first), mirroring `BreedRoster`

`scripts/kennel_roster.gd`: the set of owned KennelDog ids + the one active id.
- `STARTER := KennelDog.STARTER_ID` ("bella") is **always owned**; a corrupt/legacy/empty restore
  degrades to `{owned:["bella"], active:"bella"}` — never dog-less.
- `owns(id)`, `adopt(id)` (no-op if unknown or already owned — spending is the caller's job),
  `set_active(id)` (no-op returning false if unowned), `to_dict()`, `restore(d)` (re-admit only
  `KennelDog.is_known` ids, clamp active to an owned id). Direct twin of `BreedRoster` — reuse its
  invariants verbatim.

**Tests (RED → GREEN):**
- `test_kennel_roster_starts_owning_only_bella`
- `test_adopt_adds_a_known_dog_and_ignores_unknown_or_duplicate`
- `test_set_active_rejects_unowned_returns_false`
- `test_restore_degrades_garbage_to_bella_only_and_clamps_active`

### 2. Persist under a new `kennel` save key (TDD first)

Extend `TrickStore.encode`/`save` with a trailing `kennel: Dictionary = {}` param (defaults keep every
existing caller unchanged), and add `TrickStore.decode_kennel(text)` → the kennel roster entry, with the
same degrade-to-default contract as `decode_roster`. A pre-109 save (no `kennel` key) → Bella-only.

**Tests (RED → GREEN):**
- `test_decode_kennel_missing_key_defaults_to_bella_only` (Phase-6 save unchanged)
- `test_encode_then_decode_kennel_roundtrips_owned_and_active`
- `test_decode_kennel_corrupt_degrades_to_default`

### 3. Adopt flow in `main.gd` (TDD the mutation; Visual Review the button)

- Replace the `_kennel_owned()`/`_kennel_active()` stubs with a real `var _kennel_roster := KennelRoster.new()`,
  restored on boot from `_store.load()` (`TrickStore.decode_kennel`) alongside the existing roster/coins.
- `_on_kennel_adopt(id)`: **affordability gate** — `KennelDog.by_id(id).price`; if
  `_purse.can_afford(price)` (or `price == 0`): `_purse.spend(price)`, `_kennel_roster.adopt(id)`,
  persist the whole blob (tricks+coins+roster+difficulty+words+**kennel**), re-render the grid + modal
  to the owned treatment, positive feedback (coin count-down + a small celebratory beat — reuse the
  072/adopt pattern). **No double-spend:** guard with an in-flight `_kennel_adopt_busy` bool (twin of
  the completion-menu guard) so a second press mid-adopt is swallowed.
- Save through the existing single blob — **do NOT add a parallel store** (spec Godot-notes).

**Tests (RED → GREEN, pure where possible):**
- `test_adopt_deducts_price_and_marks_owned` (drive purse+roster through a small seam, assert balance
  and owned set)
- `test_adopt_unaffordable_is_a_noop` (balance and owned set unchanged)
- `test_adopt_is_idempotent_no_double_spend` (two adopts of the same id spend once)

### 4. Adopt button in the modal (Visual Review — `kennel_screen.gd`)

Fill the `_build_adopt_button(detail)` seam (currently returns null): a full-width button reading
**«Adopter · N mynt»** (blue `#4a90e2`, Baloo 2), emitting a new `adopt_requested(id)` signal wired to
`main._on_kennel_adopt`. Per **K-3**: when `coins < price`, render it **dim + non-tappable** (disabled,
no error state). An owned dog's modal/cell flips to the owned treatment (green «Din hund» tag, «Din»
price) — the button is not shown for an owned non-active dog here (its «Tren med [navn]» switch label
lands in K-5, next task; for this task an owned dog simply shows no adopt button). Trulte's free-adopt
coral button is K-6 — this task ships the priced blue button + disabled state only.

### Before
```gdscript
# main.gd — owned/active are STARTER-only stubs; the adopt button seam returns null.
func _kennel_owned() -> Array: return [KennelDog.STARTER_ID]
func _kennel_active() -> String: return KennelDog.STARTER_ID
# kennel_screen.gd
func _build_adopt_button(_detail: Dictionary) -> Control: return null
```
### After
```gdscript
# main.gd — a real persisted kennel roster + an adopt flow with an affordability gate.
var _kennel_roster := KennelRoster.new()
func _on_kennel_adopt(id: String) -> void:
	if _kennel_adopt_busy: return
	var price := KennelDog.by_id(id).price
	if price > 0 and not _purse.can_afford(price): return   # K-3 gate
	_kennel_adopt_busy = true
	_purse.spend(price); _kennel_roster.adopt(id); _persist(); _rerender_kennel(id)
	_kennel_adopt_busy = false
# kennel_screen.gd — priced button, dim when unaffordable, emits adopt_requested(id).
```

## Placeholder / tofu check

- Grep the diff for `placeholder|stub|dummy|fake|mock|TODO|FIXME|stand-in|for now|… later` — none in a
  shipped path. The tinted-Labrador dog render is the already-flagged honest BUST-068 stand-in (unchanged
  here). No dead button — the adopt button is fully wired to a real spend.
- Price string is numerals (Baloo 2), «Adopter»/«mynt» plain words — no non-theme glyph / emoji.

## Acceptance criteria

- [ ] **TDD first:** `KennelRoster`, the `decode_kennel` persistence, and the adopt-mutation tests all
      written RED, then GREEN (reference the `tdd` skill).
- [ ] The coin balance shows live in the kennel header; every buyable cell + the modal button show the
      price; the modal adopt button reads «Adopter · N mynt» (K-3).
- [ ] When `coins < price` the adopt button is visibly disabled (dim, non-tappable) — no error state (K-3).
- [ ] Pressing an enabled adopt button deducts the price, marks the dog owned, gives positive feedback
      (coin count-down + a small celebratory beat), and flips the cell/modal to the owned treatment (K-4).
- [ ] No double-spend: an in-flight adopt can't fire twice (K-4).
- [ ] Coins + the owned set persist to `user://` under a new `kennel` save key; a pre-109 (Phase-6) save
      decodes to Bella-only, unchanged (K-7). No parallel store added.
- [ ] `_kennel_owned()`/`_kennel_active()` now read the persisted `KennelRoster` (id-space reconciled).
- [ ] `nix develop -c bash verify.sh` green (import·boot·test·export).
- [ ] Visual Review PASS (390×844, real canvas tap): open a dog's modal, adopt an affordable dog →
      balance counts down, cell flips to owned; open an unaffordable dog → button is dim/non-tappable;
      reload → the adoption persists. Training page intact.
