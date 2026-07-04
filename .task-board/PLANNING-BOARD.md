# Planning Board — Bra! v2

Source of truth: [`.docs/specs/`](../.docs/specs/) (phased user stories — one file per
phase + `index.md`; PO log in `po-review.md`) and the ADRs in [`adr/`](../adr/).

> **Phasing rule (from the spec):** Phase 1 is the whole bet. Nothing past Phase 1
> starts until Phase 1 passes its Visual Review and is bug-free.

## Status — PHASE 5 CURRENT — father's first Phase-5 PO play-test (2026-07-04) DECLINED sign-off, filed 2 buildable directives → scan replenished 094/095 — 2026-07-04

The father PO play-tested the Phase-5 foundation (091/092/093 on the live build) and **declined
sign-off** (`.docs/specs/po-review.md`, PO Review 2026-07-04). Two of four stories are confirmed
good — **P5-4** (load/swap in the menu) and **P5-1** (progressive unlock + voiced Piper lines) —
but the phase is not sign-off ready:

- **Improvement 1 (P5-3 — the word never appears on screen).** On a successful mark the only
  on-screen text is the top-centre "PERFECT" verdict; nothing pops for the marker **word**.
  Phase 5's headline (collectible words) is invisible in the one moment it should pay off →
  loading Dyktig! changes only the audio, so play "reads as nothing changed."
- **Improvement 2 (P5-2 — the stronger-word trade-off is imperceptible).** The cooldown cost is
  invisible at the decision point (a stronger word's menu row shows only "Switch", no hint of the
  wider-window/cooldown trade-off), and the resting badge has no count. A cost the player can't
  see isn't a trade-off. PO: **ship this together with P5-3.**

**Empty backlog → scan replenished 2 current-phase tasks (both direct PO directives, NOT work-ahead) — BOTH NOW SHIPPED, pushed, verify 502/0:**
- **094 — FEATURE — P5-3 marker word pops on the mark — DONE (`b77a133`).** New `WordPop` dumb renderer
  (twin of `TierReadout`, driven from `main._process`, mounted above the BRA button). On every
  successful mark `_play_payoff` pops the **effective fired word** (`_words.display_for(fired)` — incl.
  the `Bra!` fallback while a stronger word cools); it floats up and fades, X-5 dampens the float not
  the word. 7 TDD tests. Visual Review PASS (`094-pop-13`: "PERFECT" top-centre + "Bra!" above the
  ghosted button — separated, no collision). Also makes the P5-2 fallback visible in play.
- **095 — FEATURE — P5-2 trade-off made legible — DONE.** `MarkerWords.cooldown_remaining(id)` +
  `classify_words` rows enriched with catalog `window_scale`+`cooldown` + `_word_rows` appends live
  `remaining`. The menu now shows each stronger word's **cost before loading** (dimmed hint
  "+15% · hviler 2" on UNLOCKED/ACTIVE rows; base "bra" none) and the cooling badge reads **"Hviler (n)"**
  with the live count. 7 TDD tests. Visual Review PASS (`095-01`/`095-02`). No in-round verb (X-2/P5-4 hold).

**Backlog now EMPTY.** Both of the father's 2026-07-04 Phase-5 directives are served (the headline word
pop + the legible cooldown), the pair the PO asked to "ship together." verify green (502/0), pushed. No
un-busted flags (voice/telemetry/breed-model residuals stay genuinely owner-gated — do NOT re-bust).
→ terminal hand-off to the father for the next Phase-5 Visual-Review sign-off pass (P5-1/P5-2/P5-3/P5-4
now all in pixels). Any PO reopen / new flag / regression preempts.

---

## Status — PHASE 3 SIGNED OFF by owner (`b2041dc` → board `daef545`) → **PHASE 5 (better marker words) NOW CURRENT** → scan replenished 091/092/093 — 2026-07-04

The owner (larssski) declared **Phase 3 done** and restored the append-only Phase Sign-off list
(P1/P2/P3) in `po-review.md` (`daef545`). The current phase resolves to the lowest unsigned
`phaseN.md` = **Phase 5 — better marker words** (numbering skips 4/7). The PO Review section is
reset, awaiting the first Phase-5 play-test.

Phase 5 is **greenfield** (repo-wide grep for `dyktig|flink|kjempebra|marker_word` = 0 hits; only
`bra_tts_placeholder.wav` exists). This is NOT the prior terminal-zero idle state — it is a real
phase transition with substantial buildable work. The voice gate is already busted (BUST-043): the
four new words synthesize offline via the proven Piper pipeline (`tools/gen_bra_voice.sh`), the
human Maren recording stays an honest open flag — same stance as base "bra".

**This iteration SHIPPED the Phase-5 foundation slice (091/092/093 — all done, pushed, verify 488/0):**
1. **091 — P5-1 marker-word catalog + 4 voiced Piper lines + progressive unlock — DONE (`_words` spine).**
   `MarkerWords` value object (mirrors `BreedRoster`), four `word_*_placeholder.wav` clips synthesized via
   the proven Piper pipeline (`tools/gen_marker_words.sh` + parameterised `gen_bra_voice.sh`), persistence
   in the one save blob (defaulted `words` key, no schema bump), `PayoffPlayer.set_active_word`. Mastery
   unlocks the next word; unlock does NOT auto-activate (orchestrator corrected the haiku test's drift —
   base "bra" stays default per P5-2/P5-4). Voice flag extended to name the 4 human-Maren stand-ins.
2. **092 — P5-4 load/swap the active word — DONE.** New "Marker words" section in `TrickMenu` (mirrors
   Breeds; row route, no in-round button). Visual Review PASS on the real build (`.screenshots/092-01/02`):
   real canvas tap swaps bra→dyktig, ACTIVE highlight moves, menu stays open. Added `__bra_word_rows`
   capture seam + `tools/web_capture_words.mjs`.
3. **093 — P5-2 stronger words trade wider window for a cooldown — DONE.** Per-word `window_scale`+`cooldown`
   (bra identity 1.0/0 → play byte-identical); a stronger word widens PERFECT when available then rests N
   successful marks, falling back to "bra" while cooling (no hard-fail); menu shows a "Hviler" badge. 10 TDD tests.

**Backlog now EMPTY.** Next iteration runs `scan-project` for the remaining Phase-5 work:
- **P5-3 (word pops/floats on screen on a mark)** — deferred THIS round by the visual-domain-saturation filter
  (visual had 5 of last 15 done). `scripts/tier_readout.gd` is the ready template (fade-in/float-out, driven
  from the same `_play_payoff` seam) — likely the next task once visual isn't saturated.
- Tuning pass on the 093 window_scale/cooldown numbers (defensible starting values; refine under PO play-test).
- Then hand the empty board to the father for the first Phase-5 Visual-Review sign-off.

**Recently completed:** Phase 3 fully shipped + signed off by owner 2026-07-04 (070–079/077, 080–082 work-ahead
difficulty, 083–086 telemetry, 087–090 showcase). All owner-gated residuals (2nd breed model, P3-2 signature
clip, POSTHOG_TOKEN, human Maren voice) remain open flags — do NOT re-bust.

---

## Status (superseded) — father RE-REVIEWED (HEAD `b7f8d51`), both showcase bugs FIXED (089/090) → no buildable directive → construction-audit CLEAN → terminal ZERO (2nd hand-off), blocked PURELY on owner — 2026-07-03

Empty backlog → scan ran. The prior hand-off reached the father, who reviewed HEAD `455f554` (087 showcase +
088 verdict) and filed **two buildable showcase bugs**; both were served and are now confirmed fixed:

