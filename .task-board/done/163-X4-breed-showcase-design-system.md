# 163 — X-4: breed showcase («Vis frem hundene») into the design system

**Source:** PO father-pass-28 (`.docs/specs/po-review.md`), HEAD `7918f0c`.
**Label:** X-4 cross-cutting polish (current arc). Not work-ahead — this is a live
signed-off-phase surface (P3-4) that the 129→162 DS/AA arc never touched.

## The defect (father, pass 28)

`scripts/breed_showcase_view.gd` (built at task 087, **before** the 096+ DS arc) is the
one persistent UI surface still entirely outside the design system:

1. It references **no `DesignSystem`** — hardcodes local charcoal/gold colours (`:19-30`),
   builds flat `StyleBoxFlat` boxes (`:192-205`), and never applies the DS font, so it
   reads as a *different app* next to the light-paper completion menu it launches from.
2. **Gold used as a button/pip/name FILL** in three places (`NAME_ACTIVE`/`PIP_ON`/
   `BTN_PRIMARY` = `Color(1.0,0.86,0.30)`, `:21,24,26`), violating the "gold is reserved
   for the coin" DS rule every recent pass (146/162) enforced.
3. The disabled «Trener denne» primary CTA is **illegible (~1.03:1)**: `_make_button`
   reuses the same gold stylebox for the `disabled` state and sets `font_color/hover/
   pressed` but **never `font_disabled_color`** (`:207`), so `_commit_btn.disabled = is_active`
   (`:268`) leaves Godot's washed default disabled font (pale gold) over the gold fill.
   Because a new player owns exactly one dog, this illegible state is the DEFAULT the
   showcase opens in.

## Fix (father's "what good looks like")

Keep the dark-**stage spotlight** concept (clear centre, lit dog visible) — only the chrome
gets DS-ified:

- Draw the panel/pills/buttons via DS tokens in the DS font; source the dark band from a DS
  token (`INK` @ alpha) instead of an ad-hoc charcoal.
- **Primary CTA = the DS blue gradient pill** (`gradient_pill` / `GRAD_PILL_*`, the BRA /
  «Fortsett treningen» palette from 153), white label — not a gold fill.
- **Gold off** the name pill and commit button (no coin/price is shown in the showcase, so
  gold simply goes away — no coin pip needed here).
- **Disabled «Trener denne»** gets an explicit AA-legible font colour: dark ink on a muted
  light fill, mirroring the kennel's «Trener nå» non-tappable style (151) — dark ink on a
  muted wash ≥4.5:1. `.disabled` now selects a distinct muted stylebox with `font_disabled_color`.

## Done when

- `test_breed_showcase_contrast.gd` green: disabled «Trener denne» ink-on-fill ≥4.5:1,
  enabled «Tren denne» white-on-blue ≥4.5:1, no chrome fill is the GOLD token.
- Existing `test_breed_showcase_view.gd` (tofu) + wiring tests still green.
- verify gate green; in-pixel showcase capture shows both CTA states legible, no non-coin
  gold, panel reads as one system with the completion menu.
