# Bra! — Specification v2 (User Stories, Phased)

> This is a **functional** rewrite of [specs.md](https://github.com/Kilars/braa/blob/deprecated-game/.docs/specs.md) as **user stories
> grouped into delivery phases**. It says *what the game is and how it plays*,
> sliced so each phase ships something coherent and playable. Technical decisions
> (engine, stack, asset pipeline) live in the [ADRs](../../adr/).
> The concrete **content** these stories operate on — which breeds, tricks, and
> scenarios exist — lives in [content-catalog.md](https://github.com/Kilars/braa/blob/deprecated-game/.docs/content-catalog.md); stories
> here reference its IDs.
>
> **Format:** every item is a user story —
> *As a [role], I want [capability], so that [benefit]* — with acceptance
> criteria. Feature stories use the **player** role; decisions that can't be
> defaulted use a **product-owner** role; constraints that apply everywhere use a
> player role too (see Cross-cutting).
>
> **Phasing rule:** every phase ends on something you can *play and look at*, not
> a half-wired system. **Phase 1 is the whole bet** — the core "mark the moment"
> verb, made genuinely good, on one trick. A phase is **declared done only on the PO's
> Visual-Review sign-off**, never on "code compiles + tests green."
>
> **Work-ahead exception (so the build loop never idle-spins on a blocked phase):** when
> the current phase is *exhausted* — all its stories built + tests green + construction-audit
> clean, and every open flag busted-or-owner-gated, so it is blocked **purely** on owner
> assets + the human sign-off — the loop may build the **next** phase's stories
> **provisionally**. This is subordinate, not advancement: it never counts as sign-off, it
> stays **dormant** in the live build so it can't disturb the current phase's play-test, and
> it is **preempted** the instant current-phase work reappears (a PO reopen, a new/un-busted
> flag, a regression). The spirit of "the whole bet" holds — the core is still proven before
> anything is *declared* done — the loop just stops wasting cycles while it waits on a human.

---

## Spec layout

This spec is split per phase. The always-true frame — North Star, Cross-cutting,
Non-Goals — lives in this index; each phase, the parked backlog, and the PO log are
their own files alongside it.

- [Phase 1 — the perfect single mark](phase1.md) — **the whole current bet**
- [Phase 2 — more tricks, same quality bar](phase2.md)
- [Phase 3 — dog breeds](phase3.md) *(provisional)*
- [Phase 4 — difficulty](phase4.md)
- [Phase 5 — better marker words](phase5.md)
- [Phase 6 — play mode](phase6.md) *(provisional)*
- [Phase 7 — training-page visual enhancement](phase7.md)
- [Beyond the phases](beyond.md) *(parked)*
- [Product Owner Review](po-review.md) — PO play-test log; the build loop reads it
  for new directives and the PO pass appends here.

---

## North Star

- **NS-1 — The one good moment.**
  *As a player, I want to watch a dog, wait for the exact instant it sits, and tap
  **BRA** to a payoff of voice + sound + the dog's reaction all landing on the
  beat, so that I immediately want to do it again.*
  Acceptance:
  - Every later story serves this moment; anything that doesn't is out of scope.

---

## Cross-cutting (apply to every phase)

- **X-1 — Portrait phone only.**
  *As a player, I want the game built for one-hand portrait phone use, so that it
  fits how I actually play.* (No landscape/tablet/desktop.)

- **X-2 — One verb, always.**
  *As a player, I want depth to come from reading the dog, not from more buttons,
  so that the game stays a single satisfying tap.* (Design Principles)

- **X-3 — The mark always feels good.**
  *As a player, I want voice + SFX + dog reaction on every successful BRA, so that
  the payoff never gets stale.* (Design Principles)

- **X-4 — Reads first, looks the part.**
  *As a player, I want Pokémon-GO stylized-realism throughout, so that the dog
  always reads as a real dog and as its breed.* (D1–D2 and D4–D9 never waivable;
  D14)

- **X-5 — Reduced motion, never less information.**
  *As a motion-sensitive player, I want motion cues dampened but never removed, so
  that every state stays distinguishable for me.* (D13)

- **X-6 — Quality gates hold.**
  *As the product owner, I want every visual task closed by Visual Review and
  every piece of game logic gated by TDD, so that "it compiles / tests pass" is
  never mistaken for done.* (CLAUDE.md)

- **X-7 — Fully offline-capable.**
  *As a player, I want the whole game to run with no network after the first load
  — e.g. on a plane — with progress saved locally and no account or server, so
  that it just works anywhere.*
  Acceptance:
  - After first load, every phase is fully playable with the network off
    (airplane mode): no request blocks gameplay.
  - All assets (engine/WASM, model, audio) are cached on first load; saves are
    local (Godot `user://`, IndexedDB-backed on web). No backend.
  - *How* this is achieved rides on the engine/PWA decision (ADR-0001).

---

## Non-Goals (scope boundaries, not stories)

No landscape/desktop builds; no multiplayer/social; no monetization/IAP; the
kennel is **not** a standalone auto-training game (active timing stays the only
skill engine).
