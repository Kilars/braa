## Phase 3 — Dog breeds (races), each with its own tricks  *(needs further spec)*

**Goal:** the player can select different real **breeds**, each with its **own
tricks / signature behaviors** and its own feel.

> ⚠️ Provisional. The owner-decision stories below must be resolved before this
> phase is sliced for build.

### Player stories (provisional)

- **P3-1 — Choose a breed.**
  *As a player, I want to pick which dog I'm training, so that I can collect and
  train different breeds.*
  Acceptance:
  - The dog reads **clearly as that real breed** at phone size — silhouette,
    proportions, coat, color. (D2)

- **P3-2 — Breeds bring different tricks.**
  *As a player, I want different breeds to open different / signature tricks, so
  that collecting breeds is also collecting moves.*
  Acceptance:
  - Each breed exposes a trick list that is not identical to every other breed's.

- **P3-3 — Breeds feel different to train.**
  *As a player, I want each breed's personality to change how it trains, so that
  breeds are deep kits, not skins.*
  Acceptance:
  - Personality drives the difficulty levers (learn speed, distractibility,
    window stability, energy). (Breeds)

- **P3-4 — Persistent, showcased roster.**
  *As a player, I want my dogs to persist across sessions and be shown off, so
  that they feel like collected units I'm proud of.*
  Acceptance:
  - A dog keeps a consistent appearance across rounds/sessions. (D3)
  - On the select screen the dog is bright/spotlit, not buried in shadow.
    (PO-Improvement-2)

### Owner-decision stories (resolve before building)

- **P3-D1 — Which breeds ship first.**
  *As the product owner, I want to fix the launch breed set, so that art and trick
  lists are bounded.*
  Acceptance:
  - Decision recorded. Proposed default: the four the licensed pack covers —
    **Labrador, Border Collie, French Bulldog, Husky** (no Poodle).

- **P3-D2 — Universal vs. signature tricks.**
  *As the product owner, I want to decide which tricks every breed knows vs. which
  are breed-exclusive, so that the trick catalog is scoped per breed.*
  Acceptance:
  - Decision recorded. Proposed default: shared core (Sitt/Ligg/Legg deg) + 1–2
    signature tricks per breed.

- **P3-D3 — How breeds are acquired. ✅ DECIDED: unlock via a light economy.**
  *As a player, I want to unlock/adopt new breeds with earned currency, so that
  collecting dogs is a goal I work toward.*
  Acceptance:
  - **Decision (owner):** breeds **unlock via a light economy** — not free-select.
  - Phase 3 therefore **pulls a light economy forward**: master tricks → earn
    coins (and a level gate where it fits the two-step "level unlocks, coins buy"
    model); spend to adopt a breed.
  - Keep it light — only as much economy as adopting breeds needs; the full
    economy/kennel depth stays parked (B-1).
  - The adopt UI shows the coin price + a clear locked state and a breed thumbnail
    so the collection axis is visible. (PO-Improvement-4)

- **P3-D4 — Per-breed animation coverage.**
  *As the product owner, I want to confirm each breed has clean clips for its
  trick list before committing it, so that we never promise a trick the rig can't
  perform.*
  Acceptance:
  - Clip coverage confirmed per breed × trick at Phase-1 quality before the list
    is locked (the pack ships shared clips, but signature tricks may not exist).
