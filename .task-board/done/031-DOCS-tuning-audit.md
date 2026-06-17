# DOCS: Tuning Audit + Balance Sanity-Check

**Status**: Backlog
**Created**: 2026-06-14
**Priority**: Medium
**Labels**: docs, balance, quality
**Estimated Effort**: Simple

## Context & Motivation

Tunable numbers are scattered across ~15 modules (mark deltas, scheduler windows,
idle rate/cap, level table, trick mults, breed intrinsics, shop costs, combo cap,
prestige). They were authored as placeholders. Audit them into ONE reference and
sanity-check the balance so future tuning is possible. (Doc-only — no behavior
change; a code-centralization into a `tuning.ts` is a possible FUTURE refactor,
noted but NOT done here.)

## Affected Components
- Modify: `.docs/tech-decisions.md` (§7 — replace/expand with the audited table)
- Read-only across: `mark.ts`, `session.ts`, `scheduler.ts`, `difficulty.ts`, `tricks.ts`, `breeds.ts`, `economy.ts`, `kennel.ts`, `phrases.ts`, `combo.ts`, `prestige.ts`, `onboarding.ts`, `main.ts`
- Dependencies: none; Blocking: none

## Approach
1. Grep each module for the tunable constants; build a table: **name | current value | file | what it affects | note**.
2. Sanity-check the curve and flag (don't fix) any obvious imbalance:
   - Mastery: marks needed (PERFECT delta vs 100); is it reachable in a sane number of taps?
   - Economy: mastery payout (base × difficulty × kennel × prestige) vs shop costs (kennel 100/250/500, adopt 200/150/300, phrases 50/150) + level thresholds — is progression reachable / not trivial?
   - Difficulty: is HARD/EXPERT EV-worthwhile (reward mult vs higher miss rate), or dominated?
   - Idle: cap vs a typical session payout — does idle stay a nudge, not a replacement?
   - Combos / prestige multipliers: any runaway?
3. Write the audited table + the balance notes into tech-decisions §7. Recommend (don't apply) any number changes.

## Progress Log
- 2026-06-14 — Task created (iteration 11)

## Resolution
_(added when complete)_

## Acceptance Criteria
- [ ] tech-decisions §7 has a complete tunable table (name/value/file/effect) covering all the modules above
- [ ] Balance sanity-check written: mastery reachability, economy progression vs costs, difficulty EV, idle cap, combo/prestige runaway — with any imbalance flagged
- [ ] No code/behavior change; `bun run test` still green (sanity); `bun run build` succeeds
- [ ] A "future: centralize into tuning.ts" note recorded (not implemented)
