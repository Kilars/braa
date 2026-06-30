# Planning Board — Bra! v2

Source of truth: [`.docs/specs/`](../.docs/specs/) (phased user stories — one file per
phase + `index.md`; PO log in `po-review.md`) and the ADRs in [`adr/`](../adr/).

> **Phasing rule (from the spec):** Phase 1 is the whole bet. Nothing past Phase 1
> starts until Phase 1 passes its Visual Review and is bug-free.

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
