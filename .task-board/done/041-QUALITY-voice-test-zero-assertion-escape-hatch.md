# 041 — QUALITY: remove the zero-assertion escape hatch in the voice-asset test

**Type:** QUALITY (test honesty)
**Phase:** 1 (P1-6 audio coverage)
**Source:** adversarial construction audit (2026-06-30), backlog-empty round. The audit
tried to refute that completed Phase-1 work is honest and surfaced this one real
test-honesty defect (plus a non-actionable stale doc note in the closed 038 file, which is
allowlisted board meta-text — code/AC/resolution all agree, no task warranted).

## What it addresses

`tests/test_payoff_player.gd::test_voice_is_the_real_spoken_asset_when_present` has an early
`return` that exits the test with **zero assertions** when the voice asset isn't loadable:

```gdscript
const VOICE := "res://assets/audio/bra_tts_placeholder.wav"
if not ResourceLoader.exists(VOICE):
    return  # asset not importable here — fallback path is covered by the other tests
```

This is the exact shape the **task-026** guard exists to catch. The guard
(`tests/test_runner.gd:39-40`) fails any `test_*` that records 0 assertions. So this
early return is **self-contradictory**: its comment intends a *graceful skip*, but if the
branch is ever taken the runner reports a misleading **"ran but made 0 assertions (empty
test…)" failure**, not a skip. It can never do what it claims.

The branch is also **dead code**: `assets/audio/bra_tts_placeholder.wav` (+ its `.import`)
is **committed and not gitignored**, and `verify.sh` runs the import leg before the test
leg, so `ResourceLoader.exists(VOICE)` is always true when this test runs. The "public CI
without it" case in the docstring does not apply — the file is in the repo.

## Technical approach

Replace the silent zero-assertion escape hatch with a direct, always-present assertion that
the committed asset is importable. A genuinely missing/unimportable committed asset is a
*real regression* and should fail loudly with a clear message — not skip, and not trip the
026 guard as a confusing "empty test".

**Before** (`tests/test_payoff_player.gd`, body of `test_voice_is_the_real_spoken_asset_when_present`):

```gdscript
	const VOICE := "res://assets/audio/bra_tts_placeholder.wav"
	if not ResourceLoader.exists(VOICE):
		return  # asset not importable here — fallback path is covered by the other tests
	var p := _player()
	var s := p.voice_stream()
	assert_eq(s.resource_path, VOICE, "the voice is the real spoken asset, not the synth blip")
	p.queue_free()
```

**After:**

```gdscript
	const VOICE := "res://assets/audio/bra_tts_placeholder.wav"
	# The spoken "Bra!" wav ships committed (named by the open voice FLAG) and verify.sh
	# imports before testing, so it is always loadable here. Assert that directly instead
	# of silently returning: a missing/unimportable committed asset is a real regression,
	# and a zero-assertion early return would trip the 026 guard (test_runner.gd:39-40) as
	# a misleading "empty test" failure rather than this clear one.
	assert_true(ResourceLoader.exists(VOICE), "the committed spoken voice asset is importable")
	var p := _player()
	var s := p.voice_stream()
	assert_eq(s.resource_path, VOICE, "the voice is the real spoken asset, not the synth blip")
	p.queue_free()
```

The class docstring's "fallback ONLY when the asset is absent (e.g. public CI without it)"
sentence describes `PayoffPlayer`'s *production* fallback (still true, still covered by
`test_ships_real_placeholder_streams`) — leave the production-behavior description, but it
no longer implies *this* test skips.

> Note: this is a test-correctness fix to the test file itself, so it is not red-green TDD
> (the test IS the deliverable). It is verified by the verify gate staying green with the
> test now always asserting, and by reasoning that no path through the method records 0
> assertions.

## Acceptance criteria

- [x] The early `return` with zero assertions is gone from
  `test_voice_is_the_real_spoken_asset_when_present`; every path through the method records
  at least one assertion.
- [x] The method asserts the committed asset is importable (`assert_true(ResourceLoader.exists(VOICE), …)`)
  before asserting `voice_stream().resource_path == VOICE`.
- [x] No other test in `tests/` has a zero-assertion early-return path (spot-checked during
  the fix).
- [x] `nix develop -c bash verify.sh` is green (import → boot → test → export), with the
  test count unchanged or +0 and no new failures.
- [x] Placeholder check on the diff: no un-allowlisted placeholder/stub hit introduced.

## Resolution (2026-06-30)

Replaced the zero-assertion early `return` in `test_payoff_player.gd` with a direct
`assert_true(ResourceLoader.exists(VOICE), …)`, so every path through the method now records
≥1 assertion. The committed-and-not-gitignored wav is always loadable after verify.sh's
import leg, so the old skip path was dead code that could only ever surface as a misleading
"empty test" 026 failure. Spot-checked all other bare `return`s in `tests/`
(`test_dog_clips.gd:93/117/121`, `test_tell_wiring.gd:146`) — each is preceded by a real
assertion (and `test_licensed_dog_if_present_resolves_a_real_sit` deliberately keeps an
`assert_true(true, "…skipped")` because the licensed dog IS gitignored/absent in CI; the
voice wav is not, so a presence-assertion is the honest form here). Verify gate green; diff
is one test file, placeholder check clean.

Surfaced by the backlog-empty adversarial construction audit. The audit's only other note
was stale "Technical Approach" numbers inside the *closed* 038 done-file (code/AC/resolution
all agree on 56/180) — allowlisted board meta-text, no task warranted.
