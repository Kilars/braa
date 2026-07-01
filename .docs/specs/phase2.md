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
  - PERFECT fills more than OK. **Wrong timing removes learning** — a mistimed tap
    (MISS) or a tap with no real apex (a feint / ambient moment, see P2-8) erodes the
    bar. (PO-Directive 2026-06-29 — amends the earlier "bar only stalls".)
  - **No hard fail state, but progress is erodible:** good play always nets forward (a
    PERFECT adds clearly more than a bad tap removes), the bar floors at 0, and a bad
    tap can't end the game — it only sets you back. Early game is **gentle**; harsher
    erosion is a Phase-4 difficulty knob (see P4-2).
  - A bad tap also reads on the dog — a brief **confused** beat, the mirror of the
    joyful mark — so the setback is *felt*, not just a silent number dropping.
  - 100% masters the trick with a celebratory beat and is a **safe checkpoint**
    (re-practice can't un-master it); mastered tricks are re-practiceable. (Training
    Sessions, Mastery)

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

- **P2-7 — One tap, then a beat (anti-mash freeze).**
  *As a player, I want the BRA button to settle briefly after each tap, so that
  mashing is never a strategy and every tap is a deliberate choice.*
  Acceptance:
  - After **every** tap (any tier, including a dead/empty tap), BRA locks for a fixed
    ~350 ms, then re-arms. Taps during the lock are **swallowed** (not scored) and do
    **not** reset or extend the timer — a fixed re-arm window, not a hold-open
    debounce a masher could keep alive.
  - The button visibly reads as locked (e.g. dims) and then restored, and that state
    stays legible under reduced motion (X-5). (PO-Directive 2026-06-29; strengthens
    P2-6 — anti-spam by input hygiene, not penalty.)

- **P2-8 — A dog with a mind of its own.**
  *As a player, I want the dog to live — wander, sniff, and sometimes fake me out — on
  no fixed rhythm, so that the skill is reading the dog, not tapping a beat.*
  Acceptance:
  - The dog **wanders** a bounded patch and turns back at the edges so it stays framed;
    the camera is fixed. (Needs the garden ground, P2-10.)
  - The gap between trick offers **varies** — no metronome cadence to game.
  - The dog sometimes **feints**: it starts a sit then aborts. Only a **real, completed**
    Sitt has a markable apex; a feint or ambient moment opens no scoring window, so
    tapping it is a wrong-moment tap (→ P2-4 negative learning). (PO-Directive 2026-06-29)

- **P2-9 — A timing trainer that fades.**
  *As a learning player, I want a clear "now" cue while a trick is new that fades as I
  master it, so that I'm taught the timing and then trusted to read the dog myself.*
  Acceptance:
  - A bold approach cue — a ring that shrinks onto the BRA button and **lands exactly at
    the apex** ("tap when it lands") — shows while the trick is **new**; its prominence
    **fades as the learned bar fills** and is **gone at mastery**, so by then you read
    the dog's body, not the ring.
  - It rides the **same `SitWindow`** as the score and the apex tell (P1-4), so it is
    honest and stays **dark during feints / ambient** moments. (PO-Directive 2026-06-29)

- **P2-10 — The garden (a world to play in).**
  *As a player, I want to look down into a sunny garden instead of a flat backdrop, so
  that the dog has a place to be and the scene feels alive.*
  Acceptance:
  - A Pokémon-GO-style **look-down** view with a horizon split: stylized sky + a visible
    **sun** above, green **grass** ground below; the dog stands and roams on the grass.
    Replaces today's flat sky-blue void + blob shadow.
  - The **BRA** button floats over the grass (lower area) — **not** a separate opaque
    control band.
  - The **functional** garden (ground + horizon + sun + look-down camera) lands here
    because the wandering dog (P2-8) needs ground to roam on; richer environment art
    (props, depth, lighting polish) defers to **Phase 7**. (PO-Directive 2026-06-29;
    X-4 stylized-realism)

- **P2-11 — Face me for the trick.**
  *As a player, I want the dog to turn and face me (the camera POV) whenever it performs a
  trick, so that I read the trick head-on and the payoff feels aimed at me — never caught in
  profile or from behind.*
  Acceptance:
  - When a **real (non-feint) trick** begins, the dog **turns to face the camera POV** and
    performs the trick so its **apex reads head-on** — it never sits/lies side-on or rear-on.
  - The turn is **smooth and in-character** — it rotates on its walk/turn (consistent with
    P2-8's honest gait), **no instant snap, no foot-slide**, and it **completes before the
    apex** so the markable moment is always framed to the player.
  - A **feint** commits to no trick, so it does **not** force a face-camera turn — the dog
    keeps its ambient wander heading; only a committed trick turns to face. (P2-8)
  - Reduced motion: the facing still **resolves** (a dampened/near-instant turn is fine), so
    the trick is always read head-on even with `prefers-reduced-motion`. (X-5, D13)
