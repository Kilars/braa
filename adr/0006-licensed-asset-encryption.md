# ADR-0006: Licensed asset protection — encrypted PCK on public web

- **Status:** Accepted
- **Date:** 2026-06-26
- **Deciders:** Lars (owner), Claude

## Context

ADR-0005 ships a **public** repo deployed to **public GitHub Pages**. Pages serves
the build's `.pck` as a fetchable file, so an embedded licensed model (ADR-0002's
Labrador) would be publicly extractable — beyond the "compiled-app bar" ADR-0002
relied on. The owner chose to keep the realistic Labrador on public web with a
good-faith licensing effort: **option C — encrypt the PCK.**

## Decision

- **Encrypt the Godot PCK for the licensed (Labrador) web build.** Build **custom
  Godot export templates from source** with `SCRIPT_AES256_ENCRYPTION_KEY` (including
  the web/wasm template) and export with encryption enabled.
- **PWA/offline is unaffected** (verified-by-design): the encrypted `.pck` is
  precached by the service worker and decrypted in-engine at load; the key is baked
  into the (also-cached) `.wasm`, so it works fully offline and installs as a PWA
  exactly like the plain build. Encryption is invisible to the player.
- **The default/CC0 public build is NOT encrypted** — official export templates, no
  custom build. Two build profiles result:
  1. **Public default** = CC0 dog, official templates, no encryption.
  2. **Licensed** = encrypted `.pck`, custom templates, licensed asset + key from
     secrets.
- **Asset & key handling:** the licensed `.glb` stays **gitignored** (never in the
  public repo, ADR-0005); it is injected into the licensed CI build from a
  **non-public source** (GitHub Actions secret / private artifact). The encryption
  key is a **CI secret** (it still ends up in the shipped wasm — see cost).

## Consequences

- **Good:** realistic Labrador on public web with a raised extraction bar and a
  documented good-faith license effort; identical PWA/offline UX to the plain build.
- **Cost:** a **from-source custom-template build in CI** (extra pipeline + upkeep
  per Godot version); **deterrence, not DRM** — on a public site both the encrypted
  `.pck` and the key-bearing `.wasm` are downloadable, so a determined party can
  extract the key and decrypt.
- **Amends ADR-0002** (its "no AES encryption" web-licensing clause) and **resolves
  the open licensing fork in ADR-0005** (selects C over A/B).
## Implementation (2026-06-28)

Built as `.github/workflows/deploy-licensed.yml` (+ `tools/web_boot_check.mjs`).
Decisions made while implementing:

- **Version match is load-bearing.** The export tool (flake-pinned Godot, `4.6.3.stable`)
  and the from-source template must be the *same* engine version or the PCK fails to
  decrypt (MD5 mismatch). The template is built from `godotengine/godot` tag `4.6.3-stable`
  with **emscripten 4.0.11** (Godot's own pinned web toolchain for that tag, read from its
  `web_builds.yml`); the workflow asserts the engine version before exporting.
- **Asset delivery: encrypted blob in the repo** — *amends* the "injected from a non-public
  source (secret / private artifact)" clause above. The ~19 MB glb can't be a GitHub secret
  (48 KB cap), so it rides in the repo as an AES-256 `openssl` blob
  `assets/models/dog_licensed.glb.enc` (gitignore un-ignores only the `.enc`; the raw glb
  stays out) and is decrypted in CI. **One secret total:** `GODOT_SCRIPT_ENCRYPTION_KEY` is
  reused as the template bake key, the export key, *and* the openssl passphrase. Trade-off
  accepted: ciphertext in git history; bends ADR-0002 to "encrypted-only in the public repo."
- **Proven in CI, not self-certified.** A headless-Chromium boot of the encrypted bundle
  gates the artifact: reaching `window.__appReady` proves the custom-key template decrypted
  the PCK; console signals prove it's the licensed dog and it Sitts. A negative test also
  asserts the empty-key runtime *cannot* open the PCK.
- **Safe rollout.** `workflow_dispatch` only; uploads an artifact by default and publishes
  to Pages only on an explicit `publish=true`, after validation — the live CC0 site is never
  replaced by an unproven build. The compiled template is cached so the ~45-min build runs
  once, not per deploy.
