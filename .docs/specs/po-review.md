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

### PO Review — 2026-07-07 (PO, father pass 34) — polish-lens pass: verified 168 (the active BREED «Aktiv» / marker-word «Aktiv» / SELECTED difficulty «Valgt» badges now draw in the SAME dark current-state ink as the active-trick «Trener nå») landed clean and pruned it; re-played training + completion-menu + **kennel** grid/modal for regressions (all clean, incl. re-confirmed grid↔modal price parity and grid↔modal coat consistency) and turned the polish lens on the **breed showcase** («Vis frem hundene»). Found ONE new sub-AA defect there — the instructional hint caption «Bla med pilene eller trykk en hund» reads **~4.1–4.3:1 (under the 4.5:1 bar)** because its translucent stage-band lets bright grass bleed through and the caption ink isn't opaque enough to compensate; the 163 showcase-DS pass never measured this caption. One buildable X-6 directive filed. No sign-off (Phase 10 owner-gated on its empty spec).

Thirty-fourth pass, fresh and stateless under the polish/critique lens. HEAD is `f2ac369` (the 168 active-badge-ink commit).
Rebuilt the **fresh local licensed bundle** at this HEAD (`nix develop -c bash verify.sh` → gate green, `build/web/index.pck` re-exported), served over http and driven in
headless Chromium at 390×844 with **deviceScaleFactor 3** (SwiftShader == the deployed GL Compatibility renderer). Three harness runs, **zero console errors** on every one:
(1) `tools/po_pass34.mjs` booted `?bra_autotap=1&bra_coins=120` → training → completion menu → adopted the 2nd breed (balance 120→90, owned = `[labrador, chocolate_labrador]`)
→ dumped the trick + breed row-sets and captured the full menu card; (2) `tools/po_pass32_kennel.mjs` → kennel grid → Nova modal; (3) `tools/po_pass31.mjs` → adopted the 2nd
dog → opened the **breed showcase**, spotlit the active Labrador and cycled ▶ to the previewed «Brun lab», cropping the bottom control band both ways. Evidence: this pass's
screenshots (`.screenshots/P34-01-training.png`, `P34-02-menu-full.png`; `P32K-01-grid.png`, `P32K-02-modal.png`; `P31-03-showcase-active.png`, `P31-04-showcase-preview.png`)
+ tight zoom crops (`/tmp/raser3.png` the menu Raser rows, `/tmp/nova_price3.png` the grid price chip, `/tmp/modal_mid.png` the modal stats, `/tmp/hint_find.png` +
`/tmp/hint_tight.png` the showcase hint, `/tmp/arrows_montage.png` all four chevrons) + the code I read (`scripts/breed_showcase_view.gd` `BAND_BG`/`SUBTLE`/`_hint`).

**Verified fixed → pruned:** the pass-33 directive (**active BREED/WORD/difficulty badges were action-blue, not the dark current-state ink the active-trick «Trener nå» uses**)
is **resolved** by 168. In my own pixels (`/tmp/raser3.png`, HEAD `f2ac369`): on the pale-blue active-row wash the active **Labrador** row's «Aktiv» badge now reads dark
charcoal — visibly the same ink as the active **Sitt** row's «Trener nå» — while the sibling «Brun lab» «Bytt» and the available «Ligg»/«Legg deg» «Tilgjengelig» badges stay
blue; an objective darkest-badge-pixel sample of both active rows returned dark-neutral (no blue dominance). Confirmed structural: 168 routes every active-state badge through
one shared `BADGE_ACTIVE := ROW_ACTIVE_INK` (`trick_menu.gd`), locked by `tests/test_trick_menu_active_badge.gd` (== `ROW_ACTIVE_INK`, distinct from `BADGE_AVAILABLE`/
`BADGE_LEARNED`, ≥4.5:1 on the wash). The word + difficulty sections are progressively hidden until their mastery-reveal thresholds and can't be forced headless (the known
SwiftShader `.play()`/autotap-mastery limit — the learned bar stays 0 %), so those two badges are covered by construction + that test, per the standing fallback. All four
selection sections now mark "you are here" as one system (wash 167 + badge ink 168). Pruned.

