## Phase 4 — Difficulty

**Goal:** the player can change difficulty, trading challenge for reward.

- **P4-1 — Choose how hard.**
  *As a player, I want to set Normal / Hard / Expert, so that the game matches my
  skill.*
  Acceptance:
  - A single global setting applied to all training. (Difficulty Modes)

- **P4-2 — Higher difficulty changes the read.**
  *As a player, I want harder modes to genuinely demand more, so that difficulty
  is real, not cosmetic.*
  Acceptance:
  - Higher = tighter window, fainter & faster apex tell, more distractors, and a
    harsher false-mark penalty (the fuller Mistakes/confuse model lands here).
    (Difficulty, Mistakes, D7, D9)
  - The **learned-bar erosion rate** (P2-4 negative learning) scales with difficulty:
    gentle by default, harsher on higher modes — a mistimed / wrong-moment tap removes
    more, up to an "unforgiving training" tier. More feints, too. (PO-Directive 2026-06-29)

- **P4-3 — Pain pays.**
  *As a player, I want harder modes to reward more, so that opting into difficulty
  is worth it.*
  Acceptance:
  - Higher difficulty raises rewards so each mode is the rational choice at a
    different skill level. (Difficulty)

- **P4-4 — Stacks with the breed.**
  *As a player, I want difficulty to combine with the breed's nature, so that a
  stubborn breed on Expert is the real wall.*
  Acceptance:
  - Effective difficulty = global mode × breed intrinsic. (Breeds)

- **P4-5 — Background grace.**
  *As a player, I want taps right after the app resumes from background to be
  ignored, so that a notification or lock never causes a false mark.* (Mistakes)
