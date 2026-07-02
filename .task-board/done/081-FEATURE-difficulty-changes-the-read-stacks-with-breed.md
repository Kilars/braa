# 081 — FEATURE: higher difficulty changes the read, stacked on the breed (dormant)

**Type:** FEATURE (game-logic TDD) · **Phase:** 4 — Difficulty · **Label:** `work-ahead` (PROVISIONAL —
Phase 3 is still the current, un-signed-off phase) · **Source:** `.docs/specs/phase4.md` **P4-2** ("Higher
difficulty changes the read") **+ P4-4** ("Stacks with the breed — effective difficulty = global mode ×
breed intrinsic") · **Priority:** the meat of Phase 4; builds directly on **080**.

## Why this is work-ahead (and how it stays dormant)

Same standing as 080: Phase 3 is exhausted and blocked purely on owner assets + PO sign-off, so next-phase
stories are provisional. **Dormancy:** every change is `× _difficulty.<scale>`, and **Normal = identity**
(all scales 1.0), so with the default Normal mode the effective levers equal exactly today's breed-resolved
values — the Phase-3 play-test is **byte-identical**. Non-Normal modes are only reachable via the dormant
`?bra_difficulty=` seam from 080 (no default-HUD selector). Independent of the blocked item (no new models,
no voice). Preempted by any reopened current-phase work.

## What it addresses

- **P4-2:** higher difficulty genuinely demands more — tighter timing window, fainter & faster apex tell,
  more feints/distractors, and harsher learned-bar erosion on a mistimed / wrong-moment tap.
- **P4-4:** difficulty **stacks with the breed** rather than replacing it. Because `BreedPersonality`
  already resolves each lever as `trait × canonical_constant`, layering the difficulty multiplier on top
  yields literally **`effective = breed_intrinsic × global_mode`** — the P4-4 acceptance, for free, via one
  composition point per lever.

## Concrete seams (found during build — the exact sites)

- **Window** — `main.gd:528` `_window = _director.trick_window(_current_trick, _breed.perfect_radius(),
  _breed.ok_radius())`. Scale both radii by `window_scale`.
- **Tell** — `main.gd:531` `_tell = ApexTell.from_window(_window, _motion_scale)`. `ApexTell`'s 2nd arg is
  `damping` = the tell **intensity**; its `ramp = window.ok_radius` (the tell tracks the scoring window —
  "one source of truth"). So **"faster/narrower tell" falls out for free** from tightening `_window` via
  `window_scale`. Only **"fainter"** needs wiring: compose `_motion_scale × tell_intensity_scale`, clamped
  to a small positive floor so X-5 holds (never zero info). **DECISION: drop `tell_speed_scale`** (added in
  080) — applying it as an *independent* ramp multiplier would decouple the tell from the scoring window and
  **break ApexTell's invariant**; leaving it defined-but-unread is a dead seam the audit rightly flags.
  Remove it from `Difficulty` + its assertions in `test_difficulty.gd`; document in `difficulty.gd` that the
  tell's timing follows the difficulty-tightened window ramp.
- **Feints** — `main.gd:1111` (`_start_dog`) **and** `main.gd:1462` (`_apply_active_breed`, live switch) both
  set `_loop.feint_chance = _breed.feint_chance()`. Both compose with `feint_scale`, clamp [0,1].
- **Erosion** — `TrickProgress.apply()` erodes by the constants `MISS_EROSION`/`DEAD_EROSION`. Add a
  per-instance `_erosion_scale := 1.0` + `set_erosion_scale(scale)` (mirroring the `_perfect_gain`/`set_gains`
  pattern), applied to both erosions in `apply()`. Default 1.0 = exact current behavior (existing net-forward
  tests use the default → stay green). An Expert tier may push erosion past `PERFECT_GAIN` ("unforgiving",
  intended) — the mastery floor still protects a mastered trick. `main` sets each progress's erosion scale
  from `_difficulty.erosion_scale` where it sets gains (construction + `_apply_active_breed`).

## Design: composition on `Difficulty` (pure resolved accessors — thin glue in main)

Keep the arithmetic on the model (same discipline as `BreedPersonality`'s resolved levers). Add to
`scripts/difficulty.gd`: `scale_radius(r) → r × window_scale`, `scale_feint(f) → clampf(f × feint_scale,0,1)`,
`scale_erosion(base) → base × erosion_scale`, `scale_tell_intensity(m) → clampf(m × tell_intensity_scale,
TELL_FLOOR, 1.0)`. Normal = identity on all four (dormancy).

## Technical approach

Difficulty multiplies the **breed-resolved** value at each existing application site. One composition rule
per lever; no new lever plumbing (080 already carries the bundle).

### The four read-levers (compose `breed × difficulty`)

1. **Timing window** — `main.gd` builds the sit window at `_begin_sit` from `_breed.perfect_radius()` /
   `_breed.ok_radius()`. Multiply by `_difficulty.window_scale`:
   ```gdscript
   # Before:
   var win := SitWindow.from_sit_clips(start_len, loop_len, _breed.perfect_radius(), _breed.ok_radius())
   # After (effective = breed intrinsic × global mode, P4-4):
   var win := SitWindow.from_sit_clips(start_len, loop_len,
       _breed.perfect_radius() * _difficulty.window_scale,
       _breed.ok_radius() * _difficulty.window_scale)
   ```
2. **Apex tell** — scale the tell's intensity by `_difficulty.tell_intensity_scale` (fainter) and its speed
   by `_difficulty.tell_speed_scale` (faster) at the `ApexTell` build/drive site. Respect **X-5 (reduced
   motion, never less information)** — the tell may get fainter/faster but must stay *distinguishable*; clamp
   so a non-zero tell never collapses to zero (reuse the `set_motion_scale` non-finite/≤0 guard pattern).
   Wire intensity at minimum; add speed if the seam takes it cleanly, else note it for a follow-up.
3. **Feints / distractors** — the round loop's feint rate is `_breed.feint_chance()`. Compose:
   ```gdscript
   # After:
   _loop.feint_chance = clampf(_breed.feint_chance() * _difficulty.feint_scale, 0.0, 1.0)
   ```
4. **Learned-bar erosion (P2-4)** — the mistimed/wrong-tap erosion (the bar drop + red setback the PO
   signed off in P2-4) scales by `_difficulty.erosion_scale`. Find the erosion amount (TrickProgress /
   LearnedBar erosion seam) and multiply it by `_difficulty.erosion_scale` at the one application point;
   TDD nails the exact site.

### TDD (RED first)

- **`tests/test_difficulty.gd` (extend) — the composition math is pure and testable directly:** for a given
  breed value `v` and mode `m`, the effective lever == `v * m.window_scale` (etc.); Normal leaves `v`
  unchanged; Expert tightens the window / raises feints / harshens erosion strictly more than Hard.
- **Wiring tests (extend `tests/test_*_wiring.gd` or the relevant per-lever tests):** instantiate `main`
  with `?bra_difficulty=expert` and a known breed, assert the **effective** window radius / feint_chance /
  erosion delta equal `breed × expert` (not `breed` alone, and not `expert` alone) — proving both P4-2 (it
  changed) and P4-4 (it stacked, didn't replace). Assert Normal → effective == breed value exactly
  (dormancy regression guard).
- **X-5 guard test:** at Expert the apex tell's effective intensity is `> 0` (fainter, never removed).

## Acceptance criteria

- [x] TDD (RED→GREEN): the per-lever composition is `effective = breed_intrinsic × difficulty.<scale>` for
      window radii, feint rate, tell intensity/speed, and erosion; Normal is the identity (effective ==
      breed value); Expert is strictly harder than Hard on each lever.
- [x] In the running game with `?bra_difficulty=hard|expert`, the **read** genuinely changes — tighter
      window, fainter/faster tell, more feints, harsher erosion — and it **stacks** with the active breed
      (a forgiving breed on Expert is measurably harder than the same breed on Normal, and harder-still than
      a tighter breed on Normal). Verified in tests via effective values.
- [x] **X-5 respected:** the tell gets fainter/faster but never collapses to zero information (clamped).
- [x] **Dormancy proven:** with default Normal, every effective lever equals today's breed-resolved value
      (regression guard test); default run byte-identical; no default-HUD selector.
- [x] Placeholder check clean.
- [x] `nix develop -c bash verify.sh` green (import·boot·test·export).

## Notes

Depends on **080** (the `Difficulty` bundle + `_difficulty` on boot). No owner assets. P4-3 (reward scaling)
is the sibling task **082**. Exact tell wiring (intensity vs. also speed) is left to the TDD — wire intensity
at minimum; if the `ApexTell` seam doesn't cleanly take a speed scale, ship intensity and note speed as a
small follow-up rather than forcing it.
