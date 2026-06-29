# BUG: 040 — Fix mipmap bleed + normal-map import hint on licensed Labrador textures (P1-1 / P1-9)

**Status**: Backlog
**Created**: 2026-06-30
**Type**: BUG (in-engine partial mitigation — import-file changes only, no scripts touched)
**Priority**: Medium — reduces "hairline seam" contribution from mipmap bleed and
corrects normal map decoding; partial fix for the P1-1/P1-9 coat seams (routed from
SPIKE 039). Does NOT close the primary tangent-seam (owner-gated; see FLAGS.md).
**Labels**: bug, visual, phase-1, import, materials, p1-1, p1-9
**Source**: SPIKE 039 — routing decision "partial in-engine mitigation"
**Estimated Effort**: Small

## What it addresses (from SPIKE 039 findings)

Two import-file misconfigurations exacerbate the coat seam visibility on the licensed
Labrador, independently of the primary tangent-seam (which is owner-gated):

1. **Albedo mipmap bleed** (`dog_licensed_Labrador_Albedo.png.import`,
   `mipmaps/generate=true`). The albedo UV island boundaries have zero-alpha background
   pixels right at the edge (confirmed: 1,166 zero-alpha pixels at the belly island's
   left edge, U 0-5%). With mipmaps enabled, the mipmap chain averages these
   zero-alpha/dark border pixels into adjacent coat texels at lower mip levels,
   producing a faint darkening band visible at native phone size. Setting
   `mipmaps/generate=false` eliminates this contribution.

2. **Normal map import hint wrong** (`dog_licensed_Labrador_Normal.png.import`,
   `compress/normal_map=0`). The normal map should be imported with
   `compress/normal_map=1` so Godot applies the correct RGTC compression and
   normal-map GPU hint. With `=0` it's imported as a generic RGBA texture, which may
   degrade the normal decode at the shader level. Fixing this correctly sets the
   texture hint to `HINT_NORMAL_MAP` in the shader, which can reduce the intensity of
   the tangent-seam artifact.

Neither change touches `scripts/`, `scenes/`, or the licensed GLB — these are
`.import`-file edits only. They travel with the build (import settings are committed and
affect the exported PCK).

## Technical approach

### Change 1: disable mipmaps on albedo

In `assets/models/dog_licensed_Labrador_Albedo.png.import`:
```
mipmaps/generate=false    # was: true
```

This prevents zero-alpha border pixels at UV island edges from bleeding into coat texels
at lower mip levels. The texture is 2048×2048 on a phone-portrait viewport (~390px
wide), so the dog occupies roughly 200px at most — mip level 3–4 is active, and that's
exactly where the bleed is most visible.

### Change 2: correct normal map import hint

In `assets/models/dog_licensed_Labrador_Normal.png.import`:
```
compress/normal_map=1    # was: 0
```

This tells Godot to import the texture as a normal map, enabling correct RGTC
compression and the `HINT_NORMAL_MAP` shader flag. Correct normal-map decoding should
reduce the apparent intensity of the tangent-seam shading bands.

## What this does NOT fix

The primary cause of both symptoms — the **UV-island MikkTSpace tangent divergence** at
the body centreline (UV gap up to 0.904, two halves of the body mapping to opposite
atlas corners) — is baked into the licensed GLB and requires an owner action (re-export
with per-vertex tangents baked, or re-bake the normal map). See FLAGS.md for the
informed flag. This task only reduces the mipmap bleed contribution.

## Before / After

- **Before**: "hairline" darkening band at the UV island boundary is visible at native
  phone size (mipmap bleed + wrong normal decode); hard shading seam also present.
- **After this task**: mipmap bleed component eliminated; normal map decoded correctly.
  The hard tangent seam at the belly centerline may be less intense. Hairline hairline
  "arc" seams on the flanks may be reduced at phone-native distance.
- **The remaining artifact** (hard shading band / sliver between legs) will still be
  present because it is tangent-seam-driven, not mipmap-driven.

## Test first (TDD gate)

Because these are `.import`-file changes with no GDScript logic, there is no headless
unit test to write (Godot's import system is editor/export-time, not runtime).
The acceptance gate is **Visual Review**: a magnified capture from the licensed web
build that shows reduced seam visibility vs. the 039 spike baseline captures.

Structural smoke test: `verify.sh` must be green after the import changes (the import
re-runs on the next Godot editor open / export, which `verify.sh` does via the export
leg).

## Acceptance Criteria

- [ ] `assets/models/dog_licensed_Labrador_Albedo.png.import` has `mipmaps/generate=false`.
- [ ] `assets/models/dog_licensed_Labrador_Normal.png.import` has `compress/normal_map=1`.
- [ ] `nix develop -c bash verify.sh` green (import · boot · test · export).
- [ ] **Visual Review**: a magnified capture (`041-mipmap-fix-chest.png` /
      `-sliver.png`) from the local licensed web build shows the hairline seam is
      visibly reduced vs. `.screenshots/039-spike-bellyseam.png` baseline. PO pixel
      sign-off required (or a before/after 4× crop showing the improvement).
- [ ] The hard belly-center shading band (owner-gated tangent seam) is documented as
      still present — this task does not claim to fix it.
- [ ] No `scripts/` or scene files modified (import-file-only change).
