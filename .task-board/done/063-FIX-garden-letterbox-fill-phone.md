# 063 — FIX: garden letterboxed by black bars on phone (P2-10 / X-1)

**Phase:** 2 (current) · **Type:** Bugfix (correctness) · **Preempts work-ahead.**

## Source
PO Review 2026-07-01 (`.docs/specs/po-review.md`, Bugfixes). On the mandated **390×844**
phone-portrait viewport the whole look-down garden renders inside a fixed **9:16 box** with a
pure-black band top (~75 px) and bottom (~64 px) — ~16 % of the screen. Reproduced on **both**
the local bundle and the **live** Pages site (`tools/po_letterbox_check.mjs`,
`.screenshots/po-p2/zoom-letterbox.png`).

## Root cause
`project.godot` sets `window/stretch/aspect="keep"` against a **720×1280 (9:16, 0.5625)** design.
Every modern phone is taller than 9:16 (iPhone X+ ≈ 0.462, most Android ≈ 0.46), so `keep`
letterboxes them. The stylization content (062) is fine — the *frame* is wrong.

## Fix
Change `window/stretch/aspect` from `"keep"` → `"expand"` (mode stays `canvas_items`). The
garden fills the whole screen across the portrait aspect range (~0.46–0.56):
- **3D fills for free:** the sky is an infinite `ProceduralSkyMaterial` (`BG_SKY`) and the
  grass plane is backed by the procedural sky's ground-half colors, so a taller view exposes
  no void. The camera already reads the **real** viewport aspect via `_viewport_aspect()`
  (`vp.get_visible_rect().size`), and `DogFraming` fits the dog to that aspect — so the dog
  stays centred + framed as the frame gets taller.
- **UI re-anchors for free:** BRA button anchors to the real bottom (anchor 1.0), readout /
  learned bar / tell marker anchor to the real top/centre — all offsets are base-unit insets
  from the real edges, so they stay put on a taller frame.

## Why not TDD-first product code
The fix is a **display/stretch config** change (pure render glue → Visual Review, per the
mother prompt). Guarded anyway by a cheap **regression test** (`tests/test_stretch_aspect.gd`)
that pins the aspect to a non-letterboxing mode, encoding *why* (portrait phones are taller
than 9:16). Real proof is a live-pixel capture at 390×844 (`po_letterbox_check.mjs`): rows 0
and 843 must be garden, not black.

## Done when
- [ ] `tests/test_stretch_aspect.gd` red → green.
- [ ] `project.godot` aspect = `expand`; stale `stretch=keep` comments in `main.gd` +
      `test_dog_framing.gd` corrected.
- [ ] `verify.sh` green (import·boot·test·export).
- [ ] Live-pixel proof at 390×844: no black top/bottom band (rows 0 & 843 are garden).
- [ ] Placeholder check on diff clean. Commit + push.