- **Bugfix 1 (tofu ◀▶ cycle controls) → FIXED by 089 (`ffce458`).** The showcase cycle arrows are now a
  **drawn** `Chevron` (`draw_colored_polygon`, no font glyph) and the hint reads "Bla med pilene eller trykk
  en hund" — no `◀`/`▶` (U+25C0/U+25B6) in any rendered string. Father confirmed in pixels
  (`po-crop-showcase-bottom-091.png`).
- **Bugfix 2 (BRA button bleeds through the showcase) → FIXED by 090 (`b7f8d51`).** `_set_training_hud_visible(false)`
  hides all 7 training-HUD nodes (BRA button incl.) while the showcase is open and restores them on every close
  path. Father confirmed the clean-centre read holds (`087-01`/`087-02`).

**Father's fresh PO review (2026-07-03, HEAD `b7f8d51`, committed this pass) declined sign-off but filed NO new
buildable directive** — every surface replays clean (core loop, 077 no-rear-spin, completion menu, feedback
form; no Phase-1/2 regression). Phase 3 is now blocked **purely on the owner**: a genuinely distinct 2nd-breed
**model** (P3-1/P3-D1/D2/D4 — the two "breeds" are one rig + a coat recolor), the per-breed **signature clip**
(P3-2, proven owner-gated by the 088 flag-bust), the `POSTHOG_TOKEN` secret, and the human Maren voice.

**This round's adversarial construction audit (cold, refute-first) covered the delta since the last audit
(`e86d71b..HEAD` = 087/088/089/090) and returned CLEAN** across all 6 checks: showcase tests assert observable
behaviour (not hollow); the 088 revert left **no** dead seam (grep-confirmed no grav/dig/trick_list symbols);
no tofu glyph reaches any rendered string (drawn chevron verified); the HUD-hide is real + reversible on all
three close paths; no placeholders / primitive stand-ins (showcase re-tints the real live rig); every shipped
`[x]` is backed by present behaviour.

**Idle ladder → clean ZERO (terminal hand-off):**
1. *Current-phase buildable work* — none; both PO showcase bugs fixed + confirmed, father filed no new directive.
2. *Flag-bust* — all 5 Open flags are `busted`-or-genuinely-owner-gated (breed **models** + P3-D1/D2/D4, the
   P3-2 signature clip, the human **Maren** voice, the `POSTHOG_TOKEN` secret). No new info → not re-busted.
3. *Asserted owner-gates* — every owner-gate the father's review names is already covered by an existing flag;
   nothing un-flagged to raise.
4. *Work-ahead* — the one block-independent slice (**Phase 9 Difficulty**) is already banked (080–082); Phases
   5/6/8 each fail a guardrail (5 = owner-gated voice; 6 = restyles the reviewed training page, can't be
   dormant + saturated; 8 = needs breed models + unbuilt Phase 6). The delta was all current-phase → **no new
   eligible work-ahead.**

So no current-phase work, no un-busted flag, no un-flagged owner-gate, no eligible work-ahead → **scan returns
zero.** `verify.sh` re-run green (docs-only commit; code byte-identical to the last green gate at `b7f8d51`).
Board left empty — a **legitimate terminal hand-off**. The father has now re-reviewed this exact HEAD and found
nothing buildable; the next unchanged pass should end the run so the human can add the breed models / secrets /
voice. Any PO reopen / new flag / regression preempts and re-opens current-phase work.

---

## Status — both PO Changes served (087 built + 088 flag-busted) → construction-audit CLEAN → terminal ZERO, hand off to father for P3 sign-off — 2026-07-03

Empty backlog → scan ran. The father's 2026-07-03 review (below) declined P3 sign-off with exactly **two
buildable Changes**; both are now served on HEAD `68d7641`:

- **Change 1 (P3-4 spotlit breed-select showcase) → BUILT (087, `63528e5`).** `BreedShowcase` pure model
  (5 TDD tests) + `BreedShowcaseView` renderer + main wiring — a menu pill opens a stage-brightened screen
  showing owned breeds as a spotlit live dog, ◀▶/pips preview by re-tinting the live rig, "Tren denne"
  commits via `_on_breed_chosen`. Visual Review PASS (`.screenshots/087-01..04`).
- **Change 2 (P3-2 breed trick divergence) → FLAG-BUSTED to an owner-gate (088, `68d7641`).** Route 2b:
  the rig's only start/loop/end action clip (`Digging`/"Grav") was driven **live** at a PERFECT apex and
  plays **rear-to-camera** — it fails the PO-enforced face-camera-at-apex bar (061/077/note 3); a per-trick
  yaw fix had no effect (the clip drives its own apex orientation). No on-rig clip clears the Phase-1 bar,
  so **no stub trick shipped**; the Grav wiring was fully reverted (grep-confirmed: no grav/dig/trick_list
  symbols remain). P3-2's divergence is recorded in `FLAGS.md` as owner-gated on a camera-facing signature
  clip / a 2nd real breed model (P3-D1/D2/D4).

**This round's adversarial construction audit (cold, refute-first, HEAD `68d7641`) returned CLEAN** — 087's
showcase renders a real live re-tinted dog (not a coloured dot/primitive), prev/next traces to the real
`CoatTint.apply` path, "Tren denne" reaches `_on_breed_chosen`, the stage brighten restores its lighting on
close, all 5 tests assert observable behaviour, and 088 genuinely carries no divergence/stub code. `verify.sh`
green (import·boot·test·export, 442/0). (Fixed two harmless doc artifacts in the 088 done file: unchecked
acceptance boxes + a stale "455 tests" figure the revert dropped back to 442.)

**Idle ladder → clean ZERO (terminal hand-off):**
1. *Current-phase buildable work* — none; both PO Changes served (built / owner-gated verdict).
2. *Flag-bust* — all Open flags are `busted`-or-owner-gated (breed **models** + P3-D1/D2/D4, the human
   **Maren** voice, the `POSTHOG_TOKEN` secret, and now the P3-2 signature clip). No new info → not re-busted.
3. *Work-ahead* — the one block-independent slice (**Phase 9 Difficulty**) is already banked (080–082);
   Phases 5/6/8 each fail a guardrail (5 = owner-gated voice; 6 = restyles the reviewed training page, can't
   be dormant + saturated; 8 = needs the 8 breed models + unbuilt Phase 6). **No eligible work-ahead.**

So no current-phase work, no un-busted flag, no eligible work-ahead → **scan returns zero.** Board left empty
for the runner to hand off to the **father's PO Visual-Review pass** on HEAD `68d7641` (now including the 087
showcase + the 088 verdict). Any PO reopen / new flag / regression preempts and re-opens current-phase work.

---

## Status (superseded) — Father REVIEWED (HEAD `e86d71b`), DECLINED P3 sign-off → 2 buildable Changes tasked (087/088) — 2026-07-03

The terminal hand-off below reached the father. The father re-reviewed the live licensed bundle at 390×844
(`po-review.md`, 2026-07-03) and **confirmed fixed**: 077 rear-spin (dog stays seated/facing through payoff),
078 garden cohesion, 079 collection loop (adopt→switch→re-tint→persist, real taps), and the X-8 feedback
entrypoint. **But declined sign-off** — the phase *headline* ("dog breeds, each with its own tricks") isn't
delivered: the 2nd "breed" is a coat recolor of the same rig, both breeds train an **identical** trick list,
and nothing *shows off* the dogs. Two buildable current-phase Changes filed → this preempts the idle hand-off:

