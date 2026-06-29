## Phase 2 — More tricks, same quality bar

**Goal:** the player can select and teach **more tricks**, each at the **exact
Phase-1 Sitt standard**. Breadth of tricks, zero drop in polish.

- **P2-1 — Pick a trick.**
  *As a player, I want to choose which trick to train from a small, clear
  selector, so that I can grow a dog's repertoire without the game becoming
  busy.*
  Acceptance:
  - Selector stays one-page, portrait, one-verb — it is **not** a second gameplay
    verb during the round.

- **P2-2 — Each trick has its own clean, distinct animation.**
  *As a player, I want every trick to visibly perform its **specific** behavior
  with a clear apex, so that reading the behavior is part of the skill.*
  Acceptance:
  - Never one generic pose reused. Starter set: **Sitt**, **Ligg** (lie down),
    **Legg deg** (settle), then expand (e.g. **Gi labb** [shake], **Rull** [roll
    over], **Snurr** [spin]).
  - The lie-down tricks read as **down**, clearly different from sit. (D6, D11,
    PO-Improvement-1)

- **P2-3 — Same polish gate per trick.**
  *As a player, I want every new trick to be as bug-free and satisfying as Sitt,
  so that quality never drops as the roster grows.*
  Acceptance:
  - No foot-sliding, clipping, snapping, or T-pose; smooth loops; honest apex
    tell; the mark feels good.
  - **Each trick passes its own Visual Review** before it counts as done.

- **P2-4 — Feel the dog learning.**
  *As a player, I want well-timed BRAs to fill a "learned" bar that reaches
  mastery, so that training a trick has a beginning, middle, and a satisfying
  end.*
  Acceptance:
  - PERFECT fills more than OK; the bar only ever stalls — **no fail state**.
  - 100% masters the trick with a celebratory beat; mastered tricks are
    re-practiceable. (Training Sessions, Mastery)

- **P2-5 — Leave and come back.**
  *As a player, I want to pause or quit and return with my per-trick progress
  intact, so that the game is snackable.*
  Acceptance:
  - Per-trick learned progress persists (introduces IndexedDB save).
  - Pause/resume supported; no timer forces play. (Round States)

- **P2-6 — Mashing should lose (light, secondary).**
  *As a player, I want tapping with nothing to mark to be gently discouraged, so
  that patience beats spamming even before full difficulty exists.*
  Acceptance:
  - Light false-mark/confuse + distractors ride along as the bar gains stakes, but
    stay **secondary** to nailing clean tricks — keep minimal until the roster
    feels good. (Mistakes — fuller treatment folded into Phase 4.)
