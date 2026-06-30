# Planning Board — Bra! v2

Source of truth: [`.docs/specs/`](../.docs/specs/) (phased user stories — one file per
phase + `index.md`; PO log in `po-review.md`) and the ADRs in [`adr/`](../adr/).

> **Phasing rule (from the spec):** Phase 1 is the whole bet. Nothing past Phase 1
> starts until Phase 1 passes its Visual Review and is bug-free.

## Status — Phase 2 OPEN; backlog replenished (2026-06-30, iteration 056)

Phase 1 is **signed off** (section below); **Phase 2 (`phase2.md`) is the current phase** per
`po-review.md`'s Phase Sign-off gate. This iteration (1) archived the six signed-off Phase-1
tasks (024, 025 from `in-progress/`; 024b/d/e/f from `on-hold/`) to `done/`, then (2) ran
`scan-project` against `phase2.md` + the Phase-2 Forward PO Directives to replenish the empty
backlog. **Everything below the Phase-1 sign-off section is historical Phase-1 working notes —
superseded by this section and the live `.task-board/` dirs (in-progress + on-hold are now
empty).**

**Phase-2 backlog (priority order — all buildable, none owner-gated):**

- **045 — FEATURE — Learned bar + mastery (P2-4).** *P0 for the phase — the spine.* Pure
  `TrickProgress` model (TDD) + on-screen learned bar + erosion on bad taps + mastery safe
  checkpoint + procedural confused/mastery beats. PERFECT fills > OK; MISS/DEAD erode; good play
  always nets forward; floors at 0; 100% latches mastery. Keyed per trick (one trick — Sitt — for
  now). The trick selector (P2-1), persistence (P2-5), and fading trainer (P2-9) all hang off it.
- **046 — FEATURE — Anti-mash BRA freeze (P2-7).** Independent of 045. Pure `TapGate` (TDD): a
  fixed ~350 ms lock after every tap; swallowed taps don't reset/extend it; the button visibly
  locks then restores, legible under reduced motion. Also delivers the secondary P2-6.
- **047 — FEATURE — The functional garden (P2-10).** Render / Visual Review. Look-down
  Pokémon-GO view — sky + a visible sun, grass ground, horizon split; the dog stands on the
  grass; BRA floats over the grass (no opaque band). Foundation for the wandering dog (P2-8). GL
  Compatibility-only; no Phase-7 art polish smuggled in.

**Deferred / gated this round (NOT emitted):**
- **P2-2 (distinct trick animations — Ligg, Legg deg, …) is ASSET-GATED.** The licensed Labrador
  pack ships only `Sitting_*` — no lie-down clip (see the `tests/test_dog_clips.gd` clip list).
  Entry point when wanted: a `SPIKE-` to inventory the real pack's clips, then likely an
  owner/asset flag for the missing trick animations. Not a build task today.
- **P2-5 (IndexedDB persistence)** follows 045 (needs a learned value to persist). **P2-8
  (wander + feints)** rides 047 (ground) + 045 (feint taps erode). **P2-9 (fading trainer)** rides
  045 + `SitWindow`. **P2-1 (selector)** waits for a 2nd real trick (i.e. P2-2 ungated).

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