**Re-verified clean (no new directive):** (a) **training page** (`P34-01`) still matches the goal — centered facing-camera cream Labrador on green grass, tan winding path →
cream/blue cottage, white picket fence, gold+rose coin scatter, opaque «Sitt … 0%» learned bar (145/159 scrim + opaque panel intact), «Triks»/«Kennel»/coin-`120` HUD pills, big
blue BRA. (b) **Completion menu** (`P34-02`): the four sections render with the unified active wash + dark active-badge ink; «Fortsett treningen» primary is the deep-blue AA
gradient (153). (c) **Kennel** (`P32K-01`/`P32K-02`): the 8-cell grid fills the portrait, rarity badges/names/coin-pip price chips all read; **grid↔modal price parity holds** —
Nova's grid chip reads «900» (`/tmp/nova_price3.png`) and her modal reads «Har ikke råd · mangler 780» (900−120), consistent; and **grid↔modal coat is hue-consistent** — I
sampled Nova's torso at (113,110,106) in the grid vs (87,84,81) in the modal bust, both neutral grey (no 147-style "breed flip"). Modal stat pips show the filled/empty max-track,
«Raseegenskaper» chips, «Unikt trekk: Øyet», «Kan lære: Sitt · Ligg · Legg deg», muted non-tappable affordability gate — all AA-legible, no gold-as-text. (d) **Breed showcase**
chevrons: all four ◀/▶ states (first/last item) render as identical white glyphs on the grey button (`/tmp/arrows_montage.png`) — the wrap-cycle is consistent, no disabled-look
asymmetry; the spotlit pip is the bright paper chip with the dark «aktiv» dot (165/166), the disabled «Trener denne» is the muted pale-slate pill with dark ink and the enabled
«Tren denne» (on the previewed «Brun lab») is the blue gradient pill (163). **No structural regression** in the signed-off phases (1/2/3/5/6/8/9).

**Improvements**

- **The breed-showcase instructional hint «Bla med pilene eller trykk en hund» fails WCAG AA (~4.1–4.3:1) over the bright-grass default view — the one caption on that surface
  the 163 showcase-DS/contrast pass never measured, and the same translucent-bleed → sub-AA class the 145/156/158/162 sweep kept catching elsewhere.** *What I saw:* in the
  default (active-Labrador) showcase view (`/tmp/hint_find.png`, `/tmp/hint_tight.png`, HEAD `f2ac369`) the centered hint line under the breed pips is the faintest text on the
  screen — light grey on the dark stage band. I measured its glyph strokes at a peak of ~(213,216,216) against the band directly under them at (91,102,103), i.e. **~4.1–4.3:1**,
  under the 4.5:1 bar for 13 px (normal-size) text. *Why it's short of good:* it's confirmed structural — the band is translucent (`BAND_BG := INK @ 0.72`, `breed_showcase_view.gd:22`)
  so over the showcase's **bright green grass** the composited band lightens to that ~(91,102,103), and the caption ink `SUBTLE := Color(1,1,1,0.78)` (`:26`, applied to `_hint`
  `:219`) is only 78 %-opacity white — not opaque enough to stay legible once the band has been lightened by the scene bleed. It's the same failure mode 159 fixed on the training
  learned-bar panel (translucent element → scene bleeds through → sub-AA) and the same "a label the DS sweep never measured" gap as 162 (the «Adopter 30» price) / 158 (the adopt
  button) / 156 (kennel grey secondary text). And it's the showcase's *only* usage instruction — a first-time user reads it to learn that the arrows and pip-taps both cycle
  breeds, so a washed-out caption directly costs discoverability. *What "good" looks like:* make the hint caption clear ≥4.5:1 against the band in the worst-case (bright-grass)
  scene — e.g. raise `SUBTLE` toward opaque white (full `Color(1,1,1)` measures ~5.9:1 over that same band; the existing `BTN_SECONDARY_TEXT` white@0.92 measures ~5.1:1 and would
  keep a hair of "secondary" vs the full-white title), keeping the dark translucent stage-band aesthetic 163 established (do NOT make the band opaque — that would kill the
  spotlight glow). Keep the 13 px size and centered placement; change only the caption ink. Add a TDD contrast assert (like `test_breed_showcase_contrast.gd`'s existing ones) that
  the hint ink clears 4.5:1 on the band over a bright scene, and re-verify in-pixel at dsf3 that the caption reads crisply over the default grass view.

**No sign-off.** Phases 1/2/3/5/6/8/9 remain signed with no regression. Phase 10 (`phase10.md`) is still **empty/deferred** — owner-gated (no spec ⇒
cannot Visual-Review and cannot be given buildable stories without inventing scope), so it can neither be signed off nor given directives. The standing
asset flags (distinct per-breed **models**, camera-facing **signature clips**, warm human "Bra!"/Maren voice, coat UV re-export) remain owner-gated.
The build loop turns the directive above into the next task.
