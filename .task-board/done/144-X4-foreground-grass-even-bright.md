# 144 — X-4: foreground grass reads dark/muddy/blotchy → even, bright lawn

**Type:** X-4 polish directive (cross-cutting, on the signed-off Phase-6 training surface)
**Source:** PO Review 2026-07-07 (father pass 9), `.docs/specs/po-review.md` Improvement #1.

## The directive (measured by the PO)

Sky/atmosphere fix (143) landed. But the **foreground/lower grass** reads dark, muddy,
and blotchy — the closest, most prominent lawn is the *darkest* part of the scene, the
opposite of the goal art's even bright green.

- Mid-band open grass ≈ `(112,171,110)` (bright, good).
- Left grass column **darkens sharply toward the foreground**: green channel falls from
  ≈175 at y≈0.45 to **≈92 at y≈0.65 and ≈106 at y≈0.75**.
- Region-average of the whole lower grass band reads a dark muddy `(48–74, 76–115, 48–72)`.
- A 2× zoom of the lower-left grass shows irregular **dark cloud-like blotches** —
  high-contrast FBM noise — not a clean lawn.
- Goal art (`.docs/specs/assets/goal-training-screen.png`) grass is a near-uniform bright
  green across the whole field: region-averages `(132–142, 182–190, 100–111)` at both
  mid-height and foreground, only subtle variation, **no dark patches**.

## Root cause

The grass plane (`_setup_ground_plane`) is a flat plane whose albedo is a 3-tone FBM
colour-ramp + a baked FBM **normal map** at `bump_strength = 1.3`. On the flat plane the
foreground is viewed at a grazing angle; the strong normal-map relief tips many bumps
*away* from the low sun (`-30°` elevation), so those bumps lose nearly all diffuse and
fall to ambient-only — reading darker than even the darkest albedo tone. Closer to camera
each bump subtends more pixels, so the dark-facing bumps dominate the foreground band →
the sharp foreground darkening + cloud-like blotches. The ramp's dark end
`(0.34,0.56,0.28)` compounds it (muddy where it lands).

## The fix (no owner asset — grass material tuning only)

1. **Tame the relief** so foreground shading is even: drop the normal-map `bump_strength`
   from 1.3 to a gentle value (named `GRASS_RELIEF_BUMP`) so bumps no longer cast into
   shadow at the grazing foreground angle → foreground stays as bright as mid-field.
2. **Raise + tighten `GRASS_TONES`**: lift the dark (shadow) tone so the darkest blotches
   read a subtle green variation, not mud, and narrow the shadow↔light spread so the
   mottle is gentle, not high-contrast.

## Verify (PO bar)

- Foreground open-grass green channel within ~15 % of mid-field, **never below ≈100**.
- No region darker than a subtle variation of the goal green `(≈135,185,105)`.
- Re-sample a fresh `verify.sh` `build/web` capture at 390×844; Visual Review vs goal art.

## Done when

- TDD: constants (`GRASS_TONES` dark-tone floor + spread, `GRASS_RELIEF_BUMP`) pinned by a
  failing-first test in `tests/test_garden_wiring.gd`, then green.
- Live capture of the training frame shows an even bright foreground lawn, no dark blotch.
- verify gate green; committed + pushed; po-review pass-9 diff committed with the fix.

---

## DONE — root cause found by probe, not the obvious suspect

**Investigated with a live grid-sampler (`tools/po_grass_sample.mjs`) + a magenta-emission
probe.** The obvious suspects were ruled out empirically:
- Killing the specular sheen (roughness→1.0) — no effect on the foreground.
- Disabling the normal map entirely — foreground still dark.
- A magenta-emission probe proved the grass plane DOES cover the whole foreground, but its
  emission renders scaled to ~40% there → a **semi-transparent dark layer composites over the
  lower frame**.

**Root cause:** the **contact-shadow disc** (031/078/101). It's a flat ~0.5-alpha black ground
decal; tasks 078/101 enlarged it to 1.55× the footprint + firmed its core (0.72) and held 0.42
alpha out to 66% radius. Seen from the low ~1.2 m camera, that flat disc **projects across the
whole lower frame** and halves the grass beneath it — the "dark/muddy/blotchy foreground lawn."
Pass-8's brighter sky/grass (143) made the long-standing wash newly obvious by contrast.

**Fix (scripts/main.gd):**
- `GARDEN_SHADOW_SPREAD` 1.55 → **1.1** (snug disc under the paws).
- Contact-shadow gradient falloff concentrated: alpha 0.42→**0.30** and moved in (0.66→**0.30**
  radius), transparent by **0.70** radius — the outer disc (which projects into the foreground)
  is now near-transparent. Firm 0.72 core kept, so the dog stays grounded (no floating regression).
- Secondary polish: `GRASS_TONES` dark end lifted off mud + spread narrowed (Δg 0.13); relief
  `GRASS_RELIEF_BUMP` 1.3→0.3; grass matte (roughness 1.0). Grass now ≈ goal green.

**Verify (fresh `build/web` capture, 390×844):** foreground open grass green now **164–194**
(mid-field 191, goal ≈185), **never below 100**; only a tight grounding smudge remains beside
the paws. Visual Review PASS — even bright lawn matching `goal-training-screen.png`. TDD guards
`GRASS_TONES` floor+spread, `GRASS_RELIEF_BUMP`, `GARDEN_SHADOW_SPREAD` (test_garden_wiring.gd).
verify gate green (import·boot·test·export).
