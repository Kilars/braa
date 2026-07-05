**PO Review**

## Phase Sign-off

> **Permanent, append-only — never pruned.** One line per phase the PO has play-tested
> **clean** on the real running build (its Visual Review gate, e.g. P1-10, passed). This is
> the explicit done-gate: the build loop reads it to know which phase is current — the
> **current phase is the lowest-numbered `phaseN.md` NOT listed here**. A phase is *not*
> advanced just because its code compiles and tests are green; it advances only when it
> appears below. (List empty ⇒ current phase is Phase 1.)

- **Phase 1 — SIGNED OFF 2026-06-30 (owner, larssski).** Played the live deployed build
  (https://kilars.github.io/braa/) at 390×844: licensed Labrador loads (no primitive flash),
  centered + shadow-grounded, idle → sit → clear seated apex → honest apex tell → BRA tap →
  joyful reaction → loop, all P1 stories (P1-0…P1-9) pass, logic is test-first, verify green.
  Accepted **as complete as best as possible**: the two residual gaps are owner-gated polish,
  not core-loop defects, and ship with honest stand-ins — the genuinely-spoken espeak "Bra!"
  (warm human Maren recording drops in under the same cue id, no code change) and the coat
  UV/tangent seam (a licensed-asset re-export, tracked as an open flag). Both remain open
  flags for the owner to close later; neither blocks the core mark. **Phase 2 is now current.**

- **Phase 2 — Visual Review passed 2026-07-01 (PO, father pass).** Played the current HEAD
  (`7a3f12f`) on a 390×844 phone-portrait viewport — both the local licensed bundle (`build/web`,
  the 38 MB pck rebuilt 17:26, after the 066 commit at 17:21) served over http in headless Chromium
  (SwiftShader == the deployed GL Compatibility renderer) **and** the **live Pages site**
  (https://kilars.github.io/braa/). Zero console errors on every run. The prior pass's sole blocker
  — "the roster is owner-gated, there is no second trick" — was a **behavior≠inventory error**: the
  licensed Labrador already held **Ligg** (`Lie_*`) and **Legg deg** (`Lie_belly_*`), and they are now
  wired as real, distinct tricks (065 / 067) behind a live **trick selector** (066), so the phase's
  headline — *more tricks at the Sitt standard* — is genuinely delivered. Verified in my own pixels:
  **P2-1** a top chip row (Sitt · Ligg · Legg deg), tapping a chip repoints the trick, the gold
  highlight + per-trick learned pip follow, live on **both** builds; **P2-2 / P2-3** three visibly
  **distinct** apex poses (Sitt = upright seated chest-high; Ligg = low sphinx lie; Legg deg = flatter
  belly-settle, forelegs sprawled), each reading as its behaviour, each turning to face the camera at a
  PERFECT apex (P2-11), no T-pose / foot-slide / snap, honest apex tell; **P2-4** PERFECT climbs the
  bar → full-**gold mastery latch**, a mistimed tap **erodes** it (bar visibly drops ~40 %→30 % with a
  brief **red setback wash** + the dog's confused beat), floors at 0, no hard-fail; **P2-5** the
  mastered bar (the very latest marks) **persists** across a same-origin reload, per-trick isolated;
  **P2-7** anti-mash lock swallows taps; **P2-8** the dog wanders varied headings on a 0.8–2.0 s
  feinting cadence; **P2-9** the fading cyan approach ring lands on the apex, distinct from the gold
  tell; **P2-10** the garden fills the phone, sun + sky + painterly grass, BRA over the grass, no
  letterbox / cyan seam. Re-checked **Phase 1** on the same build — the Sitt core loop
  (idle → wander → face-camera → seated apex → tell → PERFECT → joyful reaction → loop) is intact, no
  regression. Accepted **as complete as best as possible**: the residuals are owner-gated, not core
  defects, and ship honest — the **expansion** tricks *Gi labb / Rull / Snurr* have **no** clip in the
  licensed asset (manifest-busted; a standing owner flag, and the P2-2 starter set Sitt/Ligg/Legg deg
  *is* complete), and the Phase-1 human "Bra!" voice (Piper stand-in) + coat UV/tangent seam remain
  open flags. None blocks the core mark. **Phase 3 is now current.**

- **Phase 3 — SIGNED OFF 2026-07-04 (owner, larssski).** Dog-breeds phase accepted done at HEAD
  `b2041dc`. The buildable spine shipped and replays clean on the real build: coin economy + drawn
  coin readout, one-active-trick completion menu (learned / available / locked + coins), centered
  camera-facing dog with the scratch feint, late-biased PERFECT window + round BRA button,
  `BreedPersonality` levers, chocolate-Labrador coat variant, the collect → adopt → switch → persist
  roster, the spotlit breed-select showcase (drawn chevrons, training HUD hidden), the textured
  garden, and the joy-beat reaction (no rear-spin / flick). All owner actionable notes (1–7) were
  addressed (tasks 070–079 + 077) and the two showcase bugs are fixed (089 / 090). Accepted
  **as complete as best as possible**: the residual gaps are owner-gated, not core-loop defects, and
  ship with honest stand-ins — a genuinely **distinct second breed model** (P3-D1/D2/D4) and a
  camera-facing **signature clip** (P3-2), the warm human "Bra!" voice, and the live-telemetry
  `POSTHOG_TOKEN` secret. All remain open flags for the owner to close later; none blocks the core
  loop. **Phase 5 is now current** (spec numbering skips 4/7 — difficulty moved to Phase 9).

- **Phase 5 — SIGNED OFF 2026-07-04 (owner, larssski).** Marker-words phase accepted done. The
  buildable stories shipped and verify green (tasks 091–095): unlockable stronger Norwegian marker
  words with per-word timing window + cooldown, the menu showing each word's cost/rest **before**
  loading, the fired word popping up from the BRA button on a successful mark, and a legible
  resting/cooldown readout. Accepted **as complete as best as possible** — the only residual is
  owner-gated: the warm **human "Bra!" / Maren voice** recordings for the alternative words ship
  with honest synthetic stand-ins under the same cue ids (open flag), swappable with no code change.
  **Phase 6 is now current.**

- **Phase 6 — Visual Review passed 2026-07-05 (PO, father pass).** Design-system + training-page
  ambiance phase accepted done at HEAD `a3750fe`. Played the fresh local licensed bundle (`build/web`,
  rebuilt at this HEAD via `verify.sh`, gate green) served over http and driven in headless Chromium at
  390×844 — SwiftShader == the deployed GL Compatibility renderer. **Zero console errors on every run**
  (idle ×3, a 30-frame `?bra_autotap=1` mark burst, the completion menu on mastery). The training page
  now reads as the goal (`assets/goal-training-screen.png`): a clean rounded HUD (white **"Triks"** pill
  with the drawn 3-bar menu glyph + **coin** pill, slate **"Sitt"** label, learned bar with `%`), the
  licensed dog **centered and grounded on green grass**, a **slim winding tan path** that passes to the
  **right** of the dog and recedes to a small **cottage** (cream walls, blue door/window, gable roof)
  top-right, a **white picket fence** across the mid-ground with a gate gap, **gold coins** framing the
  dog, a grounding shadow, green bushes, and a big rounded **BLUE BRA** button anchored at the bottom —
  all in the DS palette (sky/grass/BLUE, GOLD reserved to the coin). The completion menu is a light DS
  **paper card** (slate "Tricks" heading, pale-pill trick/breed/marker-word rows, blue accents,
  Norwegian actions). The three round-2 garden directives from the `6096a41` pass are all **fixed and
  verified in my own pixels**: (1) the **path** no longer over-corrects into a dirt wedge — the dog sits
  on green grass and the path is a slim ribbon to the side; (2) the **coins** read as real gold — an
  in-world gold-pixel scan (excluding the HUD pill) counts **9146** coin-gold pixels framing the dog on
  both sides (was **zero** the prior pass), and a 3× zoom shows actual gold discs; (3) the **house**
  reads as a cozy cottage, not a blown-out tower. Re-checked the earlier signed-off phases on the same
  build — **no regression**: **Phase 1** the Sitt core loop (idle → wander → face-camera → seated apex →
  cyan approach ring → mark → joyful reaction → loop) replays clean across the burst; **Phase 2** the
  three-trick roster (Sitt learned / Ligg / Legg deg available) + learned bar render; **Phase 3** the
  coin economy + breeds (Labrador active / Chocolate locked 30) render; **Phase 5** the marker words
  (Bra! active / Dyktig! switch / Flink! / Super! / Kjempebra! locked) render — all intact in the
  completion menu. Accepted **as complete as best as possible**: Phase 6's own stories are fully
  buildable and all delivered; the only residuals are the same long-standing **owner-gated** flags
  carried from earlier phases (the warm human "Bra!" / Maren voice, the coat UV/tangent re-export),
  which ship with honest stand-ins and don't touch the design-system work. **Phase 8 (kennel) is now
  current.**

---

## Product Owner Review

> Owner play-test notes from driving the **real running game** on a phone-portrait
> viewport (390×844). Each pass replays the **current phase** (the lowest phase not yet in
> Phase Sign-off above), prunes what is now fixed, and lists concrete, buildable
> directives. The build loop turns these into tasks. **Prune-as-you-go applies to THIS
> section only — never touch the Phase Sign-off list above except to append a new
> sign-off.**

### PO Review — 2026-07-05

Phase 8 (kennel) is current. Re-played the kennel on the **live deployed Pages site**
(https://kilars.github.io/braa/, HEAD `4e14c69`) at 390×844 in headless Chromium — the deployed build
is the only one that renders the **licensed Labrador** (the local `verify.sh` export bundles the CC0
dev dog: boot log `dog loaded: res://assets/models/dog.glb … no Sitt clip`), so item 1 below — a
render-quality claim about the licensed dog — can only be judged there, exactly as Phase 1 was. Live
boot log confirms the licensed rig (`dog loaded: res://assets/models/dog_licensed.glb … dog can Sitt`).
**Zero relevant console errors; browse-grid → inspect-modal driven with real canvas taps.** **The prior
voxel-dog blocker is FIXED — but the coat tint miscolours the one real breed (a blue Labrador), which
keeps the phase off sign-off.**

**Fixed / verified working in my own pixels:**

- **Kennel dogs now read as the stylized-realism licensed Labrador — prior Improvement #1 core
  RESOLVED (116).** The blocky CC0 voxel dog is gone; every cell and the modal header now render the
  game's **actual licensed Labrador rig** via a live SubViewport, standing in a 3/4 front pose with
  the **head/face turned toward the viewer** (not rear-/side-slumped), behind faint steel bars —
  matching the training page's quality (`.screenshots/LIVE-kennel-grid.png`, 3× crop of Bella confirms
  a real dog, not a block). This clears the X-4 «reads as a real dog» bar for the render itself.
- **Grid fill** — the 8 cells in 4 rows span the full 844 px portrait, no dead grey (115 held up on
  the licensed build too). Header «Kennelen · Profesjonell fasilitet» + coin chip up top.
- **K-2 inspect modal** opens on tap (cell centres re-published correctly after the 116 refactor):
  Bella's panel shows the warm blurb, 4 data-driven stat rows (Læreevne 5 / Energi 5 / Mot 4 /
  Fokus 5), Raseegenskaper chips (Snill · Tålmodig · Glupen), the «Godbit-radar» Unikt-trekk card, the
  K-8 trick list («Kan lære: Sitt · Ligg · Legg deg»), and the green «Trener nå» action for the owned
  dog (`.screenshots/LIVE-kennel-modal.png`).
- **Names / breeds / prices / tags** all correct at a glance; Bella «Labrador retriever» owned + «Din»
  tag, Trulte «★ Påskeegg» + «Gratis», the rest priced gold. (K-3/K-4/K-5/K-6/K-7 adopt / gate /
  switch / easter / persist were driven end-to-end clean in the prior pass at `f5b8efb`; 116 changed
  only the portrait render + bar tint, and the modal/tap path replays intact here.)
- **No regression:** closing the kennel restores the Phase-6 training page and the Phase-1/2 core mark
  loop — the warm cream licensed Labrador centred facing camera on green grass, cottage / fence / gold
  coins / BLUE BRA button all present (`.screenshots/LIVE-training.png`).

**Improvements — one shortfall keeps the phase off the sign-off line**

1. **The per-breed coat tint turns the dog its rarity-band colour, so the one real breed — Bella the
   Labrador — renders BLUE, not her warm training-page coat (X-4 «reads as its breed» not met).** The
   116 render tints the neutral coat *toward each cell's `band_tint`* (`kennel_screen.gd:513`,
   `_band_dog_tint(row.band_tint)`), so every dog's coat = its band colour. For most breeds the band is
   a plausible dog hue (Sol golden, Balder / Sniff brown, Nova / Trulte grey) — fine. But **Bella sits
   on a blue band and therefore renders as a blue-grey dog** (`.screenshots/LIVE-kennel-grid.png`,
   top-left cell + 3× crop), while the **very same dog is a warm cream Labrador on the signed-off
   training page** (`.screenshots/LIVE-training.png`). A player owns Bella, sees her cream in training,
   then blue in the kennel — a jarring cohesion break on the *flagship* dog, the one breed we have a
   real model for. A demanding owner won't ship a blue Labrador. **This is not owner-gated** — it's a
   tint-calibration fix. *Good* = the coat modulate is decoupled from the raw band-background colour so
   every dog reads as a **plausible dog coat**, and Bella-the-Labrador specifically reads as her warm
   training-page coat (cream/yellow), not blue. The rarity band can stay coloured behind the bars; only
   the dog's coat needs a natural hue. Independent review then confirms it on the running licensed
   build. (Minor, fold in while here: in the modal the «Bella» title text overlaps the dog render in
   the header band — nudge the title clear of the portrait.)

**Owner-gated residual (honest, NOT a blocker to sign-off once #1 lands):** all 8 breeds are
tinted stand-ins of the one available rig, so every dog's trick list is the shared core (Sitt / Ligg /
Legg deg) — distinct **breed models** and camera-facing **signature clips** are the long-standing owner
gates (BUST-068 residual, P3-2), already flagged. K-8 is honest here: a breed only offers a trick its
rig actually has a clean clip for (behaviour ≠ inventory), and no per-breed trick is faked.

**Not signed off** — the spine is complete and clean in pixels, the grid fills the portrait, and the
kennel dogs now read as the stylized-realism licensed Labrador (the big prior blocker is fixed). The
one remaining shortfall is the coat-tint miscolour that makes Bella-the-Labrador read blue (item 1).
Once the coats read as natural dog colours — Bella matching her warm training-page coat — and
independent review confirms it on the running licensed build, the phase is sign-off ready (its only
other residuals are the already-flagged owner gates above).
