# 078 — VISUAL: the garden is a flat green void — stylized-grass + depth so dog and world read as one scene

**Type:** VISUAL (Visual Review; pure render/3D glue — exempt from TDD) · **Phase:** 3 (current) ·
**Source:** PO Review 2026-07-02 `po-review.md` **Improvement 2 (Note 6)** ("The garden is a flat
green void and does not cohere with the dog (X-4) … the photoreal dog appears to float on it") ·
**Priority:** P2 for this phase — below the core-loop payoff bug (077), above the adopt/select feature
(079). X-4 requires stylized-realism *throughout*: the dog reads, and its world must read too.

## What it addresses

The ground is a single mottled-green plane meeting a gradient sky at a hard horizon, with a sun blob
and no props or depth (evidence: `.screenshots/po-p3/A-idle-00`, `B-react-010`). The photoreal
licensed Labrador looks like a **cutout floating on a fill**, not a dog standing in a garden.

Good (PO, buildable now, no owner asset): give the ground **real stylized-grass shading/texture** and
**some depth** (a graded horizon, a fence line or bushes), and **ground the dog with a contact
shadow**, so dog and garden read as **one stylized-real scene**.

## Current state (source)

- `_setup_ground_plane` (`scripts/main.gd`, ~248/500+) — the grass plane at the foot plane
  (047/P2-10), currently a mottled-green fill (`062` stylization).
- `_setup_sun_disc` (~250) + the `ProceduralSkyMaterial` gradient (`scripts/main.gd:500–521`) — bright
  blue zenith → warm peach horizon; ground half muted grass → warm haze.
- `_setup_contact_shadow` / `_contact_shadow` (`main.gd:204–207`, `_track_contact_shadow:1574`) — a
  blob shadow that already tracks the wandering dog. Confirm it reads clearly under the dog at phone
  size (the PO says the dog "appears to float" — the contact shadow may be too faint / mis-scaled).

## Technical approach (Visual Review, GL-Compatibility-safe — no Forward+-only features)

Pick the combination that reviews best on a 390×844 phone-portrait viewport; all must stay within the
WebGL2 GL-Compatibility renderer (the deploy target) — no SDFGI/Forward+ effects.

1. **Stylized grass, not a flat fill.** Give the ground plane real texture/shading — e.g. a
   procedural or authored stylized-grass albedo with subtle tonal variation and a soft normal/rough
   variation so it catches the light, or a shader that breaks up the flat green (blade-ish micro
   variation, gentle color banding toward the horizon). Honest asset: generate a real grass texture
   offline (`nix shell nixpkgs#<tool>` — e.g. an authored/proc texture) rather than a single solid
   color; **no placeholder fill left as "done."**
2. **Depth at the horizon.** Add readable mid/background depth so the world has a "there there" — a
   simple stylized **fence line** and/or **bushes/hedge** band near the horizon, and/or a graded
   ground fog/haze that seats the plane into the sky (soften the current hard horizon seam). Keep it
   low-poly / GL-safe and low-cost; it must read at phone size without stealing focus from the dog.
3. **Ground the dog.** Make the contact shadow read clearly as the dog's shadow at native size
   (opacity / size / softness tuned so the dog is planted, not floating) — it already tracks the
   wander, so this is a legibility tune, not new plumbing.

Reuse existing plumbing (ground plane, sky, contact shadow, sun); this is a stylization pass, not a
re-architecture. No regression to the letterbox fill (063) — the garden must still fill 390×844 with
no black bands. Keep the dog centered and legibly lit (no darkening the scene to hide the seam).

## Visual Review (blocking)

Spawn Visual-Review subagents per the mother-prompt protocol on the local licensed bundle at 390×844.
Capture idle + reaction frames (same angles as the PO's `A-idle-*` / `B-react-*`). Sign-off requires:
the ground reads as **stylized grass with depth** (not a flat void), the horizon no longer reads as a
hard cutout line, and the dog reads as **standing in** the garden (grounded by a legible contact
shadow), one cohesive stylized-real scene. Verify frames by eye (never trust a pixel counter alone —
the SwiftShader counter gotcha). Findings are blocking.

## Acceptance criteria

- [ ] The ground is **stylized grass with real shading/texture** (tonal/normal variation), not a
      single flat green fill; any generated texture is a genuine asset (offline-made), not a solid
      color left as a stub.
- [ ] The scene has **readable depth** near the horizon (fence line / bushes / graded horizon haze),
      GL-Compatibility-safe, low-cost, and it does not steal focus from the dog.
- [ ] The dog is **grounded by a legible contact shadow** at 390×844 — it no longer reads as floating.
- [ ] No letterbox regression (063): the garden fills 390×844, no black bands; dog stays centered and
      well-lit.
- [ ] Visual Review PASS (phone-portrait), frames verified by eye; findings blocking. Evidence under
      `.screenshots/`.
- [ ] Placeholder check clean on the diff (no flat-fill/solid-color "grass" stub; no bare-primitive
      prop left as a placeholder).
- [ ] `nix develop -c bash verify.sh` green (import·boot·test·export).

## Notes

X-4 is the throughline: stylized-realism *everywhere*, not just the dog. Keep the warmth of the 062
sky grade; the fix is the *ground and depth*, which currently lag the dog and sky. If a prop band
(fence/bushes) proves heavy to make read well at phone size within budget, prioritise (a) stylized
grass texture + (b) contact-shadow grounding first — those two alone kill most of the "cutout on a
fill" read; the horizon props are the depth bonus.
