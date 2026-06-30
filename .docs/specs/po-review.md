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

Drove the **real Godot Web/PWA build** at 390×844 in headless Chromium — a local licensed
export earlier, and **this pass the LIVE deployed Pages site itself** (https://kilars.github.io/braa/).
The live site's own boot log confirms it now serves the licensed build —
`dog loaded: res://assets/models/dog_licensed.glb (1 coat surface(s) forced opaque)` and
`dog can Sitt — looping a sit every 1.2s (real apex from the licensed Labrador)` — and the
full sit loop runs live there: the dog idles, builds into a clear seated apex, the apex
tell fires, score marks, and it loops. **The carried-over P1-4 blocker is RESOLVED**, and
the prior pass's third gap — a **live-deployed-site visual check** — is now **cleared**
(see *What holds up*). Phase 1 is **not** signed off this pass: the only gaps left are
owner-gated — the spoken-voice on-device listen and the coat re-export. Do not advance to
Phase 2.

**The blocker is gone (P1-4 — proven live, no seam):** a free-run 90-frame burst across
several sit cycles, with **no `?bra_force_tell` seam**, shows the warm-gold apex ring at the
seated apex — **max 2621 gold px, 4/90 frames**, the pulse building and tapering across the
button band (2621 → 2145 → 374 → 120) like a soft "now" pulse, and dark in idle
(`.screenshots/po-live-apex-burst.png`). This is the binding live proof the prior pass
demanded (a no-seam burst with max gold > 0), **not** the forced seam. The core "now" cue
now reads in actual play — timing is a readable skill again, not a blind guess.

**What holds up (re-verified live this pass, keep it):**
- **Apex ring frames "BRA", doesn't bury it (P1-4 polish — was an improvement, fixed).**
  In the live apex frame the gold ring rings the marker and the "BRA" word stays fully
  legible inside it (`.screenshots/po-live-apex-burst.png`).
- **Tier readout sits in clear sky above the crown (P1-7 polish — was an improvement, fixed).**
  Forced PERFECT/OK/MISS each flash high above the dog's head, well clear of the ears
  (`.screenshots/033-readout-perfect.png`); the prior ear/crown overlap is gone.
- **Reduced motion dampens the tell, never removes it (P1-8).** With `prefers-reduced-motion`
  the apex ring is faint but present (**max 127 gold px** vs 2621 normal) and the seated
  apex stays fully readable by pose (`.screenshots/po-reduced-apex.png`).
- **Reaction reads as joy (P1-6).** A live PERFECT mark fires a clear happy hop — front paws
  up, head high, ears flying (`.screenshots/po-reaction-06.png`).
- **Readout contrast (P1-7).** All three tiers carry a dark outline and pop against the sky
  (outline px: miss 32019 / ok 29892 / perfect 30667).
- **The dog reads, the sit is legible, it stays centered, opaque coat, contact shadow, and
  the loop repeats with no console errors (P1-1/P1-2/P1-3/P1-9).** Clear Labrador silhouette,
  grounded by the shadow disc, no see-through panels, no primitive-blob flash.
- **Live deployed Pages site serves the licensed Sitt build (P1-10 visual gate — was the 3rd
  sign-off blocker, now CLEARED).** Driving the **live site itself** (not a local export) at
  390×844, the boot log reports the licensed Labrador with a real Sitt looping every 1.2s; the
  dog sits legibly, stays centered, and is grounded by the shadow disc every cycle (idle →
  build → seated apex → loop), and the **apex tell fires live on the deployed build** — a
  warm-gold ring framing "BRA" at the seated apex (live burst: **max 678 gold px, gold on
  3/60 frames** sampled at 500 ms over 30 s, consistent with a brief ~0.2 s tell; dark in
  idle). No console errors beyond benign GL `ReadPixels` perf notes, no T-pose / blob flash /
  drift / clipping. The visual core of P1-1/2/3/4/5/9 holds on the actual live site — this is
  the live-pixel confirmation the prior pass demanded, taken on the deployed build the P1-10
  gate names.

#### Improvements (still open — owner-gated, not loop-buildable)

- **Coat UV/tangent seam down the chest/belly (P1-1 / P1-9).** Magnified, the opaque coat
  shows a hard vertical shading band down the body-symmetry centerline plus symmetric flank
  arcs (`.screenshots/po-coat-magnified.png`) — subtle at native phone size but a real
  shading artifact, not real fur, up close. (What the 2026-06-29 note called a stray "sliver"
  *is* this centerline band — the 039 spike confirmed it is **not** stray geometry and **not**
  a transparency gap.) Root-caused to the **licensed asset's mirrored-UV / missing-tangent
  layout**; it is **owner-gated** — needs a re-export with baked tangents / a re-baked normal
  map (`.task-board/FLAGS.md`, 2026-06-30). Task 040's in-engine mitigation was correctly
  found to be a deploy no-op and rerouted, so **there is no new loop task here**. *Good looks
  like:* smooth opaque coat with no hard centerline band or flank arcs at any pose, confirmed
  by a magnified capture.

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
