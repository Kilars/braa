# ADR-0005: Repo & project structure

- **Status:** Accepted (defaults chosen non-interactively — flip on request)
- **Date:** 2026-06-26
- **Deciders:** Lars (owner), Claude

## Context

ADR-0001 (Godot 4) is a clean break from the Babylon/TS code in the current `braa`
repo. We need to decide where the Godot project lives, its layout, and how the
licensed asset (ADR-0002) is handled in version control. The owner flagged earlier
that a separate repo is likely.

## Decision

- **New dedicated Godot repo.** Avoids carrying dead Babylon/TS/Vite/Bun files;
  clean Godot project layout. The existing `braa` repo is kept as **archived
  reference** (history + legacy `tech-decisions.md`).
- **Design docs live with the code.** Move `specs2.md`, `content-catalog.md`, and the
  `adr/` folder into the new repo as the single source of truth. (Until migrated,
  they remain on the `braa` PR branch.)
- **Private repo.** Simplest for a commercial-leaning game with a licensed asset —
  the Labrador can't leak. Can open up later.
- **Godot project layout** (conventional):
  ```
  project.godot          # at repo root
  scenes/                # .tscn — training page, dog, UI
  scripts/               # .gd (typed GDScript, ADR-0003)
  assets/
    models/              # CC0 placeholder committed; licensed .glb gitignored
    audio/               # marker voice / SFX
  addons/                # plugins if any
  docs/  (specs2, content-catalog, adr/)
  export_presets.cfg     # Web (PWA) preset, ADR-0004
  ```
- **Asset/licensing in VCS:** `.gitignore` the licensed model and any baked
  `.pck`/encrypted artifacts; commit only **CC0/placeholder** assets. The licensed
  Labrador enters only the export/build, never the tracked tree (ADR-0002).

## Consequences

- **Good:** clean slate, no transitional churn, licensing-safe by construction,
  docs co-located with code.
- **Cost:** git history of the design discussion stays in `braa` (link it from the
  new repo's README); a one-time docs migration.
- **Follow-up:** create the repo + scaffold `project.godot`, the folder skeleton, a
  `.gitignore`, and the Web/PWA export preset; copy docs over and add a back-link to
  the `braa` design history.
- **Reversible:** if a public or in-place choice is preferred, this ADR is superseded
  by a new one — no code depends on it yet.
