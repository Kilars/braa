# 072 — FEATURE: one active trick at a time + completion menu (learned / available / locked + coins)

**Type:** FEATURE (mixed: TDD logic + Visual Review) · **Phase:** 3 (current) · **Source:** PO
Review 2026-07-02 `po-review.md` **Actionable note 1** ("Only one trick should be active at a
time. Sitt for example. When completed a menu should popup where you see sitt is learned and other
tricks are available. In this screen you also see currency and unavailable tricks"). · **Priority:**
P1 for this phase — the owner's headline directive; it **supersedes** the always-on 066 chip row.

## What it addresses

Today the top-of-HUD `TrickSelector` chip row (066, P2-1) is **always on** — the player can switch
trick any time, and there's no sense of focusing on / completing one trick. The owner wants a
**guided, one-trick-at-a-time** loop: train the single active trick (Sitt by default); when it's
**completed (mastered)**, a **menu pops up** showing the collection — the just-learned trick marked
learned, the other **available** tricks to train next, the **coin** balance, and the
**locked/unavailable** tricks — and the player picks what to train next from there.

This replaces the always-on chip row with an on-completion (and reopenable) menu. It still
satisfies P2-1 "pick a trick" — just no longer as a permanent second in-round surface. The
economy earn side (068/069) and its coin readout stay; this task gives the coins a home in the menu.

**Honesty gate (never fake a trick):** "available" tricks are only ones the loaded dog can actually
perform (Sitt / Ligg / Legg deg — resolved via `_selectable_tricks()`). "Locked/unavailable" tricks
are the genuinely **absent** ones (Gi labb / Rull / Snurr — BUST-064 residual, owner-gated): shown
as **display-only greyed roadmap entries**, never selectable, never playing a faked clip. The full
adopt/breed UI stays owner-gated (do not fake a breed).

## Technical approach

### 1. One active trick — retire the always-on chip row

Drop `_setup_selector()` from the default HUD build (and its top-band offset). Keep `select_trick()`,
`_current_trick`, `_progress_by_trick`, and the per-trick persistence exactly as-is — the menu drives
`select_trick()` instead of the chip row. `_current_trick` stays Sitt by default (unchanged default
experience). Reclaim the freed top-band space (the coin line moves into the menu / stays as the
small readout).

### 2. Completion menu (new dumb-renderer Control + modal)

New `scripts/trick_menu.gd` (`class_name TrickMenu extends Control`), same `_draw` + `_gui_input`
dumb-renderer pattern as `TrickSelector` / `CoinReadout` (pure, framebuffer-free, unit-testable):

- A centred modal panel over a dimmed backdrop, mouse-opaque (eats taps behind it).
- Header: **coins** (reuse the drawn-coin motif from `CoinReadout`, no font-glyph tofu).
- A list of trick rows, each: name + state badge — **Learned** (mastered), **Available**
  (performable, tap to train), or **Locked** (absent/owner-gated, greyed, not tappable).
- Emits `trick_chosen(id)` when an **Available**/**Learned** row is tapped; a `dismissed` signal
  (or a Close/"keep training" affordance) to hide without switching.

Expose a **pure** roster builder so the learned/available/locked split is TDD-locked without a
framebuffer:
```gdscript
# scripts/trick_menu.gd
class_name TrickMenu
extends Control
signal trick_chosen(id: String)
signal dismissed
enum State { LEARNED, AVAILABLE, LOCKED }
## Pure: classify each known trick given the performable set + per-trick mastery + the current trick.
## performable = ids the dog can actually do; mastered = {id: bool}; locked = genuinely-absent ids.
static func classify(all_ids: Array, performable: Array, mastered: Dictionary, locked: Array) -> Array:
    var rows: Array = []
    for id in all_ids:
        var st := State.LOCKED
        if performable.has(id):
            st = State.LEARNED if mastered.get(id, false) else State.AVAILABLE
        rows.append({"id": id, "state": st})
    return rows
```

### 3. Wire the menu into the loop (main.gd)

- On mastery, open the menu and pause offers:
```gdscript
# in _apply_progress(), where mastery is detected today:
if _progress.just_mastered(delta):
    _play_mastery_beat()
    _purse.earn(COIN_REWARD_MASTERY); _refresh_coins()
    _open_trick_menu()          # NEW: the completion menu pops up (loop pauses)
```
- `_open_trick_menu()` builds the roster (performable via `_selectable_tricks()`, mastery from
  `_progress_by_trick`, locked = the absent roadmap ids), shows the modal, and pauses the round
  loop (reuse `_loop.reset_to_idle()` + a `_menu_open` guard in `_advance_loop` so no offer fires
  while the menu is up).
- `trick_chosen(id)` → `select_trick(id)` (only for performable ids; Locked rows never emit) →
  hide menu → resume the loop. `dismissed` → hide → resume with the current trick unchanged.
- Add a small persistent **"Tricks"** affordance (a compact button) to reopen the menu between
  rounds, so a returning player (everything already mastered) or one who wants to switch isn't
  stuck waiting for a mastery — MVP-minimal, top corner, clear of the BRA band.

### TDD (follow `.claude/skills/tdd/SKILL.md`) — pure/logic first, RED before GREEN

- `tests/test_trick_menu.gd` (new): `TrickMenu.classify(...)` returns LEARNED for a mastered
  performable trick, AVAILABLE for an un-mastered performable one, LOCKED for an absent one; order
  follows `all_ids`; a Locked row is never reported selectable.
- `tests/test_trick_menu_wiring.gd` (or extend a main/scene test): scene-level — after a trick is
  mastered the menu opens and the loop pauses (no START_SIT while open); choosing an Available trick
  calls `select_trick` (repoints `_current_trick`) and resumes; dismiss resumes with the trick
  unchanged; a Locked id never switches the active trick (never plays a faked clip).
- Guard the never-fake honesty: assert a Locked trick id is NOT in `_selectable_tricks()` and
  `_director.has_trick(locked_id)` is false (so it can never be trained).

Reuse the existing shared test-mount helpers + the CC0-vs-licensed clip gate. The panel visuals +
the pop/dismiss feel are **Visual Review**.

## Acceptance criteria

- [ ] TDD: failing `TrickMenu.classify()` test first (LEARNED / AVAILABLE / LOCKED split correct,
      order preserved, Locked never selectable) → GREEN.
- [ ] TDD: failing wiring test first — mastery opens the menu + pauses offers; choosing an Available
      trick switches `_current_trick` and resumes; dismiss keeps the current trick; a Locked id
      never switches/plays → GREEN.
- [ ] Only **one trick is active at a time**; the always-on 066 chip row is removed from default play
      (the menu is the chooser). Default active trick stays **Sitt** (unchanged default experience).
- [ ] On mastering the active trick a **menu pops up** showing: the **coin** balance (drawn coin, no
      tofu), the just-learned trick as **Learned**, other performable tricks as **Available**, and
      the genuinely-absent tricks as **Locked/unavailable** (greyed, not tappable — never faked).
- [ ] Choosing an Available trick trains it (menu closes, offers resume as that trick); a
      **Tricks** affordance reopens the menu between rounds so switching isn't a dead-end.
- [ ] Per-trick progress + coins persistence unchanged (still survive a reload; `select_trick`
      repoints the bar/model as before).
- [ ] Visual Review at 390×844 (licensed bundle, headless Chromium, `env -u LD_LIBRARY_PATH`):
      autotap-master Sitt → menu pops up legibly (coins + learned/available/locked rows), tap an
      Available trick → it becomes active and offers resume; live canvas-tap e2e proves the switch
      (`__bra_current_trick`). Boot clean, zero console errors. Screenshots under `.screenshots/072-*`.
- [ ] Placeholder check clean on the diff (Locked rows are honest display-only, named by the
      BUST-064 owner-gated residual — allowlisted as a flagged stand-in, not a faked capability);
      `nix develop -c bash verify.sh` green.

## Notes

Supersedes the always-on `TrickSelector` (066) per the owner's directive — P2-1 "pick a trick" is
still met (via the completion menu). Reuses the `CoinReadout` drawn-coin motif and the
`TrickSelector` dumb-renderer + `_gui_input` tap pattern — no new rendering primitives. The adopt /
breed-thumbnail UI and any additional breeds remain owner-gated (BUST-068 residual) — this menu is
the **trick** collection surface, not the breed adopt screen; do not fake a breed to fill it.

## Done 2026-07-02

- **Retired the always-on chip row.** Deleted `scripts/trick_selector.gd` + its two test files;
  stripped `_selector`/`_setup_selector`/`_refresh_selector`/`SELECTOR_*` from `main.gd`. Reclaimed the
  freed top band: the learned bar now anchors directly under the coin line
  (`LEARNED_BAR_OFFSET_TOP = COIN_READOUT_TOP + CoinReadout.HEIGHT + 14`).
- **New `scripts/trick_menu.gd`** (`class_name TrickMenu extends Control`), same dumb-renderer split as
  TrickSelector/CoinReadout: pure `classify()` (LEARNED/AVAILABLE/LOCKED, roadmap ids always Locked),
  `is_selectable()`, `id_at()` hit-map, `trick_chosen`/`dismissed` press-only signals, drawn-coin
  header (no glyph tofu), a "Keep training" close + tap-backdrop-to-dismiss.
- **Wired into `main.gd`:** `_menu_open` guard in `_advance_loop` (pauses offers), `_open_trick_menu()`
  fired on the mastery crossing in `_apply_progress`, `_on_trick_chosen`→`select_trick`+close,
  `_on_menu_dismissed`→close, a persistent top-left **"Tricks"** reopen button, and
  `ROADMAP_LOCKED_TRICKS = [gi_labb, rull, snurr]` (BUST-064 residual, display-only Locked rows —
  never selectable, never performable, never play a clip). Web hook `__bra_menu_open` for capture.
- **TDD:** `tests/test_trick_menu.gd` (13) + `tests/test_trick_menu_wiring.gd` (10) written RED first,
  then GREEN. Retargeted `test_coin_readout.gd`'s non-overlap invariant off the retired selector.
- **Verify gate green** (import · boot · test 307/0 · export). Placeholder check clean (the only
  hits are never-fake-gate documentation).
- **Visual Review** (390×844, licensed bundle, headless Chromium via `tools/web_capture_menu.mjs`):
  autotap mastered Sitt → menu popped legibly (`.screenshots/072-menu-open.png` — coins 10, Sitt
  Learned, Ligg/Legg deg Available, Gi labb/Rull/Snurr Locked-greyed, Keep training); a real canvas
  tap on the Available Ligg row switched `__bra_current_trick` sitt→ligg and closed the menu, offers
  resumed with Ligg's own empty bar (`.screenshots/072-after-switch.png`). Coins persisted across the
  switch. Boot clean, zero console errors.
