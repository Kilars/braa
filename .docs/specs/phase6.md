## Phase 6 — Play mode  *(the learning-technique phase — needs further spec)*

**Goal:** add a **chaotic free Play mode** (toys, praise, petting) that **bonds
the dog and significantly boosts learning**. This turns "tap the apex" into "train
a dog."

> ⚠️ Provisional. The owner-decision stories below must be resolved before build.

### 6a — Shaping / steps  🚩 FLAGGED FOR LATER (owner: defer)

> **Decision (owner): shaping of tricks is deferred — flagged for later, not in
> this phase.** Captured here so the design isn't lost; do **not** build it as
> part of Phase 6. Revisit after Play mode (6b) lands. (Also parked: see B-5.)

- **P6-1 — Teach a trick in steps.** *(deferred)*
  *As a player, I want a complex trick broken into markable sub-steps I master in
  order, so that I learn (and the dog "learns") it the real, gradual way.*
  Acceptance:
  - Example — **Legg deg**: step 1 = **step onto the bed/mat** (not lying down
    yet), step 2 = lower the front, step 3 = full settle.
  - Each step is its own behavior with its own apex and learned bar; mastering a
    step unlocks the next.

- **P6-2 — Steps can use props / scenarios.** *(deferred)*
  *As a player, I want steps to introduce a prop the behavior references, so that
  shaping feels concrete and the scene evolves with the trick.*
  Acceptance:
  - E.g. a **dog bed/mat** for *Legg deg*, a cone, a target; the scene gains the
    object for that trick.

#### Owner-decision stories *(deferred with shaping — resolve when un-parked)*

- **P6-D1 — Do steps need their own animations?**
  *As the product owner, I want the per-step animation cost confirmed, so that we
  don't commit to shaping the rig can't render cleanly.*
  Acceptance:
  - Likely **yes** — each step is a distinct pose/motion (stepping onto a bed is
    locomotion, not the final down); movement must be clean (no foot-slide/clip).
  - Confirm the rig has — or can get — clips per step, or design steps around
    clips we have. This is the phase's main cost/risk.

- **P6-D2 — All tricks, or only some?**
  *As the product owner, I want to decide which tricks get steps, so that shaping
  feels earned, not bolted onto everything.*
  Acceptance:
  - Decision recorded. Proposed default: **only some** — positional/compound
    tricks (Legg deg, Rull, Dau) earn steps; atomic tricks (Sitt, Snurr) stay
    single-step.

- **P6-D3 — How granular?**
  *As the product owner, I want a step-count ceiling, so that shaping teaches the
  idea without dragging.*
  Acceptance:
  - Proposed default: 2–3 steps max per trick to start. Tunable.

### 6b — Play mode (engagement → faster learning)

- **P6-3 — Go chaotic with the dog.**
  *As a player, I want a free Play mode where I interact loosely, so that I get
  joyful, unstructured time with my dog as a counterpoint to precise training.*
  Acceptance:
  - Throw toys, pet, praise ("flink gutt!"), tug, pet "aggressively" — many
    tappable things at once, deliberately the opposite of the single-tap training.
  - Reads as joyful and a little unhinged.

- **P6-4 — Play builds bond; bond boosts learning.**
  *As a player, I want playing to significantly speed up later training, so that
  building the relationship pays off (as in real training).*
  Acceptance:
  - Play raises the dog's engagement/bond, which increases learn-speed / mood on
    subsequent training.

#### Owner-decision stories (resolve before building)

- **P6-D4 — How Play feeds learning.**
  *As the product owner, I want the play→learning mechanic defined and tuned, so
  that Play is a meaningful carrot, not a token.*
  Acceptance:
  - Decision recorded. Proposed default: a **bond meter** that decays slowly and
    grants a learn-speed multiplier — play to top it up. Needs tuning.

- **P6-D5 — Play animation scope.**
  *As the product owner, I want the Play clip set bounded, so that the animation
  cost is known.*
  Acceptance:
  - Confirm coverage (fetch, tug, roll, get-pet, zoomies); reuse existing pack
    clips where possible.
