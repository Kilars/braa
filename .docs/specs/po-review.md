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

### PO Review — 2026-07-08 (PO, father pass 40) — polish-lens pass: verified **174** (the show-off surfaces now name the **active kennel dog** across all 8 dogs, not just the starter) landed clean **in-pixel** and pruned the pass-39 directive. Driving the real adopt-and-train path — **adopt Nova (grey Border collie) → «Tren med Nova»** — the completion-menu «Raser» row now reads **«Nova» / «Border collie» «Aktiv»** and the breed showcase header **«Nova — aktiv» / «Border collie»** with a **«Nova»** pip, over the grey coat, in full agreement with the kennel's «Trener nå». The 172 pose holds (the showcase settles to a centred, camera-facing standing portrait). One residual directive filed: on that same «Raser» active row the little round **coat swatch** beside the name is still the golden **Labrador breed swatch**, not Nova's grey coat — 174 repointed the NAME+breed but left the swatch colour behind. No sign-off (Phase 10 owner-gated on its empty spec).

Fortieth pass, fresh and stateless under the polish/critique lens. HEAD is `64a1166` (the 174 show-off-name commit); board empty, working tree clean.
Rebuilt the **fresh local licensed bundle** at this HEAD (`nix develop -c bash verify.sh` → gate green, `build/web/index.pck` re-exported ~03:18). The local Web build **bundles the
licensed dog** (per the deploy notes), so it renders the real cream Labrador / grey Nova rig. Drove the bundle over http (`python3 -m http.server 8099`) in headless Chromium at
390×844, **deviceScaleFactor 3** (SwiftShader == the deployed GL Compatibility renderer), `env -u LD_LIBRARY_PATH` (local-Chromium glibc gotcha). Runs, no game console errors observed:
(1) `tools/po_pass40_kennel_train.mjs` — `?bra_coins=2000` → kennel grid → Nova inspect modal → **adopt Nova (balance 2000→1100) → «Tren med Nova»** (`P40K-training-nova.png`, grey
rig centred facing camera) → completion menu (`P40K-menu-nova.png`) → breed showcase (`P40K-showcase-nova.png`); (2) `tools/po_pass40_showcase_settle.mjs` — same adopt+train flow, then
four showcase frames at t=1/2.5/4/6 s (`P40S-t1000/2500/4000.png`) to distinguish a caught-mid-idle-stretch frame from a persistent pose. Evidence: those screenshots (+ crops
`P40K-menu-raser-zoom2.png`, `P40S-t4000.png`) + the published globals (`__bra_kennel_active = "nova"`, `__bra_active_breed = "labrador"`, `__bra_showcase_spotlit = "labrador"` — the
roster still points at labrador, so the correct on-screen «Nova» proves the 174 `_active_from_kennel` override is doing the work, not a roster repoint) + the code I read
(`main.gd:2121/2371` build the row with `KennelDog.showoff_name(...)` for name+subtitle but `"tint": bp.swatch_color()`; `_active_coat_tint()` at `main.gd:2538`).

**Verified fixed → pruned:** the pass-39 directive (**training a non-starter kennel dog makes the show-off surfaces label it «Bella / Labrador»**) is **resolved for all 8 dogs** by
174. In my own pixels after adopt-Nova → «Tren med Nova»: the completion-menu «Raser» active row reads a two-line **«Nova»** with a dimmed **«Border collie»** subtitle + «Aktiv» badge
(`P40K-menu-raser-zoom2.png`); the breed-showcase header is a clean **«Mine hunder» / «Nova — aktiv» / «Border collie»** stack over the grey dog with a **«Nova»** pip
(`P40K-showcase-nova.png`, `P40S-t4000.png`); training and showcase both render the grey Nova coat (the 174 `_active_coat_tint()` glue holds the trained coat through the showcase, no
cream repaint). Name, breed and coat all agree with the kennel's «Trener nå». Pruned.

