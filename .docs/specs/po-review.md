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

### PO Review — 2026-07-09 (PO, father pass 70) — critique/polish pass. Pass-69's marker-word pip/indent directive (task 195) **re-verified in pixels and resolved** (pruned): the completion menu's «Markørord» rows (Bra!/Dyktig!/Flink!) now start their names **flush** at the same left edge as the trick rows (Sitt/Ligg/Legg deg) and «Vanskelighet» rows, with **no** leading decorative bullet — all four selection sections share one row-name column (`.screenshots/P69-wordalign-menu.png` post-195; the meaningful breed coat swatch is untouched). **ONE new buildable X-6 directive:** the breed-showcase **secondary caption tier** (the «Labrador» breed subtitle in the top header band + the «Adopter flere hunder for å bla» hint in the bottom band) renders **faint / sub-AA in the shipped pixels** — I measured **2.40:1** and **2.05:1** — even though 169/173 set both to `SUBTLE` (white@0.92, an *analytic* ~5.3:1). The crisp white titles («Mine hunder» 6.3:1, «Bella — aktiv» 6.2:1) sit right beside them, so the caption tier is the lone AA fail on the surface. No sign-off (Phase 10 owner-gated on its empty spec).

Fresh, stateless pass. HEAD `fa8b275` (task 195; board empty); `build/web/` rebuilt at HEAD via `verify.sh` (gate green — Sitt-capable licensed Labrador bundled locally, ~39 MB `index.pck` refreshed 03:29), served over http (`python3 -m http.server 8099`) and driven in headless Chromium at 390×844 (SwiftShader == the deployed GL Compatibility renderer), `env -u LD_LIBRARY_PATH`. **Zero game console errors** on every run — training boot (`?bra_autotap=1`, PERFECT verdict + «Bra!» word-pop), the completion menu (words revealed after mastery), the breed showcase, the kennel grid + Sniff/Nova modals. (Contrast figures below are measured off the captured PNGs with a WCAG-luminance sampler — brightest ink of each text line vs the band it sits on.)

