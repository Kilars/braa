# IMPROVEMENT: 038 — Tier readout flashes in clear sky, not on the dog's head (P1-7 polish)

**Status**: Backlog
**Created**: 2026-06-30
**Priority**: High — open **PO directive** (Improvements) on the Phase-1 Visual-Review
sign-off path (P1-10). The only-remaining-gap override applies (visual domain is saturated
030–034, but this is one of just three open Phase-1 PO findings).
**Labels**: visual, ui, phase-1, po-directive, p1-7
**Estimated Effort**: Small

## What it addresses (PO directive, `.docs/specs/po-review.md` → Improvements)

> **Tier readout lands on the dog's head, not clear sky (P1-7 polish).** The
> PERFECT/OK/MISS word flashes low enough to overlap the dog's ears/crown. It's legible
> (the dark outline carries it), but it would read cleaner pulled up into clear sky above
> the dog.

Confirmed in code (2026-06-30): the readout band is anchored to the top with
`READOUT_OFFSET_TOP = 96`, `READOUT_OFFSET_BOTTOM = 220` (`main.gd:266-269`), a 124 px band
whose vertically-centred `font_size 88` word sits at ~y 158 of the 720×1280 viewport. The
centred dog's crown reaches up into that region, so the word overlaps the ears/crown. The
dark outline from 033 keeps it legible, but the PO wants it lifted into clear sky.

This is a **pure positioning** change (no logic): move the readout band up so the word
clears the dog's head. Per the scan rules, pure rendering/positioning tasks are TDD-exempt
and closed by **Visual Review** with a captured proof frame.

## Technical Approach

Pull the readout band up into the clear sky above the dog by lowering its top-anchored
offsets, keeping it full-width and centred. Tune the exact rise against the captured
frame (the dog's on-screen crown height is what we're clearing); start from ~48 px up and
confirm by capture.

**Before** (`scripts/main.gd`, lines 266–269):

```gdscript
const READOUT_OFFSET_LEFT := 24.0
const READOUT_OFFSET_RIGHT := -24.0
const READOUT_OFFSET_TOP := 96.0
const READOUT_OFFSET_BOTTOM := 220.0
```

**After** (band lifted into clear sky above the dog's crown; left/right unchanged):

```gdscript
const READOUT_OFFSET_LEFT := 24.0
const READOUT_OFFSET_RIGHT := -24.0
## Lifted into the clear sky above the dog's crown (P1-7 polish, 038): the centred dog's
## ears reached the old 96–220 band, so the flashed tier overlapped the head. Pulled up
## ~48 px; final value confirmed against the forced-tier capture below.
const READOUT_OFFSET_TOP := 48.0
const READOUT_OFFSET_BOTTOM := 172.0
```

Keep the 124 px band height (so `font_size 88` still fits with the 033 outline). Do **not**
touch `TierReadout` itself (the fade math, tier colours, outline, DEAD-shows-nothing
behaviour all stay) — this is purely where the band is anchored.

Do not push so far up that the word collides with the top edge / a notch: keep a
comfortable top margin (the ~48 px start leaves it). If the capture shows the dog's crown
is taller than expected, lift further — the gate is "clear sky, no head overlap", not a
specific pixel value.

## Visual Review (the real gate)

Run `polish`, then capture the flashed tier over the live dog on the running **local
licensed web export** at 390×844 using the existing seam `?bra_force_tier=perfect|ok|miss`
via `tools/web_capture_readout.mjs`. In the captured frame the tier word must sit in clear
sky **fully clear of the dog's ears/crown** (no overlap), still crisply legible (033
outline intact). Save the proof frame under `.screenshots/038-readout-clear-sky.png`.
Findings are blocking.

## Acceptance Criteria

- [ ] Readout band offsets lifted so the flashed tier sits above the dog's crown
      (`READOUT_OFFSET_TOP`/`_BOTTOM` reduced; band height + horizontal anchors unchanged).
- [ ] `TierReadout` behaviour untouched (fade math, colours, 033 outline, DEAD-shows-
      nothing) — existing readout tests stay green.
- [ ] Comfortable top margin retained (word not clipped by the top edge / notch).
- [ ] Visual Review on the running 390×844 licensed export: the PERFECT/OK/MISS word reads
      in clear sky, fully clear of the dog's ears/crown, still legible — captured proof in
      `.screenshots/038-readout-clear-sky.png`.
- [ ] `nix develop -c bash verify.sh` green (import → boot → test → export).
