# 140 — VISUAL — kennel modal header: consistent front-facing hero bust for every dog

**Source:** PO Review 2026-07-06 (father pass 5), `.docs/specs/po-review.md` — the ONE
"Still falls short" directive after 139 landed.

## Directive (verbatim intent)

The modal "hero bust" is inconsistent dog-to-dog. The modal reuses each dog's **grid-cell**
portrait texture, whose yaw was deliberately varied per cell for grid variety (131,
`PORTRAIT_YAW_SPREAD`). So the `COVERED` crop lands very differently by cell yaw: front-facers
(Nova, Sol) become gorgeous face-on busts, but side-facers (Bella, Balder) get a zoomed **side
profile** — essentially the identical shot as the grid cell you just tapped, only cropped tighter.

**What good looks like:** give the modal header its **own** consistent front/¾-facing framing for
all 8 dogs, independent of the grid cell's variety yaw — so every inspect modal opens on a
Nova/Sol-quality hero bust, not a re-cropped side shot.

## Approach

The modal doesn't need a per-dog *model* (owner-gated, BUST-068) — the grid already shows per-dog
distinctness via yaw + coat tint. The modal's job is a *closer, better, consistent* look. So:

- Add a **dedicated modal portrait** live SubViewport at a **fixed front-¾ yaw** (`MODAL_PORTRAIT_YAW
  = 0.0`, i.e. pure `PORTRAIT_THREE_QUARTER` with no per-cell variety offset). Built once, shared by
  all 8 modals (coat differs by the existing per-dog `modulate` tint — same trick the grid uses).
- `_build_modal_band` uses this dedicated texture instead of `_get_portrait_texture(cell_index)`.
- Keep the grid cells exactly as-is (variety yaw stays — that's the grid's design).

## Definition of done

- Every inspect modal (all 8 dogs) opens on a consistent front-¾ face-on hero bust — no side profile.
- TDD: modal framing yaw is index-**independent** (contract that the fix decouples modal from the cell
  spread); grid cells still use the per-cell spread.
- `verify.sh` green (import·boot·test·export).
- Visual Review PASS: capture ≥4 dogs incl. the old side-facers (Bella, Balder) → all face-forward.

`work-ahead`: no. Current X-4 polish arc directive, preempts Phase-10 owner-gate.

## DONE

Added `MODAL_PORTRAIT_YAW = 0.0` + `modal_portrait_yaw_offset()` helper (index-independent),
a dedicated `_get_modal_portrait_texture()` (one live front-¾ SubViewport shared by all 8 modals,
coat via modulate), and repointed `_build_modal_band` off `_get_portrait_texture(cell_index)`.
Grid cells keep their per-cell variety spread. 3 TDD asserts green (682 total, 0 fail), verify green.
Visual Review PASS: `.screenshots/140-modal-{nova,bella,balder,sol}.png` — the old side-facers
Bella + Balder now render the SAME front-¾ face-forward hero bust as Nova/Sol (only coat tint
differs), each decoupled from its grid cell's side/front angle.
