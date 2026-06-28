# Bra! — Design & Decisions

This repository holds the **design and decision record** for **Bra!**, a
mobile-only dog-training timing game.

- [specs2.md](specs2.md) — functional spec v2 (user stories, phased).
- [adr/](adr/README.md) — Architecture Decision Records (0001–0006).
- [process/](process/README.md) — the mother/father prompts + runner for the v2
  autonomous build loop (builds the game here from `specs2.md`).

## Provenance

Migrated 2026-06-26 from the original game-prototype repo. That prototype
(Babylon.js PWA + assets) is **deprecated**; its full history is preserved on the
[`deprecated-game`](https://github.com/Kilars/braa/tree/deprecated-game) branch
of this same remote, and in the local `bra` working copy. A few links in the docs
below point into that branch for files that stayed behind — `specs.md` (v1),
`content-catalog.md`, `CLAUDE.md`, and some task-board / asset references.
