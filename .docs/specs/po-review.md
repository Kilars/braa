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

### PO Review — 2026-06-28

Drove the **real Godot Web/PWA build** (local export of the licensed Labrador, served
over http) in a headless browser at 390×844, reading the live console for scored tiers
and analysing ~220 captured frames pixel-by-pixel. **Phase 1 is NOT done — it has open
visual defects, the most serious being that the apex tell never renders. Do not advance
to Phase 2; reopen Phase-1 work below.**

> Pruned the prior `2026-06-27` note: it described the **deprecated Babylon build**, not
> this one — it cited a CSS `--apex` variable and certified Phase-2 features (Ligg chip
> row, learned bar, IndexedDB persistence, pause/▶) that **do not exist** in the current
> Godot `main.gd`. None of Phase 2 is built; Phase 1 is the whole current scope.

**What holds up (re-verified live, keep it):**
- **Scoring is honest end to end.** 60 real BRA taps scored PERFECT / OK / MISS / DEAD;
  the bands match spec (PERFECT apex±80 ms, OK apex±200 ms), and a tap with no window
  open does nothing (P1-5/P1-7 logic). Console tiers never contradicted the readout.
- **The dog reads & the sit is legible.** Centered Labrador on a clean bright backdrop;
  the sit builds as one continuous fold to a clearly seated apex; head-top swings ~272 px
  between stand and seat, so the build→apex is readable on the dog (P1-1/P1-3).
- **The loop repeats** idle → sit → idle indefinitely with no console errors and no
  degradation across many cycles (P1-9).

#### Bugfixes

- **The apex tell never renders (P1-4 — blocker).** Across ~220 frames spanning many
  full sit cycles (apexes confirmed by the 272 px head-swing *and* by live PERFECT/OK
  scores), the warm-gold halo+ring (`ApexTellMarker`) **never appears** on or around the
  BRA marker: zero gold on the ring's left/right/bottom arcs in any frame, zero saturated
  gold anywhere near the marker. The same detector readily flags the dog's own tan paws,
  so the absence is real, not a capture gap. *Why it's wrong:* P1-4 is the core "now"
  cue — without it timing is a blind guess, not a readable skill, and the marker stays a
  dead gray slab through every apex. The unit tests pass (the `ApexTell` curve and
  `set_intensity` are correct) — this is a tests-green / pixels-wrong gap, exactly what
  the Visual Review gate exists to catch. *Good looks like:* on the running 390×844 web
  build a soft warm pulse is **clearly visible** ringing the BRA marker, building to a
  peak exactly at the seated apex and dark in idle — proven by a captured apex frame
  showing the gold ring. Suspects to check on the real canvas: `self_modulate` vs
  `modulate` on a custom `_draw`, the marker drawing *under* the opaque `Button`
  (z-order), or the marker rect not getting a size. Fix must be confirmed in pixels.

- **The dog floats — no contact shadow (P1-1).** In every pose (idle, build, seat,
  stand) the paws end against flat blue with nothing beneath, and the front paws dangle
  over the top of the BRA button. The `DirectionalLight3D` is created with shadows off
  and there is no blob/decal. *Why it's wrong:* P1-1 explicitly requires the dog
  "anchored by a contact shadow (not floating)"; floating breaks the grounded read and
  the Pokémon-GO look. *Good looks like:* a soft contact shadow under the feet (cheap
  blob decal or a ground plane catching the sun), present at idle and tracking the sit,
  so the dog clearly sits/stands *on* something.

- **Translucent "shell" artifacts on the dog body (P1-1 / P1-9).** Magnified, the
  Labrador shows semi-transparent ghost panels — a vertical see-through strip down the
  chest/belly and curved translucent surfaces across both flanks/haunches — present in
  every pose, idle and seated. They are geometric and consistent (not render noise),
  i.e. a model/material issue: a coat/fur shell (or duplicated mesh) importing as
  alpha-blended/two-sided instead of opaque. *Why it's wrong:* P1-1 wants a clean
  real-dog silhouette and P1-9 "no bugs"; the see-through flaps make the dog look broken.
  *Good looks like:* a solid, opaque coat with no see-through panels at any pose — set
  the offending surface(s) to opaque / cull backfaces (or drop the duplicate shell) in
  the import, confirmed by a magnified capture.

#### Improvements

- **Tier readout is too low-contrast to read (P1-7).** The PERFECT/OK/MISS word flashes
  at full opacity in the upper third, but OK (pale green) and especially MISS (light
  grey, `0.72`) sit at almost the same luminance as the bright-blue sky and are barely
  legible — "MISS" nearly disappears. It's a contrast problem, not opacity (captured
  well within the 0.6 s hold). *Good looks like:* a dark outline / drop-shadow (or
  higher-contrast fills) so every tier pops against the bright backdrop, PERFECT still
  the brightest — each word crisply readable at 390×844.

- **The "positive reaction" is a lone Bark and doesn't read as celebration (P1-6).**
  The licensed pack's only clip matching the reaction vocab is `Bark` (no
  wag/happy/excited/perk clip exists in the Labrador set), so a successful mark fires a
  single bark on a dog whose mouth is already open in idle — I could read no clear,
  joyful reaction in the post-mark frames; the dog just continued its stand/sit loop.
  Playing a (standing) Bark over the seated pose also risks a pose pop. *Good looks
  like:* a reaction that reads as joy at phone size — e.g. a small happy bounce/hop
  (the pack has `Jump_Place`/`JumpAir_low`) or a clear perk-up, blended cleanly from the
  seat with no snap, PERFECT brighter than OK — confirmed in a capture.

*Scope note: audio can't be heard in the headless harness, so the "Bra!" voice/SFX is
judged only as wired + gated (silent on MISS / dead tap) — worth an on-device listen
before final sign-off.*
