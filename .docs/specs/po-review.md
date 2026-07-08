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

### PO Review — 2026-07-08 (PO, father pass 58) — critique/polish pass. Pass-57's showcase-label directive is **FIXED and verified in my own pixels** (pruned); ONE NEW X-6 directive: the training-page **«Kennel» HUD nav pill renders truncated as «Kennel.»** — an ellipsis is appended because the fixed 96 px pill is too narrow for the 6-char label at `T_HEAD`, while its sibling «Triks» pill (widened to 128 px for exactly this reason) fits cleanly. Fresh sweep at HEAD `f08699c` (last code commit `f08699c`/184; board empty). No sign-off (Phase 10 owner-gated on its empty spec; this directive is cross-cutting polish, preempts any terminal idle).

Fifty-eighth pass, fresh and stateless. HEAD `f08699c`; `build/web/` rebuilt at this HEAD via `verify.sh` (gate green, import·boot·test·export), served over http (`python3 -m http.server 8099`) and driven in headless Chromium at 390×844, deviceScaleFactor 3 (SwiftShader == the deployed GL Compatibility renderer), `env -u LD_LIBRARY_PATH`. The local Web build **bundles the licensed dog** (real cream Labrador rig). **Zero game console errors** on every run — training boot, the completion menu, the breed showcase on the active dog, the kennel grid + Nova modal, and the feedback form.

**Pass-57 directive RESOLVED (showcase active-dog status word) — verified in pixels, pruned.** Task 184 (`f08699c`) added the pure static `BreedShowcaseView.commit_label(is_active)` and repointed `_commit_btn.text` off the divergent «Trener denne» onto **«Trener nå»** for the active (disabled) state, keeping the enabled switch action **«Tren denne»**. In my pixels — opening the showcase on Bella, the active dog (`.screenshots/P58-showcase-active.png`, 12× crop `P58-commit-zoom.png`) — the bottom commit pill now reads **«Trener nå»** in dark ink on the pale slate `#CFD6DD` disabled fill (163), byte-matching the kennel modal «Trener nå» treatment (151) + the trick-menu ACTIVE badge (152). All five current-item surfaces (trick / breed / word menus · kennel modal · breed showcase) now speak one status word. Fill/AA/behaviour unchanged, as directed.

