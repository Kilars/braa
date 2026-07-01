# 067 — FEATURE: wire Legg deg as the third trick (P2-2/P2-3)

**Phase:** 2 (current) · **Type:** Feature · Routed from BUST-064. Rides the 065 trick generalization.

## Source
BUST-064: **Legg deg** (settle on belly) clips `Lie_belly_start / Lie_belly_loop_1|2 / Lie_belly_end`
(+ `Lie_Sleep_*`) are **present** in `dog_licensed.glb` but unwired. P2-2 names it in the starter set
and requires the lie-down tricks read as **down**, clearly different from sit — and Legg deg must read
as distinct from Ligg (belly-settle vs lie).

## Scope
- Resolve `Lie_belly_*` as a third trick bundle via the 065 trick generalization (`DogClips`,
  `DogDirector`, `main.gd` `_current_trick`), keyed `legg_deg`.
- Guard the resolver so Legg deg ≠ Ligg ≠ Sitt (belly vs plain lie vs sit vocab).
- Reachable via selector (066) / `?bra_trick=legg_deg`.

## Done when
- [x] Legg deg resolves + drives as a real, distinct, markable trick reading as a belly-settle.
      TDD (11 new): `Lie_belly_*` resolution excluding the belly-SLEEP / plain-sleep / plain-lie (Ligg)
      decoys (`test_dog_clips.gd`); generic `play_trick/trick_window/play_trick_end("legg_deg")` drive a
      belly build→hold→stand distinct from Ligg's `Lie_*` (`test_dog_director_trick.gd`); own isolated
      per-trick progress slot that persists under its own key (`test_trick_store_wiring.gd`). Wired via
      `DogClips.TRICK_LEGG_DEG` + `main.gd` `_current_trick`/`KNOWN_TRICKS`; reachable via
      `?bra_trick=legg_deg` until the 066 selector lands; default play stays Sitt (unregressed).
- [x] Visual Review on the local **licensed** bundle (`.screenshots/legg_deg/`): `web_boot_check`
      asserts `dog_licensed.glb` + `dog can perform 'legg_deg'`; `legg-apex.png` shows the Labrador
      **fully down on its belly** (head low to the grass, flatter than Ligg's raised-chest sphinx-lie)
      at a gold **PERFECT** apex ring (2518 gold px) — a real, markable belly-settle, distinct from Ligg and Sitt.
- [x] `verify.sh` green (import·boot·test·export). Placeholder check clean (only the documented,
      asset-gated "CC0 placeholder" reference). Commit + push.
