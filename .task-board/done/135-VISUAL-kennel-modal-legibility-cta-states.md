# 135 — VISUAL+TDD — Kennel inspect modal: legible stats/trick line + explicit CTA states

**Source:** PO Review 2026-07-06 (father pass 2), directive **#1 [HIGH]** (kennel).
**Phase:** current-phase X-4 quality (preempts the Phase-10 owner-gate).

## What it addresses

`.screenshots/108-kennel-modal.png` — the inspect modal reads *broken*, not intentional:
- The card is small/cramped against the dimmed grid.
- The 4-stat block (Læreevne/Energi/Mot/Fokus) draws its blue pip bars fine, but the left-hand
  stat **labels are unreadable micro-type**, and the «Kan lære: Sitt · Ligg · Legg deg» line is tiny.
- The bottom action button, when unaffordable (Nova costs 300, player has 0), is **pale text on a
  pale fill** — it reads *broken*, not disabled; nothing says «Har ikke råd».

**Acceptance (PO):**
- Enlarge the modal to fill more of the portrait width.
- Stat labels **≥13px Ink-Soft `#5A6B7D`** at **≥1.4 line-height / ~8px row rhythm**; the «Kan lære»
  line legible (not micro-type).
- The adopt/select CTA in **full Bra-Blue `#4A90E2` + white ≥700 when affordable**, and an
  **explicit disabled token** (greyed fill + a «Har ikke råd»-style label showing the shortfall)
  when not — never an accidentally-washed-out button.

## Technical approach

All in `scripts/kennel_screen.gd`.

**1. Widen the card (render).** `MODAL_CARD_MAX_W 330 → ~362` (390 portrait − ~14px margin each
side). Confirm the CenterContainer still centres and nothing clips at the wider width.

**2. Legible stat labels (render).** `_build_modal_stats()` (~L1122): add an explicit Ink-Soft
token `const C_INK_SOFT := Color("5a6b7d")` (memory: the modal palette lacks it) and use it for the
stat labels; keep `T_SMALL` (13px, meets ≥13) **but** set `add_theme_constant_override("line_spacing", …)`
or raise to `T_BODY` (15px) so it clears the "micro-type" read — pick whatever renders legibly in
capture at 390×844. Bump the stats VBox `separation` 7 → 8 (the ~8px row rhythm). Give each stat row
label a min line-height ≥1.4 (label custom_minimum_size.y or line_spacing).

**3. Legible «Kan lære» line (render).** `_build_modal_trick_list()` (~L1245): raise from `T_SMALL`
muted to a legible size/colour (T_BODY, Ink-Soft) so it is not micro-type.

**4. Explicit disabled CTA (LOGIC — TDD this).** `_build_adopt_button()` (~L1376) currently, when
`affordable==false`, keeps the «Adopter N mynt» text, dims to `modulate.a=0.55`, and disables — that
is the washed-out read the PO flags. Instead:
- Extract a **pure static helper** for the disabled label + shortfall, e.g.
  `static func adopt_button_label(price:int, balance:int, affordable:bool) -> String` returning
  `"Adopter  %d mynt" % price` when affordable and `"Har ikke råd · mangler %d" % (price-balance)`
  (shortfall) when not (guard price>balance; never negative). **Write the failing test first**
  (`tests/test_kennel_modal_cta.gd`) over this pure mapping — that is the TDD leg.
- In `_build_adopt_button`, when not affordable use a **distinct greyed disabled token** (a solid
  muted-grey StyleBoxFlat fill + Ink-Soft text at full opacity) — NOT the dimmed-blue+0.55-alpha
  wash. When affordable keep full `C_ADOPT_BLUE` + white bold (already correct). `detail` already
  carries `price`, `affordable`, and the balance is available via `_balance` (or add it to `detail`
  in `open_detail`'s augmentation, ~L202) so the helper can compute the shortfall.

Everything except the pure label helper is render glue → **Visual Review** on
`108-kennel-modal.png` (both an affordable dog and an unaffordable one — capture Nova at 0 coins to
prove the «Har ikke råd · mangler N» disabled token, and an affordable dog to prove the blue CTA).

## Definition of done
- Failing test first for `adopt_button_label` → green; full suite green.
- `nix develop -c bash verify.sh` green (import·boot·test·export).
- Visual Review at 390×844: modal wider, stat labels + «Kan lære» clearly legible, affordable CTA
  full blue, unaffordable CTA a clear greyed «Har ikke råd · mangler N» — never washed-out.
- Placeholder-grep clean on the diff.
