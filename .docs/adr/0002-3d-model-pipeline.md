# ADR-0002: 3D dog model & asset pipeline

- **Status:** Accepted
- **Date:** 2026-06-26
- **Deciders:** Lars (owner), Claude

## Context

The game needs a realistic, breed-recognizable 3D dog (specs §The Dog) running in
Godot (ADR-0001). We currently **own only the Labrador** from the *Dogs Big Pack*
($30, bought as a vertical-slice first). The pack offers more breeds, all sharing
**one canine rig and the same 100+ animation library**. A CC0 placeholder dog also
exists. Owner is willing to **buy additional breed models** as the catalog grows.

## Decision

- **Ship the licensed *Dogs Big Pack* Labrador** as the realistic dog.
- **Add breeds by buying each breed's model from the same pack** as needed. Because
  same-pack breeds share the rig + animation set, each new breed drops in with the
  **same trick clips and no retargeting**. This is the "direct per-breed models"
  approach — chosen over a shared-rig/morph/retarget pipeline, since the pack
  already delivers cross-breed rig + clip consistency.
- **Import path:** FBX → glTF → Godot (Godot's native glTF import; FBX2glTF or
  Blender for the conversion). Import the pack's PBR maps with the model.
- **Web / licensing:** bake assets into the exported Godot **`.pck`/binary** — not
  a fetchable raw file. This satisfies the Royalty-Free "no raw-file extraction"
  clause at the compiled-app bar, so **no AES encryption** (the old Babylon web
  workaround is dropped). Deterrence, not DRM — a `.pck` is still unpackable with
  tools.
- **CC0 placeholder:** dev-only fallback, **not shipped**.

## Consequences

- **Good:** highest fidelity; consistent rig + animations across breeds with no
  retargeting; simple native import; simpler licensing than the Babylon web path.
- **Cost:** each new breed is a **per-breed purchase** + content work; we're scoped
  to the pack's breeds. The pack has **no Poodle** (already dropped from the
  catalog); any non-pack breed would need its own sourcing decision (new ADR).
- **Money gate:** buying additional breed models is owner-approved spend (Labrador
  already bought).
- **Follow-up:** re-verify the Labrador's textures import correctly into Godot
  (the legacy Babylon path once had a missing albedo; textures were later supplied).
