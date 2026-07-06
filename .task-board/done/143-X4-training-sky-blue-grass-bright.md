# 143 — X-4: training scene reads sunny (blue sky + brighter grass), not dusk/haze

**Source:** PO Review 2026-07-07 (father pass 8), Improvement 1. Owner-corroborated
(2026-07-06 background-vs-mockup gap). Cross-cutting **X-4** polish on the signed
Phase-6 training surface — the polish lens explicitly permits these on signed surfaces.

## The gap (measured by the PO)
- Live training frame sky samples a warm grey-brown `(166,156,127)` → greenish horizon
  `(76,117,93)` under a blown-out white sun disc — **no blue in the sky at all**.
- Grass beside the dog reads a dark low-saturation olive `(85,148,94)`.
- Goal art (`.docs/specs/assets/goal-training-screen.png`): sky a clean pale **blue**
  `(184,213,240)`, grass a bright saturated **green** `(136,185,104)` — a cheerful
  sunny day. Build is markedly darker/browner/less saturated; also clashes with the
  bright, clean kennel grid, breaking the one-world read.

## Root cause
`_setup_environment` sets `sky_horizon_color = Color(0.88,0.68,0.44)` (warm peach, the
old 062 "Pokémon-GO warmth" directive) and `ground_horizon_color` warm cream. The
look-down camera shows mostly the **near-horizon band**, so the peach horizon — not the
blue zenith — dominates the visible sky → it reads brown/hazy. This directly conflicts
with, and is **superseded by**, the newer father-pass-8 sky directive.

## Fix (buildable, no owner asset)
- Sky: horizon → clear pale-blue; ground-horizon haze → cool, not warm cream. Verify
  re-sample reads blue (**B > R and B > G by a clear margin**).
- Grass: lift albedo tones toward the goal's brighter, more-saturated green.
- Ambient: raise exposure so the page reads a bright sunny day.
- Sun: keep a soft, contained disc — not a blown white one.

## TDD
- Rewrite `test_the_sky_is_graded_and_warm_at_the_horizon` → assert the horizon reads
  **cool/blue** (b > r, b > g) so a regression to the warm-peach haze can't read green.
- Add a grass-brightness guard on a named `GRASS_TONES` constant (lightest tone is a
  bright saturated green near the goal).

## Done when
verify green + Visual Review confirms the training frame reads a bright blue-sky day
(sky B > R,G; grass brighter/more saturated), no regression to path/house/fence/coins.
