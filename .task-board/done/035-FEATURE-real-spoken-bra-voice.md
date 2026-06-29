# FEATURE: 035 — Ship a genuinely spoken "Bra!" (replace the sine-tone placeholder) (P1-6)

**Status**: Done (2026-06-29)
**Created**: 2026-06-29
**Priority**: High — open **PO directive** (P1-6, current phase). The synth blip is not an
honest spoken word; Phase 1 ships a real spoken "Bra!" before P1-10 sign-off. Non-owner-gated
(the spoken stand-in already exists on disk); the warm **human** voice is a separate open flag.
**Labels**: audio, payoff, phase-1, po-directive, tdd
**Estimated Effort**: Small

## What it addresses (PO directive, 2026-06-29)

The owner rejected the "placeholder TTS acceptable" stance for P1-6: the payoff "voice" is two
sine tones (`scripts/payoff_player.gd` `_voice_blip()` — 300 Hz → 370 Hz), an abstract beep, not
a spoken word. P1-6 is amended to require a **genuinely spoken** "Bra!" even before the real
recording, and to **flag** the human voice if it can't be produced (done — see
`.task-board/FLAGS.md`). The spoken stand-in has already been synthesized and committed:

- **`assets/audio/bra_tts_placeholder.wav`** — an offline `espeak-ng` Norwegian "Bra!"
  (mono, 16-bit, 22050 Hz, ~0.83 s). Generated via `nix shell nixpkgs#espeak-ng -c
  espeak-ng -v nb -s 140 -p 35 "Bra!" -w …`. Robotic, a clear placeholder, **same 22050 Hz
  as `PayoffPlayer.MIX_RATE`**. The warm human Maren recording drops in under the same cue id
  later (owner-gated; tracked in `FLAGS.md`).

## Technical Approach

Wire the spoken asset into `PayoffPlayer` as the voice stream, **preferring the real clip,
falling back to the synth blip only if the asset is absent** (mirrors the dog-loader's
`ResourceLoader.exists()` degrade-cleanly pattern, so public CI without the asset still boots):

- In `scripts/payoff_player.gd` `_init()`, set `_voice.stream` from
  `load("res://assets/audio/bra_tts_placeholder.wav")` when `ResourceLoader.exists()` is true,
  else keep `_voice_blip()`. Keep `_voice_blip()` as the documented fallback (don't delete it).
- **Keep all existing policy unchanged:** the success gate (silent on MISS/DEAD), and
  PERFECT-louder-and-slightly-higher-than-OK via `MarkPayoff.brightness` (volume_db / pitch_scale).
  The clip is one "Bra!"; brightness still modulates it, exactly as for the blip.
- Stable cue id (`MarkPayoff.VOICE_PERFECT` / `VOICE_OK`) is untouched — the human voice is still
  a drop-in replacement of the file with no code change.

## TDD steps (`tests/test_payoff_player.gd`)

1. **Red — the voice is the real spoken asset when present.** Assert `voice_stream()` is the
   loaded resource at `res://assets/audio/bra_tts_placeholder.wav` (e.g. its `resource_path`),
   **not** a freshly-synthesized `AudioStreamWAV` blip. Fails today (always the blip).
2. **Green** — apply the loader (Step above).
3. **Keep green** — the existing gate tests: silent on MISS/DEAD (`is_voicing()` stays false,
   `last_played == false`), PERFECT `voice_volume_db()` > OK. The fallback path stays covered
   (when the asset is absent the blip is still used and the gate still holds).

Follow `.claude/skills/tdd/SKILL.md` (red → green → refactor).

## Verification

- `nix develop -c bash verify.sh` green (import → boot → test → export). The new `.wav` imports
  cleanly and rides the export; commit its generated `.import` alongside the wiring.
- Audio can't be heard headless, so this is judged **wired + gated + a real spoken-word asset
  loaded under the cue** — note in `po-review.md` that an **on-device listen** + the **human-voice
  flag** remain before final P1-10 sign-off.

## Results (2026-06-29)

**Wired (TDD red→green).** `scripts/payoff_player.gd` now sets `_voice.stream = _load_voice()`
in `_init()`. `_load_voice()` prefers the real spoken asset — `ResourceLoader.exists(VOICE_ASSET)`
→ `load(VOICE_ASSET)` (new `const VOICE_ASSET := "res://assets/audio/bra_tts_placeholder.wav"`) —
and falls back to `_voice_blip()` only when the asset is absent (mirrors the dog-loader's
degrade-cleanly pattern; public CI without the file still boots). `_voice_blip()` is kept,
re-documented as the fallback. The class doc now states the voice is a genuinely spoken "Bra!".

New test (red first, then green): `test_voice_is_the_real_spoken_asset_when_present` asserts
`voice_stream().resource_path == res://assets/audio/bra_tts_placeholder.wav` (the loaded resource,
not a freshly-synthesized blip whose `resource_path` is `""`). Confirmed red against the old code,
green after the wiring. **115 tests, 0 failures**; `nix develop -c bash verify.sh` green
(import · boot · test · export). The `.wav` was already committed; its generated `.import`
sidecar is committed with this change so the asset rides the Web export.

**Gate intact (no regression):** `test_miss_and_dead_make_no_sound` (silent on MISS/DEAD) and
`test_perfect_is_louder_than_ok` (PERFECT louder than OK) stay green — brightness still modulates
volume/pitch independent of which stream is loaded.

**Still pending (recorded, not closed by this task):** audio can't be heard headless, so an
**on-device listen** remains; and the **warm human Maren "Bra!"** is owner-gated — already
tracked as the open flag in `.task-board/FLAGS.md` (a no-code-change file drop-in at the same
path). `.docs/specs/po-review.md` is PO-owned (read-only for the loop), so that note is left to
the PO pass; the FLAGS entry is the loop's standing record. This closes the **spoken-word** gap,
not the **human-voice** one.

## Acceptance Criteria

- [x] `PayoffPlayer` loads `assets/audio/bra_tts_placeholder.wav` as the voice stream when
      present; falls back to the synth blip only if absent (no hard dependency).
- [x] Failing test written first: `voice_stream()` is the real loaded asset, not the synth blip.
- [x] Gate intact: silent on MISS / dead tap; PERFECT louder + slightly higher than OK.
- [x] Stable cue id unchanged — the human Maren recording remains a no-code-change drop-in.
- [x] `verify.sh` green; the `.wav` + its `.import` are committed.
- [x] On-device listen + warm human voice still pending (owner-gated): tracked in `FLAGS.md`
      (the open human-voice flag). `po-review.md` is PO-owned/read-only for the loop, so its note
      is left to the PO pass — this closes the *spoken-word* gap, not the *human-voice* one.
