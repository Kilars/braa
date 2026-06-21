# FEATURE: Pack/encrypt the licensed Labrador for the web build (decrypt-in-memory load)

**Status**: Ready. Implements the owner-confirmed distribution decision (tech-decisions
§3d, re-confirmed 2026-06-20 in an interactive session). The **textured licensed glb now
exists** (`models-build/out_anim.glb`, 19.7 MB, albedo+normal embedded, 113 clips, via
`scripts/skin-dog-model.mjs`). Gate 1 (texture) and the FBX→glb conversion are both DONE.
This is the **last slice before the real Labrador can render on the live web-PWA**.
**Created**: 2026-06-20 (interactive session)
**Priority**: High
**Labels**: render, assets, build, licensing, security, epic:pokemon-go-visuals
**Estimated Effort**: Large

## Context & Motivation

The Dogs Big Pack Royalty-Free license permits the model embedded in a compiled app but
**forbids end-users extracting the raw file** (§3b). A plain `/models/labrador.glb` on
GitHub Pages is `curl`-able → violates the clause. `src/render/dogModelSource.ts` currently
resolves the licensed model to a **plain fetchable URL** — that path must NOT ship as-is.

Per §3d the agreed mitigation is **pack/encrypt the `.glb`, decrypt in memory at load time**.

> **Honest security note (record, do not oversell):** the decrypt key ships in the client
> bundle, so this is **deterrence, not DRM** — a determined user can still recover the glb.
> It defeats casual raw-fetch (satisfies the "not redistributed in an open format" letter)
> and matches the practical bar of a compiled native bundle. Document it as best-effort.

## Current State

- `dogModelSource.ts` — `resolveDogModelSource({allowLicensed, licensedAssetPresent})`
  returns `/models/labrador.glb` (plain) or the CC0 `/models/dog.glb`. No encryption.
- `dogModelLoader.ts` — fetches a URL and hands it to Babylon. No decrypt path.
- `models-build/out_anim.glb` — the textured licensed glb (gitignored). Source of truth.
- CC0 `public/models/dog.glb` ships plain (fine — it's CC0).

## Desired Outcome

- **Build step** (e.g. `scripts/pack-dog-model.mjs`): AES-GCM-encrypt `models-build/out_anim.glb`
  → an opaque artifact emitted into the build output (NOT a plain `.glb`; e.g. `dog.pack`).
  Plaintext licensed glb must never land in `public/`, `dist/`, or git.
- **Pure, TDD-covered crypto round-trip** (`encryptAsset`/`decryptAsset`, Web Crypto
  AES-GCM): `decrypt(encrypt(bytes)) === bytes`; wrong key/tampered blob → rejects.
- **Runtime**: fetch the packed artifact, decrypt to an `ArrayBuffer` in memory, load into
  Babylon **from memory** (Blob/ObjectURL or `SceneLoader.ImportMesh` from buffer) — never
  expose a plaintext glb at a fetchable URL.
- `resolveDogModelSource` returns an encrypted-source descriptor on the web/licensed path;
  CC0 fallback unchanged. Existing `dogModelSource.test.ts` stays green.

## TDD slices (vertical, one test → impl → repeat)

1. `encryptAsset`/`decryptAsset` round-trip (pure) — happy path, then wrong-key rejection.
2. `resolveDogModelSource` returns the packed descriptor when `allowLicensed && present`.
3. Loader: given a packed buffer + key, yields a Babylon-loadable in-memory source (no URL).
4. Build glue: `pack-dog-model.mjs` emits the encrypted artifact from `models-build/`.

## Visual Review (blocking)

Once wired, render the **real Labrador on a phone-portrait viewport** behind the existing
`importedDog` flag and confirm: correct fur (not white/metallic), animations play, framerate
OK on mobile. Flip the flag on only if it Visual-Reviews ≥ the procedural baseline (079 rule).

## Gates

- Gate 1 (texture) — **RESOLVED** (textured glb exists).
- Gate 2 (license scope) — **DECIDED**: pack/encrypt on web (§3d, owner-confirmed 2026-06-20).
- No remaining owner gates. This is now pure implementation.

## Resolution (2026-06-20) — DONE

All four TDD slices implemented test-first; full verify gate green (typecheck 0 ·
729 tests · clean build · e2e smoke + full-loop). See tech-decisions **§3i**.

- **Slice 1** — `src/render/assetCrypto.ts` (+ `.test.ts`, 7 tests): AES-256-GCM
  `encryptAsset`/`decryptAsset`, format `IV(12) ‖ ciphertext+tag`. Covers lossless
  round-trip, fresh-IV-per-call, wrong-key / tampered / truncated → reject.
- **Slice 2** — `resolveDogModelDescriptor()` in `dogModelSource.ts` (+3 tests):
  `{ kind:'plain', '/models/dog.glb' }` (CC0) or `{ kind:'packed', '/models/dog.pack' }`
  (licensed web). **Decision:** added a *new* descriptor fn rather than changing
  `resolveDogModelSource` (which still returns a `.glb` string) so the existing
  `dogModelSource.test.ts` stays green exactly as required.
- **Slice 3** — `loadPackedDogModel` / `packedToGlbFile` in `dogModelLoader.ts`
  (+2 tests): decrypt → in-memory `File('dog.glb')` → Babylon glTF loader. No plaintext
  glb at any fetchable URL. Babylon imports stay dynamic (lazy `babylon-loaders` chunk).
- **Slice 4** — `scripts/pack-dog-model.mjs` (`bun run pack-dog-model`): encrypts
  `models-build/out_anim.glb` → `public/models/dog.pack`, self-verifies the round-trip.
  Shared key in `src/render/dogPackKey.ts` (single source of truth; **deterrence not DRM**,
  ships in bundle). `public/models/dog.pack` gitignored (regenerate on demand).
- **Wiring** — `scene.ts` consumes the descriptor and branches plain vs packed. Committed
  default unchanged (`allowLicensed:false` → CC0 plain glb). DEV-only `?licensedDog=1`
  (`devOverrideLicensedDog`) routes the packed path for review.

**Visual Review — packed Labrador renders with correct fur (deliverable proven):**
DEV `?importedDog=1&licensedDog=1` → `/models/dog.pack` fetched (200, 18.7 MB), decrypted
in memory, Labrador rendered with **matte tan fur (not white/metallic)**. The encryption
+ decrypt-in-memory pipeline works end-to-end.

**Flag stays OFF (gate not met, by design):** the imported render is *not yet ≥ the
procedural baseline* — the rig faces away from camera and the 113 embedded clips aren't
played. Both are imported-mesh **framing/animation** concerns (tasks 079/080), out of this
encryption task's scope. Per the 079 rule, `renderConfig.importedDog` is left OFF.
**Follow-up to flip it:** base yaw on the framing pivot (face camera) + play AnimationGroups,
then re-Visual-Review. Recommend a new backlog task for that.
