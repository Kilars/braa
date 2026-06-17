# Bra! — Build Status

## How this was built

Bra! was built autonomously via a self-paced "Ralph Wiggum" loop: a Claude agent
ran `/scan-project` each iteration to generate the next three tasks, then
`/start-working` to implement them — with no human coding input. The loop ran for
**19 iterations** across **54 tasks** (see [`.task-board/done/`](../task-board/done/)
for every task file and [`.task-board/RALPH-LOOP.md`](../task-board/RALPH-LOOP.md)
for the per-iteration log).

The loop covered the full spec plus all "Future / Post-v1" branches: combos,
untraining, multiple breeds with signature tricks, economy, idle income, kennel and
adopt shops, phrase collection, difficulty modes, achievements, daily streak,
graduation/prestige, onboarding drip, help overlay, mastery celebration, settings
panel, accessibility sweep, balance audit and tuning, CI, e2e smoke test, PWA
manifest and service worker, Capacitor native-wrap scaffolding, and a final polish
pass.

## Current metrics

| Metric | Value |
|--------|-------|
| Unit tests | **440 passing** (25 test files) |
| Source modules | **27** (TypeScript, under `src/`) |
| E2e smoke | `bun run e2e` — select → train → mark |
| CI | `.github/workflows/ci.yml` — typecheck + test + build |
| Typecheck | Clean (`tsc --noEmit`) |
| Build | Clean (Vite; initial bundle ~29 KB, Babylon lazy-loaded) |

## Known deferred items

- **3D dog art**: currently procedural Babylon primitives (clears D1/D2 at
  silhouette level, not D14 "looks the part"). Sourcing route **decided**
  (asset-store base model + shared-rig retargeting, tech-decisions §3); execution
  planned as the [Pokémon-GO Visuals epic](../.task-board/EPIC-pokemon-go-visuals.md)
  (tasks 077–085). The main remaining content risk, now scoped.
- **Marker voice ("Maren")**: deferred pending sourcing/rights decisions
  (see [tech-decisions.md §3](tech-decisions.md)).
- **Level table**: defined to level 5 (1000 XP); content beyond level 5 not yet
  authored.