**Pass-69 directive RESOLVED (195 dropped the decorative marker-word pip + indent) — re-verified in pixels, pruned.** Task 195 (`fa8b275`) added a shared `NAME_INSET = 14.0` + `row_name_left()` helper and routed the trick, difficulty **and** marker-word names through it (word names moved +20→+14), removing `WORD_ROW_INDENT` / `WORD_PIP_R` / the pip draw. In the post-195 menu capture (`.screenshots/P69-wordalign-menu.png`) «Bra!» / «Dyktig!» / «Flink!» start flush with «Sitt» / «Ligg» / «Legg deg» and «Gi labb», no leading bullet on any word row; the dimmed cost subtitle («+15% · hviler 2» under Dyktig!) shares the flush name x; the 170 ink decisions and «Bytt»/«Aktiv»/«Låst» badges are unchanged; the *meaningful* breed coat swatch (`SWATCH_R`) is untouched. All four selection sections now share one row-name left edge. Resolved; not re-filed. (I also re-considered whether the trick rows' switchable badge «Tilgjengelig» should become «Bytt» to match words/breeds/difficulty — decided **NOT** to file: tricks carry a richer status model, incl. a «Lært»/learned state the other three lack, so «Tilgjengelig»/«Lært» carry information «Bytt» would flatten, the same "meaningful, not decoration" caution 195 applied to the breed swatch.)

**Improvement (X-6, WCAG AA — the breed-showcase secondary caption tier reads faint in the shipped pixels).** The showcase's two SUBTLE captions fail AA in the *actual render*, not just borderline — a legibility gap the 169 analytic fix left standing.
- **What I saw / measured:** in the spotlit breed showcase (`.screenshots/P70d-header.png`, `P70d-bottom.png`, and independently `P70d-full.png`), the **breed subtitle «Labrador»** in the dark top header band (band ≈ `#3d5268`, ink ≈ `#7f8d9e`) measures **2.40:1**, and the **«Adopter flere hunder for å bla» hint** in the grey bottom control band (band ≈ `#5b6667`, ink ≈ `#92999a`) measures **2.05:1** — both well under the 4.5:1 AA bar, and both visibly hard to read. Directly above them, the title «Mine hunder» (6.32:1) and the active name «Bella — aktiv» (6.18:1) are crisp white. Both captions are set to `SUBTLE = white@0.92` (`breed_showcase_view.gd:30,181,268`) which 169 tuned to an *analytic* ~5.3:1, yet the shipped pixels land ~2:1 — the two captions render at an effective alpha ≈0.34, while the titles (drawn in the heavier `font_display` Baloo) do not.
- **Why it's wrong:** AA legibility is the design bar (and an explicit cross-cutting rule — "call out AA fails"). The gap is that 169 measured the *analytic composite colour* (SUBTLE over an assumed band) rather than the real render: the caption tier uses the **thin 13–15px `font_body` (Nunito)** over the **translucent `BAND_BG` (INK@0.72)**, and the thin strokes under-cover, so the brightest shipped pixel never reaches the 0.92 the calc assumed — it lands ~2:1. The header breed subtitle (added later by 173, reusing SUBTLE) was never independently AA-checked on the **top** band at all — 169 only tuned the bottom hint. Net: the surface the player reads to identify their spotlit dog («Labrador») and to learn the carousel («Adopter flere hunder …») is the one place the showcase text is illegible.
- **What "good" looks like:** make **both** SUBTLE captions clear ≥4.5:1 **verified from an actual captured screenshot** (not only the analytic composite) while staying subordinate to the white title — e.g. give the caption tier a small DS text outline/shadow (as other DS text uses) to lift the thin-stroke coverage, and/or raise `BAND_BG` opacity behind the captions so the white composites against a stable dark base, and/or nudge SUBTLE toward full-opaque white. This is **not** a revert of 169 (its bottom-hint intent stands); it closes the analytic-vs-render gap 169 left and extends the same legibility to the 173 header subtitle. Keep the titles, pills, «Tilbake»/chevron chrome (171) and the spotlight-glow (translucent band) as-is.

**Surface sweep — otherwise clean (re-verified this pass, in my own pixels):**
- **Training page** (`P70-a-training.png`, `P70-topbar.png`): matches the goal art — blue BRA hero CTA, hamburger + «Triks» + «Kennel» nav pills (full «Kennel», no truncation), gold coin pill «5000», «Sitt … 0%» learned bar with opaque cream track, cream Labrador centred/grounded on grass (faces camera at a seated apex, PERFECT verdict, «Bra!» word-pop, cyan approach ring), tan path → blue-roofed cottage, white picket fence, gold + rose coins.
- **Completion menu** (`P69-wordalign-menu.png`, post-195): DS paper card — «Triks» Baloo-2 title over coin pill, trick rows (Sitt «Trener nå» / Ligg · Legg deg «Tilgjengelig» / Gi labb «Låst»), «Markørord» (Bra! «Aktiv» / Dyktig! «Bytt» + dimmed «+15% · hviler 2» / Flink! «Låst») now flush-aligned (195), blue-ghost «Gi tilbakemelding» + solid-blue «Fortsett treningen» primary. Progressive reveal (`MenuReveal`) staggers correctly. Section headings (193) uniform, subordinate to the title.
- **Breed showcase** (`P70-d-showcase.png`, `P70d-full.png`): «Mine hunder» / «Bella — aktiv» / «Labrador» header (subtitle AA flagged above), cream Labrador spotlit on the garden (HUD hidden), page-dot «Bella» indicator, «Trener nå» (pale non-tappable status) + «Tilbake» (dark pill, 171 AA holds) controls.
- **Kennel** (`P70b-menu1-full.png` grid, `P70b-menu2-full.png` Sniff modal): 8 cells fill the 844 portrait under «Kennelen · Profesjonell fasilitet · 8 plasser» + coin chip, front-¾ full-body poses, Norwegian rarity/status corner badges (Bella «Din hund»/green, Nova «Episk»/violet, Balder+Sol «Sjelden»/blue, Pontus/Lykke/Sniff «Vanlig»/slate, Trulte «Påskeegg»/coral — all dark-ink AA per 149), gold coin price chips descending by rarity (Nova 900 › Balder 650 › Sol 500 › Sniff 320 › Pontus 350 › Lykke 300; owned Bella none + faint-green tint; Trulte «Gratis»). Sniff modal: dark hero bust matching the grid cell, blurb, 4 blue stat meters with the empty segment a present slate track (188), «Raseegenskaper» chips (Sporty · Stø · Sosial), «Unikt trekk» (Nesa styrer), «Kan lære: Sitt · Ligg · Legg deg», solid-blue «Adopter 🪙 320» primary, unified light-disc ✕ (189). Coats: Bella cream, Sol golden, Trulte the clean silver-white from 192, Nova dark.

**Considered but NOT filed — owner-gated / intentional, not buildable polish.** (1) The four warm-brown breeds (Balder/Schäferhund, Pontus/Gravhund, Lykke/Spisshund, Sniff/Beagle) read as similar mid-browns — but their catalog tints already span a genuine value/hue range and their real identities are **pattern/shape** (shepherd saddle, dachshund body, beagle tricolor) a single-colour tint on the one shared Labrador rig cannot convey; the honest fix is distinct per-breed **models** (BUST-068, P3-D1/D2/D4), a standing owner flag. (2) The trick-row «Tilgjengelig» vs the other sections' «Bytt» switch badge — kept (tricks carry a «Lært» learned state the others lack; see the resolved-195 note). (3) The active-state badge word differs across sections (trick «Trener nå», breed/word «Aktiv», difficulty «Valgt») — each reads correctly in its own context and pass-68 deliberately kept «Valgt»; not re-litigated. (4) The showcase dog is a live idle that can turn rear/side between frames — animation timing, not a fixable layout defect.

**No regression** in any signed-off phase: every surface renders as before, the autotap burst mastered Sitt clean (PERFECT verdict + «Bra!» word-pop, marker-words revealed), the completion menu opens/closes, and the kennel grid + modal drive clean — closing back restores the Phase-6 training page + Phase-1/2 core mark loop (cream Labrador centred facing camera on green grass, tan path, cottage, fence, coins, blue BRA). Zero console errors throughout.

**No sign-off.** Phases 1/2/3/5/6/8/9 remain signed with no regression. Phase 10 (`phase10.md`) is still **empty/deferred** — owner-gated (no spec ⇒ cannot Visual-Review, cannot invent scope). This pass re-verifies the 195 flush-alignment fix, prunes it, and files **one buildable X-6 directive** (lift the breed-showcase secondary caption tier — «Labrador» subtitle 2.40:1 + «Adopter flere …» hint 2.05:1 — to clear AA in the actual render). The standing asset flags (distinct per-breed **models**, camera-facing **signature clips**, warm human "Bra!"/Maren voice, coat UV re-export) remain owner-gated.
