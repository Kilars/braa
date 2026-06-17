# DOCS: Project README

**Status**: Backlog
**Created**: 2026-06-14
**Priority**: Low
**Labels**: docs
**Estimated Effort**: Simple

## Context & Motivation

There's no top-level README. Add one so the repo is approachable: what Bra! is,
how to run it, the architecture, and where the detailed docs live.

## Affected Components
- Create: `/home/larsski/Code/bra/README.md`
- Read (for accuracy): `package.json` (scripts/deps), `.docs/specs.md`, `.claude/CLAUDE.md`, `.docs/tech-decisions.md`, `src/` layout

## Content
- **What it is:** one-paragraph pitch — mobile dog-training timing game; tap "BRA" at the right instant; built around marker training; Norwegian flavor.
- **Quick start:** `bun install`, `bun run dev`, `bun run test`, `bun run build`, `bun run typecheck` (verify these match package.json exactly).
- **Tech:** TypeScript + Vite + Bun + Babylon.js (WebGL) + DOM HUD + IndexedDB; PWA. Link tech-decisions.md.
- **Gameplay (brief):** select a dog + trick (Sitt/Ligg/Legg deg + untraining), time the BRA on the apex tell, build combos, earn coins/XP, adopt breeds, buy kennel upgrades, graduate dogs for prestige. Link specs.md for the full design.
- **Project structure:** `src/core` (pure game logic, fully unit-tested), `src/state` (IndexedDB save), `src/render` (Babylon scene), `src/ui` (DOM HUD), `src/audio`, `src/app` (helpers), `.docs/` (spec + tech), `.task-board/` (the autonomous build log).
- **Status:** test count + that the full spec is implemented; note placeholder art + that the Maren voice is deferred (tech-decisions §3).

## Verification
- Cross-check every command + path against the actual repo (don't invent scripts/paths). Run `bun run test` once and cite the real number.

## Progress Log
- 2026-06-14 — Task created (iteration 13)

## Resolution
_(added when complete)_

## Acceptance Criteria
- [ ] `README.md` exists with: pitch, quick-start (commands match package.json), tech, gameplay, structure, status
- [ ] Every command + path verified against the repo (no invented scripts/paths)
- [ ] Links to specs.md, tech-decisions.md, CLAUDE.md
- [ ] No code change; `bun run test` still green
