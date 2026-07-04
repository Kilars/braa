# 099 — VISUAL: Build the garden ambiance to the goal training screen

**Type:** VISUAL (3D scene / render / asset glue — Visual Review gated)
**Phase:** 6 (current) — PO Review 2026-07-04, Improvement #2
**Priority:** P1 (the named visual target of the phase; the running garden reads as an empty field)

## What it addresses

Spec gap (PO directive #2). `phase6.md` names `.docs/specs/assets/goal-training-screen.png`
as the visual target — *"match the composition, grounding, and juice, not the exact pixels."*
The running garden is **noisy blocky FBM grass + a blurred sun/horizon and nothing else** —
no path, no house, no fence, no border bushes, no ground coins, only the faintest grounding
under the dog. The dog reads as **floating on an empty field**.

Evidence: `.screenshots/po-p6-idle-a.png`, `-idle-c.png`, `-mark-14.png` (PO). Goal:
`.docs/specs/assets/goal-training-screen.png`.

The goal garden is a **place**: a winding **path curving back to a small house** top-right,
a **white picket fence** line across the mid-ground, **low bushes** framing the corners, a
couple of **gold coins on the grass**, a clear **horizon hedge/hills**, and a soft **shadow
ellipse grounding** the dog.

## Why now

Phase 6 is current; the PO named this as **not sign-off ready** and it is the phase's
explicit visual goal. Non-owner-gated — all buildable in-engine with the existing garden
setup pattern. (Domain note: visual/rendering is heavy this phase, but this is a **named
current-phase spec gap**, so the saturation filter is overridden — it is the goal itself.)

## Technical approach

The garden is assembled in `scripts/main.gd` at `_ready`/setup time via
(`main.gd:319-322`, defs from ~`main.gd:628`):
- `_setup_ground_plane(dog)` — grass ground plane at the foot plane (047/P2-10; 078 FBM grass)
- `_setup_hedge_band(dog)` — stylized hedge at the horizon (078/Note-6)
- `_setup_contact_shadow(dog)` — blob shadow on the grass (031/P1-1)
- `_setup_sun_disc(dog)` — sun disc in the sky
- `_setup_garden_backdrop` — `ProceduralSkyMaterial` sky gradient (`main.gd:628-661`)

**Add new stylized garden layers** (all GL-Compatibility-safe — no Forward+-only features,
per CLAUDE.md; add each as its own `_setup_*` for the same testable, node-local pattern the
existing garden uses — accumulate node-local transforms, the skinned-AABB gotcha):

1. `_setup_path_to_house(dog)` — a winding light-tan **path** (a flattened curved
   `MeshInstance3D` strip or a few quads on the grass plane) curving from mid-ground back
   toward the **top-right**, ending at a **small stylized house** (simple box + gable roof
   mesh, warm walls + a darker roof, in the DS-adjacent warm palette). Small in frame, sits
   above the horizon-side of the grass, reads as "home in the distance."
2. `_setup_fence_line(dog)` — a **white picket fence** line across the mid-ground (a row of
   thin white posts + two rails; instance a small post mesh along a line, or one baked strip
   mesh). Reads as the goal's fence separating near-grass from the path/house band.
3. `_setup_border_bushes(dog)` — a few **low rounded bushes** framing the bottom corners
   (squashed green spheres/blobs with slight tonal variation), so the centered dog is framed,
   not floating.
4. `_setup_ground_coins(dog)` — **two or three gold coins** resting on the grass near the dog
   (flat gold discs, `DesignSystem.GOLD` / `GOLD_DARK` rim, angled to catch light — same coin
   read as the HUD coin). Ambient only (not collectible this task); framing juice.
5. **Grounding shadow:** strengthen `_setup_contact_shadow` so the dog sits in a believable
   **soft shadow ellipse** (darker/larger/soft-edged enough to read as grounded), matching
   the goal's clear grounding — the PO called ours "only the faintest grounding."
6. **Grass:** the PO reads the current FBM grass as **pixel noise** rather than the goal's
   smoother painterly grass. Soften it — lower the FBM contrast/frequency or blend toward a
   smoother base grass-green so it reads painterly at phone scale, in the DS grass tone. Keep
   the baked normal-map depth (078) but dial the noise down.

**Palette:** compose in the DS-cohering palette — sky/grass greens, `DesignSystem.BLUE` /
`GOLD` accents — so the garden coheres with the restyled HUD (097) and menu (098). Prefer
`DesignSystem` colour tokens over fresh literals where a token fits; garden-specific hues
(house walls, path tan, bush green) may be named `const`s in `main.gd` (homed, not scattered).

**Composition target:** centered + grounded dog, path-to-house top-right, fence across the
mid-ground, corner bushes, a few ground coins, clear horizon hedge/hills, bottom BRA button —
a believable, juicy garden that reads at a glance. **Not pixel-exact** — match the layered
composition + grounding + ambient juice.

**Guardrails:** no bare primitive standing in for the **dog** (this is scenery, not the dog —
fine); keep everything behind/around the dog so it never occludes the centered dog or the apex
read (face-camera-at-apex contract, 061/077 — scenery must not block the dog's silhouette at
the scored apex). Reuse one dev server for captures.

## Visual Review (blocking — VISUAL task)

Spawn phone-portrait (390×844) review agents. Capture idle + a scored-apex frame via the
existing harness (`tools/web_capture_*.mjs` / the PO's `po_p6_drive.mjs`). Compare against
`.docs/specs/assets/goal-training-screen.png` for **composition + grounding + juice** (not
pixel-identity). Confirm the dog stays centered, unoccluded, and readable at the apex.
Orchestrator verifies the actual frames.

## Acceptance criteria

- [ ] A **path** curves back toward a **small house** in the upper-right of the garden.
- [ ] A **white picket fence** line reads across the mid-ground.
- [ ] **Low bushes** frame the bottom corners so the dog is framed, not floating.
- [ ] **Two or three gold coins** rest on the grass near the dog (ambient framing; DS gold).
- [ ] A clear **horizon hedge/hills** band reads (existing hedge kept/tuned), and the dog has
      a believable **soft grounding shadow** (contact shadow strengthened — not "faintest").
- [ ] The grass reads **smoother/painterly** at phone scale (FBM noise dialled down), not
      pixel noise; normal-map depth retained.
- [ ] New garden layers are added as their own `_setup_*` in `main.gd`, node-local transforms,
      GL-Compatibility-safe; garden hues homed in named `const`s (no scattered literals);
      DS tokens used where they fit (sky/grass/BLUE/GOLD).
- [ ] Scenery **never occludes** the centered dog or its scored-apex silhouette
      (face-camera-at-apex contract preserved).
- [ ] `nix develop -c bash verify.sh` → `✓ verify gate green` (boot log clean — no SCRIPT
      ERROR; the skinned-dog / AABB / embedded-camera gotchas respected).
- [ ] **Visual Review PASS** (orchestrator-verified frames): the garden matches the goal's
      **layered composition + grounding + ambient juice** (not pixel-exact) and coheres in the
      DS palette with the restyled HUD.
- [ ] Placeholder check clean on the diff (no un-allowlisted stub/placeholder/TODO).
