# 110 — FEATURE: Switch which dog I train (kennel → training) + active-dog persistence

**Type:** FEATURE (TDD for the active-switch + persistence logic → **Visual Review** for the flow)
**Phase:** 8 (Kennel — current)
**Stories:** K-5 (switch which dog I train), K-7 (active dog persists). Ties into Phase-3 breeds
(coat tint + temperament levers).
**Depends on:** 109 (`KennelRoster` owned set + `kennel` save key + adopt flow).
**Source:** PO Review 2026-07-05 — the "adopt/switch/persist spine." This closes the loop the kennel
exists for: an owned dog actually becomes the dog you train.

## What this addresses

After 109 a player can adopt a dog, but adopting only records ownership — it never changes **who they
train**. K-5: an owned dog's modal/cell shows **«Tren med [navn]»**; pressing it sets that dog active,
closes the kennel, and the training scene loads **that dog** (its coat tint + stats), and the choice
**persists** across a reload.

**Honest model story (BUST-068).** Only the Labrador rig ships (+ the chocolate recolor); the other 7
breeds have no distinct models (owner-gated, already flagged). So «Tren med Nova» loads the **Labrador
rig re-tinted** to the dog's `band_tint` via the existing `CoatTint` seam (the exact chocolate-Lab
mechanism, 076) and applies that dog's stats/temperament — the honest stand-in, not a faked new model.
No new owner asset; every KennelDog is trainable as a tinted, stat-distinct variant of the shared rig.

## Why now

- 109 gives the owned set + persistence spine; switching the active dog is the immediate next story and
  the payoff that makes adoption meaningful.
- Reuses the proven coat-retint + lever-reapply path from 076/079 (`_on_breed_chosen`), so it's low-risk.

## Technical approach

### 1. Active-switch logic on `KennelRoster` + persistence (TDD first)

`KennelRoster.set_active(id)` already exists from 109 (no-op-if-unowned). Wire it + persist the active
id under the same `kennel` save key. Add `TrickStore.decode_kennel` already carries `active` (109) —
assert it round-trips here.

**Tests (RED → GREEN):**
- `test_set_active_to_owned_dog_updates_active`
- `test_set_active_to_unowned_is_rejected` (already covered in 109 — extend if needed)
- `test_active_kennel_dog_roundtrips_through_save` (adopt Nova → set active → encode → decode → active is Nova)

### 2. Coat tint + stats reflect the chosen dog (TDD the resolve, Visual the render)

- Add a resolver `main._apply_active_kennel_dog(id)`: look up `KennelDog.by_id(id)`, re-tint the coat to
  its `band_tint` via `CoatTint` (the 076 path), and apply its stats. Map the KennelDog's stats/rarity to
  the training levers — reuse `BreedPersonality` where an owned breed maps cleanly (Bella→labrador), and
  for the tinted stand-ins drive the levers from the KennelDog's 4 stats (a small pure
  `KennelDog.to_personality()` or a documented mapping) so «Fokus 5» actually tightens the timing window
  etc. Keep it pure + tested; `main` stays thin glue.
- **Test:** `test_active_kennel_dog_resolves_to_a_tint_and_stats` (a known id → non-default tint + the
  expected stat-driven lever scale).

### 3. «Tren med [navn]» button + return-to-training (Visual Review — `kennel_screen.gd` + `main.gd`)

- In the modal: for an **owned** dog that is **not already active**, the full-width button reads
  **«Tren med [navn]»** (green owned treatment) and emits `train_with_requested(id)`. The **active** dog
  shows a non-tappable «Trener nå»/active state (no dead button). This replaces the "owned dog shows no
  button" placeholder 109 left.
- `main._on_kennel_train_with(id)`: `_kennel_roster.set_active(id)`, `_apply_active_kennel_dog(id)`,
  persist, `_close_kennel()` (restore the training HUD), so the player lands back on the training scene
  with the chosen dog loaded and framed. On boot, `_apply_active_kennel_dog(_kennel_roster.active)` runs
  after the dog loads so a returning player boots into their chosen dog (K-7).

### Before
```gdscript
# An owned dog has no way to become the trained dog; boot always loads Bella/the persisted breed.
```
### After
```gdscript
func _on_kennel_train_with(id: String) -> void:
	if not _kennel_roster.set_active(id): return
	_apply_active_kennel_dog(id)   # coat re-tint + stat levers (CoatTint / lever map)
	_persist(); _close_kennel()    # back to training with that dog loaded
# boot: _apply_active_kennel_dog(_kennel_roster.active) after the dog loads → returning player restored.
```

## Placeholder / tofu check

- Grep the diff for the placeholder list — none in a shipped path. The tinted Labrador stand-in is the
  already-flagged BUST-068 honest stand-in (no new fake model; the retint is the real 076 mechanism).
- «Tren med …»/«Trener nå» are plain words; the name is data — no non-theme glyph / emoji.

## Acceptance criteria

- [x] **TDD first:** the active-switch, save round-trip, and tint/stats-resolve tests written RED → GREEN.
- [x] An owned, non-active dog's modal shows «Tren med [navn]»; pressing it sets that dog active and
      returns to the training scene with the dog loaded (K-5).
- [x] The training scene's model (coat tint) + stats reflect the chosen dog — via the `CoatTint` retint
      of the shared rig (honest BUST-068 stand-in) + stat-driven levers, no faked new model.
- [x] The active dog shows a non-tappable active state in its modal (no dead button).
- [x] The active dog persists across a reload under the `kennel` save key; a returning player boots into
      their chosen dog (K-7). No parallel store.
- [x] `nix develop -c bash verify.sh` green (import·boot·test·export).
- [x] Visual Review PASS (390×844, real canvas tap): adopt a dog → «Tren med [navn]» → kennel closes,
      training shows the re-tinted dog; reload → still that dog. Bella round-trips too. — proven by
      task 112: `web_capture_kennel_switch.mjs` PASSED (active=sol, save wrote active=sol, reload
      restored active=sol + owned=[bella,sol]); frame `.screenshots/112-switch-training-sol.png`.
