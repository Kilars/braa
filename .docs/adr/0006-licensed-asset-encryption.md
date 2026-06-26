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
- **Follow-up:** stand up the two build profiles in the GitHub Actions → Pages
  workflow; store the licensed asset + key as secrets; verify the encrypted build
  installs + plays offline on Chrome.
