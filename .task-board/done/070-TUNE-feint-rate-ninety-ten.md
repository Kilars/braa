# 070 — TUNE: dog less distracted — feint rate ~90/10

**Type:** TUNE (game-logic, TDD) · **Phase:** 3 (current) · **Source:** PO Review 2026-07-02
`po-review.md` **Actionable note 2** ("The dog is TOO distracted … 90% is just plain trick")
+ PO sharpening ("Good = ~90% real completed tricks, ~10% feints/distraction") · **Priority:**
P1 for this phase (feel fix on the one live surface; low-risk constant + test).

## What it addresses

Between offers the loop coin-flips each offer into a real markable trick or a **feint**
(dip-and-abort, no scoring window). Today `SitLoop.FEINT_CHANCE := 0.35` → roughly **a third**
of offers abort, so real markable moments feel scarce (the PO watched "roughly a third of
offers abort as feints"). The owner wants the dog to *mostly* perform the trick and only
occasionally feint/distract: **~90% real trick, ~10% feint.**

This is the feint **rate** only. The scratch feint + between-offer framing (owner note 3) is a
separate task (071); the one-active-trick + completion menu (owner note 1) is 072.

## Technical approach

Single tuning constant in `scripts/sit_loop.gd`, guarded by a **statistical test-first** check
that the observed feint fraction sits at ~10% (not the old ~35%). `FEINT_CHANCE` is already the
sole knob — `tick()` feints when `_rng.randf() < FEINT_CHANCE`.

**Before** (`scripts/sit_loop.gd`):
```gdscript
const FEINT_CHANCE := 0.35       ## fraction of offers that abort (a feint) instead of completing
```

**After** (`scripts/sit_loop.gd`):
```gdscript
const FEINT_CHANCE := 0.10       ## ~1 in 10 offers feints; the rest complete (PO note 2 — dog not too distracted)
```

Also fix the two stale `~0.35` references that would now read as lies:
- `tests/test_sit_loop.gd` line ~132 message `"expected a feint within 50 cycles (FEINT_CHANCE ~0.35)"`
  → `~0.10` (a feint is now rarer, so widen the search cap if 50 cycles is too tight for a seed).
- `scripts/sit_loop.gd` header comment "Some offers are FEINTS" stays true; no number there.

### TDD (follow `.claude/skills/tdd/SKILL.md`)

Write the failing test FIRST in `tests/test_sit_loop.gd` (extend the existing suite; reuse its
seeded-RNG driver). Because feints are a coin-flip, assert the **rate over a large sample**, not
a single offer:

```gdscript
func test_feint_rate_is_about_one_in_ten() -> void:
    # Over many completed offers on a seeded loop, ~FEINT_CHANCE are feints — the PO's
    # "90% real trick, 10% feint". Wide tolerance so it's about the RATE band, not the exact seed.
    var rng := RandomNumberGenerator.new(); rng.seed = 424242
    var loop := SitLoop.new(rng, 0.0)  # zero sit-hold so real sits end immediately
    var feints := 0; var total := 0
    while total < 400:
        var intent := _next_offer(loop)          # drive to the next START_SIT / START_FEINT
        if intent == SitLoop.Intent.START_FEINT: feints += 1
        _complete_open_offer(loop)               # stand back up either way, come round again
        total += 1
    var rate := float(feints) / float(total)
    assert_true(rate > 0.03 and rate < 0.20,
        "feint rate ~10%% (PO note 2), got %.2f" % rate)   # RED at 0.35 (~0.35 observed) → GREEN at 0.10
```

Reuse the file's existing `_next_offer` / `_complete_open_offer` helpers (they already drive the
loop past feints to the next offer). Watch it go RED against `FEINT_CHANCE = 0.35` (observed rate
~0.35 fails `< 0.20`), then drop the constant to `0.10` and watch it go GREEN.

## Acceptance criteria

- [x] TDD: a failing feint-rate test exists first (`test_feint_rate_is_about_one_in_ten`,
      asserts observed rate ∈ ~(0.03, 0.20) over 400 seeded offers), RED at 0.35 (**got 0.34**) →
      GREEN at 0.10.
- [x] `SitLoop.FEINT_CHANCE == 0.10`; its inline doc reads as "~1 in 10 offers feints".
- [x] No stale `0.35` / "~0.35" feint reference left in `scripts/` or `tests/` (message updated to
      ~0.10; remaining 0.35 hits are unrelated — colors, tap-gate lock, damping, dog bounds).
- [x] Existing feint tests still pass (feints still occur, open no markable window, end + resume;
      real sits still come round) — search caps widened 50→150 for the rarer feint; 289 tests, 0 fails.
- [x] Placeholder check clean on the diff; `nix develop -c bash verify.sh` green (import·boot·test·export).

## Notes

Pure logic change — no Visual Review needed (the *behavior* of a feint is unchanged and already
verified; only its frequency moves). The owner will judge the felt frequency on his next play-test.

## Completion note

Dropped `SitLoop.FEINT_CHANCE` 0.35 → 0.10 so ~90% of offers complete the trick and only ~10%
feint (PO note 2 — "the dog is TOO distracted"). Locked test-first: new
`test_feint_rate_is_about_one_in_ten` drives 400 seeded offers and asserts the observed feint
fraction sits in ~(0.03, 0.20) — RED at 0.35 (got 0.34) → GREEN at 0.10. Widened the two
feint-finding tests' search caps 50→150 (a feint is now rarer, so the seed's first one can be
further out) and updated the stale "~0.35" message. Verify gate green (import·boot·test·export),
289 tests 0 failures, placeholder check clean.