**New Change (X-6) — the training-page «Kennel» nav pill is truncated to «Kennel.» (label overflows the fixed 96 px pill → Godot appends an ellipsis).** On the training HUD the two top-left nav pills sit side-by-side: a hamburger-glyph + **«Triks»** pill and a **«Kennel»** pill. I sampled the HUD at 12× (`.screenshots/P58-a-training.png`, crops `P58-hud-zoom.png` / `P58-kennelpill-nn.png`): the Kennel pill renders **«Kennel.»** — the full word plus a stray trailing dot, i.e. Godot's text-overrun ellipsis kicking in because the label doesn't fit. The same truncated pill is visible behind the feedback form (`P58-feedback.png`), so it is consistent static chrome, not a one-frame fluke. The sibling «Triks» pill renders cleanly with margin.
  *Why it's wrong:* it's a **typography/layout defect on a primary navigation control** — a truncation ellipsis on a 6-letter Norwegian noun reads as a bug (looks like «Kennel.» with an errant period), and it's an avoidable inconsistency with the «Triks» pill beside it. The root cause is in the code, not the copy: `main.gd:2173` sets `btn.text = "Kennel"` (no period), but the button is pinned to a **fixed 96 px width** (`main.gd:2195`, `offset_right = … + 96.0`) — too narrow for «Kennel» at `T_HEAD` (18 px Baloo 2 bold) once the pill's internal horizontal padding is subtracted, so the Button trims with an ellipsis. Tellingly, the **Triks** pill hit this exact class of bug and was already fixed by widening: `TRICKS_BTN_WIDTH := 128.0` carries the comment *"100: a touch wider so the glyph + 'Triks' both fit the pill"* (`main.gd:814`). The Kennel pill never got the same treatment.
  *What "good" looks like:* the «Kennel» label renders in full with no trailing dot/ellipsis and the same internal padding as «Triks». Simplest buildable fix: widen the Kennel pill from 96 px to whatever fits «Kennel» at `T_HEAD` with matching padding — ~116–120 px is safe (it has no glyph, so it needs less than Triks's 128 px, but clearly more than 96) — i.e. bump the `+ 96.0` on `main.gd:2195` (and keep it a named constant for parity with `TRICKS_BTN_WIDTH`). Equivalent acceptance: no ellipsis on the pill, «Kennel» centred with balanced side padding. A pure-drawn/measure-to-content sizing would also be fine, but the fixed-width bump mirrors the existing Triks fix and is lowest-risk.

**Rest of the surface sweep — all clean, no other directive (re-verified this pass):**
- **Training page** (`P58-a-training.png`): matches the goal art — blue BRA hero CTA, hamburger + «Triks» nav pill, gold coin pill «5000», cream Labrador grounded on green grass (rear during a wander, faces camera at the seated apex), «Sitt» learned bar, tan path → blue-roofed cottage, white picket fence, gold + rose coins. The **only** blemish is the «Kennel.» pill above.
- **Completion menu** (`P58-menu.png`, opened via the «Triks» pill): clean DS paper card — «Triks» heading + coin pill; Sitt («Trener nå», active pale-blue wash, dark ink), Ligg/Legg deg («Tilgjengelig»), Gi labb («Låst»); «Raser» Bella·Labrador («Aktiv») / Brun lab («Adopter 30» + coin); «Vis frem hundene» + «Gi tilbakemelding» outlined secondaries; solid-blue «Fortsett treningen» primary; BRA button correctly dimmed under the modal scrim.
- **Breed showcase** (`P58-showcase-active.png`): «Mine hunder» / «Bella — aktiv» / «Labrador» header (legible per 169/171/173), spotlit dog, drawn chevrons + pips, active «aktiv» dot, «Tilbake» chrome, and the now-unified **«Trener nå»** disabled commit pill.
- **Feedback form** (`P58-feedback.png`): 182 fix holds — muted grey-blue disabled «Send» (`#CFD6DD`-family) distinct from the ghost-outline «Avbryt»; light PAPER card, Norwegian copy («Fortell oss hva du synes», six slate chips Feil/Idé/For vanskelig/For lett/Forvirrende/Annet), privacy line, no gold anywhere.
- **Kennel** (`P58-kennel-grid.png`, `P58-kennel-modal.png`): 8 cells fill the portrait, front-¾ full-body poses, Norwegian rarity/status corner badges legible with dark ink on calm accents (owned / Vanlig / Episk / Påskeegg), coin price chips, plausible per-dog coats; the Nova modal opens on tap with a hero bust on a **calm** nameplate band, blurb, 4 blue stat meters, «Raseegenskaper» chips, «Unikt trekk» card, «Kan lære: Sitt · Ligg · Legg deg», and a blue «Adopter 🪙 900» CTA.

**No regression** in any signed-off phase: 184's diff is confined to `breed_showcase_view.gd` (+ tests), so no training-scene / menu / kennel / economy / marker-word logic changed; every surface renders as before. (The «Kennel.» truncation is a pre-existing Phase-8 HUD blemish surfaced by this pass's closer typography lens, not a regression from 184.)

**No sign-off.** Phases 1/2/3/5/6/8/9 remain signed with no regression. Phase 10 (`phase10.md`) is still **empty/deferred** — owner-gated (no spec ⇒ cannot Visual-Review, cannot invent scope). This pass verifies the pass-57 showcase-label unification (184) in pixels and files one buildable X-6 (widen the «Kennel» nav pill so its label stops truncating to «Kennel.»). The standing asset flags (distinct per-breed **models**, camera-facing **signature clips**, warm human "Bra!"/Maren voice, coat UV re-export) remain owner-gated.