- **087 — ✅ DONE (2026-07-03): spotlit breed-select/showcase screen (P3-4 / PO-Improvement-2).** New
  `BreedShowcase` pure model (5 TDD tests) + `BreedShowcaseView` dumb renderer + main wiring: a "Vis frem
  hundene" menu pill opens a screen that **brightens the stage** (key ×1.7 + viewer-side fill, restored on
  close) and shows the owned breeds as a spotlit, centred live dog — ◀ ▶/pips **preview** by re-tinting the
  live rig (no persist), "Tren denne" commits via the existing `_on_breed_chosen` (switch+persist). Visual
  Review PASS (`.screenshots/087-01..04`, real taps). verify 442/0. 079 adopt loop unregressed.
- **088 — FEATURE: breeds train different tricks (P3-2).** Flag-bust `dog_licensed.clips.txt` for a **real,
  Phase-1-quality** signature clip (strongest candidate: `Digging_*` = "Grav"); if usable, wire it as one
  breed's signature so the two lists **diverge** (per-breed trick list, like 065/067). If nothing usable at
  quality → record P3-2 as owner-gated (P3-D1/D2/D4), no stub. Bust-gate → TDD build + Visual Review.

**Owner-gated residuals (NOT build-loop work — do not re-date):** a genuinely distinct 2nd-breed *model*
(Border Collie / French Bulldog / Husky — P3-D1/D2/D4), the `POSTHOG_TOKEN` secret, the human Maren voice.

Domain note: UI is near-saturated (072/073/085), but 087/088 are current-phase *headline* requirements the PO
named, not polish → eligible under the "only remaining gap in the current phase" override.

---

## Status (superseded) — Phase 3 EXHAUSTED → clean scan-project ZERO → terminal hand-off to father (P3 sign-off) — 2026-07-03

Empty backlog → scan ran. Since the 2026-07-02 block below, telemetry/feedback shipped (**083** base ADR-0007,
**084** call-site wiring, **085** in-menu feedback form, **086** CI token inject) — the X-8 done-bar for Phase 3
is now met, dormant until the owner sets `POSTHOG_TOKEN`. HEAD `e86d71b`, tree clean.

This round's **adversarial construction audit of Phase 3 returned CLEAN** (2nd independent pass): every P3 story
built and honestly wired — coin economy, one-active-trick completion menu, chocolate-Lab recolor breed,
BreedPersonality's 4 levers at real call-sites, JoyBeat celebration driven at **both** mark sites with
`play_reaction` retired (no rear-spin), garden FBM grass + hedge + contact shadow, the adopt→switch→persist
roster loop reachable in-game via the TrickMenu signals, and all **6 telemetry events** through the single
`telemetry.gd` choke-point (fire-and-forget, anonymous/cookieless, no-op without a token). Difficulty work-ahead
(080/081/082) confirmed truly dormant (Normal = identity on all levers). No construction findings.

