# 141 — FIX: Bella (owned/active) modal opens on the same shared hero bust (PO father-pass-6)

**Source:** `.docs/specs/po-review.md` — PO Review 2026-07-06 (father pass 6). Directive:
Bella (cell 0, owned/active) reportedly still opens on her grid-cell full-body side profile
while the other 7 dogs open on the dedicated front-¾ modal hero bust (task 140). "Route
Bella's modal header through the same dedicated fixed front-¾ modal portrait as the other
seven."

## Investigation (this iteration)

Reproduced against the on-disk `build/web` first — Bella DID show a full-body side profile,
7 others a bust. But that bundle was **stale (pre-140)**: the pre-140 modal reused each dog's
per-cell variety-yaw grid texture, which is exactly the pass-5 symptom. Consistent with the
open disk-full flag (0 bytes free) having left a partial/stale export.

On a **clean, freshly-exported build of HEAD 519f618** the bug does NOT reproduce:

- All 8 modals (incl. Bella) render a consistent front-¾ hero bust — deterministic across
  many runs and at every settle time tried (60 / 100 / 150 / 900 ms).
- Instrumented the render path: `_build_modal_band` calls `_get_modal_portrait_texture()`
  **unconditionally** (no owned/active branch). Printed the texture for Bella / Trulte / Nova
  modals — all three are the **identical shared `ViewportTexture`** (same RID); only the
  `modulate` coat tint + band bg differ. A modulate cannot change geometry.
- The measured rects are byte-identical (card 362×?, band 362×200, mdog 346×154) for Bella
  and the others.
- `DogBounds.measure` frames off the **rest-pose bone span** (`get_bone_global_rest`), which
  is available synchronously on frame 0 — so there is no cold-AABB race in the lazy modal
  build either.

Conclusion: 140 already routes every dog — including the owned/active Bella — through the one
dedicated `MODAL_PORTRAIT_YAW` front-¾ portrait. The PO's finding is a stale/partial build
artifact, not a live code bug.

## Definition of done

- A **regression test** locking the specific pass-6 concern: the owned+active dog's modal
  portrait references the SAME shared dedicated modal texture as an unowned dog (guards against
  anyone re-coupling the owned dog to a per-cell path). Complements the existing task-140
  yaw-decoupling test.
- `build/web` rebuilt **fresh** (the actionable root cause) and a fresh 8-dog modal montage
  captured proving Bella is a consistent bust.
- verify gate green (import·boot·test·export). Commit + push.

## Notes

- Do NOT redesign the working 139/140 framing — fresh builds render all 8 correctly; changing
  the tuned COVERED bust framing would risk regressing the 7 good dogs with no reproducible bug
  to fix.
- The disk-full flag (`FLAGS.md`, 2026-07-05) is the likely cause of the stale export the PO
  reviewed; noted there.
