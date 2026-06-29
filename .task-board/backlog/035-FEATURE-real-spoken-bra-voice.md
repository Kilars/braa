# FEATURE: 035 — Ship a genuinely spoken "Bra!" (replace the sine-tone placeholder) (P1-6)

**Status**: Backlog
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

## Acceptance Criteria

- [ ] `PayoffPlayer` loads `assets/audio/bra_tts_placeholder.wav` as the voice stream when
      present; falls back to the synth blip only if absent (no hard dependency).
- [ ] Failing test written first: `voice_stream()` is the real loaded asset, not the synth blip.
- [ ] Gate intact: silent on MISS / dead tap; PERFECT louder + slightly higher than OK.
- [ ] Stable cue id unchanged — the human Maren recording remains a no-code-change drop-in.
- [ ] `verify.sh` green; the `.wav` + its `.import` are committed.
- [ ] `po-review.md` / `FLAGS.md` note that the on-device listen + warm human voice are still
      pending (owner-gated), so this closes the *spoken-word* gap, not the *human-voice* one.
