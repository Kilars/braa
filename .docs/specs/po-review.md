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

### PO Review — 2026-07-09 (PO, father pass 83) — **task 205 «Trener nå» owned-status pill AA fix VERIFIED in-pixel (Bella modal pill now renders its true dark token `[20,28,38]` → 14.78:1 on the mint fill, was 2.70:1 washed — matches 151's analytic ~14.8:1); ONE new buildable X-6: the kennel rarity/owned CORNER BADGE labels («Din hund» green / «Episk» violet / «Sjelden» blue / «Vanlig» slate / «Påskeegg» coral) are the LAST un-outlined dark-token text left by the whole 200→205 arc — 149 swapped them to `C_TAG_INK` but never outlined them and only verified the ratio ANALYTICALLY, so they render washed to a mid-tone at ~1.7–1.8:1 on both the grid and the modal.** No sign-off (Phase 10 stays owner-gated empty-spec).

Fresh, stateless pass. HEAD `4766d71` (task 205, board empty, tree clean). The `build/web/` was exported by a fresh `verify.sh` gate at this HEAD (green: import·boot·test·export), so I served it over http and drove it in headless Chromium at 390×844 (SwiftShader == the deployed GL Compatibility renderer), `env -u LD_LIBRARY_PATH` (`tools/po_pass8_drive.mjs`). **Zero game console errors** on every run (training capture, `?bra_autotap=1` mark burst, menu / kennel-grid / modal drive). Contrast measured in shipped pixels with a WCAG sampler over the captured PNGs (darkest stroke-core vs each element's opaque local fill).

**Pass-82 «Trener nå» pill X-6 → FIXED and pruned.** Task 205 landed decisively in my own pixels on the owned dog (Bella) — `.screenshots/PO8-07-modal-bella.png`. The non-tappable green «Trener nå» owned-status pill at the bottom of the modal now renders its true dark `C_TAG_INK` core `[20,28,38]` → **14.78:1** on its mint pill fill `[228,242,225]` (was `[137,148,143]` → 2.70:1 washed) — exactly matching task 151's ~14.8:1 analytic token, now that 205 applied the same-colour `outline_size=SOFT_INK_OUTLINE` + `font_outline_color=C_TAG_INK` Button-typed lever the 200→204 arc used on every Label. The showcase sibling active pill got the same disabled-scoped outline. Directive resolved.

**X-6 (Bugfix / AA) — the kennel rarity/owned CORNER BADGE labels render below the 4.5:1 AA floor on both the grid and the modal; the whole 200→205 sweep lifted every surrounding Label/Button but never the badge labels in `_make_tag`, so they are now the single faintest text left in the kennel.**
- *What I saw (my own pixels — `.screenshots/PO8-05-kennel-grid.png`, `PO8-07-modal-nova.png`, `/tmp/episk_zoom.png` 8× NEAREST zoom, WCAG sampler, darkest stroke-core vs each badge's opaque accent fill).* Every buyable dog's rarity corner badge, plus the owned green badge, renders its dark-token label washed to a mid-tone of its own accent, well under AA — measured on the grid: Bella «Din hund» darkest `[66,136,75]` vs green fill `[87,184,92]` → **1.73:1**; Nova «Episk» `[107,89,150]` vs violet `[155,123,212]` → **1.77:1**; Balder/Sol «Sjelden» `[65,101,147]` vs blue `[91,143,208]` → **1.79:1 / 1.77:1**; Pontus «Vanlig» slate + Trulte «Påskeegg» coral wash to `[118,129,139]` / `[172,89,99]` (their fills are lighter, so the ratio is less extreme but the strokes still never reach the dark token). The 8× zoom of «Episk» shows it plainly: the letters are a slightly-darker purple, no pixel approaches `C_TAG_INK` #141c26. The **modal** carries the identical wash — Nova's modal corner badge «Episk» measures **1.81:1** (same `_make_tag`). Controls that pass right beside them on the same grid: the 203 subtitles «Labrador retriever» 5.48:1, «Profesjonell fasilitet» 5.48:1, the «Kennelen» header 11.44:1 — so this is again the **one specific** un-swept text tier, not a blanket wash.
- *Why it's a real defect, not sampling noise.* Root cause is in `kennel_screen.gd` `_make_tag()` (line ~975): **both** badge-label branches — the secret star-pip label (line ~1008–1014) and the buyable/owned label (line ~1016–1022) — set `font_color = C_TAG_INK` **but neither has an `outline_size` / `font_outline_color` override**, unlike the `_apply_ink_outline` helper (line 82–83) and the `_build_active_state` pill that 205 just fixed (line 1636–1637). So the small **10 px bold** badge text renders the exact thin-Nunito-stroke wash the whole 200→205 arc closed everywhere else: the token is dark, the shipped pixels are a mid-tone. Task 149 swapped these labels to the dark ink and verified only **analytically** (`KennelScreen.wcag_contrast`, ~5–7:1 on each accent) — never render-floor-verified — which is precisely the analytic-vs-render trap the arc has been busting one surface at a time. Grid (line ~705) and modal (line ~1352) share this one `_make_tag`, so both wash from a single cause.
- *What "good" looks like.* Every corner badge label clears **≥4.5:1 in the actual 390×844 SwiftShader render** (darkest core vs its own accent fill, as measured here — not the analytic ratio), reading at least as solid as the 203 subtitles beneath the cell. Reuse the exact arc lever: give **both** `_make_tag` badge Labels the same-colour `add_theme_constant_override("outline_size", SOFT_INK_OUTLINE)` + `add_theme_color_override("font_outline_color", C_TAG_INK)` so they render their true dark token — the dark ink on each accent is analytically 5–7:1 (green ~6.9:1, violet ~5.1:1, blue ~5.2:1), so reaching the token via the outline alone is sufficient; **do not change any accent fill or badge colour identity.** Guard with an **in-pixel** render-floor measurement (not the analytic ratio) so an analytic-only value can't re-mask it, and cover both the grid cell and the modal corner badge. **Keep the accent hues (green owned / coral secret / slate·blue·violet rarity), the corner position, the pill shape + radius, the star pip, the 149 dark-ink token, and every badge word (199 «Din hund»/«Påskeegg» parity) exactly** — this is an ink/render-coverage fix only, not a colour, layout, or wording change.

**Surface sweep — otherwise clean (re-verified this pass; 199 owned-badge «Din hund» parity, 200 nav pills, 201 readout, 202 menu rows, 203 kennel secondary, 204 modal blurb/value/chips, 205 «Trener nå» pill all stay fixed).** **Training page** matches the goal art (`.screenshots/PO8-01-training-a.png`): crisp-dark nav pills (17.48:1) + learned readout (5.31:1), blue BRA hero CTA bold-white, gold coin pill, cream Labrador centred facing camera on green grass, tan path → blue-roofed cottage, white picket fence, gold + rose coins. **Completion menu** (`PO8-04-menu.png`): «Triks» heading + crisp dark row names («Ligg» 4.78:1), «Sitt · Trener nå» active row (14.55:1), blue «Tilgjengelig» badges, greyed «Gi labb · Låst», outline «Gi tilbakemelding» secondary + solid blue «Fortsett treningen» primary. **Core loop juice** replays clean on the `?bra_autotap=1` burst: a PERFECT climbs the bar to 23 %, dog turns to camera and reacts — Phase 1/2 intact. **Kennel grid + modals** (`PO8-05` … `PO8-07-modal-{bella,nova,trulte}.png`): all 8 cells fill the portrait, correct Norwegian rarity words, plausible per-dog coats (117), crisp 203 subtitles + 204 blurb/chips/value (11.72:1 / 7.39:1) + 205 «Trener nå» pill (14.78:1); modals open on tap with bottom nameplate clear of the face, 4 stat meters, «Unikt trekk», «Kan lære», affordability-gated adopt button — all structurally clean apart from the corner-badge label wash filed above.

**Considered but NOT filed — owner-gated / settled / timing.** (1) Warm-brown breeds read as similar mid-browns and Nova as uniform dark-grey, not iconic patterns — identity is **model/pattern**, owner-gated (BUST-068, P3-D1/D2/D4). (2) The disabled adopt button «Har ikke råd · mangler» renders ~2.29:1 — a *disabled* state at conventionally-reduced contrast (WCAG 1.4.3 exempts inactive components; the enabled adopt path is 6.84:1), so left out of the directive. (The corner badges ARE filed despite the disabled-button precedent, because they are *always-on primary informational* labels the player reads to know a dog's rarity/ownership — not an intentionally-dimmed unavailable action — so they must be legible.) (3) The active-**dog** word differs across surface families (menu selection-language «Trener nå»/«Aktiv»/«Valgt» vs kennel/showcase ownership-green «Trener nå») — each internally coherent and apt, a settled arc (152/167/pass-68/74). (4) The gold «PERFECT» verdict + gold «Bra!» word-pop use GOLD off the coin — a long-standing, signed-off celebration convention (Phase 1). (5) The live idle dog can turn rear/side between frames — animation timing, not a layout defect.

**No sign-off.** Phases 1/2/3/5/6/8/9 remain signed; the corner-badge label wash is a cross-cutting X-6 on the signed-off Phase-8 kennel (a polish/AA directive, not a phase regression — these badge labels always rendered their dark token washed under the bare no-outline path; this pass measured them decisively now that 200→205 lifted every element around them to AA-clear, leaving the corner badges the lone faint tier). Phase 10 (`phase10.md`) is still **empty/deferred** — owner-gated (no spec ⇒ cannot Visual-Review, cannot invent scope). One buildable improvement filed; the rest stay standing owner-gated asset flags (distinct per-breed **models**, camera-facing **signature clips**, warm human "Bra!"/Maren voice, coat UV re-export).
