# Dog Rendering Polish Loop (5 iterations)

Focused loop: each iteration = (1) review the dog rendering, (2) create tasks,
(3) implement. Goal: take the placeholder sphere → a recognizable, appealing
dog (semi-realistic, Pokémon-GO-ish per specs.md "Visual Presentation").

## Baseline review (before iter 1)
A single tan **sphere** with per-state color/scale/position tweaks (idle/offering/
confused/happy/distractor/misbehaving). No dog shape, no shadow (floats), flat
plastic shading + harsh specular, hard flat horizon. Biggest gap: **it's not a dog**.

## Plan
1. **Shape** — primitive-composed dog (body/head/ears/snout/legs/tail) under a parent; preserve `updateDog` per-state visuals.
2. **Material + shadow + lighting** — ground shadow, soft fur-ish material (no plastic specular), eyes/nose.
3. **Animation** — idle breathing/bob, tail wag, per-state poses (sit / lie / jump / happy bounce).
4. **Scene** — ground + sky gradient/texture, soft framing/vignette.
5. **Breed looks + final polish** — vary appearance per breed; final review.

## Progress
| Iter | Status | Task(s) | Notes |
|------|--------|---------|-------|
| 1 | ✅ done | 056 mesh, 057 shadow+material+face, 058 poses | sphere → primitive dog (silhouette, grounded shadow, eyes/nose, per-state poses). 451 tests. Steps 1–3 of plan done. |
| 2 | ✅ done | 059 breed looks, 060 on-dog apex, 061 backdrop | D2 breeds distinct (coat+proportions), D6 dog crests at markable instant (reuses UI apex signal), D12 dog pops vs gradient backdrop. 466 tests. distractorRate=0 was NOT a bug (onboarding gate). |
| 3 | ✅ done | 062 per-trick poses, 063 two-tone coats, 064 per-mark reward | D11 dog performs the specific trick (sit/lie/spin/roll/howl/sleep), D2 Collie/Husky two-tone, D8 every PERFECT/OK mark pops the dog. 482 tests. Also added `bun run verify` dots wrapper. |
| 4 | starting | (scan) | Next candidates: idle look-around variety (D4), confused head-tilt richness (D7), mastery on-dog flourish bigger than per-mark (D8), distractor pose distinctness (D9), trainer hand for rewards (Visual Presentation). |
