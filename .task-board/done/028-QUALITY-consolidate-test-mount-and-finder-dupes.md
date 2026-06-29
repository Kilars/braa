# QUALITY: 028 — Consolidate the duplicated scene-mount + tree-finder boilerplate

**Status**: Done — 2026-06-28
**Created**: 2026-06-28
**Priority**: Medium (maintainability; touches no gameplay behavior)
**Labels**: quality, godot, phase-1, tests, dry
**Estimated Effort**: Small

## Done (2026-06-28)

Pure DRY consolidation, no behavior change. **96 tests / 0 failures before and after**
(refactor-only, count unchanged), full `nix develop -c bash verify.sh` green
(import · boot · test · export).

1. **One mount helper.** Added `instantiate_main(dog := CC0_DOG, reduced := -1)` +
   `const CC0_DOG` to the shared base `tests/test_case.gd`. Deleted the five near-identical
   `_instantiate_main()` copies (`test_idle_loop`, `test_bra_button`, `test_payoff_wiring`,
   `test_tell_wiring`, `test_readout_wiring`) — each now calls the inherited helper. The
   `reduced` seam (field `reduced_motion_override`, default `-1`) is set only when forced,
   so the four non-readout mounts are byte-for-byte equivalent and the readout test passes
   `instantiate_main(CC0_DOG, 0|1)`. The load-bearing "_ready is deferred — the headless
   runner quits before any process frame (026)" comment now lives in **exactly one place**.
2. **One tree-finder.** Added `static func find_animation_player(n: Node)` to
   `scripts/dog_clips.gd` (the dog-clip layer, already a global `class_name` reachable
   everywhere). `main.gd::_start_dog`, `test_dog_clips.gd` (×2 call sites — the committed
   AND licensed binders), and `test_idle_loop.gd` (was `_find_ap`) all call it; their three
   private copies are deleted. The per-type `_find_button/_marker/_payoff/_readout` finders
   stay (GDScript single-inheritance can't generify the return types — left as the card
   scoped, not over-engineered).

## Why now

Five wiring tests each carry a near-identical `_instantiate_main()` (load `main.tscn`,
set `dog_path_override`, add to the tree root, call `_ready()` if not ready) —
`tests/test_idle_loop.gd:10`, `test_bra_button.gd:8`, `test_payoff_wiring.gd:9`,
`test_tell_wiring.gd:9`, `test_readout_wiring.gd:10`. The load-bearing comment about
*why* `_ready()` is invoked manually ("the headless runner quits before any process
frame", 026) is copy-pasted, so the institutional knowledge lives in five places and a
change to the mount dance (override field rename, the `is_node_ready()` guard) must be
made five times. Separately, the recursive depth-first `AnimationPlayer` finder is
duplicated between production (`scripts/main.gd:241` `_find_animation_player`) and tests
(`tests/test_dog_clips.gd:110` plus per-type `_find_ap` copies in the wiring tests).
This is pure dead-weight duplication with a real "edit-one-forget-the-others" risk; no
behavior changes.

## Technical Approach

**1. One mount helper on the shared base** (`tests/test_case.gd`). All wiring tests already
`extends "res://tests/test_case.gd"`, so a single helper there is inherited by all five.

```gdscript
# AFTER — add to tests/test_case.gd (the comment now lives in ONE place)
const CC0_DOG := "res://assets/models/dog.glb"

## Mount the production main scene headlessly. `dog` pins which model loads (default CC0
## so mounts are deterministic regardless of the gitignored licensed Labrador, 025).
## `reduced`: -1 leaves the scene's own reduced-motion resolution; 0/1 forces the seam.
## The headless runner quits before any process frame, so _ready is deferred — we invoke
## it explicitly to build the production wiring. (026)
func instantiate_main(dog := CC0_DOG, reduced := -1) -> Node:
    var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
    main.dog_path_override = dog
    if reduced != -1:
        main.reduced_motion_override = reduced   # whatever the existing seam field is named
    (Engine.get_main_loop() as SceneTree).root.add_child(main)
    if not main.is_node_ready():
        main._ready()
    return main
```

Then each `test_*_wiring.gd` deletes its local `_instantiate_main()` and calls
`instantiate_main()` (passing `reduced` only where it matters, e.g. test_readout_wiring).
Confirm the exact reduced-motion seam field name in `main.gd` and match it.

**2. One shared tree-finder.** Move the production recursive finder to a tiny pure util so
both sides share it:

```gdscript
# AFTER — scripts/main.gd::_start_dog
var ap := DogClips.find_animation_player(dog)   # or a new scripts/node_search.gd static

# scripts/dog_clips.gd (or node_search.gd) — static, no engine state of its own
static func find_animation_player(n: Node) -> AnimationPlayer:
    if n is AnimationPlayer: return n
    for child in n.get_children():
        var found := find_animation_player(child)
        if found != null: return found
    return null
```

Tests then call the same static instead of their own `_find_ap`/`_find_animation_player`
copies. (GDScript single-inheritance means per-type `_find_button`/`_find_marker` finders
in the wiring tests can't be fully generified — leave those, or add only the AP finder to
scope; do not over-engineer.)

## Acceptance Criteria

- [x] `instantiate_main()` lives only in `tests/test_case.gd`; the five local copies are
      deleted and call the shared helper.
- [x] The "_ready is deferred / runner quits before a process frame" comment exists in
      exactly one place.
- [x] The recursive `AnimationPlayer` finder exists once (a static util); `main.gd` and the
      tests call it instead of private copies.
- [x] No behavior change: the same tests still assert the same things.
- [x] Full gate green: `nix develop -c bash verify.sh`; test count unchanged (refactor only,
      0 failures).
