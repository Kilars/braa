# 188 — X-6: kennel modal stat-meter empty segment reads as a present track

**Source:** PO father-pass-62 (`.docs/specs/po-review.md`) — ONE new buildable X-6 directive.

## Directive
The kennel inspect-modal stat meters (Læreevne/Energi/Mot/Fokus) draw 5 segment pips
each — filled = DS blue, empty = a very pale grey-blue. The empty pip is
`C_PIP_EMPTY = #dfe5ea` (223,229,234) on the card `C_MODAL_SURFACE = #fbfbf7`
(251,251,247) — only **~1.22:1**. So a **4/5 reads almost identically to a 5/5**; the
missing box disappears and the meter conveys "lots of blue", not a value out of 5.
This undercuts the modal's compare-before-adopt job (K-2/K-8) and is inconsistent with
the DS track treatment (the training learned-bar rail was made an opaque, clearly-present
groove in 145/179 for exactly this reason).

## Fix
Repoint the empty stat pip to a **clearly-present-but-unfilled track** — a light slate-grey
in the SLATE_SOFT hue family that clears **≥~1.6:1** against the card, while staying
obviously lighter/greyer than the saturated DS-blue filled pip so the meter still reads by
value. Applied in the shared `_StatPip` draw / `C_PIP_EMPTY` const so all 8 dogs' meters
read at a glance. Keep DS-blue for the filled segments; only the empty slot changes.

Note: BORDER (#e9e2d5) — the learned-bar TRACK_COLOR — is only ~1.24:1 on the PAPER card
(it reads on the training page because it sits against the bright *sky* + a scrim), so it
would NOT fix this. The father's "SLATE_SOFT-family, ≥1.6:1" is the operative guide.

## Implementation
- `scripts/kennel_screen.gd`: `C_PIP_EMPTY` `#dfe5ea` → `#b3bcc4` (light slate track,
  ~1.85:1 on the card; still far lighter than the DS-blue fill).
- TDD: `tests/test_kennel_stat_meter_contrast.gd` — empty pip ≥1.6:1 on card, ghost
  baseline <1.3:1, empty stays lighter than filled, symmetry.

## Done when
- verify gate green, Visual Review confirms 4/5 vs 5/5 now reads at 1×.

## Outcome — DONE
- `scripts/kennel_screen.gd:57`: `C_PIP_EMPTY` `#dfe5ea` → `#b3bcc4` (one-token change; the
  shared `_StatPip._draw` + `_build_modal_stats` already route every dog's meters through it,
  so all 8 read). Measured contrast on `C_MODAL_SURFACE`: **1.85:1** (was 1.22:1), clears the
  father's ≥1.6 floor; empty stays far lighter than the DS-blue fill so value still reads.
- TDD: `tests/test_kennel_stat_meter_contrast.gd` (4 asserts: empty ≥1.6:1 on card, ghost
  <1.3:1 baseline, empty lighter than filled, symmetry). Written red first, green after.
- Verify gate GREEN (import·boot·test·export).
- Visual Review PASS: `.screenshots/188-statmeter-nova-modal.png` — Nova's Mot row now reads
  **4 blue + 1 clearly-present grey**, distinguishable from the 5/5 rows at 1×; zero console
  errors. Capture tool `tools/po_pass62_statmeter.mjs`.
