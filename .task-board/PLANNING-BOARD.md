# Planning Board — Bra! v2

Source of truth: [`.docs/specs/`](../.docs/specs/) (phased user stories — one file per
phase + `index.md`; PO log in `po-review.md`) and the ADRs in [`adr/`](../adr/).

> **Phasing rule (from the spec):** Phase 1 is the whole bet. Nothing past Phase 1
> starts until Phase 1 passes its Visual Review and is bug-free.

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
- **039 — SPIKE — coat seams + stray sliver root-cause** (P1-1/P1-9). Symmetric chest seams +
  flank arcs + a hard-edged sliver between the front legs on the licensed Labrador; cause
  unknown (texture/UV vs normal-map vs `CoatOpaque` vs stray geometry) → research, then route
  to a `040` build task or an informed flag.

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
