# 138 — FEATURE: localize the completion menu to Norwegian

**Source:** PO Review 2026-07-06 (father pass 3), directive 1 [MEDIUM]. Prior 135/136/137 arc
verified fixed + pruned; this is the one new buildable X-4 directive.

**Problem.** Every other player-facing string is Norwegian — the HUD pill reads «Triks», the
kennel is «Kennelen / Læreevne / Energi / Mot / Fokus / Raseegenskaper / Har ikke råd / Kan
lære», the footer buttons «Fortsett treningen / Gi tilbakemelding», the marker words «Bra! /
Dyktig! / Flink!» — but the completion menu the «Triks» pill opens is headed **«Tricks»** with
row badges **«Learned / Available / Locked»**, a **«Marker words»** subheading, breed badges
**«Active / Switch / Adopt / Locked»**, and a **«Breeds»** subheading (hardcoded in
`scripts/trick_menu.gd`). Internal contradiction: the «Triks» pill opens a «Tricks» panel.

**Bar:** X-4 "reads first" — one language across the app.

**Acceptance (from the directive):**
- «Tricks» → «Triks» (panel title)
- «Marker words» → «Markørord» (subheading)
- «Breeds» → «Raser» (subheading)
- badge «Learned» → «Lært», «Available» → «Tilgjengelig», «Locked» → «Låst»
- badge «Active» → «Aktiv», «Switch» → «Bytt», «Adopt» → «Adopter» (breeds + words rows)
- sweep the rest of the menu + difficulty rows for other English UI strings →
  `difficulty.gd` display name «Expert» → «Ekspert» (Normal/Hard are valid Norwegian).

**Approach.** Pure string/const change in `scripts/trick_menu.gd` (BADGE / BREED_BADGE /
WORD_BADGE dicts + the three inline heading literals, homed as named LABEL_ consts to match the
file's no-scattered-literals convention) and `scripts/difficulty.gd` (Expert display name).
TDD: a localization test asserting the menu chrome carries the Norwegian strings (no English
structural labels remain) + update the existing `test_difficulty` Expert assertion.

**Not owner-gated** — layout/colour/type/language the CC0 rig renders truthfully.