**Re-verified clean (no new directive):** (a) **training page** (`P40K-training-nova`) matches the goal — grey Nova centred + grounded facing camera on green grass, tan winding path →
cream/blue cottage, white picket fence, gold+rose coin scatter, «Sitt … 0%» learned bar, «Triks»/«Kennel»/coin HUD pills, deep-blue BRA. (b) **Completion menu** (`P40K-menu-nova`):
«Sitt» «Trener nå» + «Nova» «Aktiv» read as dark name + dark badge on the pale-blue active wash identically (167/168/170 intact); tricks Ligg/Legg deg «Tilgjengelig», Gi labb «Låst»,
«Brun lab» «Adopter 30» single-line (no kennel individual — the 174 fallback), «Vis frem hundene» / «Gi tilbakemelding» ghost rows, «Fortsett treningen» solid-blue primary;
marker-word + difficulty sections correctly hidden by progressive disclosure. (c) **Breed showcase** (`P40S-t1000→4000`): the 172 pose is solid — one frame in the first run caught the
dog mid-idle-stretch (crouched, head down), but with a settle sweep it stands **centred + camera-facing** by t=1 s and holds through t=4 s; «Tilbake» dark pill + ◀▶ chevrons + blue
active pip clear (171). **No structural regression** in the signed-off phases (1/2/3/5/6/8/9); 174's diff is confined to `kennel_dog.gd` (pure `showoff_name`) + `main.gd`
(`_active_from_kennel` flag + `_active_coat_tint()`), touching no economy / kennel-render / core-mark path.

**Improvements**

- **174 unified the show-off NAME + breed across all 8 dogs, but the completion-menu «Raser» active-row COAT SWATCH still shows the golden Labrador breed colour for a grey Border
  collie named «Nova» — the one remaining fragment of the same "the chip doesn't match the dog" contradiction 173/174 set out to kill.** *What I saw (empirical, not inferred):* after
  adopt-Nova → «Tren med Nova», the completion-menu «Raser» active row correctly reads a two-line **«Nova» / «Border collie» «Aktiv»** (`P40K-menu-raser-zoom2.png`), but the small round
  colour swatch to its left is a warm **golden/tan disc** — unmistakably the Labrador breed swatch — while the dog on the training page, in the showcase, and named on this very row is a
  **grey** Border collie (`P40K-training-nova.png`, `P40S-t4000.png`). *Why it falls short:* `main.gd:2121` (`_render_showcase`) and `main.gd:2371` (`_breed_rows`) both build the row as
  `{name, subtitle}` from `KennelDog.showoff_name(...)` — the 174 fix — but still hard-set `"tint": bp.swatch_color()`, i.e. the **breed roster's** active-breed swatch (labrador →
  golden), never the active kennel dog's coat. So 174 fixed the words and the 3D coat but left this one colour chip pointing at the stale roster; a golden chip captioned «Nova / Border
  collie (grey)» re-introduces, in miniature, exactly the cohesion break the arc was closing — the little "here is MY dog" swatch shows the wrong dog's colour. *What "good" looks like:*
  when the active row is the kennel-driven dog (`_active_from_kennel`), its swatch must derive from the **active kennel dog's coat** (grey for Nova) — the ready `_active_coat_tint()`
  helper (`main.gd:2538`, already used for the showcase 3D coat at `main.gd:2082`) or `KennelDog.by_id(_kennel_roster.active).portrait_tint()` — so the chip, the name, the breed and the
  coat on screen all agree, for all 8 dogs. Non-active «Raser» rows keep `bp.swatch_color()` unchanged; keep the 173/174 two-line layout, the 172 pose and 087/163 re-tint exactly as
  they are. This is a one-line re-point of the *swatch source* for the active row, mirroring how 174 re-pointed the name — no new asset or economy change.

**No sign-off.** Phases 1/2/3/5/6/8/9 remain signed with no regression. Phase 10 (`phase10.md`) is still **empty/deferred** — owner-gated (no spec ⇒
cannot Visual-Review and cannot be given buildable stories without inventing scope), so it can neither be signed off nor given directives. The standing
asset flags (distinct per-breed **models**, camera-facing **signature clips**, warm human "Bra!"/Maren voice, coat UV re-export) remain owner-gated.
The build loop turns the directive above into the next task.
