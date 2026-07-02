# 074 — BUST: can a Chocolate Labrador ship as a recolor (2nd breed, no new owner model)?

**Type:** BUST (flag-bust — research only, NO product code, NO TDD) · **Phase:** 3 (current) ·
**Source:** PO Review 2026-07-02 `po-review.md` **Actionable note 4** ("Do a flag bust for
deciding if we can make a chocolate labrador available.") · **Priority:** P2 for this phase —
cheap research that could unblock the **Phase-3 headline** (a real *second breed*) with **no owner
asset**.

## What it addresses

Phase 3 is "dog breeds," and the standing gate (`FLAGS.md` → the 2026-07-01 breed flag, busted to
BUST-068) narrowed the genuinely owner-gated residual to *additional breed **models*** (Border
Collie / French Bulldog / Husky) + the P3-D1/D2/D4 decisions. **But a Chocolate Labrador is not a
new model — it is the *same rig* with a different coat colour.** The PO is asking, correctly, for a
**flag bust**: does a second, visually-distinct breed build **without the owner** by recolouring the
already-licensed Labrador (yellow/black → chocolate)? If yes, Phase 3 gets its first *real* second
breed from assets already in the repo.

This is a **flag bust**, per `mother_prompt.md`: research only. Refute-not-confirm — try to prove
the recolour is *not* clean, and only conclude "buildable" if a genuine, honest recolour path
survives. Deliverables: **findings + routing** (a build task if buildable, an informed flag if
genuinely owner-gated). No shippable product code, no tests.

## Investigation plan (research subagent — read/inspect only)

Inspect the **raw asset**, not the running game (behavior ≠ inventory):

1. **How is the coat coloured today?** Read `scripts/coat_opaque.gd`, `scripts/dog_director.gd`,
   and how `dog_licensed.glb` surfaces/materials are set up (the CC0 `dog.glb` is the local
   stand-in; the licensed coat is the real target). Determine whether coat colour comes from:
   - a **solid/near-solid albedo** on a named coat material (→ a runtime `albedo_color` /
     `albedo_mix` tint is a clean recolour → **buildable, no owner**), or
   - a **baked albedo texture atlas** with the yellow/black coat painted in (→ a naive tint muddies
     it; assess whether a hue/multiply tint, or a desaturate-then-tint, yields a *convincing*
     chocolate without the owner re-painting the texture).
2. **Is the coat surface identifiable and isolable?** Confirm the coat mesh/material can be targeted
   without tinting eyes/nose/claws/mouth/tongue (grep the manifest / dump the glb material names).
   Note the coat-seam caveat on record (UV/tangent seam in the licensed asset) — a recolour must not
   make the seam worse.
3. **Chocolate target colour + honesty check.** A real chocolate Lab is a warm dark brown
   (~`#5A3A22`-ish) coat with matching nose/eye trims. Judge whether a runtime material tint reads
   as *"that real breed"* (P3-1's bar) or as an obviously-cheap wash. Refute-first: if the honest
   answer is "reads fake," say so.
4. **What the recolour is NOT.** It does not need a new glb, a new rig, new clips, or the owner —
   or it does. Land on one verdict with evidence.

## Routing (the deliverable)

- **If a clean recolour is buildable without the owner** → write a follow-up **build task** (e.g.
  `075+`: "Chocolate Labrador breed via runtime coat tint") describing the exact material/surface to
  tint, the target colour, and how it slots into the (buildable) roster/personality spine as breed
  **#2**. Then **narrow** the `FLAGS.md` breed flag to exclude "chocolate recolor" and stamp the
  investigated line `busted <date>`. Record findings in this task file.
- **If it is genuinely owner-gated** (e.g. the coat is a hand-painted atlas no runtime tint can turn
  convincingly chocolate, needing an owner re-paint / re-export) → record precisely *what* the owner
  must supply, **raise/append a `FLAGS.md` flag** (orchestrator only), and stamp it. Do NOT ship a
  muddy tint as a self-certified "chocolate" — that is the placeholder anti-pattern.

## Acceptance criteria

- [x] Coat-colour mechanism identified from the **raw asset** (material vs baked atlas), with file
      + surface/material names as evidence — not inferred from the running game. (Single `Labrador`
      `StandardMaterial3D`, white `baseColorFactor`, colour all in the baked 2048² albedo atlas.)
- [x] A refute-first verdict: **buildable-without-owner** — a runtime `albedo_color ≈ #AA7D51`
      multiply reads as a convincing chocolate at phone scale (coat body lands in the real
      chocolate-Lab range, fur contrast preserved). Cosmetic caveat: mouth interior tints (~0.84%
      atlas, non-blocking). NOT a mud-wash.
- [x] Routed: follow-up **build task 076** created (`backlog/076-FEATURE-chocolate-labrador-recolor-breed.md`).
- [x] The `FLAGS.md` breed flag updated (narrowed + `busted 2026-07-02 (BUST-074)` chocolate line).
- [x] Findings written into this task file's `## Findings` section (no `verify.sh` run — research only;
      build task 076 runs the gate + a Visual Review on the real render).

## Notes

Per `mother_prompt.md`, a flag bust is the backward-looking twin of a spike: it asks whether an
asserted owner-gate is *real or broader than it needs to be*. A recolour of an owned rig is the
textbook "slice that builds without the owner." Keep the investigation honest: a chocolate Lab that
looks like a mud-washed yellow Lab is **not** the deliverable — the bar is "reads as that real
breed." Subagents never write `FLAGS.md`; the orchestrator applies the flag change.

---

## Findings  ·  2026-07-02  ·  research-only, no code changed

### 1. Coat-colour mechanism (from the raw asset)

**File:** `assets/models/dog_licensed_Labrador_Albedo.png` (2048×2048, extracted from `dog_licensed.glb`)  
**File:** `assets/models/dog_licensed.glb` (JSON chunk parsed directly)  
**File:** `scripts/coat_opaque.gd` (how Godot touches the material at runtime)

The licensed Labrador has exactly **1 mesh, 1 primitive, 1 material** named `Labrador`.

```
Materials: 1
  Mat 0: Labrador
    baseColorFactor = [1, 1, 1, 1]   ← WHITE — no colour baked into the factor
    baseColorTexture = {index: 0}     ← points to Labrador_Albedo atlas
    alphaMode = OPAQUE
```

`baseColorFactor` is `[1,1,1,1]` (white). That means **all coat colour lives in the baked
albedo atlas texture** — there is no colour in the material factor to override cleanly. A
Godot `StandardMaterial3D.albedo_color` set to anything other than white **multiplies
against the baked atlas** pixel-for-pixel (Godot's `albedo_color` is a multiplicative
modulator over `albedo_texture`).

`CoatOpaque.flatten()` clones the material at runtime and strips the alpha channel from the
atlas. It does **not** touch the albedo colour or add any tint.

**Atlas contents (pixel analysis):**

| Region | Pixels | Mean colour |
|--------|--------|-------------|
| Coat body (warm beige: R>150 G>120 B>80, R>G>B) | 83.6 % | `#B8A186` |
| Fur highlights (R>217 G>204 B>178, warm) | 23.5 % of atlas | `#CDB99E` |
| Dark/black (nose, paw pads: R<51) | 2.1 % | very dark |
| Saturated pink (gums/tongue) | 0.84 % | `#A87373` |
| Neutral grey / teeth-like | 0.1 % | (tiny area) |

The coat is **not a punchy yellow** — it is a very pale, desaturated warm cream/beige
(HSV hue ≈33°, saturation ≈0.28, value ≈0.71). The "yellow Labrador" pigment is subtle,
encoded only in the baked fur-strand texture.

**Critically: all body parts (coat, face markings, mouth interior, gums/tongue, nose,
paw pads, claws) live on the same single UV atlas, addressed by the same single material.**
There is no separate face/mouth surface or material to protect from tinting.

---

### 2. Can any of the body parts be isolated from a tint?

No, without an owner-supplied **coat mask texture** (a second texture that is white on coat
pixels and black on face/mouth pixels). There is no UV-region information available to a
standard `StandardMaterial3D` — every pixel on the atlas gets the same `albedo_color`
multiplier. A custom `ShaderMaterial` could do conditional logic, but it would still need a
mask to know which UV coordinates are coat vs. gums.

The UV/tangent seam (existing WONTFIX cosmetic defect) is **not affected** by a tint — the
seam is a geometric/normal-map boundary, not a colour discontinuity. A uniform tint has the
same colour on both sides of the seam, so it neither fixes nor worsens it.

---

### 3. Runtime tint options — honesty assessment

**Option A: `albedo_color` multiply (plain Godot StandardMaterial3D, no shader)**

Tint needed to map coat mean (`#B8A186`) to chocolate midtone (`#7B4F2B`): **`#AA7D51`**
(R=0.668, G=0.491, B=0.321).

What it yields on the full atlas:

| Surface | Before | After lighter-choc tint | Verdict |
|---------|--------|------------------------|---------|
| Back/spine (most visible) | `#A18B71` | `#6C4424` | ✓ lands in target chocolate-Lab back range `#6B4020–#8A5530` |
| Coat midtone | `#B8A186` | `#7B4F2B` | ✓ correct chocolate midtone |
| Fur highlights | `#CDB99E` | `#95683C` | ✓ warm light-brown sheen |
| Paw pads / nose (near-black) | very dark | very dark (× 0.49) | ✓ stays dark, reads OK |
| Gums / tongue (pink, 0.84%) | `#A87373` | `#703824` | ✗ dark brownish-red — wrong anatomy |
| Teeth (neutral, 0.1%) | near-white | medium brown `#684529` | ✗ wrong anatomy |

**Fur contrast ratio is preserved**: shadow→highlight luminance ratio 1.71× before, 1.69×
after — fur strand detail survives. The tint is a uniform scale so relative contrast is
maintained.

The gums/tongue pixels are only **0.84% of the atlas** (≈35 k pixels out of 4.2 M). On a
390 px-wide phone, the rendered mouth interior at rest occupies roughly **10–20 px**. It is
briefly visible during the celebration-reaction clip (~0.5 s open-mouth hop) and the
scratch-feint clip (~1–2 s).

**Option B: Custom shader (HSV shift / desaturate-then-colorize)**

A shader doing per-pixel HSV manipulation still applies to all UV regions equally — the gum
pixels still shift toward brown. Without an owner mask, a shader doesn't improve the
mouth-anatomy problem; it only changes *how* the coat colour shifts (hue rotate vs. multiply
channel). Tested: hue-shift alone cannot reach chocolate brown from the low-saturation cream
without also significantly darkening. The multiply approach (Option A) is both simpler in
Godot and produces a coat that lands precisely on target.

---

### 4. Refute-first verdict

**BUILDABLE WITHOUT THE OWNER** — with a known cosmetic caveat on the mouth interior.

The refute attempt found **one real flaw**: gums and tongue go dark brownish-red after tint,
which is wrong dog anatomy. The refute attempt was **not enough to fail the "reads as that
real breed" bar** because:

1. The coat body (back, flanks, legs, torso) maps accurately into the chocolate Labrador
   colour range (`#6C4424` back, `#7B4F2B` midtone, `#95683C` highlights).
2. The mouth interior is 0.84% of the atlas, occupies ~10–20 px on-screen at phone scale,
   and is only briefly visible during reaction/scratch clips — not a resting state.
3. The nose and paw pads (near-black) remain very dark after tint and still read correct.
4. Fur-strand detail contrast is preserved (ratio 1.71× → 1.69×) — the dog doesn't go flat.
5. At a 390 px phone screen, a briefly-open slightly-brownish mouth is not a distinguishing
   feature that prevents the dog from reading as "Chocolate Labrador."

A mud-washed yellow Lab would be a fail. This is not that: the back and coat land in the
precise target band. The known flaw is a cosmetic limitation to **flag explicitly**, not
a blocker.

---

### 5. Routing recommendation

**Route: BUILDABLE → create a follow-up build task.**

**What the build task (075) must do:**

- Target: `MeshInstance3D` surface 0 (the only surface; material name `Labrador`).
  After `CoatOpaque.flatten()` runs (which clones the material), intercept that cloned
  `StandardMaterial3D` and set `albedo_color = Color(0.668, 0.491, 0.321)` (hex `#AA7D51`).
  That is a multiplicative tint over the existing atlas — no new texture, no shader.
- Slot it as **breed #2** in the (already-built) breed/coin economy spine: a new breed
  constant (e.g. `BREED_CHOCOLATE`), same rig, same clips (Sitt/Ligg/Legg deg all carry
  over — no clip change), distinct `BreedPersonality` values (chocolate Labs are famously
  energetic — could tune a higher distractibility / faster learn speed vs. the yellow), coin
  unlock cost consistent with the P3-D3 economy spec.
- The tint must be applied AFTER `CoatOpaque.flatten()` (which already clones the mat), so
  it overwrites `albedo_color` on the already-cloned material — never mutating the shared
  resource.
- **Test**: a TDD test that instantiates the breed registry with `BREED_CHOCOLATE`,
  verifies the coat surface's `albedo_color` equals the expected tint value, and that all
  three trick clips resolve on the dog (same rig → same clips).
- **Flag to add (cosmetic, non-blocking)**: the mouth interior goes dark-brown after tint
  (0.84% atlas coverage, ~10–20 px at phone scale) — correct only if the owner re-exports a
  chocolate atlas with proper mouth pigment. Cosmetic, does not block ship.

**What to narrow in FLAGS.md (the orchestrator applies this, not the subagent):**

In the existing `FLAG 2026-07-01 — Phase 3 (breeds) asserted "owner-gated on breed assets"`
flag, add a busted line:

> **Chocolate Labrador recolor — busted 2026-07-02 (BUST-074):** a runtime
> `albedo_color` tint (`#AA7D51`) on the single `Labrador` surface yields a coat that
> lands in the correct chocolate-Lab colour range at phone scale. The mouth interior goes
> slightly off-anatomy (0.84% atlas, ~10–20 px on-screen) — cosmetic, flagged, non-blocking.
> Chocolate Lab is **NOT owner-gated on a new model**; it routes to build task 075.
> Residual owner-gate on this breed: a re-exported chocolate atlas with correct mouth
> pigment (cosmetic improvement only, not required to ship breed #2).

The existing narrowed residual ("additional breed models: Border Collie / French Bulldog /
Husky") stands unchanged for those three breeds.
