# ADR-0001: Tech stack & animation strategy

- **Status:** Accepted
- **Date:** 2026-06-26
- **Deciders:** Lars (owner), Claude

## Context

Bra! is an **animation-heavy, mobile-portrait** dog-training game: a realistic 3D
skeletal dog (glTF/FBX clips) plus a lot of UI juice. Distribution should be
simple (web/PWA preferred, native not required). The deciding factor is the
**animation authoring story at scale** — many clips, smooth blending, state-driven
transitions (Phase 7). Target browser is **Chrome** (Chromium); Safari is
best-effort only.

## Decision

**Build on the Godot 4 engine, exported to web (WASM, single-threaded).** The whole
game — 3D, UI, and juice — lives in Godot; animation uses Godot's
**AnimationPlayer / AnimationTree** (visual state machines, blend trees). Godot 4.3+
single-threaded web export removes the SharedArrayBuffer / COOP-COEP hosting
requirement, so it ships as a simple static web build / PWA.

This **supersedes the prior Babylon.js + DOM/CSS direction**: there is no DOM
overlay, so the earlier "CSS + GSAP for UI juice" choice **does not apply** — UI and
juice are Godot-native.

## Consequences

- **Good:** best-in-class animation tooling (state machines, blend spaces) for the
  core "lots of clean, blended animations" need; one runtime for 3D + UI; simple
  web/PWA distribution on Chrome.
- **Cost:** mobile **Safari** is Godot web's weak spot — explicitly out of scope
  (Chrome-targeted). Heavier WASM first-load than a JS web app. Implementation may
  live in a **separate repo**; this decision is engine-level, not a migration plan
  for the current Babylon code.
- **Constraint — must satisfy offline (spec X-7):** the build must be **fully
  playable offline after first load** (e.g. on a plane). The self-contained WASM
  export + local `user://` saves make this largely inherent; the one open piece is
  a **PWA precache strategy** that caches the whole WASM bundle + assets on first
  load (heavier payload vs browser cache limits). **Now its own record: ADR-0004.**
- **Follow-ups:** ADR-0002 — 3D dog model & asset pipeline (glTF/FBX import into
  Godot; the licensed Labrador survives the engine change). A later ADR may fix the
  scripting language (GDScript vs C#) — GDScript is the working assumption.
