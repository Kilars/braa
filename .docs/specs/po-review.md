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

### PO Review — 2026-06-29

Re-drove the **real Godot Web/PWA build** (local export of the licensed Labrador —
`build/web`; console confirms `res://assets/models/dog_licensed.glb`, "dog can Sitt",
looping every 1.2 s) in a headless browser at 390×844. Captured the idle pose, a free-run
burst across several full sit cycles, apex-synced frames (the live PERFECT path via
`?bra_autotap=1`), forced-tell / forced-tier reference frames, and 10 real BRA taps —
reading the live console throughout. **Phase 1 is still NOT done: the apex tell — the
core "now" cue (P1-4) — renders only under the `?bra_force_tell=1` capture seam and is
invisible in actual play. Do not advance to Phase 2.**

Most of the 2026-06-28 defects are genuinely fixed and are pruned from this log (see
"what holds up"). The apex tell is the one carried-over blocker — with a sharper
diagnosis now: it is a **live-path** failure, not a draw or curve failure.

**What holds up (re-verified live, keep it):**
- **Scoring honest end to end (P1-5/P1-7).** Autotap scored PERFECT; 10 blind manual taps
  scored only MISS / DEAD and did nothing — no penalty, no payoff. Console tiers never
  contradicted the readout.
- **Contact shadow grounds the dog (P1-1 — was a blocker, fixed).** A soft dark disc sits
  under the feet in every pose; the dog no longer floats.
- **Coat is opaque (P1-1/P1-9 — was a blocker, fixed).** Magnified, no sky shows through
  the chest/belly/flanks at any pose — the see-through panels are gone. (Faint hairline
  seams remain — see Improvements.)
- **Readout contrast fixed (P1-7 — was an improvement).** MISS / OK / PERFECT each carry a
  dark outline and pop against the bright sky; PERFECT is the brightest. All three legible
  at 390×844.
- **Reaction reads as joy (P1-6 — was an improvement).** A successful mark fires a clear
  happy hop (front paws up, ears flying), blended cleanly from the seat — not a lone bark.
- **The dog reads, the sit is legible, it stays centered, and the loop repeats**
  idle → sit → apex → reaction → idle with no console errors (P1-1/P1-2/P1-3/P1-9).

#### Bugfixes

- **The apex tell still never renders in live play (P1-4 — blocker, carried over).** With
  the `?bra_force_tell=1` seam the warm-gold halo+ring renders boldly on the BRA marker
  (saturated-gold detector: **1647 gold px, 6/6 frames**). In **normal play it never
  appears**: a free-run 90-frame burst across multiple full sit cycles scored **0 gold px
  in 0/90 frames** with the same detector, and the seated **apex** frame captured the
  instant a live PERFECT mark fired (`?bra_autotap=1`, which drives the real live-intensity
  path) shows a plain grey BRA slab — no ring. *Why it's wrong:* P1-4 is the core "now"
  cue; without it timing is a blind guess, not a readable skill — this is the same
  2026-06-28 blocker, still open. The forced-only pixel-proof (`web_capture_apex.mjs` with
  `BRA_FORCE=1`) passed and **masked** it: the gate exercised the seam, not gameplay.
  *Suspect (sharper now):* the draw and the curve are both proven good — the forced
  `set_intensity(1.0)` draws fine, `ApexTell.intensity()` returns ~0.65→1.0 near the apex,
  and autotap confirms the clock reaches the band. The fault is in the **live application**
  at `main.gd:181-184` (the `elif _tell != null and _session.is_open()` branch) — the
  live-intensity `set_intensity()` never reaches the marker as a visible value. *Good looks
  like:* on the running 390×844 build, **with no seam**, a soft warm pulse is clearly
  visible ringing the BRA marker, building to a peak at the seated apex and dark in idle.
  **The binding proof must be a live capture** — a free-run burst with max gold > 0, or a
  `?bra_autotap=1` apex frame showing the ring — **not** the `bra_force_tell` seam, which
  must no longer be accepted as the gate.

#### Improvements

- **Residual coat seams + a stray geometry sliver (P1-1 / P1-9).** Magnified, the now-opaque
  coat still shows faint symmetric hairline seams down the chest and curved arcs across both
  flanks, plus a small hard-edged sliver dangling between the front legs (clearest in idle).
  Subtle at native phone size, but they break the clean real-dog silhouette up close. *Good
  looks like:* smooth opaque coat with no hard-edged seams or stray dangling geometry at any
  pose, confirmed by a magnified capture.

- **The apex ring buries the "BRA" word at peak (P1-4 polish).** In the forced-tell
  reference the gold ring is centered tightly over the button and partially occludes the
  "BRA" text. When the live tell is fixed, size/position the ring to frame the marker
  without hiding the word.

- **Tier readout lands on the dog's head, not clear sky (P1-7 polish).** The PERFECT/OK/MISS
  word flashes low enough to overlap the dog's ears/crown. It's legible (the dark outline
  carries it), but it would read cleaner pulled up into clear sky above the dog.

*Scope note: audio can't be heard in the headless harness, so the spoken "Bra!" voice/SFX
(task 035 espeak placeholder — wired + gated: console confirms silence on MISS/DEAD, payoff
only on a successful mark) is judged only as wired. It needs an on-device listen, and the
warm human Maren voice remains owner-gated (`.task-board/FLAGS.md`), before final sign-off.*

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
