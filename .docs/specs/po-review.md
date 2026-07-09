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

### PO Review — 2026-07-09 (PO, father pass 80) — **task 202 completion-menu row-text AA fix VERIFIED in-pixel (menu «Sitt» name core now the true `[21,29,39]` ROW_ACTIVE_INK / «Ligg» the true SLATE `[90,107,125]` @4.78:1 — was 3.64 / 2.35); ONE new buildable X-6: the SAME thin-stroke render-wash lives on in the KENNEL screen — its grey `C_INK_SOFT` secondary text (grid breed subtitles + header subtitle + modal stat labels / section headings / «Kan lære») renders 1.38–2.94:1 in the actual render, under AA, the last high-traffic text surface the outline lever never reached.** No sign-off (Phase 10 stays owner-gated empty-spec).

Fresh, stateless pass. HEAD `85408fb` (task 202, board empty). The pre-existing `build/web/` (15:06) predated the 202 commit (15:11), so I rebuilt at HEAD via `verify.sh` (gate green, `✓ verify gate green` import·boot·test·export, Sitt-capable licensed Labrador bundled locally), served over http and driven in headless Chromium at 390×844 (SwiftShader == the deployed GL Compatibility renderer), `env -u LD_LIBRARY_PATH` (`tools/po_pass8_drive.mjs`). **Zero game console errors** on every run (training capture, `?bra_autotap=1` mark burst, menu / kennel-grid / modal drive). Contrast measured in shipped pixels with a WCAG sampler over the captured PNGs (darkest stroke-core vs the local fill).

**Pass-79 completion-menu row-text X-6 → FIXED and pruned.** Task 202 landed decisively in my own pixels (`.screenshots/PO8-04-menu.png`): the menu row names now render their **true** tokens — active «Sitt» darkest core `[21,29,39]` (= the real `ROW_ACTIVE_INK #141c26`, was the washed `[124,132,144]`@3.64), available «Ligg» core `[90,107,125]` (= true SLATE) at **4.78:1** vs the cream row (was 2.35), and the «Labrador» breed subtitle is now readable rather than a 1.58:1 ghost. The `draw_string_outline` stroke-thickening lever added inside `trick_menu._draw_text()` (`ROW_LABEL_OUTLINE=4`) raised every row through the same path to ~full coverage — names, badges, and the subtitle all lifted at once. Directive resolved.

