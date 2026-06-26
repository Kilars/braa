# ADR-0005: Repo & project structure

- **Status:** Accepted (new repo + public + GitHub Pages, owner-decided)
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
- **Public repo, deployed to GitHub Pages.** CI (GitHub Actions) exports the Godot
  **Web** build and publishes it to Pages. Two consequences fall out:
  - **Single-threaded export is required** (ADR-0001/0004): Pages can't set the
    COOP/COEP cross-origin-isolation headers that multi-threaded Godot web needs.
    Our single-threaded choice is already compatible — Pages reinforces it.
  - **Base path:** a project Pages site serves at `user.github.io/<repo>/`, so the
    export must use the matching base/relative paths.
- **⚠️ Licensing tension with ADR-0002 (must reconcile — see Consequences).** A
  public repo + public Pages means the licensed Labrador is publicly fetchable in
  the deployed build, which is beyond ADR-0002's "compiled-app bar." Default taken
  here: **the public Pages build ships only the CC0 placeholder**; the licensed
  Labrador is reserved for a license-safe channel. Owner to confirm (escalated).
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

- **Good:** clean slate, no transitional churn, docs co-located with code; free,
  simple hosting on GitHub Pages; public code is fine since only CC0/placeholder
  assets are tracked.
- **Cost:** git history of the design discussion stays in `braa` (link it from the
  new repo's README); a one-time docs migration.
- **⚠️ Open licensing fork (escalated to owner) — conflicts with ADR-0002's "ship
  the licensed Labrador":** a public Pages deployment serves the build's `.pck`
  fetchably, so any embedded licensed model is publicly extractable (worse than an
  app-store binary). Options:
  - **(A) CC0 on public Pages** *(default here)* — licensed Labrador only via a
    license-safe build later (native, or a private/encrypted build). Safe; the
    public game looks less polished than the Labrador.
  - **(B) Licensed on public Pages anyway** — accept the deterrence-not-DRM
    exposure as the owner did before (riskier on an open website than in a binary).
  - **(C) Encrypt the `.pck`** for the licensed build — raises the bar; the key
    still ships in the client, so still not true DRM.
  Resolve before any licensed-model web deploy; **ADR-0002 may need superseding** to
  match whichever is chosen.
- **Follow-up:** create the repo + scaffold `project.godot`, the folder skeleton, a
  `.gitignore`, the Web export preset, and a **GitHub Actions → Pages** deploy
  workflow; copy docs over and add a back-link to the `braa` design history.
- **Reversible:** if an in-place or private choice is later preferred, supersede this
  ADR — no code depends on it yet.
