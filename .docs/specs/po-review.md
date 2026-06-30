## Phase Sign-off

> **Permanent, append-only — never pruned.** One line per phase the PO has play-tested
> **clean** on the real running build (its Visual Review gate, e.g. P1-10, passed). This is
> the explicit done-gate: the build loop reads it to know which phase is current — the
> **current phase is the lowest-numbered `phaseN.md` NOT listed here**. A phase is *not*
> advanced just because its code compiles and tests are green; it advances only when it
> appears below. (List empty ⇒ current phase is Phase 1.)

_(none yet — current phase is Phase 1)_

---

## Product Owner Review

> Owner play-test notes from driving the **real running game** on a phone-portrait
> viewport (390×844). Each pass replays the **current phase** (the lowest phase not yet in
> Phase Sign-off above), prunes what is now fixed, and lists concrete, buildable
> directives. The build loop turns these into tasks. **Prune-as-you-go applies to THIS
> section only — never touch the Phase Sign-off list above except to append a new
> sign-off.**

### PO Review — 2026-06-30

Re-verification pass. Drove the **LIVE deployed Pages site itself** (https://kilars.github.io/braa/)
at 390×844 in headless Chromium (SwiftShader == the deployed GL Compatibility renderer),
and independently re-ran every Phase-1 acceptance check on the running build — boot log,
a no-seam apex-tell burst, **real BRA taps**, the timing readout, and a magnified coat
capture. The live boot log still reports the licensed build —
`dog loaded: res://assets/models/dog_licensed.glb (1 coat surface(s) forced opaque)` and
`dog can Sitt — looping a sit every 1.2s (real apex from the licensed Labrador)` — and the
full loop runs there: idle → build → clear seated apex → apex tell → mark → loop. **Every
claim from the prior pass still holds** on my own fresh capture; nothing newly broke and
nothing was newly fixed to prune. Phase 1 is **not** signed off: the only remaining gaps
are owner-gated — the spoken-voice on-device listen and the coat re-export. Do not advance
to Phase 2.

**The blocker stays gone (P1-4 — proven live again, no seam):** a free-run 50-frame burst
across several sit cycles, with **no `?bra_force_tell` seam**, shows the warm-gold apex ring
at the seated apex — **max 3082 gold px, gold on 4/50 frames** (~560 ms sampling; a brief
~0.2 s tell), and **dark in idle** (per-frame: long runs of 0, spiking 2281 / 2363 / 2912 /
3082 at the apexes). The seated apex frame reads cleanly: clear Labrador, gold ring framing
the marker, "BRA" fully legible inside it (`.screenshots/po2-live-apex.png`); idle frame has
the button band dark, no ring (`.screenshots/po2-live-idle.png`). This is the honest live
"now" cue, not a forced seam.

**What holds up (re-verified live this pass on my own captures, keep it):**
- **The BRA tap really scores and pays off (P1-5 / P1-6).** I clicked the live BRA button
  70 times across sit cycles (real Playwright pointer events on the canvas, no seam); **7 of
  them landed a successful mark and fired the dog reaction** (`window.__bra_reaction_n` went
  0 → 7). Post-tap frames catch the dog's open-mouth perk-up reaction
  (`.screenshots/po2-live-aftertaps.png`). Blind taps with no window open simply do nothing —
  no false payoff.
- **Apex ring frames "BRA", doesn't bury it (P1-4 polish).** The gold ring rings the marker
  and the "BRA" word stays fully legible inside it (`.screenshots/po2-live-apex.png`).
- **Tier readout sits in clear sky above the crown, legible, dark-outlined (P1-7).** Pinned
  PERFECT flashes bold gold and MISS flashes grey, each high above the dog's head well clear
  of the ears, with a dark outline that pops against the sky
  (`.screenshots/po2-readout-perfect.png`, `.screenshots/po2-readout-miss.png`); no ear/crown
  overlap. The readout is driven off the same `_on_bra_pressed` tap path as the reaction that
  I confirmed firing, so it flashes on real marks too.
- **Reaction reads as positive (P1-6, visual half).** Real marks visibly perk the dog up —
  head high, mouth open (`.screenshots/po2-live-aftertaps.png`).
- **The dog reads, the sit is legible, it stays centered, opaque coat, contact shadow, and
  the loop repeats with NO console errors (P1-1/P1-2/P1-3/P1-9).** Clear Labrador silhouette,
  grounded by the shadow disc, no see-through panels, no primitive-blob flash, no T-pose, no
  drift. The console captured **zero** SCRIPT ERROR / page error across boot + ~50 s of play.
- **Live deployed Pages site serves the licensed Sitt build (P1-10 visual gate — stays
  CLEARED).** Driving the **live site itself** (not a local export) at 390×844, all of the
  above holds on the actual shipped build — the live-pixel confirmation the P1-10 gate names.
  (P1-8 reduced-motion was confirmed dampened-not-removed on a prior live pass — max 127 gold
  px vs normal, apex still readable by pose — and is unchanged this pass.)

#### Improvements (still open — owner-gated, not loop-buildable)

- **Coat UV/tangent seam down the chest/belly (P1-1 / P1-9).** Re-confirmed live this pass:
  magnifying the seated apex's chest (`.screenshots/po2-coat-magnified.png`) shows a hard
  vertical shading band down the body-symmetry centerline plus symmetric flank arcs — subtle
  at native phone size but a real shading artifact, not real fur, up close, and **unchanged**
  from the prior capture (no regression, no improvement). (What the 2026-06-29 note called a
  stray "sliver" *is* this centerline band — the 039 spike confirmed it is **not** stray
  geometry and **not** a transparency gap.) Root-caused to the **licensed asset's mirrored-UV
  / missing-tangent layout**; it is **owner-gated** — needs a re-export with baked tangents /
  a re-baked normal map (`.task-board/FLAGS.md`, 2026-06-30). Task 040's in-engine mitigation
  was correctly found to be a deploy no-op and rerouted, so **there is no new loop task here**.
  *Good looks like:* smooth opaque coat with no hard centerline band or flank arcs at any pose,
  confirmed by a magnified capture.

#### Sign-off is blocked only on owner/PO actions (no buildable Phase-1 code remains)

With P1-4 fixed, the two readout/ring improvements verified, and the **live deployed site now
confirmed serving the licensed Sitt build** (the 3rd blocker, cleared above), the visual core
loop is fully there on the real shipped build. Phase 1 is **not** signed off only because two
acceptance items remain that can be cleared solely off-loop:

1. **Spoken "Bra!" listen (P1-6).** Audio can't be heard in the headless harness. The
   espeak stand-in is wired and gated (silence on MISS/DEAD, payoff only on a successful
   mark), but the subjective "warm, Maren-style" delivery and "PERFECT brighter than OK"
   need an **on-device listen**, and the warm **human** Maren voice stays **owner-gated**
   (`.task-board/FLAGS.md`).
2. **Coat re-export (P1-1/P1-9)** — the seam above; owner-gated. (Still visible up close on
   the live build — a faint vertical centerline band + symmetric flank arcs — though subtle
   at native phone size.)

The live site is now confirmed serving the licensed build, so that gate is no longer
outstanding. When the owner supplies the warm human voice (and an on-device listen confirms
the delivery + "PERFECT brighter than OK") and the coat re-export lands, a PO pass can sign
Phase 1 off. Until then the build loop has **no remaining buildable Phase-1 task** — do not
invent one, and do not start Phase 2.

---

## Forward PO Directives (captured 2026-06-29)

> Owner design decisions captured ahead of their phase. **These are not current-phase
> play-test notes**, and the build loop should **not** action the Phase-2/4 items until
> that phase is current — they are already formalized into the phase specs cited below.
> Listed here only for provenance: what the PO asked for, and when. (The father pass owns
> the two sections above and leaves this one alone.)

### 2026-06-29 — grilled feature set (→ Phase 2 / Phase 4)

1. **Anti-mash freeze on BRA.** After every tap, lock BRA ~350 ms, swallow taps during the
   lock, don't reset the timer. → **P2-7**.
2. **A living dog: wander + variable rhythm + feints.** The dog roams a bounded patch on no
   fixed cadence and sometimes fakes a sit; only a real, completed Sitt is markable. → **P2-8**
   (rides the garden, P2-10).
3. **Negative learning.** Wrong-timing / wrong-moment taps **remove** learning — gentle by
   default, erodible, floors at 0, mastery is a safe checkpoint; a bad tap shows a confused
   beat. → **amends P2-4**; harshness scales in **P4-2**.
4. **A fading timing trainer.** A bold approach-ring "now" cue for a new trick that fades with
   the learned bar and is gone at mastery; honest (rides `SitWindow`), dark during feints.
   → **P2-9**.
5. **The garden.** Look-down Pokémon-GO view — sky + sun above, grass below, BRA floating over
   the grass; fixed camera, dog roams a bounded patch. Functional garden in Phase 2 (it enables
   the wandering); environment art polish deferred to **Phase 7**. → **P2-10**.

### 2026-06-29 — the voice is not "placeholder-acceptable" (current phase, P1-6)

The synthesized **sine-tone beep** was not an honest attempt at a spoken "Bra!". A *genuinely
spoken* word is now required for Phase 1 (P1-6 amended): an offline-TTS stand-in (`espeak-ng`
"Bra!", `assets/audio/bra_tts_placeholder.wav`) ships until the warm **human** Maren recording —
which is **owner-gated** — is supplied. The owner gap is an **open flag** (`.task-board/FLAGS.md`);
the wiring is **task 035**. This is current-phase work (not parked under "Forward").
