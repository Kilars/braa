# FEATURE: 025a — encrypted `Web Licensed` export preset + ADR-0006 gate-sizing spike

**Status**: Done — 2026-06-28. The export-*side* of ADR-0006 is built and verified;
slice carved out of 025 so the owner-gated remainder (from-source templates + secrets +
publish flip) is precisely scoped and isolated.
**Parent**: 025 (encrypted licensed-asset CI deploy) — stays in-progress, owner-gated.
**Labels**: pipeline, godot, ci, licensing
**Effort**: Small (verifiable export-side only; the heavy template build is the parent's
owner-gated remainder, deliberately NOT attempted blind).

## What shipped (all locally verified)

- **`export_presets.cfg` → `[preset.1] "Web Licensed"`**: a copy of `Web` with
  `encrypt_pck=true`, `encrypt_directory=true`, `encryption_include_filters="*"`.
  Inert for every existing path — the local verify gate and `deploy.yml` export `"Web"`
  by name, so they never touch it and need no key. **Verified** the control `Web` export
  + boot still pass (`[Bra!] scaffold ready`), 90 tests green, full verify gate green
  with the preset present.
- **`.docs/tech-decisions.md`**: the verified findings + the precise owner runbook.

## Spike findings (verified, reproducible — see tech-decisions.md for commands)

1. Official templates **encrypt fine**: exporting `Web Licensed` with
   `GODOT_SCRIPT_ENCRYPTION_KEY` set → exit 0, real encrypted PCK
   (`pack_flags` bit 0 `PACK_DIR_ENCRYPTED`: plain `0x2` → licensed `0x3`).
2. Official templates **cannot decrypt** a custom-key PCK: booting it →
   `Can't open encrypted pack directory / Cannot open resource pack`.
3. `GODOT_SCRIPT_ENCRYPTION_KEY` is **export-time only** — setting it at runtime does
   not help; the runtime key is **compiled into the template**. ⇒ ADR-0006's
   from-source custom-template build is genuinely required (now empirical, not assumed).

## Why the rest is left to the owner (not blocked — precisely scoped)

The remaining work is irreducibly owner/secret/CI-gated and **cannot be validated
here**: it needs (a) the secret AES key, (b) the secret licensed `.glb`, and (c) a
from-source web/wasm template build with the key baked in. Writing an untested
emscripten/scons (or nix-override) template build and self-certifying it would be
fabricating an unvalidatable artifact — explicitly avoided. The exact, verified runbook
is in `.docs/tech-decisions.md`; the parent 025 card carries it forward.

## Verify

`nix develop -c bash verify.sh` → green (import · boot · test · export), 90 tests.
Public CC0 deploy + local gate unchanged.
