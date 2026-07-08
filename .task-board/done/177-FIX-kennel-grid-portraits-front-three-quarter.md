# 177 — FIX: kennel grid portraits render front-¾ (not broadside) for every cell

**Source:** PO father-pass-44 directive (`.docs/specs/po-review.md`), Bugfix.
**Phase:** 8 (kennel browse surface, K-1/K-3 — 155 intent). Signed-off phase; regression fix.

## The bug (PO pass-44)
On the kennel grid, only Bella (cell 0) presented a flattering front-¾ with her face to the
viewer; Balder / Pontus / Sniff (and to a lesser degree others) rendered **broadside** — a full
side flank, face turned away. Reproduced in a fresh 390×844 web-export capture; stable across two
captures 4 s apart (a fixed per-cell pose, not an idle-sway frame). Contradicts task 155 / PO
pass-20's "every cell front-¾, face to viewer."

## Root cause (diagnosed, not assumed)
The PO's hypothesis was a relative-vs-absolute rotation bug in the heading math. **Disproven by
measurement**: instrumenting `_build_one_portrait` showed the per-cell dog root basis spans only
~18° (exactly the yaw spread), the skeleton/bones are identical across cells, and at **delta = 0**
every cell renders a clean front-¾ identical to the modal hero. Headless `get_image()` returns
blank, so the web-export renderer was used as the truthful oracle throughout.

The real cause is the **asymmetric sensitivity** of the fixed portrait viewing geometry. The
camera sits front-RIGHT of the dog (`PORTRAIT_VIEW_DIR ≈ +X,+Z`), so a **positive** per-cell
delta turns the nose *further from the camera* and the silhouette grazes to a full flank
astonishingly fast — a mere **+0.10** already reads broadside — while a **negative** delta turns
the face back toward the viewer and stays flattering out to ~-0.14. The 155 spread
(`[0.06,-0.14,0.14,-0.08,0.18,-0.05,0.10,-0.12]`) carried +0.10/+0.14/+0.18 positives → the
broadside cells. It passed the old test because that test validated only the *arithmetic* band
`[0.24,0.68]` (which happily admits +0.18) — never the rendered facing.

## The fix
- `PORTRAIT_YAW_SPREAD` re-biased to `[0.06,-0.14,0.04,-0.10,0.02,-0.12,0.05,-0.08]` — positives
  capped at the proven-good Bella value (+0.06), negatives allowed to the proven-good Nova value
  (-0.14). Deterministic, non-monotonic, both signs, no two adjacent equal → per-cell variety (131)
  survives; every value re-verified front-¾ face-to-viewer in a fresh capture (all 8 cells).
- No change to `PORTRAIT_THREE_QUARTER` base or the modal path (both signed-off good; delta=0
  proven correct).
- Comment above the constant rewritten to record the asymmetric-sensitivity finding.

## TDD
`tests/test_kennel_grid_portrait_yaw.gd`: tightened `BAND_MAX` 0.68 → 0.50 (past ~0.50 grazes to
broadside), and added `test_positive_deltas_are_capped_so_no_cell_grazes_to_broadside` enforcing
the asymmetric safe window `[-0.14, +0.06]` — the guard the old test lacked (it would have caught
the 155 +0.18). Red on the old spread, green on the new.

## Verify
`nix develop -c bash verify.sh` green (import · boot · test · export). Grid re-captured at 390×844:
all 8 cells front-¾, face to viewer; modal hero unchanged.
