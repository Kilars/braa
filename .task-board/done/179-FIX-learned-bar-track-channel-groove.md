# 179 — FIX: training HUD learned bar — unfilled track channel invisible (PO father-pass-50, X-4/X-6)

## What it addresses
PO father-pass-50 directive (`.docs/specs/po-review.md`, 2026-07-08). On the training HUD the
learned/mastery meter does not read as a meter: at 0 % there is no visible track at all, and
when partly filled the BLUE fill floats with the unfilled remainder invisible. Root cause in
`scripts/learned_bar.gd`: the track rail `TRACK_COLOR = DesignSystem.PAPER` (line 47) is drawn
**on top of** the backing panel `SCRIM_COLOR = DesignSystem.PAPER` (line 48) — the same white —
so the empty channel has zero contrast and the meter shape is only ever implied by the small
blue nub. The goal art (`.docs/specs/assets/goal-training-screen.png`) shows a defined rounded
track groove holding the fill, so "this fills as you learn" reads even when low/empty.

## Constraints (do NOT regress 145 / 159)
- The track must stay **opaque** and **light** (existing asserts: `TRACK_COLOR.a == 1.0`,
  luminance > 0.80) so neither the bright sky nor the sun disc bleeds through it (145).
- The backing panel must stay **opaque `DesignSystem.PAPER`** (existing asserts: `SCRIM_COLOR.a
  == 1.0`, `SCRIM_COLOR == PAPER`) so the HUD reads as one set of solid chips (159).
- So the fix is NOT reverting the track to a translucent BORDER@0.9 (that was the 145 bug) — it
  is repointing the **opaque** track to a token visibly darker than the panel.

## Technical approach (TDD — a testable contrast fact, like 145/149/153)
Repoint the track to `DesignSystem.BORDER` (`#e9e2d5`), the design system's designated opaque
groove/hairline tone: luminance ≈ 0.89 (still > 0.80, blue fill still reads), opaque (no bleed),
yet ~0.095 luminance darker than the `PAPER` panel (≈0.98) → a clearly-defined empty groove.

Before (`scripts/learned_bar.gd:47`):
```gdscript
const TRACK_COLOR := DesignSystem.PAPER       ## opaque light rail (was BORDER @ 0.9)
```
After:
```gdscript
## 179 (PO father-pass-50, X-4/X-6): 145/159 made BOTH the track rail AND the backing panel
## opaque PAPER, so the empty channel was invisible against its own panel — the meter never
## read as a meter at 0 % / partly filled. Repoint the track to the DS BORDER groove: still
## opaque + light (blue fill reads, no sky/sun bleed — 145/159 kept), but visibly darker than
## the PAPER panel so the full rounded track reads as a defined empty channel.
const TRACK_COLOR := DesignSystem.BORDER      ## opaque light groove, darker than the PAPER panel (179)
```

New failing test in `tests/test_learned_bar.gd` (render-free, reads the public consts):
```gdscript
func test_empty_track_channel_reads_as_a_distinct_groove_in_the_panel() -> void:
	assert_true(LearnedBar.TRACK_COLOR != LearnedBar.SCRIM_COLOR,
		"the empty track is a distinct groove, not the same white as its own panel")
	assert_true(LearnedBar.SCRIM_COLOR.get_luminance() - LearnedBar.TRACK_COLOR.get_luminance() >= 0.04,
		"the track is a groove visibly darker than the panel (was identical PAPER — invisible)")
```
The existing `test_track_is_opaque_and_light_so_the_sun_cannot_bleed_through` (opaque + lum>0.80)
and `test_backing_panel_is_the_same_paper_surface_as_the_pills` still pass with BORDER.

## Acceptance criteria
- [ ] Failing test written first (`test_empty_track_channel_reads_as_a_distinct_groove_in_the_panel`), red before the fix
- [ ] `TRACK_COLOR` repointed to `DesignSystem.BORDER`; panel/labels/145/159 opacity untouched
- [ ] All prior learned-bar asserts still green (track opaque+light>0.80, panel opaque PAPER)
- [ ] `nix develop -c bash verify.sh` green (import → boot → test → export)
- [ ] Placeholder check clean on the diff
