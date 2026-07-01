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
- [ ] Legg deg resolves + drives as a real, distinct, markable trick reading as a belly-settle.
      TDD the resolution + drive; Visual Review it reads distinct from Ligg and Sitt.
- [ ] `verify.sh` green. Placeholder check clean. Commit + push.
