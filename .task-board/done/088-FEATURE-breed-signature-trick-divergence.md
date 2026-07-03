# 088 — FEATURE: breeds train different tricks — flag-bust a real signature clip, wire it so the trick lists diverge (P3-2)

**Type:** FEATURE (flag-bust research → game-logic TDD + Visual Review) · **Phase:** 3 (current) ·
**Source:** PO Review 2026-07-03 `po-review.md` **Change 2** ("The two breeds train an identical trick
list … P3-2 requires each breed exposes a trick list that is **not identical** to every other
breed's … flag-bust `assets/models/dog_licensed.clips.txt` for a **real, Phase-1-quality** clip that
can serve as a per-breed **signature** trick … a real clip only — no faked/stub trick. If the manifest
has nothing usable at quality, P3-2 is genuinely **owner-gated** … record that as the flag verdict")
· **Priority:** P1 for this phase — the second of the two buildable shortfalls blocking P3 sign-off.

## What it addresses

**Spec gap — P3-2 acceptance "Each breed exposes a trick list that is not identical to every other
breed's."** Today the yellow Lab and the adopted chocolate Lab both expose exactly Sitt / Ligg /
Legg deg — the trick list above the Breeds section is *shared* (`main._current_trick` + `TrickMenu`
rows are breed-agnostic). Collecting breeds is meant to be collecting *moves*; a recolor with the
identical trick list isn't that.

This task has a **flag-bust gate first, then a build** (per the PO's explicit instruction):

1. **Flag-bust the manifest** (research, adversarial — refute "P3-2 is owner-gated"): does
   `assets/models/dog_licensed.clips.txt` hold a **real, Phase-1-quality** clip — a clean,
   recognisable, markable trick with a hold-able apex — usable as a **signature** trick distinct from
   the three "settle" tricks (Sitt/Ligg/Legg deg)? The rig has 113 clips; candidates already on disk:
   - **`Digging_start / Digging_loop / Digging_end`** ("Grav" / dig) — start/loop/end structure exactly
     like the wired tricks; a distinct, recognisable action. **Strongest candidate.**
   - **`Crouch_Idle_start / _loop_1|2 / _end`** ("Krype" / crouch-low) — settle-class, may read too
     close to Ligg.
   - **`Bark`** ("Snakk" / speak) — distinct but a single clip (no start/loop/end), check it has a
     clean, mark-able beat and isn't a one-frame snap.
   - **`Scratching`** — already used as a *feint* (071), so poor as a headline trick (would collide).
   Judge each by actually driving it on the rig at a PERFECT apex (the `?bra_trick=` harness pattern
   + a `tools/web_capture_*.mjs` frame grab), not by name. The bar is Phase-1 quality: it reads as
   that trick, holds an apex the SitWindow can score, and blends cleanly in/out of idle.

2a. **If a usable clip is found → BUILD it (TDD):** wire it as a **signature** trick and make it
   **breed-specific** so the two breeds' lists diverge. The clip layer is already generalised
   (`DogClips` bundles, `DogDirector.play_trick*`, per-trick `TrickProgress`) — 065/067 added Ligg /
   Legg deg the same way, so a fourth trick is a bundle add + a label, NOT new architecture. Then gate
   the trick list by breed: `BreedPersonality` (or `BreedRoster`) exposes a per-breed **trick list**,
   and `main` / `TrickMenu` filter the offered/available tricks to the active breed's list. Assign the
   new signature to ONE breed (e.g. Grav → the chocolate Lab) and keep it OFF the other, so the two
   lists are provably non-identical. Shared core (Sitt/Ligg/Legg deg) stays on both per P3-D2's
   proposed default ("shared core + 1–2 signature tricks per breed").

2b. **If nothing is usable at quality → do NOT fake it.** Record the verdict: raise/append a
   `FLAGS.md` flag (orchestrator-only) that P3-2's signature trick is **owner-gated on a second real
   breed model + its signature clips (P3-D1/D2/D4)**, narrowing rather than leaving P3-2 silently
   unmet. Ship no stub trick. (The orchestrator writes the flag; the research subagent only reports
   findings + the recommended route.)

## Technical approach

### Flag-bust (research only — no product code, no TDD; deliverable = findings + route)

- Grep + dump the manifest; shortlist non-settle clips with a start/loop/end shape or a clean single-beat.
- For each shortlisted clip, drive it live via the capture harness at a forced PERFECT apex and grab
  frames; judge readability + apex hold + blend quality by eye (Phase-1 bar).
- Output: the single best clip (or "none usable"), with frame evidence, and the route (build vs flag).

### Build (only if a clip passes — TDD, mirrors 065/067)

**Before** — one shared trick list; every breed offers the same three:
```gdscript
# main.gd — _current_trick cycles Sitt/Ligg/Legg deg regardless of breed
const TRICKS := [TRICK_ID_SITT, TRICK_ID_LIGG, TRICK_ID_LEGG_DEG]
```
**After** — a new signature trick bundle + a per-breed trick list, so the offered set is breed-scoped:
```gdscript
# dog_clips.gd — add the signature bundle (e.g. Grav) exactly like Ligg/Legg deg (065/067)
const TRICK_GRAV := "grav"
# grav -> Digging_start / Digging_loop / Digging_end   (only if the bust proved it Phase-1-quality)

# breed_personality.gd (or breed_roster.gd) — each breed owns its trick list
func trick_list() -> Array[String]:
	return _trick_list   # labrador -> [Sitt,Ligg,Legg deg]; chocolate -> [Sitt,Ligg,Legg deg,Grav]

# main.gd / trick_menu.gd — offer/menu the ACTIVE breed's list, not a global constant
```
TDD (RED first, per `.claude/skills/tdd/SKILL.md`):
- `test_breeds_have_non_identical_trick_lists` — `labrador.trick_list() != chocolate.trick_list()`
  (the exact P3-2 acceptance, as a test).
- `test_signature_trick_only_offered_to_its_breed` — the signature id is in the active breed's offered
  set only when that breed is active; switching breeds changes the offered/menu list.
- `test_signature_trick_progress_is_per_trick` — the new trick masters through its own
  `TrickProgress` key (no cross-trick bleed), like Ligg/Legg deg.
- `test_menu_lists_the_active_breeds_tricks` — `TrickMenu` classify shows the active breed's tricks as
  Learned/Available and does not offer another breed's signature as trainable.

## Testing / verification

- **Flag-bust** produces frame evidence for the chosen clip (or a documented "none usable").
- **TDD** GREEN for the divergence + per-breed offering (if built).
- **Visual Review (blocking, if built):** capture the signature trick performed at a PERFECT apex on
  its breed (`?bra_trick=<sig>` + real-tap e2e), dog reads clearly doing that trick, clean apex + blend;
  switching to the other breed removes it from the offered list. Screenshots `.screenshots/088-*`.
- `nix develop -c bash verify.sh` green.
- **Placeholder check at done:** grep the diff for the placeholder/stub list — the signature trick is a
  **real** clip driven on the rig, never a faked/renamed/stub trick. A hit = not done.

## Acceptance criteria

- [ ] Flag-bust done: the manifest was checked **against live-driven frames** (not names), and the best
      candidate is identified with frame evidence — or "none usable at Phase-1 quality" is documented.
- [ ] **If a clip passed:** it is wired as a **real** signature trick (bundle + label + per-trick
      progress, like 065/067), RED-first tests written before the code.
- [ ] `labrador.trick_list() != chocolate.trick_list()` — the two breeds' offered/menu trick lists are
      provably **non-identical** (P3-2 acceptance), and the signature is offered only for its breed.
- [ ] No faked/stub trick shipped; placeholder check clean; the signature reads as a real trick at a
      PERFECT apex in Visual Review (`.screenshots/088-*`), reviewed by eye.
- [ ] **If nothing was usable:** no stub shipped; the orchestrator has recorded a narrowed `FLAGS.md`
      verdict that P3-2's divergence is owner-gated on a second real breed model + signature clips
      (P3-D1/D2/D4), and this task is closed as the flag route (not a self-certified stub).
- [ ] `nix develop -c bash verify.sh` green.

## Resolution (2026-07-03) — closed as ROUTE 2b (flag verdict, no stub shipped)

**Outcome: the flag-bust drove the manifest's signature candidate live and REJECTED it on Phase-1
quality — so no signature trick / breed divergence ships this task, and the gate is recorded as a
narrowed owner-gate (`FLAGS.md`, 2026-07-03 "P3-2 per-breed trick DIVERGENCE" flag).**

- **Flag-bust (adversarial, live-driven — acceptance #1 met):** `Digging_*` ("Grav") is the rig's only
  clip with the (start, loop, end) shape a mark-timing trick needs *and* a distinct non-settle action.
  It resolved cleanly and its apex ring fired (2154 gold px). But driven at a PERFECT apex on the
  chocolate Lab (`?bra_trick=grav&bra_breed=chocolate`, `web_capture_apex.mjs` + `web_capture_frames.mjs`),
  the dog digs **rear-to-camera at the scored apex and through the hold** — `.screenshots/088-grav-choc-07/08/09`
  + `088-grav-apex-best` (reviewed by eye). That breaks the game's PO-enforced face-the-camera-at-apex
  contract (061 / 077 / PO note 3). `Bark` has no hold-able apex; `Crouch_Idle` reads as Ligg; `Scratching`
  is the 071 feint. **No on-rig clip clears the Phase-1 face-camera bar.**
- **Fix attempted before flagging (not a premature flag):** a per-trick base-yaw bias of π
  (`_trick_face_offset`) to let the clip's own rotation bring the apex back to camera. Re-exported +
  re-captured (`088-grav-apex-fixed`, `f001/f015/f035`): **no effect** — `_begin_sit` already engages the
  061 face-turn for every trick, so the base heading was right; the `Digging` clip drives the body's apex
  orientation itself (root/hips sweep). Correcting it needs per-frame root-motion compensation — animation
  surgery, disproportionate + high-risk, possibly non-convergent. Attempt reverted.
- **Route 2b executed:** the 088 Grav wiring + per-breed `trick_list` divergence + the yaw-offset attempt
  were **fully reverted** to the pre-088 tree — no rear-to-camera trick, no dead divergence seam. Both
  breeds keep the shared, PO-signed Sitt / Ligg / Legg deg core. The per-breed-trick-list infra is a
  bundle-add + label away (065/067 pattern) the moment the owner supplies a usable camera-facing signature.
- **Placeholder check:** N/A — no product code shipped (net diff = the flag verdict + this task note).
- **Gate:** `verify.sh` green on the reverted tree (455 tests, 0 failures).

**P3-2's "non-identical trick lists" is DEFERRED to the owner asset (camera-facing signature clip /
2nd breed model + P3-D1/D2/D4), NOT silently unmet — see the FLAGS.md verdict.**
