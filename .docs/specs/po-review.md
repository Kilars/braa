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

- **Phase 8 — Visual Review passed 2026-07-05 (PO, father pass).** Kennel browse-and-adopt roster
  accepted done at HEAD `0ff7902`. Played on the **live deployed Pages site**
  (https://kilars.github.io/braa/) at 390×844 in headless Chromium — the only build that renders the
  **licensed Labrador** (live boot log confirms `dog loaded: res://assets/models/dog_licensed.glb …
  dog can Sitt`); the deployed pck refreshed at 10:06 GMT to this HEAD, so item 1 below could be
  judged on the real rig exactly as Phases 1/2 were. **Zero relevant console errors; browse-grid →
  inspect-modal driven with real canvas taps.** The prior pass's sole blocker is **fixed and confirmed
  in my own pixels on the licensed build:** Bella-the-Labrador now renders as her **warm cream/golden
  training coat** on her blue owned-rarity band — no longer a blue-grey dog
  (`.screenshots/LIVE117-kennel-grid.png`, top-left cell); the 117 `KennelDog.portrait_tint()` decouples
  the coat modulate from the rarity `band_tint`, so the rarity band stays coloured while every dog reads
  a plausible coat (Bella cream, Nova grey, Balder/Sniff brown, Sol golden, Pontus grey, Lykke brown,
  Trulte grey-tan). The minor fold-in also landed: in Bella's modal the «Bella» title now sits on a
  **bottom nameplate clear of the dog's face** (`.screenshots/LIVE117-bella-modal.png`), which also shows
  the warm blurb, 4 data rows (Læreevne/Energi/Mot/Fokus), Raseegenskaper chips (Snill · Tålmodig ·
  Glupen), the «Godbit-radar» Unikt-trekk card, «Kan lære: Sitt · Ligg · Legg deg» (K-8), and the green
  «Trener nå» action for the owned dog. **K-1/K-3** the 8 cells (Bella · Nova · Balder · Sol · Pontus ·
  Lykke · Sniff · Trulte) fill the full 844 px portrait with no dead grey, correct names / breeds /
  prices / owned + «Påskeegg»/«Gratis» tags, under the «Kennelen · Profesjonell fasilitet» header + coin
  chip; **K-2** the inspect modal opens on tap; **K-3/K-4/K-5/K-6/K-7** adopt / affordability-gate /
  switch-to-training / Trulte free-adopt easter egg / persisted roster were driven end-to-end clean in
  the prior passes (`f5b8efb`), and 117 changed only the portrait tint + nameplate, leaving the tap/modal
  path intact. Re-checked the earlier signed-off phases — **no regression**: 117's diff is confined to
  `kennel_dog.gd` + `kennel_screen.gd` (touches no training / menu / economy / marker-word code), and
  closing the kennel restores the Phase-6 training page + Phase-1/2 core mark loop — cream Labrador
  centred facing camera on green grass, tan path, cottage, white picket fence, gold coins, blue BRA
  button (`.screenshots/105-kennel-03-closed.png`). Accepted **as complete as best as possible**: the
  only residuals are the long-standing **owner-gated** flags — distinct per-breed **models** (BUST-068,
  P3-D1/D2/D4) and camera-facing **signature clips** (P3-2), so all 8 breeds are honest tint stand-ins of
  the one licensed rig and share the core Sitt / Ligg / Legg deg trick list (K-8 is honest — a breed only
  offers a trick its rig actually has a clean clip for; no per-breed trick is faked). None blocks the
  kennel experience. **Phase 9 is now current.**

- **Phase 9 — Visual Review passed 2026-07-05 (PO, father pass).** Difficulty phase accepted done at
  HEAD `5331e49`. Played the fresh local licensed bundle (`build/web`, rebuilt at this HEAD via
  `verify.sh`, gate green — Sitt-capable Labrador) served over http and driven in headless Chromium at
  390×844 (SwiftShader == the deployed GL Compatibility renderer). **Zero console errors on every run**
  (fresh training boot, a `?bra_autotap=1` mastery burst, the completion menu on a normal dog and on a
  special dog). The two Improvements that blocked the prior pass are both **fixed and verified in my own
  pixels:** (1) the "Vanskelighet" rows now show the reward/challenge trade inline — Normal baseline / no
  annotation, **Hard «×1.4 mynt · smalere vindu»**, **Expert «×2 mynt · mye smalere vindu»** — same
  dimmed-subtitle treatment as the marker-word rows (Dyktig! «+15% · hviler 2»), derived from the
  `Difficulty` model, so the trade is legible at the point of choice (`.screenshots/PO9-01-normal.png`);
  (2) the special-dog lock now states the **reason** — on Nova (EPIC) the section carries the one-line
  note **«Spesialhunder trener alltid på Hard»** under the Vanskelighet heading, Normal/Expert greyed and
  Hard badged «Låst» (`.screenshots/PO9-03-locked.png`). **P4-1** a real canvas tap flips the global mode
  on a normal dog (Normal → Expert, `window.__bra_difficulty` normal→expert, «Valgt» badge moves) and is
  **swallowed** on a special dog (Nova stays Hard); **P4-2/P4-3/P4-4** the mode scales window radii, tell
  intensity, feint chance, bar erosion **and** the mastery coin payout on top of the breed (effective =
  breed × mode), wired + unit-tested; **P4-5** background grace is armed on the resume notification and
  unit-tested (inert headless). Re-checked the earlier signed-off phases on the same build — **no
  regression**: **Phase 1** the Sitt core loop (autotap mastered Sitt clean, licensed Labrador centred +
  grounded facing camera on green grass, `.screenshots/PO9-04-training.png`); **Phase 2** the three-trick
  roster (Sitt Learned / Ligg / Legg deg Available); **Phase 3** the coin economy + breeds (Labrador
  Active / Chocolate Locked 30, coin chip); **Phase 5** the marker words (Bra! Active / Dyktig! Switch /
  Flink! / Super! / Kjempebra! Locked); **Phase 6** the training page still pixel-matches the goal (tan
  path → cottage, white picket fence, gold coins, blue BRA button, DS paper completion card); **Phase 8**
  the kennel — the only kennel-code change since its sign-off is two **additive** pure lock predicates in
  `kennel_dog.gd` (`locks_difficulty()` / `locked_difficulty_id()`), which don't touch the render / adopt
  / modal path, and closing back to training restores the Phase-6 page. Accepted **as complete as best as
  possible**: Phase 9's own stories are fully buildable and all delivered; the only residuals are the same
  long-standing **owner-gated** flags carried from earlier phases (the warm human "Bra!" / Maren voice, the
  coat UV/tangent re-export, distinct per-breed models), which ship with honest stand-ins and don't touch
  the difficulty work. **Phase 10 (play mode) is now current.**

---

## Product Owner Review

> Owner play-test notes from driving the **real running game** on a phone-portrait
> viewport (390×844). Each pass replays the **current phase** (the lowest phase not yet in
> Phase Sign-off above), prunes what is now fixed, and lists concrete, buildable
> directives. The build loop turns these into tasks. **Prune-as-you-go applies to THIS
> section only — never touch the Phase Sign-off list above except to append a new
> sign-off.**

### PO Review — 2026-07-09 (PO, father pass 78) — **task 200 nav-pill AA fix VERIFIED in-pixel (17:1, was 2.4:1); ONE new buildable X-6: the SAME thin-stroke render-wash leaves the LearnedBar «Sitt» / «%» readout at ~3.9:1 — under AA, now the faintest text on the HUD directly below the freshly-crisp nav pills.** No sign-off (Phase 10 stays owner-gated empty-spec).

Fresh, stateless pass. HEAD `5c37a03` (task 200, board empty). Cleared the stale export cache (`rm -rf .godot/exported`, the logged task-200 ghost), rebuilt `build/web/` at HEAD via `verify.sh` (gate green, Sitt-capable licensed Labrador bundled locally), served over http (`python3 -m http.server 8137`) and driven in headless Chromium at 390×844 (SwiftShader == the deployed GL Compatibility renderer), `env -u LD_LIBRARY_PATH`. **Zero game console errors** on every run (`tools/po_pass77.mjs` + menu drive).

**Pass-77 nav-pill X-6 → FIXED and pruned.** Task 200 landed decisively in my own pixels (`tools/po_pass77.mjs`, glyph-core sampler vs pill fill `[251,251,247]`, `.screenshots/P77-hud-zoom.png`): **«Triks» = 17.48:1**, **«Kennel» = 17.32:1** — the darkest stroke-core now renders the true `NAV_INK [10,22,40]` (was the washed periwinkle `[134,168,209]`@2.37 / `[131,166,208]`@2.43). The deeper-ink + stroke-thickening-outline levers defeated the sub-pixel coverage wash; both nav labels now read crisp, saturated, and un-truncated («Kennel» whole), the strongest primary text on the HUD. Directive resolved.

**X-6 (Bugfix / AA) — the LearnedBar «Sitt» / «%» readout renders washed pale-grey at ~3.9:1, under the 4.5:1 AA floor.**
- *What I saw (my own pixels, `.screenshots/P77-hud-zoom.png` 4× HUD zoom + `.screenshots/P77-training.png`).* With the nav pills now crisp-dark, the eye goes straight to the **«Sitt» learned-bar label directly below them, which renders a faint pale-grey** — visibly the **weakest primary text on the whole page**. Sampling its darkest stroke-core against the bar fill `[251,251,247]`: **`[119,127,135]` → 3.92:1**, under the 4.5:1 AA floor (Baloo 2 **bold** at 18px = 13.5pt, below the 14pt-bold large-text threshold, so 4.5:1 applies). This is the **exact same thin-stroke render-wash** task 200 just fixed on the nav pills: the task-200 root-cause established «Sitt» = `DesignSystem.INK #1e2a3a` at ~0.60 sub-pixel stroke coverage → the darkest core is a 60/40 ink-over-paper blend, so an analytically-near-black token (~13:1) renders only ~3.9:1. Task 200 wrote in its own root-cause note that «Sitt» "barely clears" / "renders `[117,125,133]` ≈4.03:1" and used it as the *acceptable* control — but 4.03/3.92:1 is itself **under AA**, and now that the nav pills jumped to 17:1 the «Sitt» readout is the odd washed-out one, a hierarchy inversion where secondary nav chrome out-punches the primary training readout.
- *Why it's a real defect, not sampling noise.* Same class the 145 (readout into sky), 196/197 (showcase captions/chrome under-AA in render), and 200 (nav pills) fixes all closed by measuring **shipped pixels**, not the analytic. The 145 fix defeated the *sky bleed* onto this readout (opaque cream track + scrim) but the newer discovery — thin-stroke sub-pixel under-coverage — was only levered out on the nav labels (200), never applied here, so «Sitt» still washes. The «%» percentage on the same bar uses the same LearnedBar label style (same `font_body_bold` Baloo 2 bold, same INK) so it shares the defect; I directly measured «Sitt».
- *What "good" looks like.* The «Sitt» + «%» readout clears **≥4.5:1 in the actual 390×844 SwiftShader render** (darkest stroke-core vs the bar fill, as measured here — not the analytic ratio), reading **at least as solid as the «Triks»/«Kennel» nav pills** now do, so the primary training readout is not the faintest text on the page. Reuse task 200's proven lever: a same-ink **stroke-thickening outline** (raises effective coverage to ~full without changing text advance/geometry) and/or a **deeper ink** on the LearnedBar labels, guarded by the existing **in-pixel** `render_floor_contrast` model (not the analytic ratio) so an analytic-only value can't re-mask it. Keep the 145 opaque cream track + scrim, the INK token intent, the «%» readout, and the bar geometry — an **ink/render** fix, not layout.

**Surface sweep — otherwise clean (re-verified; 199 owned-badge «Din hund» grid↔modal parity + 200 nav pills stay fixed).** Training page matches the goal art apart from the «Sitt» readout above (crisp-blue nav pills now, blue BRA hero CTA bold-white + 3D lip, gold coin pill, cream Labrador wandering → facing camera → cyan approach ring → seated apex, tan path → blue-roofed cottage, white picket fence, gold + rose coins — Phase 1/2 core loop replays clean, `.screenshots/P78-kennel.png`). The «Triks» completion menu (`.screenshots/P78-kennel2.png`) renders clean — DS paper card, coin chip 5000, dark-ink AA rows (Sitt «Trener nå» / Ligg · Legg deg «Tilgjengelig» / Gi labb «Låst»), Raser (Bella «Aktiv» / Brun lab «Adopter 30»), blue «Fortsett treningen» primary + «Vis frem hundene» / «Gi tilbakemelding». Task 200's diff is confined to the HUD nav ink token + outline (`design_system.gd` `NAV_INK` + `main.gd` `HUD_NAV_INK`/outline), touching no menu / kennel / showcase code, so those surfaces are unaffected and remain as verified clean in pass-77 (kennel grid + Bella/Nova/Trulte modals, dark-ink corner badges 149, coin price chips, stat meters 188; showcase scrim-chip captions 196, green-mint «Trener nå» 198, «Tilbake» chrome 197).

**Considered but NOT filed — owner-gated / settled / timing.** (1) Warm-brown breeds read as similar mid-browns and Nova as uniform dark-grey, not iconic patterns — identity is **model/pattern**, owner-gated (BUST-068, P3-D1/D2/D4). (2) The active-**dog** word differs across surface families (menu selection-language «Trener nå»/«Aktiv»/«Valgt» vs kennel/showcase ownership-green «Trener nå») — each internally coherent and apt, a settled arc (152/167/pass-68/74). (3) Trick-row «Tilgjengelig» vs the «Bytt» switch badge — kept (tricks carry a «Lært» state). (4) The live idle dog can turn rear/side between frames — animation timing, not a layout defect.

**No sign-off.** Phases 1/2/3/5/6/8/9 remain signed; the «Sitt» readout defect is a cross-cutting X-6 on the signed-off Phase-6 training HUD (a polish/AA directive, not a phase regression — the label already rendered this faint; this pass measured it decisively now that the nav pills beside it jumped to 17:1). Phase 10 (`phase10.md`) is still **empty/deferred** — owner-gated (no spec ⇒ cannot Visual-Review, cannot invent scope). One buildable improvement filed; the rest stay standing owner-gated asset flags (distinct per-breed **models**, camera-facing **signature clips**, warm human "Bra!"/Maren voice, coat UV re-export).
