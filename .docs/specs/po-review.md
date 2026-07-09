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

### PO Review — 2026-07-09 (PO, father pass 72) — critique/polish pass. Pass-71's breed-showcase bottom-control chrome directive (task 197) **re-verified in pixels and resolved** (pruned): «Tilbake» now renders crisp **white on a near-black opaque pill** (stroke-core **7.44:1**, 99th-pct **5.05:1** on a tight glyph crop, peak 11.8:1 — was a grey ~2.35–3.15:1) and «Trener nå» reads dark-on-near-white at **5.24:1** (was 4.03), captions still clear (subtitle **7.38:1**, hint **13.99:1**), zero console errors (`.screenshots/P72-tb-tight.png`, `P72-bottom.png`, `P72-trener`). **ONE new buildable X-6 directive:** the *same* non-tappable «Trener nå» active-training-dog status pill now renders **two different tints across surfaces** — a cool pale slate `#eef1f5` in the breed showcase (set by 197) vs a faint green-mint `#e4f2e1` in the kennel modal (151) — even though 197's own commit claimed to match the kennel «Trener nå» precedent. Unify the showcase pill to the kennel's ownership-green active wash so the "currently training this dog" status reads as one colour language everywhere. No sign-off (Phase 10 owner-gated on its empty spec).

Fresh, stateless pass. HEAD `e0d37fc` (task 197; board empty); `build/web/` rebuilt at HEAD via `verify.sh` (gate green — Sitt-capable licensed Labrador bundled locally, ~39 MB `index.pck` refreshed at this HEAD), served over http (`python3 -m http.server 8099`) and driven in headless Chromium at 390×844 (SwiftShader == the deployed GL Compatibility renderer), `env -u LD_LIBRARY_PATH`. **Zero game console errors** on every run — training boot, the «Triks» menu, the breed showcase, the kennel grid + Nova modal. (Contrast figures below are measured off the captured PNGs with a WCAG-luminance sampler.)

**Pass-71 directive RESOLVED (197 backed the «Tilbake»/chevron chrome with an opaque near-black scrim + the thick Baloo display face, and lightened the «Trener nå» fill `cfd6dd`→`eef1f5`) — re-verified in pixels, pruned.** Task 197 (`e0d37fc`) mirrored 196's proven lever: `BTN_SECONDARY := CAPTION_SCRIM` (opaque near-black, was translucent `black@0.45`), `BTN_SECONDARY_TEXT` → full-opaque white, and `_make_button(..., display_face)` draws the back + cycle buttons in `font_display()` so their strokes cover full-white pixels. Measured this pass off tight glyph crops: «Tilbake» stroke-core **7.44:1** (pill lum 0.022, stroke-core 0.488), 99th-pct **5.05:1**, peak 11.8:1 — visibly crisp white (`.screenshots/P72-tb-tight.png`); «Trener nå» dark-on-pale **5.24:1** on the near-white `eef1f5` fill. Both clear the 4.5:1 AA bar in the actual render. Resolved; not re-filed.

**Improvement (X-6, DS consistency — the same «Trener nå» status pill renders a different tint in the showcase vs the kennel modal).** The prompt's DS lens explicitly calls out "the same component rendered differently across screens — unify them," and the non-tappable active-dog «Trener nå» status pill is now exactly that.
- **What I saw / measured:** the breed-showcase «Trener nå» pill fill is `commit_disabled_fill() = Color("eef1f5")` (`breed_showcase_view.gd`, set by 197) — a **cool pale slate**, computed rgb (238, 241, 245), blue-biased (b>g>r). The kennel modal's owned-active «Trener nå» pill fill is `active_state_fill() = C_MODAL_SURFACE.lerp(C_STATUS_OWNED, 0.14)` (`kennel_screen.gd:1585`) — a **faint green-mint** `#e4f2e1`, computed rgb (228, 242, 225), green-biased (g highest). So the identical non-tappable status pill for "the dog you're currently training", carrying the identical word «Trener nå», reads cool-slate in one surface and warm green-mint in the other. 197's commit message states it lightened the fill "matching the kennel-151 «Trener nå» precedent", but the colours don't actually match — the intended unification wasn't achieved.
- **Why it's wrong:** the green in the kennel is meaningful — `C_STATUS_OWNED` (#57b85c) is the ownership/active-dog identity colour («Din hund», the owned faint-green cell tint, the green «Tren med [navn]» switch). A player who sees the green-mint «Trener nå» in the kennel and then a cool-slate «Trener nå» in the showcase gets two different colour signals for the same "this is your active training dog" status, weakening the design-system's colour language. It's the lone cross-surface component inconsistency left after the AA sweep.
- **What "good" looks like:** unify the showcase «Trener nå» status fill to the **kennel's green-mint active wash** (reuse `active_state_fill()`'s green-mint, or an equivalent `#e4f2e1`) so the active-training-dog status pill reads one colour on both surfaces and ties to the ownership-green language. This is low-risk: both fills are near-white (lum ~0.83–0.88), so the dark-ink label keeps clearing AA in-pixel — **re-verify ≥4.5:1 from a captured showcase screenshot after the change** (the showcase pill sits over the dark spotlit band, so confirm the render, not only the analytic composite). Keep the label word «Trener nå», the pill shape, and the 197 AA win intact — this only aligns the tint.

