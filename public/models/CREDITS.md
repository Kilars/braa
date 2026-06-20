# Model credits

## `dog.glb` — PLACEHOLDER (temporary)

- **Current file:** a CC0 / Public-Domain low-poly dog (via Poly Pizza), used
  **only** to prove the imported-model pipeline (tasks 078/079) behind the
  default-off `renderConfig.importedDog` flag. CC0 = no attribution required; it
  is safe to commit.
- **To be replaced by:** the licensed **Labrador from "Dogs Big Pack"** (CGTrader /
  Sketchfab, Royalty-Free) — **purchased and dropped** at the repo root as
  `Labrador_FBX.rar` (2026-06-19). **Remaining step: convert FBX → glb** and stage it
  here as `dog.glb`. See [`tech-decisions.md` §3a–§3c](../../.docs/tech-decisions.md).

⚠️ **License note for the real asset:** the Dogs Big Pack Royalty-Free license (like
TurboSquid / Unity Asset Store) permits the model **embedded in a compiled app** but
**forbids letting end-users extract the raw file**. The Capacitor native build bundles
it compiled (clean); a raw web-PWA serves the `.glb` fetchable (gray area). Keep the
licensed `.glb` out of the web-PWA build, or gate it to the native app — decide PWA
scope before shipping the bought model. The placeholder above is CC0 and unaffected.
