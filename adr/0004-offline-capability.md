# ADR-0004: Offline capability

- **Status:** Accepted
- **Date:** 2026-06-26
- **Deciders:** Lars (owner), Claude

## Context

Spec X-7 requires the game to be **fully playable offline after first load** (e.g.
on a plane), with local saves and no backend. ADR-0001 ships a Godot 4 web/WASM
build on Chrome; ADR-0002 bakes all assets into the `.pck`. This ADR fixes *how*
offline is delivered — the piece previously folded into ADR-0001.

## Decision

- **Distribute as a PWA via Godot's built-in web-export "Progressive Web App"
  option.** It generates a service worker that **precaches every exported file**
  (engine `.wasm`, the `.pck` with all baked assets, loader JS, icons), so after one
  successful online load the game runs fully offline and is installable to the home
  screen.
- **Saves:** use Godot `user://` (IndexedDB-backed on web). Flush after each write
  and request **persistent storage** (`navigator.storage.persist()`) so saves and
  the cache aren't evicted under storage pressure.
- **Updates:** the service worker re-caches on the next **online** visit; offline
  sessions run the last cached version. No live-update-while-offline requirement.
- **First load needs connectivity:** the full bundle must download once (inherent to
  the heavy WASM payload, ADR-0001 cost). Offline applies only afterward.
- A custom (e.g. Workbox-style) service worker is **not** adopted now — only if
  Godot's built-in precache proves insufficient.

## Consequences

- **Good:** offline + installable come essentially free from the engine export; one
  `.pck` means "cache the bundle" caches all gameplay assets; no backend to be
  offline-tolerant about.
- **Cost / risks:** heavy first-load download before offline works; players get
  updates only on reconnect (stale-until-online — acceptable); storage eviction is
  possible but mitigated by `persist()`.
- **Verify on device:** confirm an installed PWA launches and plays in airplane mode
  on Chrome (Android), and that a save survives a fully-offline relaunch — part of
  the X-7 acceptance check.
