# 065 — FEATURE: wire Ligg as a real, distinct second trick (P2-1/P2-2/P2-3)

**Phase:** 2 (current) · **Type:** Feature · **Preempts work-ahead.** · Routed from BUST-064.

## Source
BUST-064 de-gated the trick roster: **Ligg** (lie down) clips `Lie_start / Lie_loop_1|2 / Lie_end`
are **present** in `dog_licensed.glb` (manifest `assets/models/dog_licensed.clips.txt`) but unwired.
P2-2 names Ligg in the starter set and requires "the lie-down tricks read as **down**, clearly
different from sit." The Explore map (obs 4188) confirms the machinery is trick-ready:
`TrickProgress`/`TrickStore` are already per-trick keyed; `SitWindow`/`SitLoop` are trick-agnostic;
only `DogClips` (resolves only `sitting`), `DogDirector` (plays only `sit_*`), and `main.gd`
(`TRICK_ID_SITT` + single `_progress`) hardcode Sitt.

## Scope (this iteration — a real, drivable, markable Ligg; NOT the selector UI)
1. **DogClips** — generalize a trick to a `(start, loop, end)` clip bundle. Add Ligg resolution
   (`lie_start`/`lie_loop`/`lie_end`, "lie"-vocab, excluding `Lie_belly*`/`Lie_Sleep*` decoys so
   Ligg ≠ Legg deg) + `has_lie()`. Keep the existing Sitt fields/API intact.
2. **DogDirector** — drive a named trick: `play_trick(id)`, `trick_window(id)`, `play_trick_end(id)`,
   feint for it, `has_trick(id)`. Keep `play_sit()`/`sit_window()`/etc. as Sitt-bound wrappers so
   nothing existing regresses.
3. **main.gd** — introduce `_current_trick` (default `TRICK_ID_SITT`) + a per-trick `_progress` map
   keyed `sitt`/`ligg`; route `_begin_sit`/`_end_sit`/`_begin_feint`/progress/persist through it.
   Reach Ligg via a debug param `?bra_trick=ligg` (same harness pattern as `?bra_force_lock`) until
   the P2-1 selector (066) lands. Default play stays Sitt → the PO-verified experience is unregressed.

## Not in scope (follow-ups)
- **066** — P2-1 trick selector UI (replaces the `?bra_trick` reach with a real chooser).
- **067** — Legg deg (`Lie_belly_*`) as the third trick.
- Gi labb / Rull / Snurr — owner-gated (clips absent; narrowed flag in `FLAGS.md`).

## TDD
- `tests/test_dog_clips.gd` (extend): Ligg resolves on the licensed clip list; `""` + `has_lie()==false`
  on the CC0 list; `Lie_belly*`/`Lie_Sleep*` do NOT resolve as Ligg.
- `tests/test_dog_director_*` (extend / new): `play_trick("ligg")` queues `lie_start`→`lie_loop`;
  `trick_window("ligg")` returns a window off the lie clip lengths; `play_trick_end("ligg")` plays
  `lie_end`→idle; no-ops on CC0.
- `tests/test_*_wiring` (extend / new): current-trick=ligg routes progress into the `ligg` key and
  persists under `ligg` in the store; sitt path unchanged.

## Done when
- [x] New/extended tests red → green (6 new: Ligg resolution + generic accessors in
      `test_dog_clips.gd`, `test_dog_director_trick.gd`, per-trick isolation in `test_trick_store_wiring.gd`).
- [x] `?bra_trick=ligg` makes the dog perform Ligg (lie down) as a real, markable trick that reads
      as **down**, distinct from sit — Visual-Review capture on the local **licensed** bundle
      (`.screenshots/ligg/`): boot log `dog can perform 'ligg'` + `dog_licensed.glb`, 0 errors; frame
      19 shows the Labrador fully DOWN (belly to grass, front legs forward, facing camera) at a gold
      PERFECT apex — unmistakably a lie-down, not a sit.
- [x] Default (no param) gameplay is still Sitt with zero regression — `?bra_trick` defaults to Sitt
      off-web; existing 243 tests still green; the "dog can Sitt" boot line is byte-identical for sitt.
- [x] `verify.sh` green (import·boot·test·export) — `✓ verify gate green`.
- [x] Placeholder check on diff clean (only benign CC0-*placeholder-dog* references + "later"; the
      `?bra_trick` reach is named by task 066 → allowlisted). Commit + push.
