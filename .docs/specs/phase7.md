## Phase 7 — Training-page visual enhancement (juice & ambiance)

**Goal:** lift the **training page** above its Phase-1 baseline — a more alive,
beautiful, satisfying scene. Phase 1 makes it *clean and bug-free*; Phase 7 makes
it *gorgeous*. This is pure enhancement: it must never regress the legibility,
performance, or reduced-motion guarantees of the core loop.

> **Constraint (all stories):** stays within the mobile rendering budget (cheap backdrop, blob shadow, no
> heavy post-processing) and honors
> `prefers-reduced-motion` (X-5): every enhancement dampens, never removes
> readability or a state cue.

- **P7-1 — Juicier "Bra" wording.**
  *As a player, I want the marker word itself to look and move beautifully when it
  fires, so that the praise moment is a visual treat, not just text.*
  Acceptance:
  - On-brand typography/styling for the word; a satisfying entrance (pop/scale,
    gentle float, fade) on each successful mark, brighter on PERFECT than OK.
  - Reinforces — does not clutter — the apex/score read; never blocks the dog.
  - Builds on P5-3 (the word *pop*); P5-3 introduces it, P7-1 polishes the feel.

- **P7-2 — Buttery animation smoothness.**
  *As a player, I want every transition between dog states to blend smoothly, so
  that the dog never snaps or pops between poses.*
  Acceptance:
  - Animation blending/cross-fade between idle ↔ offer ↔ trick ↔ apex ↔ reaction;
    eased timing, no hard cuts, no T-pose, no foot-slide.
  - Holds a steady frame rate on a mid-range phone; degrades gracefully, never
    janks the mark.

- **P7-3 — Lifelike dog movement.**
  *As a player, I want the dog to move with weight and personality, so that it
  feels like a real animal, not a clip player.*
  Acceptance:
  - Richer ambient/secondary motion (breathing, weight shift, ear/tail flicks,
    look-around, blink) layered over the base loops.
  - Movement reads natural (grounded contact, no float/slide); stays centered and
    framed (D12); dampened under reduced motion but still alive.

- **P7-4 — Dynamic sun / changing light.**
  *As a player, I want the scene's lighting to shift over time (sun moving,
  warm→cool, soft day cycle), so that the training ground feels alive and the page
  stays fresh across sessions.*
  Acceptance:
  - A subtle, cheap time-of-day / sun shift (light direction + color, sky tint,
    shadow warmth) — no per-frame shadow-map cost; reuse the gradient-backdrop
    approach.
  - Lighting never hurts the dog's read or breed legibility at any point in the
    cycle (D2, D14); keeps the bright, clean Pokémon-GO feel.

- **P7-5 — Living ambiance.**
  *As a player, I want gentle life in the scene around the dog, so that the
  training ground feels like a real place.*
  Acceptance:
  - Cheap ambient touches (subtle grass/foliage sway, occasional drifting
    particle/butterfly, soft cloud drift) — peripheral, never competing with the
    dog or the apex tell.
  - All ambiance pauses/calms under reduced motion; zero impact on tap timing.

- **P7-6 — Mark juice.**
  *As a player, I want a successful mark to feel physically satisfying on screen,
  so that "the mark always feels good" reaches its visual ceiling.*
  Acceptance:
  - Tasteful feedback on PERFECT (e.g. a soft burst/sparkle/ring, a tiny camera
    or dog pop), scaled down for OK, none on Miss.
  - Restrained — enhances the beat, never seizure-y; fully reduced-motion-safe.

- **P7-7 — No regression.**
  *As the product owner, I want Phase 7 gated by the same Visual Review + perf
  bar, so that "prettier" never costs us legibility, frame rate, or accessibility.*
  Acceptance:
  - Independent Visual Review on a 390×844 portrait viewport confirms the scene is
    more beautiful *and* every Phase-1 read/perf/reduced-motion guarantee still
    holds. (CLAUDE.md Visual Review gate)