**Surface sweep — otherwise clean (re-verified this pass, in my own pixels):**
- **Training page** (`P71-a-training.png`): matches the goal art (`.docs/specs/assets/goal-training-screen.png`) — blue BRA hero CTA with bold white label + 3D lip, hamburger + «Triks» + «Kennel» nav pills (full «Kennel», no truncation), gold coin pill, «Sitt … 0%» learned bar with opaque cream track, cream Labrador grounded on grass (wanders on idle, faces camera at a seated apex), tan path → blue-roofed cottage, white picket fence both sides, gold + rose coins, bushes. The extra «Kennel» nav pill vs the goal's single «Triks» is the intentional Phase-8 addition.
- **«Triks» menu** (`P72-menu-mastered.png`): DS paper card — «Triks» Baloo-2 title over coin pill, trick rows (Sitt «Trener nå» / Ligg · Legg deg «Tilgjengelig» / Gi labb «Låst»), «Raser» (Bella «aktiv» / Brun lab «Adopter 30»), blue-ghost «Vis frem hundene» + «Gi tilbakemelding» + solid-blue «Fortsett treningen» primary. Row names flush-aligned (195), section headings uniform (193).
- **Breed showcase** (`P71-c-showcase.png`, `P72-bottom.png`): «Mine hunder» / «Bella — aktiv» white titles + «Labrador» scrim-chip caption (196, AA-clear), cream Labrador spotlit on the garden (HUD hidden), «Bella» page-dot indicator (dark-ink on white, AA-clear), «Adopter flere …» hint scrim chip (196, 13.99:1), «Trener nå» + «Tilbake» bottom chrome now AA-clear (197) — tint-consistency flagged above.
- **Kennel** (`P72-kennel-grid.png` grid, `P72-kennel-nova.png` Nova modal): 8 cells fill the 844 portrait under «Kennelen · Profesjonell fasilitet» + coin chip, front-¾ full-body poses, Norwegian rarity/status corner badges (Bella «Din hund»/green, Nova «Episk»/violet, Balder+Sol «Sjelden»/blue, Pontus/Lykke/Sniff «Vanlig»/slate, Trulte «Påskeegg»/coral — dark-ink AA per 149), gold coin price chips by rarity (owned Bella none + faint-green tint; Trulte «Gratis»). Nova modal: dark hero bust matching the grid cell, «Nova» nameplate, blurb, 4 blue stat meters with the empty segment a present slate track (188), «Raseegenskaper» chips (Lærevillig · Energisk · Intens), «Unikt trekk» (Øyet), «Kan lære: Sitt · Ligg · Legg deg», solid-blue «Adopter 🪙 900» primary, unified light-disc ✕ (189). Coats: Bella cream, Sol golden, Trulte clean silver-white (192), Nova dark.

**Considered but NOT filed — owner-gated / intentional, not buildable polish.** (1) The four warm-brown breeds (Balder/Schäferhund, Pontus/Gravhund, Lykke/Spisshund, Sniff/Beagle) read as similar mid-browns — their catalog tints already span a genuine value/hue range and their real identities are **pattern/shape** (shepherd saddle, dachshund body, beagle tricolor) a single-colour tint on the one shared Labrador rig cannot convey; the honest fix is distinct per-breed **models** (BUST-068, P3-D1/D2/D4), a standing owner flag. (2) The trick-row «Tilgjengelig» vs the other sections' «Bytt» switch badge — kept (tricks carry a «Lært» learned state the others lack). (3) The active-state badge *word* differs across sections (trick «Trener nå», breed/word «Aktiv», difficulty «Valgt») — each reads correctly in its own context and pass-68 deliberately kept «Valgt»; not re-litigated (distinct from the *colour* directive above, which is a genuine cross-surface tint mismatch of the same «Trener nå» component). (4) The showcase dog is a live idle that can turn rear/side between frames — animation timing, not a fixable layout defect.

**No regression** in any signed-off phase: every surface renders as before, the «Triks» menu + breed showcase + kennel grid + Nova modal all drive clean, closing back restores the Phase-6 training page + Phase-1/2 core mark loop (cream Labrador grounded on green grass, tan path, cottage, fence, coins, blue BRA). Zero console errors throughout.

**No sign-off.** Phases 1/2/3/5/6/8/9 remain signed with no regression. Phase 10 (`phase10.md`) is still **empty/deferred** — owner-gated (no spec ⇒ cannot Visual-Review, cannot invent scope). This pass re-verifies the 197 chrome-AA fix («Tilbake» 7.44:1 core / «Trener nå» 5.24:1), prunes it, and files **one buildable X-6 directive** (unify the showcase «Trener nå» status-pill tint `#eef1f5` cool-slate to the kennel's `#e4f2e1` green-mint active wash so the same component reads one colour across surfaces). The standing asset flags (distinct per-breed **models**, camera-facing **signature clips**, warm human "Bra!"/Maren voice, coat UV re-export) remain owner-gated.
