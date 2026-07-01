# 059 — QUALITY: play the authored `Sitting_end` stand-up (kill the dead `clips.sit_end` seam)

**Type:** QUALITY (dead-seam fix surfaced by the 2026-07-01 adversarial Phase-2 construction audit)
**Phase:** 2 (current). Non-owner-gated — the clip already ships in the licensed Labrador.

## What it addresses

`DogClips.resolve` resolves `clips.sit_end` from the licensed Labrador's authored
`Sitting_end` clip (`dog_clips.gd:43`), but **no `DogDirector.play_*` method ever consumes
it** — every other resolved clip (idle, walk, sit_start, sit_loop, reaction) has a live
caller; `sit_end` has none. `main._end_sit()` (`main.gd:346`) stands the dog back up with a
bare `play_idle()`, so the seated hold snaps to idle on the 0.2 s blend alone and the
authored stand-up animation — the missing third beat of the sit cycle (build-in → hold →
**stand-up**) — is dropped. This is the "one minor dead method" the prior audit flagged
(obs 3863) and the current audit re-confirmed.

## Why now

The construction-audit gate treats a resolved-but-never-called clip as a dead seam → task,
not a clean zero. It uses a **real authored asset already in the shipped dog** (no new
asset, no owner action) and completes the honest sit cycle.

## Coupling constraint (why the naive one-liner is wrong / hollow)

`_end_sit()` also calls `_resume_wander()`, and `_drive_wander` (`main.gd:995`) fires
`play_walk()` on the first moving frame — which would **clobber the stand-up within one
frame**, making a bare wiring change a near-no-op. The fix must let the stand-up read *in
place* without disturbing the PO-approved P2-8 **variable cadence**: SitLoop owns the
next-sit clock and must NOT be touched — only hold the *roam* for the stand-up's span, then
amble.

## Technical approach

**1. `DogDirector.play_sit_end()` (TDD — mirrors `play_feint`/`play_reaction`).**
Before: (no such method; `clips.sit_end` never played.)
After:
```gdscript
## Stand the dog back up out of the seated hold with its authored stand-up clip
## (`Sitting_end`) — the missing third beat of the sit cycle — then settle into idle.
## Falls back to a plain idle when the dog ships no stand-up clip (CC0), so the dog always
## ends up alive at rest, never frozen mid-sit. Honest reuse of the licensed clip.
func play_sit_end() -> void:
	if _ap == null:
		return
	if clips.sit_end == "":
		play_idle()  # no authored stand-up — settle straight to idle rather than freeze
		return
	_set_loop(clips.sit_end, Animation.LOOP_NONE)  # the stand-up plays once, never loops
	_ap.play(clips.sit_end)
	if clips.idle != "":
		_ap.queue(clips.idle)  # settle into the ambient idle after standing

## True while the authored stand-up is the clip currently playing — main holds the roam in
## place during it so the stand-up reads, then ambles (does NOT touch the SitLoop cadence).
func is_standing_up() -> bool:
	return _ap != null and clips.sit_end != "" and _ap.current_animation == clips.sit_end
```

**2. `main._end_sit()` — play the stand-up instead of a bare idle.**
Before: `_director.play_idle()`
After:  `_director.play_sit_end()`  # stand up with the authored Sitting_end (059)

**3. `main._drive_wander()` — don't let the amble clobber the stand-up.**
Before: `if _wander_active:`
After:  `if _wander_active and not _director.is_standing_up():`
so the roam holds the dog in place for the stand-up's span, then resumes (cadence-neutral —
SitLoop's next-sit clock is untouched).

## Acceptance criteria

- [x] Failing test first: `tests/test_dog_director_sit_end.gd` — `play_sit_end()` on a
      sit-capable dog plays `Sitting_end` (LOOP_NONE) and queues idle; is a graceful idle
      fallback on a dog with no stand-up clip; `is_standing_up()` is true only while the
      stand-up is the current clip. (RED confirmed: nonexistent-method errors + hollow-test
      guard fired; then GREEN — 221 tests, 0 failures.)
- [x] `DogDirector.play_sit_end()` + `is_standing_up()` implemented; test green.
- [x] `clips.sit_end` now has a live caller — dead seam gone (`play_sit_end` called from
      `_end_sit` at main.gd:346).
- [x] `main._end_sit()` calls `play_sit_end()`; `_drive_wander` guards the amble on
      `is_standing_up()` (main.gd:997).
- [x] Verify gate green (import · boot · test · export).
- [x] Visual Review (local licensed web capture, 390×844): `.screenshots/059-rise-26..31`
      show the dog **seated (26–29) → mid-rise off the haunches (30) → standing/ambling (31)**
      in the SAME spot — the authored stand-up reads, stood up in place, then ambles. The
      600 ms run (`059-standup-*`) confirms the P2-8 variable cadence + wander still read
      (varied positions, real gait, framed, no slide; trainer ring still fires).
- [x] Placeholder check clean on the diff (only allowlisted "never a faked pose" test comment).
