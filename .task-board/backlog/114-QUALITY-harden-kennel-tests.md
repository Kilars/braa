# 114 — QUALITY: harden two kennel tests (real guard seam + full HUD-hide coverage)

**Type:** QUALITY (current-phase, Phase 8) — test honesty
**Source:** Phase-8 construction audit (2026-07-05), **Findings 3 + 4**.

## What this addresses
Two kennel tests are weaker than they read — the exact hollow/near-hollow class this project
guards against (cf. task 026; the headless runner hides runtime SCRIPT ERRORs as green).

1. **`tests/test_kennel_adopt.gd` — unaffordable-adopt is a comment-test, not a seam test.**
   `test_adopt_unaffordable_is_a_noop` sets up a purse (200) vs price (900), asserts
   `can_afford == false`, then checks `balance == 200` / `owns == false` — both trivially
   true because **no adoption call is made**. It documents the guard in comments and only
   unit-tests `CoinPurse.spend`. A bug in the actual gate condition in `main.gd`
   (`_on_kennel_adopt`, e.g. `>=` vs `>`, or price-0 mishandling) would pass this test.
   Fix: exercise the **real** `_on_kennel_adopt` guard path (or the smallest extractable
   pure seam it delegates to) so an unaffordable adopt is proven a no-op *through the
   handler*, not merely described. Cover the boundary (coins == price − 1 rejects; coins ==
   price adopts) and confirm the **price-0 free-adopt** path is NOT swallowed by the
   affordability gate.

2. **`tests/test_kennel_screen_wiring.gd` — `CHROME_NODES` under-covers the HUD hide.**
   `_set_training_hud_visible` hides 9 nodes but `CHROME_NODES` only lists 6 (`_bra_button`
   is asserted separately). `_word_pop` and `_kennel_button` are never asserted hidden when
   the kennel opens — a regression that left either visible over the kennel would pass green.
   Fix: add `_word_pop` and `_kennel_button` to the asserted set so all 9 hidden nodes are
   covered on open and restored on close.

## Approach (test-first — these ARE tests)
- Extend `test_kennel_adopt.gd`: replace the descriptive no-op test with one (or add one)
  that drives the adopt handler/seam and asserts balance + owned are unchanged on an
  unaffordable attempt, changed on an affordable one, and that a price-0 dog adopts free.
  If the guard is buried in `main.gd` node glue, extract the pure decision (afford + price-0)
  into a small testable function and call that — do not assert through comments.
- Extend `test_kennel_screen_wiring.gd`: add `_word_pop` and `_kennel_button` to the
  hidden-on-open / restored-on-close assertions.

## Acceptance criteria
- [ ] The unaffordable-adopt test invokes the real guard seam (handler or an extracted pure
      decision), and would FAIL if the gate condition were inverted — verify by temporarily
      inverting it locally, seeing red, then reverting.
- [ ] Boundary covered: coins == price − 1 rejects, coins == price adopts, price == 0 adopts
      free without the affordability gate swallowing it.
- [ ] `test_kennel_screen_wiring.gd` asserts all 9 `_set_training_hud_visible` nodes hidden
      on kennel-open and restored on close (adds `_word_pop`, `_kennel_button`).
- [ ] No test ends with zero assertions; no behavior asserted only in comments.
- [ ] `nix develop -c bash verify.sh` green.
