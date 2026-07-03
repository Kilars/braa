# 090 — FIX: the training "BRA" button bleeds through the showcase's transparent centre

**Type:** FIX (visual + wiring) · **Phase:** 3 (current) · **Source:** PO Review 2026-07-03 (HEAD `455f554`), Bugfix 2.

## What the PO saw
On both showcase frames the underlying training HUD's big round **"BRA"** button is visible, ghosted,
floating over the spotlit dog (`087-01`, `087-02`, `po-crop-showcase-bottom.png`). The showcase
deliberately keeps its centre transparent so the dog shows through, but the live BRA button leaks
through that clear centre — a stray "BRA" hovering over the showcased dog breaks the "here is my dog,
shown off" read and looks like a layering bug.

## Root cause
`main._on_showcase_requested()` hides `_menu` (the opaque trick-menu panel covers the chrome) but
never hides the training-HUD chrome. The trick menu is opaque so nothing leaks behind it; the showcase
is transparent-centre by design, so the always-on BRA button (and its concentric ring markers, the
coin readout, learned bar, tier readout, Tricks reopen button) show through.

## Definition of done (PO "Good")
While the showcase is open, the training-HUD chrome that falls in the clear centre (at minimum the BRA
button) is hidden, so only the dog + the showcase's own title/control bands are visible. On close
(commit **or** dismiss) the chrome is restored.

## Plan
- `scripts/main.gd`: add `_set_training_hud_visible(v)` toggling the full training-HUD set
  (`_bra_button`, `_tell_marker`, `_trainer_marker`, `_readout`, `_learned_bar`, `_coin_readout`,
  `_tricks_button`) — all null-guarded; none self-set `.visible` (their `_process`/event drivers set
  `.disabled`/`.modulate`/`.text` only), so a visibility toggle is safe + sticky.
- Hide in `_on_showcase_requested()` (after `_menu.hide()`); restore in `_close_showcase()` (shared by
  commit + dismiss).
- TDD (`tests/test_breed_roster_wiring.gd` or a showcase wiring test): open showcase →
  `_bra_button.visible == false`; close → `_bra_button.visible == true`.
- Visual Review: re-run `tools/web_capture_showcase.mjs` → no "BRA" ghost over the spotlit dog on
  `087-01`/`087-02`.

## Placeholder check
Real visibility gating, no stub. No allowlist needed.