**Idle ladder resolved → clean ZERO (terminal hand-off), NOT more work-ahead:**
1. *Current-phase buildable work* — none (audit clean).
2. *Flag-bust* — all four Open flags are already `busted` or genuinely owner-gated (breed **models** +
   P3-D1/D2/D4, the human **Maren** voice, and the `POSTHOG_TOKEN` secret). No new information since the last
   bust → not re-busted (converge, don't spin).
3. *Work-ahead* — the one clean, block-independent next-phase slice (**Phase 9 Difficulty**) is **already banked**
   (080–082). Every *other* remaining unbuilt phase fails a hard work-ahead guardrail:
   - **Phase 5 (marker words)** — the phase *is* the owner-gated **voice** (P5-1 "voiced line in the Maren
     delivery"). Guardrail (d): don't build next-phase work that depends on the voice block. **Ineligible.**
   - **Phase 6 (design system / training-page restyle)** — restyles *the training page*, the exact screen the
     father reviews for P3 sign-off → cannot be dormant. Guardrail (b). (Also saturated visual domain.)
     **Ineligible.**
   - **Phase 8 (kennel)** — "Builds on the Phase 6 design system" (unbuilt) and needs the **8 breed models**
     (owner-gated). Guardrail (d) + unbuilt prerequisite. **Ineligible.**

So there is no current-phase work, no un-busted flag, and no *eligible* work-ahead → **the scan returns zero.**
Per `mother_prompt.md` this empty board is a **legitimate terminal hand-off**, not a failure — the loop must not
manufacture busywork to stay alive. Board left empty for the runner to hand off to the **father's PO
Visual-Review pass** on HEAD `e86d71b` (which now includes 077/078/079 + the telemetry drop, none of which the
father has reviewed since the `0506503` pass). Any PO reopen / new flag / regression preempts and re-opens
current-phase work. No verify re-run this round: no code changed, tree byte-identical to the last green gate (086).

---

## Status — Phase 3 EXHAUSTED (construction-clean) → WORK-AHEAD into Phase 4 (Difficulty) — 2026-07-02

Empty backlog → scan ran. **077/078/079 all shipped** (post-BRA JoyBeat fix, garden cohesion, adopt/select/
persisted roster). The **adversarial construction audit of Phase 3 returned CLEAN** — tests behavioral (not
hollow), no un-allowlisted placeholders, JoyBeat/CoatTint real, and the 079 adopt→switch→persist loop is
genuinely wired to the TrickMenu signals (not gated behind `?bra_breed=`). All three Open flags are `busted`;
the residual (extra breed *models* + P3-D1/D2/D4 + spotlit select polish) is genuinely owner-gated. So Phase 3
is blocked **purely** on owner assets + the human PO sign-off.

Per the spec's **Work-ahead exception**, the loop pulls the **next unbuilt phase (Phase 4 — Difficulty)**
buildable stories **provisionally** — dormant (Normal-default = today's feel exactly; only the `?bra_difficulty=`
seam activates non-Normal), independent of the owner-gated block, never advancing the phase. Three tasks:

- **080 — FEATURE (work-ahead) — `Difficulty` mode model + persisted global setting (P4-1). DONE
  2026-07-02.** New pure `Difficulty` (Normal = identity — every modifier 1.0, so dormant; Hard/Expert
  monotonic deltas), `catalog()/is_known()/by_id()` resolver. Rides the ONE save blob
  (`TrickStore.encode/decode_difficulty/load_difficulty`, legacy/corrupt/unknown → "normal"), boot resolves
  `_difficulty` from the persisted setting or the `?bra_difficulty=` dormant seam (no default-HUD selector).
  Verify green (369/0), placeholder-clean, default boot byte-identical to HEAD. No lever wired yet (081).
- **081 — FEATURE (work-ahead) — higher difficulty changes the read, stacked on the breed (P4-2 + P4-4).
  DONE 2026-07-02.** Composition lives as pure resolved accessors on `Difficulty` (`scale_radius/scale_feint/
  scale_erosion/scale_tell_intensity`, Normal = identity); `main` composes `effective = breed × difficulty` at
  the four sites — window radii (528), tell intensity (531, `ramp=ok_radius` so the tighter window makes the
  tell narrower/"faster" for free — one source of truth), feints (1111 + 1462 breed-switch), and erosion (new
  per-instance `TrickProgress._erosion_scale`/`set_erosion_scale`, mastery floor still protects). **Removed the
  redundant `tell_speed_scale`** (would break ApexTell's tell-tracks-window invariant → dead seam). X-5 floor
  `TELL_FLOOR=0.15` keeps the tell non-zero. Verify green (393/0, +43), placeholder-clean, default-Normal boot
  byte-identical (dormancy regression tests green).
- **082 — FEATURE (work-ahead) — pain pays: difficulty scales the mastery reward (P4-3). DONE 2026-07-02.**
  Pure `Difficulty.mastery_reward(base) = round(base × reward_scale)`; the mastery earn site
  (`main.gd:1609`) pays `_difficulty.mastery_reward(COIN_REWARD_MASTERY)`. Normal → 10 (today's economy
  exactly), Hard → 14, Expert → 20. Verify green, placeholder-clean, default-Normal economy byte-identical.

**Board now EMPTY.** The core Phase-4 difficulty loop is built **dormant** (P4-1 setting, P4-2/P4-4 read×breed,
P4-3 reward) — all gated behind Normal-default + the `?bra_difficulty=` seam, so the Phase-3 play-test is
untouched. Remaining Phase-4 work-ahead for a later round: **P4-5** (background-resume grace — independent,
small) and a player-facing difficulty selector (that lands when Phase 4 becomes *current*, not dormant).
Phase 3 still awaits the human PO sign-off; any PO reopen / new flag / regression preempts work-ahead.

**Note (adjudicated):** memory observations 4816/4817 claim a "post-BRA visual regression persists on 077" —
these were auto-generated by the memory system's summarizer watching the audit subagent and **conflate** the
*pre-077* PO directive (build `0506503`) with a new finding. The committed `po-review.md` is unchanged since the
077 commit (`cf6af99`), no uncommitted spec edit, no new flag; the audit independently confirmed 077's fix is
real and reachable. **No current-phase work is reopened**, so work-ahead is not preempted. If the human PO
re-reviews HEAD post-079 and finds the flick, that lands as a committed directive and preempts work-ahead then.

**Current-phase preemption still stands:** any PO reopen / new flag / regression drops work-ahead and serves
Phase 3 first. The father's PO sign-off pass runs on its own cadence regardless.

---

## Status — Phase 3 CURRENT — PO 2026-07-02 (HEAD 0506503) pass: 077 reaction-fix DONE, 078/079 queued — 2026-07-02

The PO re-reviewed the chocolate-Lab + BreedPersonality drop (HEAD `0506503`) and pruned the shipped
directives (completion menu, framing, BreedPersonality, chocolate render all confirmed), filing **three
new buildable Phase-3 directives**. The empty backlog → scan emitted **077 / 078 / 079** in priority
order (bugfix → improvement → change); **077 built this iteration.**

- **077 — FIX — post-BRA reaction rear-spin → facing-preserving celebration (Bugfix/Note 7). DONE
  2026-07-02.** The mark celebration played `Jump_Place_IP` — the only in-place celebration clip — which
  **rotates the dog rear-to-camera** (tail up) and snaps through a side profile (PO frames
  `B-react-018/021`), breaking the core payoff. New pure `JoyBeat` (unit-tested) drives a damped,
  **yaw-capped** happy bounce off the dog root — the positive twin of the confused beat — that stays
  facing the player, eases in/out, settles exactly to rest (X-5 scaled). Both mark sites (`_play_payoff`,
  `_play_mastery_beat`) now drive it instead of the hop; `DogDirector.play_reaction` retained as a tested
  capability. 5 TDD tests RED→GREEN, 326/0; **Visual Review PASS** — 17 live frames `.screenshots/077-joy-*`,
  dog never rear-to-camera. Verify green, placeholder-clean.
- **078 — VISUAL — garden cohesion: stylized grass + depth + contact shadow (Improvement/Note 6).
  QUEUED.** The flat green void makes the photoreal dog read as a cutout; give the ground real stylized
  shading/texture + horizon depth + a legible contact shadow so dog and world read as one stylized-real
  scene. GL-Compatibility-safe; no letterbox regression.
- **079 — FEATURE — adopt + select + persisted owned-breeds roster (Change/P3-1·D3·P3-4). QUEUED.**
  Spend earned coins to adopt the already-built chocolate Lab, persist an owned-breeds roster in the one
  save blob, switch the active breed — turning the disconnected economy + 2nd breed + menu into the real
  collect-and-train loop. Additional breed *models* + select-screen *polish* stay owner-gated flags.

**Next scan:** work 078 then 079 (both current-phase, no owner model needed). No un-busted flags remain.

---

## Status — Phase 3 (breeds/economy/personality) CURRENT — scan tasked PO 2026-07-02 notes 4/5 + Improvement-4 — 2026-07-02

Phase 2 signed off (2026-07-01); **Phase 3 is current**. The economy/personality/roster spine builds
without the owner (BUST-068); only extra breed models + P3-D1/D2/D4 decisions stay owner-gated. The
owner's 2026-07-02 `po-review.md` pass added actionable notes; the loop is working them in order.

**Recently completed (Phase 3):** 068 coin economy core · 069 coin readout · 070 feint rate 0.35→0.10
(note 2) · 071 dog present between offers — centred + faces player + scratch feint (note 3) · **072 —
one active trick + completion menu (note 1). DONE 2026-07-02.** Notes 1/2/3 all shipped.

**This scan (empty backlog → 3 tasks, current-phase work):**
- **073 — FIX — mark is hard to time: clearer tap target + late-biased PERFECT (note 5). DONE
  2026-07-02.** `SitWindow` bands are now late-biased (`DEFAULT_LATE_BIAS := 0.09`): a ~120 ms-late
  tap lands PERFECT, early edge unchanged (TDD, 3 new tests RED→GREEN). BRA button is now a rounded
  pill so the shrinking trainer ring reads as a *tap* target, not a swipe (Visual Review PASS,
  `.screenshots/058-trainer-ring.png`). Verify green.
- **074 — BUST — Chocolate Labrador as a recolor (note 4). DONE 2026-07-02 — BUILDABLE.** The
  licensed Lab is a single coat material with a white `baseColorFactor` (colour is all in the baked
  atlas), so a runtime `albedo_color ≈ #AA7D51` multiply reads as a convincing chocolate at phone
  scale — a real 2nd breed, **no owner model.** Routed → **build task 076**; breed flag narrowed
  (`busted BUST-074`). Only a cosmetic mouth-interior re-paint stays owner-gated (non-blocking).
- **075 — FEATURE — `BreedPersonality` drives the difficulty levers (Improvement-4 / P3-3). DONE
  2026-07-02.** New pure `BreedPersonality` (RefCounted) holds four temperament multipliers around
  1.0 and resolves them against the canonical constants; Labrador #1 = learn 1.15 / distract 0.9 /
  window 1.1 / energy 1.0. Wired additively: `TrickProgress._init(p_perfect, p_ok)` (defaults =
  constants, anti-regression), settable `SitLoop.min_gap`/`max_gap`, `DogDirector.trick_window` takes
  optional radii, and `main.gd` holds one `_breed` feeding all four levers. 4 new TDD tests RED→GREEN;
  every existing test stays green (neutral 1.0 == baseline); verify green; placeholder-clean.

**Still queued (next scan):** note 6 (garden styling + dog↔garden cohesion — deferred this round by
the domain-saturation filter: visual/UI dominate the last 15 done) and Change-5 (persisted roster
spine, P3-4).

---

## Status — Phase 2 OPEN; all buildable stories DONE (058/P2-9 landed) — awaiting PO sign-off — 2026-07-01

Phase 1 **signed off**; **Phase 2 (`phase2.md`) is the current phase** per `po-review.md`'s Phase
Sign-off gate. This iteration ran `scan-project` on an **empty backlog**, found the one remaining
non-owner-gated story (**P2-9**, the fading timing trainer), emitted it as **058**, and **built it**
in the same iteration. With 048 + 050 (P2-8) and 049 (P2-5) already landed, **every non-owner-gated
Phase-2 story is now built**: P2-4 (045), P2-5 (049), P2-7 (046), P2-8 (048+050), P2-9 (058), P2-10
(047). The board is now empty with **no un-busted open flags** → the next iteration is a true **idle
hand-off to the father / PO sign-off pass**.

- **058 — FEATURE — A timing trainer that fades (P2-9). DONE 2026-07-01.** A bold cyan approach ring
  that **shrinks onto the BRA button and lands exactly at the apex**, shown while a trick is new,
  **fading as the learned bar fills** and **gone at mastery**, riding the **same `SitWindow`** so it
  stays dark during feints/ambient. Hybrid like P1-4: pure **`TrainerRing`** envelope (TDD —
  lands-at-apex + fade-with-progress + dark-off-window, single-source-of-truth `from_window`) +
  **`TrainerRingMarker`** dumb renderer (cyan, distinct from the gold tell) + `main.gd` glue
  (`_begin_sit` builds it from current learned level; feint never builds it → ring dark;
  `?bra_force_trainer=1` capture seam, web-marshal-safe STRING sentinel). **218 tests / 0 failures**
  (+28 new, confirmed running); verify gate green; placeholder-clean. **Local render proof PASS**
  (`.screenshots/058-trainer-ring.png`, 4937 cyan px) — the cyan ring composites over the BRA button
  on the real Web GL path (guards the 030/036 tests-green/pixels-blank failure). **Live behavioral
  proof too** (the local Web bundle prefers the licensed sit-capable dog): a free-run burst caught the
  cyan ring **shrinking through a real sit and landing on the BRA word at the apex** with the dog
  fully seated, concentric just inside the gold tell, and **dark between sits / feints**
  (`.screenshots/058-live-*`). Explicit fade-with-bar / gone-at-mastery (unit-locked) rides the PO pass.

**What now awaits the PO sign-off pass (no buildable construction left):** the live-pixel review of
P2-9 on the deployed build **and** the P2-4 erosion / confused-beat live-pixel catch the PO flagged
for the eventual sign-off — both on the deployed licensed build, both PO/father actions. Per the
phasing rule, nothing past Phase 2 starts until Phase 2 is signed off in `po-review.md`.

**Still gated (NOT buildable):** P2-1 / **P2-2** / P2-3 (trick selector + distinct trick
animations + per-trick polish) stay **owner-gated** — the licensed Labrador pack ships only
`Sitting_*` (no Ligg / Legg deg clip), so there is no second trick to select, perform, or polish. A
one-entry selector or a faked second trick is forbidden (CLAUDE.md); entry point is a `SPIKE-` to
inventory the pack, then an owner/asset flag. The warm **human** Maren "Bra!" recording remains the
only other open owner gate (narrowed flag; warm Piper neural stand-in ships under the cue id, 044).

---

## Status — Phase 2 OPEN; 045/046/047 done, backlog replenished with 048/049 (2026-06-30)

Phase 1 is **signed off** (section below); **Phase 2 (`phase2.md`) is the current phase** per
`po-review.md`'s Phase Sign-off gate. This iteration ran `scan-project` against `phase2.md` + the
Phase-2 Forward PO Directives on an **empty backlog** (045/046/047 all done; the one Open flag is
already `busted`, so no `BUST-` task). The construction-audit/idle hand-off does **not** apply —
Phase 2 has clear remaining buildable gaps, so the scan replenished the backlog with the next two
well-scoped, **non-visual, TDD-able** slices (the visual/rendering domain is **saturated** — ~7 of
the last ~15 done tasks — so pure-visual work is deprioritized): **048** (P2-8 logic core —
variable cadence + feints, the keystone, now unblocked by 047's garden) and **049** (P2-5
persistence, completing the 045 learned-bar story). Board-only this iteration (the proven
"056" rhythm: one scan fills the backlog, each task then builds in its own focused iteration).
**Everything below the Phase-1 sign-off section is historical Phase-1 working notes — superseded by
this section and the live `.task-board/` dirs (in-progress + on-hold are empty).**

**Phase-2 progress:**

- **045 — FEATURE — Learned bar + mastery (P2-4). DONE 2026-06-30 (iteration 056).** The spine
  of the phase. Pure `TrickProgress` (TDD: PERFECT +0.20 > OK +0.08; MISS −0.10 / DEAD −0.05
  erode; net-forward; floors at 0; 100% latches mastery as a safe checkpoint) + `LearnedBar` UI
  (green→gold, reads by length, red setback wash) + main wiring (mastery beat reuses the real
  joyful clip; procedural confused recoil restored to rest, no drift). 142 tests green; verify
  green. **Live-proven on the licensed build** (`.screenshots/045-learnbar-{00,04,12}.png`):
  empty → ~45% green → full gold + reaction. Keyed per trick (Sitt only today). Erosion *feel* +
  confused-beat live visibility ride the deployed-PO Visual Review (no local MISS/DEAD seam).

- **046 — FEATURE — Anti-mash BRA freeze (P2-7). DONE 2026-06-30.** Pure `TapGate` (TDD,
  RefCounted): a fixed `LOCK_S = 0.35` re-arm window; only an accepted tap calls `lock()`, so
  swallowed taps can neither reset nor extend it (masher-proof by construction). Wired into
  `main.gd`: `_on_bra_pressed` returns early when not armed (not scored, learned bar untouched)
  and `lock()`s on the accepted tap; `_process` ticks the gate and dims+disables the BRA button
  while locked (`BRA_LOCKED_ALPHA = 0.4`, restored at full when armed) — a STATIC dim, so it
  reads under reduced motion (X-5). 13 new tests (7 unit + 6 wiring); **155 tests green**; verify
  green. Visual-proven on the real licensed build via `?bra_force_lock=1` seam +
  `tools/web_capture_lock.mjs`: near-white "BRA" glyphs 1327→0 when locked, identical in
  normal/reduced motion (`.screenshots/046-lock-*`). Delivers the secondary **P2-6** for free
  (spam taps simply never register — input hygiene, not penalty).

- **047 — FEATURE — The functional garden (P2-10). DONE 2026-06-30.** Render / Visual Review
  (no TDD; the `DogFraming`/`DogBounds` framing tests stay green). Replaced the flat sky-blue void
  with a look-down garden: `ProceduralSkyMaterial` sky gradient + a visible sun (an explicit
  emissive `SphereMesh` in the sky band — the procedural sun-disc *shader* doesn't render in the
  local headless GL path, only on the deployed real-GPU site, so an honest 3D sun guarantees it
  reads everywhere) + a 40×40 m grass `PlaneMesh` at the foot plane + a downward-pitched camera
  (horizon in the top ~25-30%, grass below). BRA floats over the grass (`StyleBoxEmpty`, no opaque
  band); contact shadow reads on the grass (+1 mm anti-Z-fight). **Two visual-review passes:**
  pass 1 REJECTED (no visible sun; dog shrank to a tiny figure — a P1-1/P1-2 framing regression),
  pass 2 fixed it (camera lift/back 1.4/1.5 → 0.5/0.4, explicit sun) and PASSED on real
  licensed-dog pixels (`.screenshots/047-garden-{rest,tell}.png`). 155 tests green; verify green.
  Foundation for the wandering dog (P2-8).

**Phase-2 backlog (priority order — all buildable, none owner-gated):**

- **048 — FEATURE — Variable cadence + feints (P2-8 logic core).** The keystone of "read the dog,
  not a beat," now unblocked by 047's garden ground. Pure TDD extension of `SitLoop`: each idle gap
  drawn from `[MIN, MAX]` (injectable seeded RNG → deterministic tests) instead of the fixed 1.2 s
  metronome, plus a **feint** intent — the dog dips toward a sit then aborts, opening **no** scoring
  window, so a tap during it is DEAD → the gentle erosion 045 already wired ("a feint/ambient
  moment, P2-8"). `DogDirector.play_feint()` reuses the real `Sitting_start` clip (no stand-in pose);
  main keeps `_session`/`_window`/`_tell` closed through a feint (apex tell stays dark — the path
  P2-9 will fade). **Scope = the two logic bullets; the bounded-wander locomotion (3rd P2-8 bullet)
  is a deferred sibling render task.**
- **049 — FEATURE — Persist per-trick learned progress (P2-5 / X-7).** Completes the 045 story: a
  bar you fill toward mastery must survive a reload. New `TrickStore` (pure `encode`/`decode` split
  from `user://` disk I/O so the round-trip is unit-testable headless; corrupt/empty/missing/wrong-
  version → clean zero state, no crash) + `TrickProgress.to_dict()`/`restore()` (mastery's safe
  checkpoint re-latches on load) + main load-on-boot / save-on-change. Local only (`user://` /
  IndexedDB on web), no backend — satisfies X-7. Independent of 048.

**Deferred / gated this round (NOT emitted):**
- **P2-2 (distinct trick animations — Ligg, Legg deg, …) is ASSET-GATED.** The licensed Labrador
  pack ships only `Sitting_*` — no lie-down clip (see the `tests/test_dog_clips.gd` clip list).
  Entry point when wanted: a `SPIKE-` to inventory the real pack's clips, then likely an
  owner/asset flag for the missing trick animations. Not a build task today.
- **P2-8 wander locomotion** (the bounded-patch roam + turn-at-edges, 3rd P2-8 bullet) is 3D render
  glue on the 047 ground — deferred to its own Visual-Review sibling task so 048 stays a clean
  headless-testable logic slice (and the **visual domain is saturated** this window). Next round.
- **P2-9 (fading trainer)** rides 045 + `SitWindow` **and** 048's feints ("dark during feints") — so
  it follows 048. It is render-heavy (the approach ring) → defer past the saturation window too.
- **P2-1 (selector)** waits for a 2nd real trick (i.e. P2-2 ungated) — a one-option selector is
  premature.

**Open owner gate (unchanged, non-blocking):** the warm **human** Maren "Bra!" recording —
narrowed flag in `FLAGS.md`; the warm Piper neural stand-in ships under the cue id (044).

## Status — Phase 1 SIGNED OFF by the owner; Phase 2 is now current (2026-06-30)

**Phase 1 is complete as best as possible after human review.** The owner (larssski) played the
live deployed build at 390×844 and signed P1-10 off in `po-review.md` (Phase Sign-off list). All
P1-0…P1-9 stories pass, logic is test-first, verify is green. One owner gate remains, tracked as
an open flag:

- the warm **human** Maren "Bra!" recording. The stand-in shipping under the cue id is now the
  **warm Piper local-neural voice** (`no_NO-talesyntese-medium`) — **task 044 LANDED 2026-06-30**,
  replacing the robotic espeak clip, no code change. Only the literal human Maren recording stays
  owner-gated (narrowed flag in `FLAGS.md`); it drops in at the same path with no code change.

The coat **UV/tangent seam** flag is **CLOSED** — the PO reviewed the live build and accepted the
coat as-is at native phone size (WONTFIX-cosmetic, 2026-06-30); no re-export needed (root cause
kept on record in `FLAGS.md` for any future re-export). Task 040 archived as moot.

Neither remaining item blocks the mark. **Phase 2 (`phase2.md`) is now the current phase** — the loop may begin
planning/building it under the same Phase-1 quality bar.

**Process change — "flag bust" (so the loop de-gates its own flags instead of spinning).** A flag
is a *hypothesis* that something needs the owner, not a verdict. New rule in `mother_prompt.md`:
when the board is otherwise idle, the loop **busts** the oldest un-busted open flag (a `BUST-`
task — adversarial, refute-not-confirm: "does any slice build *without* the owner?"), routes the
buildable slice to a build task, and **narrows** the flag to the true residual. This replaces the
idle re-verification spinning seen in commits 043–055. First application: **BUST-043** busted the
voice flag (which had been raised *whole, with no spike* — the named anti-pattern) → selected
**Piper** local-neural TTS → build task **044** (warm `nb_NO` "Bra!", no code change, owner-free);
flag narrowed to only the literal human Maren recording.

**Process change — "work-ahead" (so a blocked phase never idle-spins again).** The idle ladder is
now: current-phase buildable work → flag-bust → **work-ahead**. When the current phase is
*exhausted* (built + green + construction-audit clean **and** every flag busted-or-owner-gated →
blocked purely on owner/human), the loop builds the **next** phase's stories **provisionally**
(`work-ahead`-labelled) instead of re-verifying. Guardrails: never counts as sign-off (PO-only),
ships **dormant** so it can't disturb the current-phase play-test, **preempted** by any
current-phase work, and never built on top of the blocked item. Wired through `index.md` (spec
carve-out), `mother_prompt.md`, `scan-project`, and `father_prompt.md`. The father still runs on
its `FATHER_EVERY` cadence, so sign-off is never starved.

## Status — Phase-1 PO re-play REOPENED work; loop building the remaining improvements (2026-06-30)

The 2026-06-29 "buildable work COMPLETE / construction clearance" framing was **premature**:
the PO's live re-play (`po-review.md`) reopened **P1-4** (the apex tell rendered only under
the `?bra_force_tell=1` seam, invisible in real play) and surfaced **three buildable
improvements**. P1-4 is now **re-fixed and landed (036)** — the live path was blanked by a
null-Variant web-marshal collapsing `motion_scale` to 0; fixed + a headless live-path
regression test. Its **pixel sign-off remains a PO action** on the deployed build.

**Current top 3 (backlog → in-progress) — the PO's remaining Phase-1 improvements:**

- **037 — DONE (2026-06-30).** Apex ring now frames the "BRA" word (marker 200→320 px,
  ring 62–74→~99 px); forced-tell capture 3290 gold px, word legible inside the ring
  (`.screenshots/037-ring-frames-bra.png`). Verify green.
- **038 — DONE (2026-06-30).** Tier readout band lifted ~40 px (TOP 96→56, BOTTOM 220→180);
  forced-tier capture shows PERFECT/OK/MISS in clear sky above the dog's crown, not clipped
  (`.screenshots/038-readout-clear-sky.png`). Verify green.
- **039 — DONE (2026-06-30, SPIKE).** Root cause found: a **licensed-asset UV/tangent seam** at
  the body centreline (mirrored UV, gap 0.90 → MikkTSpace tangents diverge → normal map bends
  shading opposite ways; the "sliver" is this seam from below). Not stray geometry, not
  transparency, `CoatOpaque` can't hide it. Routed → **informed flag raised** (owner re-export of
  `dog_licensed.glb` with baked tangents) + **040 drafted** (cheap in-engine partial mitigation).
  Evidence: `.screenshots/039-spike-*`.

**Next up:**

- **040 — BUG — albedo mipmap + normal import fix** (backlog). `mipmaps/generate=false` (albedo)
  + `compress/normal_map=1` (normal) — import-file-only; *reduces* the hairline seam, does not
  fix the owner-gated tangent band (see FLAGS). Magnified before/after Visual Review vs the 039
  baseline.

**Already landed this round:**

- **Bugfixes:** 030 apex tell renders · 031 contact shadow · 032 opaque coat · **036 apex
  tell live-path fix** (null-Variant web-marshal guard + live regression test).
- **Improvements:** 033 tier-readout contrast · 034 joyful hop reaction.
- **Voice:** 035 genuinely spoken `bra_tts_placeholder.wav` (espeak-ng), gate intact.

**Owner/PO-gated, still open (see `FLAGS.md`):** the **P1-10 visual sign-off** on the live
licensed deploy (including the live pixel proof of the 036 apex tell — a no-seam burst with
gold > 0, or a `?bra_autotap=1` apex frame); confirming the **ADR-0006 encrypted licensed
deploy** is live (task 025; `deploy-licensed.yml` no-ops without the key secret + encrypted
glb); an **on-device audio listen**; and the warm **human Maren "Bra!"** recording. Nothing
past Phase 1 starts until P1-10 is signed off in `po-review.md`.

## Status — trust-nothing reconcile (2026-06-28)

`main` was reset to a clean single Godot root commit (Babylon gone). A source-level,
trust-nothing audit of the committed Phase-1 tree then found the board was over-claiming.
Reconciled below. Two findings dominate:

### 🟡 Blocker 1 — core loop now LIVE IN DEV; deployed site still CC0 (025-wire done 2026-06-28)
**Update:** the licensed Labrador is now wired in. With it present locally, `main` loads it,
the dog **sits** (boot: `dog can Sitt — apex at 1.250s, markable 0.000..2.917s`), and the
whole loop (sit → apex → tap → score → payoff) is live in dev; verify green at 74 tests.
What remains is the **deployed** half: the public Pages build still ships the CC0 dog (the
licensed asset is gitignored / absent in CI), so the *live site the father reviews* can't
sit until the **ADR-0006 encrypted pack** ships — one **owner-gated** CI secret (025). The
original dormancy analysis below stands for the deployed build only.


The shipped CC0 dog (`assets/models/dog.glb`) has **no Sitt clip** (and no reaction clip).
So at runtime: the sit never opens → every BRA tap scores **DEAD** → no score, no apex
tell, no payoff (silent), no dog reaction. **A player cannot experience Phase 1 on the
deployed site today** — they see a centered, idling dog and a BRA button that does nothing
audible/visible. The sit/tell/tap/payoff code is real and unit-correct but **dormant**.

**The fix is small — the sit asset already exists and the code already supports it.** The
bought licensed Labrador (`models-build/out_anim.glb`, 113 clips incl.
`Arm_Labrador|Sitting_start / loop / end`) is on disk; `DogClips.resolve()` already matches
those names, so `has_sit()` would be true and the loop would light up the moment the loader
points at it. **025 = wire + ship the Labrador**, not acquire one. The only owner-gated
piece is shipping it to the **public** Pages site without leaking the license (ADR-0006
encrypted pack → one CI secret/key, set once). Local review needs no secret.

### ✅ Blocker 2 — RESOLVED: the verify gate is now honest (026, done 2026-06-28)
The runner used to read `all green / exit 0` even when a test aborted on a runtime SCRIPT
ERROR (zero recorded failures). Fixed: `test_case.gd` counts assertions and `test_runner.gd`
fails any `test_*` that ends with 0 assertions (silent abort or empty test); the
`main.gd:123` null-viewport crash is guarded; the boot leg now greps `is_inside_tree`. The
honest gate immediately caught a hollow camera test, which exposed and got us a **real
production bugfix** (the dog camera was never aimed — `look_at` before `add_child`). Full
gate green for real at 73 tests.

### Per-system audit result
| System (card) | Code | Tests | Live on CC0 dog? | Board |
|---|---|---|---|---|
| scoring math `SitWindow`/`SitSession` (024a) | real | real, pure | n/a (logic) | **done** |
| idle loop (024c) | real | ok | **LIVE** | in-progress (needs visual review) |
| camera framing `DogFraming` | real | real, pure | **LIVE** | (part of 021/024) |
| sit (024b) | real | — | dormant | **on-hold → 025** |
| apex tell (024d) | real | real, pure | dormant | **on-hold → 025** |
| BRA tap (024e) | real | **hollow** (026) | tap always DEAD | **on-hold → 025** |
| payoff (024f) | real, synth WAV (not Maren voice) | real | silent | **on-hold → 025** |
| readout P1-7 (024g) | **MISSING** (only `print()`) | — | none | backlog |
| reduced-motion P1-8 (024g) | **MISSING** (dead seam, no caller) | — | none | backlog |

> Note: `scripts/main.gd` comments claiming "the readout (024g) consumes `marked`" are
> **false/aspirational** — no UI consumer exists. Clean up with 024g.

## Current phase

**Phase 1 — the perfect single mark** (`.docs/specs/phase1.md`). The logic is largely built and
correct; the phase is gated on a sit-capable dog (025) and an honest gate (026).

## Before restarting the autonomous loop — DO THESE FIRST
1. ✅ **026** — DONE. The test gate is honest (runtime aborts fail; `main.gd` viewport
   guarded; boot leg hardened). Bonus: fixed the un-aimed dog camera.
2. ✅ **025-wire** — DONE. Licensed Labrador wired; dog sits in dev; gate green (74).
   **Remaining (025 proper):** ship it to public Pages via the ADR-0006 encrypted pack —
   one **owner-gated** CI secret. Until then the deployed site the father reviews is still
   CC0 (idle only), so Phase-1 live visual review (024b/d/e/f → P1-10) stays blocked on that.

## In progress
- **024** — Phase 1 epic. The loop runs end-to-end in dev, but the PO review (2026-06-28)
  **reopened it**: the apex tell doesn't render, the dog floats, and the coat has
  translucent shell panels (**030–032**), plus two improvements. **030 + 031 + 032 are now
  fixed** (apex tell renders; the dog has a contact shadow; the coat is opaque — all
  pixel-verified on the licensed export). Remaining buildable visual work: two improvements
  (P1-7 readout contrast, P1-6 reaction-not-a-bark). Stays open until those land and the
  **P1-10** done-gate passes (P1-10 live-deploy review still waits on the owner-gated 025).
- **025** — ADR-0006 encrypted licensed pack. Export-side built (025a); the remainder
  (secret AES key + secret glb + from-source web template + Pages flip) is **owner-gated**
  and cannot be validated here. Until it ships, the deployed dog stays CC0 (idle only).

> **Loop status (2026-06-28, after PO review):** the PO/father drove the **real licensed
> Labrador web build** at 390×844 and **REOPENED Phase 1** — it is NOT done. Five concrete
> visual defects were found, **none owner-gated** (they're render/material/import bugs,
> reproducible on the local licensed export). scan-project turned the three bugfixes into
> **030–032** (below); the two improvements (readout contrast P1-7, reaction-not-a-bark
> P1-6) are logged for the next scan round. So the loop again has buildable Phase-1 work
> that does **not** wait on the owner-gated 025 deploy.

## On-hold (code written + committed, blocked on 025 — do NOT rebuild, do NOT mark done)
- **024b** — the sit (P1-3) — dormant on CC0.
- **024d** — the apex tell (P1-4) — dormant (sit never opens).
- **024e** — BRA tap + scoring (P1-5) — every tap DEAD live; button tests hollow (026).
- **024f** — payoff voice/SFX/reaction (P1-6) — silent live; audio is synth placeholder,
  not the Maren voice.

## Backlog (in priority order — generated by scan-project 2026-06-29, all Phase-1, non-gated)
The PO review's three reopened **bugfixes** (030–032) are now all done + pixel-verified
(see Done). This round's scan adversarially re-audited those three on the committed tree —
**all REAL** (wired, called, real nodes in the tree, tests assert observable behaviour; no
dead seams). 033 (readout contrast) is now **done + pixel-verified** too (see Done), leaving
**034** the only open Phase-1 directive blocking the P1-10 sign-off. It is reproducible on
the local licensed export (not gated on the deploy). Build per `start-working` (TDD logic
seam + the binding pixel-verify on a 390×844 Web export).
- **034** — IMPROVEMENT: the positive reaction is a lone Bark (P1-6). Rank a joyful bounce
  (`Jump_Place`/`JumpAir_low`) ahead of `bark` in `REACTION_VOCAB`, specific enough not to
  match the CC0 `Jump`; blend cleanly from the seat. TDD the resolver; Visual Review the joy.

> **Deploy note (2026-06-29):** the owner resolved the 025 deploy gate — `deploy-licensed.yml`
> is now the **sole, automatic** (push-to-`main`) deploy of the encrypted licensed Labrador,
> and `deploy.yml` (CC0) was removed. So the deployed site is no longer pinned to CC0; the
> remaining Phase-1 work (033/034 + the P1-10 review) is all locally verifiable.

## Done (verified)
- **044** — FEATURE (from BUST-043, P1-6): warm **Piper local-neural** "Bra!" replaces the
  robotic espeak clip at `assets/audio/bra_tts_placeholder.wav` (voice `no_NO-talesyntese-medium`,
  rhasspy/piper-voices). Same path → **zero GDScript change**; peak-matched to the espeak headroom
  (−5 dBFS) so only timbre changes, not loudness. 123/123 tests green incl.
  `test_voice_is_the_real_spoken_asset_when_present`; verify gate green. Provenance pinned in the
  task file. Only the literal human Maren recording stays owner-gated (narrowed flag).
- **033** — IMPROVEMENT (PO directive P1-7): tier readout too low-contrast. Added a dark
  outline (`font_outline_color` near-black + `outline_size` 12 px) to `TierReadout._init` so
  PERFECT/OK/**MISS** pop against the bright sky; tier fills unchanged so PERFECT stays
  brightest. 3 TDD tests (outline-color override, `outline_size >= 8`, emphasis-value
  invariant). **Pixel-verified:** web-only capture seam `?bra_force_tier=miss|ok|perfect` +
  `tools/web_capture_readout.mjs` boots the real Web bundle in SwiftShader Chromium at
  390×844, pins each tier, fails closed if the stroke is missing/thin — ran PASS (~33k
  outline px/tier, floor 200); all three frames eyeballed legible
  (`.screenshots/033-readout-*.png`). Gate green.
- **032** — BUG (PO-reopened): the **coat is opaque** — the translucent fur-mask "shell"
  panels are gone. Root cause (A/B-probe-confirmed): the licensed Labrador's body albedo
  atlas carries a baked fur/hair-strand alpha mask that the GL Compatibility renderer
  samples as see-through panels. New pure `CoatOpaque.flatten` (called from `main._load_dog`)
  walks every `MeshInstance3D`, forces alpha-textured surfaces `transparency=DISABLED` +
  `cull=BACK`, and **strips the texture's stray alpha to RGB** (keeps the real coat texture
  + normal map) — model-agnostic, ships in the pck, clean no-op on the CC0 dog. 3 TDD tests
  (synthetic meshes → public-CI safe). Gate green (109 tests). **Verified on the real asset:**
  `tools/verify_coat_fix.gd` → 1 stray-alpha surface before, 1 fixed, 0 after; **pixel-
  verified** `.screenshots/032-opaque-coat.png` (solid opaque Labrador, no blue through the
  body) + `032-ab-{nofix,fix}-chest3x.png` before/after. ⚠ Caught + fixed the on-disk code
  left mid-A/B-probe (flat-tan-colour fake + a dead-code early `return` that skipped the real
  assignment). Faint UV/normal shading seams remain at 3× — geometry, not transparency.
- **031** — BUG (PO-reopened): the **dog no longer floats** — a cheap blob contact shadow
  now grounds it. New pure `ContactShadow` (foot-plane placement + footprint radius off the
  same `DogBounds` the camera frames from → model-agnostic); `main._setup_contact_shadow`
  mounts a flat unshaded `PlaneMesh` blob with a radial `GradientTexture2D` alpha (no shader
  → headless-safe). 4 TDD tests (3 pure + 1 scene-mount wiring). Gate green (106 tests).
  **Pixel-verified** on the real 390×844 web build (licensed Labrador) →
  `.screenshots/031-contact-shadow.png` (soft dark oval under the dog) via
  `tools/web_capture_shadow.mjs` (headless Chromium / SwiftShader).
- **030** — BUG (P0, PO-reopened #1): the **apex tell now renders**. Root cause was *not*
  structural (rect/z-order/self_modulate all fine — a forced-intensity Web capture proved
  the ring composites over the BRA button): the cue was a thin, ~half-alpha, pale-cream
  ring that desaturated over the dark button and was halved again under reduced motion, so
  it read as "never renders." Fix: saturated bold gold (`GLOW` s=0.80, `RING_ALPHA` 1.0,
  `RING_WIDTH` 10, `HALO_ALPHA` 0.40) + a web-only `?bra_force_tell=1` deterministic-capture
  seam. **Pixel-verified on a 390×844 Web export:** `.screenshots/030-apex-tell-visible.png`
  (gold ring) + `030-apex-tell-live.png` (dark in idle). 5-test regression fence in
  `test_tell_wiring.gd` guards all three suspects + boldness + the seam. Gate green.
  (The earlier "0 gold pixels" web finding was a broken capture harness, since fixed.)
- **029** — QUALITY: scoring-band constants (`PERFECT_RADIUS`/`OK_RADIUS`) homed in
  `SitWindow`; magic viewport/layout literals in `main.gd` named. 98 tests green.
- **028** — QUALITY: consolidated the duplicated test scene-mount helper + the recursive
  `AnimationPlayer` finder into one shared place (single source of truth).
- **027** — FEATURE: the loop now **repeats** (P1-9). `main.gd` used to play the sit once
  and stall; new pure `SitLoop` state machine + `_advance_loop/_begin_sit/_end_sit` drive
  idle → sit → idle indefinitely. 96 tests; runtime-probed on the real licensed dog (5
  cycles / 22s, apex 1.250s). **Last non-owner-gated Phase-1 functional gap — closed.**
- **025a** — FEATURE: encrypted `Web Licensed` export preset + ADR-0006 gate-sizing spike;
  proved official templates encrypt-but-can't-decrypt a custom-key PCK → from-source
  template build is genuinely required (the owner-gated remainder of 025).
- **024g** — FEATURE: honest on-screen timing readout (`TierReadout`, P1-7) + reduced-motion
  (`ReducedMotion`, P1-8), both wired & tested (previously MISSING).
- **024c** — FEATURE: ambient idle loop (P1-2) + model-agnostic camera framing
  (`DogFraming`/`DogBounds`, bone-span measure — fixed the licensed-Labrador mis-frame).
- **026** — BUG: verify gate made honest (assertion-count guard + null-viewport fix + boot
  grep). Surfaced & fixed a real camera-framing bug (look_at before add_child).
- **024a** — apex-band / scoring-window math (`SitWindow`/`SitSession`), test-first,
  source-audit confirmed real (mutation-tested).
- **023** — bun/Babylon toolchain removed; verify gate is Godot headless
  (`nix develop -c bash verify.sh`: import · boot · test · export).
- **022** — CI exports Godot Web/PWA to Pages (export-gated, nix-pinned).
- **021** — Godot 4 scaffold; boots headless with the dog loaded + centered (real framing).
