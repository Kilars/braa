# Model credits

## `dog.glb` — PLACEHOLDER (temporary)

- **Current file:** a CC0 / Public-Domain low-poly dog (via Poly Pizza), used
  **only** to prove the imported-model pipeline (tasks 078/079) behind the
  default-off `renderConfig.importedDog` flag. CC0 = no attribution required; it
  is safe to commit.
- **To be replaced by:** the licensed **Labrador from "Dogs Big Pack"** (CGTrader /
  Sketchfab, Royalty-Free) — **purchased and dropped** at the repo root as
  `Labrador_FBX.rar` (2026-06-19). **FBX → glb conversion is now DONE** (2026-06-20):
  the rigged mesh + 113 animation clips convert cleanly via `node-unrar-js` + `fbx2gltf`
  (recipe in [`tech-decisions.md` §3e](../../.docs/tech-decisions.md)); artifacts sit in
  gitignored `models-build/`. **Two things still block making it the live `dog.glb`:**
  (1) the pack's albedo texture (`Labrador_Albedo1.png`) is **missing from the drop** →
  the model is currently untextured/white, so the owner must supply the texture folder;
  (2) the web-PWA licensing decision before it ships. See §3b/§3d/§3e.

⚠️ **License note for the real asset:** the Dogs Big Pack Royalty-Free license (like
TurboSquid / Unity Asset Store) permits the model **embedded in a compiled app** but
**forbids letting end-users extract the raw file**. The Capacitor native build bundles
it compiled (clean); a raw web-PWA serves the `.glb` fetchable (gray area). Keep the
licensed `.glb` out of the web-PWA build, or gate it to the native app — decide PWA
scope before shipping the bought model. The placeholder above is CC0 and unaffected.