**X-6 (Bugfix / AA) — the KENNEL screen renders its grey secondary text washed at 1.38–2.94:1 in the actual render, under the 4.5:1 AA floor; the 13px breed subtitles and modal captions are effectively invisible.**
- *What I saw (my own pixels — grid `.screenshots/PO8-05-kennel-grid.png` + `/tmp/bella_sub.png` 5× zoom, modal `.screenshots/PO8-07-modal-nova.png`, WCAG sampler, darkest core vs each element's opaque local fill).* With the HUD (200/201) and the completion menu (202) all now crisp, the eye goes to the **kennel**, whose grey secondary tier is the faintest text left in the game. **Grid:** the breed subtitle **«Labrador retriever» under «Bella» renders `[188,195,202]` → 1.78:1**, **«Border collie» `[191,198,205]` → 1.72:1**, **«Gravhund» `[196,202,209]` → 1.65:1** (all 13px `T_SMALL` `C_INK_SOFT` under each dog name), and the **header subtitle «Profesjonell fasilitet · 8 plasser» `[141,152,162]` → 2.94:1**. **Modal (Nova):** the **stat label «Læreevne» `[199,205,208]` → 1.55:1**, the **section heading «Raseegenskaper» `[189,196,200]` → 1.70:1**, and **«Kan lære: Sitt · Ligg · Legg deg» `[212,216,217]` → 1.38:1** — nearly invisible. Controls that PASS on the same surfaces render their true dark token: the **«Kennelen» title 11.44:1**, dog names **«Bella» 9.34:1 / «Pontus» 9.49:1** — so this is **not** a blanket wash, it is specifically the **grey `C_INK_SOFT` secondary tier** (subtitles, stat labels, section headings, «Kan lære»/«Unikt trekk» captions) that fails, exactly as the completion menu's row/subtitle tier did before 202.
- *Why it's a real defect, not sampling noise.* Same class the 145 / 196 / 197 / 200 / 201 / 202 fixes all closed by measuring **shipped pixels**, not the analytic ratio. Root cause is structurally identical **but on a different draw path:** `kennel_screen.gd` renders all its text through Godot `Label` nodes (grep confirms **zero** `draw_string` and **zero** `outline` in the file) with **no** `outline_size` / `font_outline_color` theme override, so at 13px the thin Nunito strokes cover only a fraction of each edge pixel and the darkest core is a partial ink-over-fill blend — the analytically-AA `C_INK_SOFT` (~4.78:1, the token task 156 chose) renders 1.4–2.9:1. This is precisely how the **nav pills** (also `Label` text) washed to 2.43:1 until task **200** gave them `HUD_NAV_LABEL_OUTLINE=4`; the 200/201/202 arc fixed the HUD, learned bar, and completion menu but **never touched `kennel_screen.gd`** — it is the last high-traffic text surface still on the bare no-outline path.
- *What "good" looks like.* Every kennel grey-secondary line (grid breed subtitles + header subtitle; modal stat labels, section headings «Raseegenskaper»/«Kan lære», the «Unikt trekk» caption) clears **≥4.5:1 in the actual 390×844 SwiftShader render** (darkest core vs its local fill, as measured here — not the analytic ratio), reading at least as solid as the «Kennelen» title / dog names already do on the same surface. Reuse the proven 200 lever adapted to the `Label` path: add a same-colour `outline_size` (≈4, matching `HUD_NAV_LABEL_OUTLINE`) + `font_outline_color` = the element's own token on the `C_INK_SOFT` Labels, raising effective coverage to ~full **without** changing font size, layout, or wording, guarded by an **in-pixel** render-floor measurement (not the analytic ratio) so an analytic-only value can't re-mask it. **Keep every token HUE and state exactly** — `C_INK_SOFT` stays the muted grey, the dark `C_INK` names/titles (already ~9–11:1) are unchanged, the 149 dark-ink badges, 117 coats, 162 price pips, and the modal layout all stay; this is an **ink/render coverage** fix, not a token, layout, or wording change.

**Surface sweep — otherwise clean (re-verified this pass; 199 owned-badge «Din hund» parity, 200 nav pills, 201 readout, 202 menu rows all stay fixed).** **Training page** matches the goal art (`.screenshots/PO8-01-training-a.png`): crisp-dark nav pills + learned readout, blue BRA hero CTA bold-white, gold coin pill, cream Labrador centred facing camera on green grass, tan path → blue-roofed cottage, white picket fence, gold + rose coins. **Completion menu** (`PO8-04-menu.png`): crisp dark row names + blue «Tilgjengelig» badges, greyed «Gi labb / Låst», solid blue «Fortsett treningen» primary + outline «Gi tilbakemelding» secondary. **Core loop juice** replays clean on the `?bra_autotap=1` burst: a PERFECT climbs the bar to 23 %, dog turns to camera and reacts — Phase 1/2 intact. **Kennel grid + modals** (`PO8-05` … `PO8-07-modal-{bella,nova,trulte}.png`): all 8 cells fill the portrait, correct Norwegian rarity corner badges (Bella «Din hund» / Nova «Episk» / Balder «Sjelden» / Sol · Pontus · Lykke «Vanlig» / Trulte «Påskeegg»), dark-ink badges (149), plausible per-dog coats (117); modals open on tap with bottom nameplate clear of the face, blurb, 4 stat meters, trait chips, «Unikt trekk», «Kan lære», affordability-gated adopt button — all structurally clean apart from the grey-text wash filed above. The task-202 diff is confined to `trick_menu.gd`, touching no kennel / HUD code, so those surfaces are unaffected by it.

**Considered but NOT filed — owner-gated / settled / timing.** (1) Warm-brown breeds read as similar mid-browns and Nova as uniform dark-grey, not iconic patterns — identity is **model/pattern**, owner-gated (BUST-068, P3-D1/D2/D4). (2) The active-**dog** word differs across surface families (menu selection-language «Trener nå»/«Aktiv»/«Valgt» vs kennel/showcase ownership-green «Trener nå») — each internally coherent and apt, a settled arc (152/167/pass-68/74). (3) The gold «PERFECT» verdict + gold «Bra!» word-pop use GOLD off the coin — a long-standing, signed-off celebration convention (Phase 1) shared with the mastery latch, deliberately not re-litigated. (4) The live idle dog can turn rear/side between frames — animation timing, not a layout defect.

**No sign-off.** Phases 1/2/3/5/6/8/9 remain signed; the kennel grey-text wash is a cross-cutting X-6 on the signed-off Phase-8 kennel (a polish/AA directive, not a phase regression — the kennel Labels always rendered this faint under the bare no-outline path; this pass measured it decisively now that the HUD + completion menu around it jumped to AA-clear). Phase 10 (`phase10.md`) is still **empty/deferred** — owner-gated (no spec ⇒ cannot Visual-Review, cannot invent scope). One buildable improvement filed; the rest stay standing owner-gated asset flags (distinct per-breed **models**, camera-facing **signature clips**, warm human "Bra!"/Maren voice, coat UV re-export).
