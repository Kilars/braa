# FEATURE: 044 — Warm local-neural "Bra!" voice via Piper (replace robotic espeak) (P1-6)

**Status**: Backlog
**Created**: 2026-06-30
**Priority**: High — the buildable slice routed out of **BUST-043** (the voice flag bust).
Owner-free: closes ~90% of the P1-6 voice gap with no owner action; only the literal human
Maren recording stays gated (narrowed flag in `FLAGS.md`).
**Labels**: audio, payoff, phase-1, p1-6, from-flag-bust
**Estimated Effort**: Small

## What it addresses

P1-6 ships a *genuinely spoken* "Bra!", but the current clip is **espeak-ng** — the robotic
FOSS floor (the owner's words: it didn't get a real attempt). BUST-043 selected **Piper**, a
local **neural** TTS: same offline `nix shell` pattern as espeak, dramatically warmer, no owner
action, X-7-safe (it bakes a static `.wav` at authoring time; runtime never hits the network).

## Technical Approach (research → asset, **no game-code change**)

The loader already prefers whatever `.wav` sits at `PayoffPlayer.VOICE_ASSET`
(`res://assets/audio/bra_tts_placeholder.wav`) — see `scripts/payoff_player.gd:27`. So this is
an **asset swap at the same path**, no GDScript change, and the existing
`test_voice_is_the_real_spoken_asset_when_present` keeps passing unchanged.

1. Generate the voice offline in the devshell (mirror the espeak provenance recorded in task
   035). Probe Piper + a warm Norwegian (`nb_NO`) voice via `nix shell nixpkgs#piper-tts` (or
   `nixpkgs#piper`); if the exact package/voice name differs, that discovery is part of this
   task — pin the working invocation in this file's Results, the way 035 pinned the espeak line.
2. Render **"Bra!"** to a mono 16-bit **22050 Hz** WAV (== `PayoffPlayer.MIX_RATE`, so no
   resample artifacts). If Piper emits 16/22.05k natively, use it; else convert with `ffmpeg`
   (`nix shell nixpkgs#ffmpeg`). Keep it ~0.6–0.9 s, one warm word, no trailing silence tail.
3. **Overwrite** `assets/audio/bra_tts_placeholder.wav` (same path → no-code-change drop-in;
   the filename's "placeholder" is allowlisted by the open human-voice flag and stays honest —
   a neural synth is still a stand-in for the human recording). Commit the regenerated `.import`
   sidecar alongside so it rides the Web export.
4. **A/B sanity:** keep the espeak bytes recoverable from git history; note in Results that the
   Piper clip is audibly warmer (an on-device listen still rides the human-voice flag).

## Keep unchanged (no regression)

- The success gate (silent on MISS / dead tap) and PERFECT-louder-and-slightly-higher-than-OK
  via `MarkPayoff.brightness` — these modulate whatever clip is loaded, exactly as before.
- The stable cue id and `VOICE_ASSET` path — so the human Maren recording is still a
  no-code-change drop-in later.
- `_voice_blip()` stays as the documented absent-asset fallback.

## Verification

- `nix develop -c bash verify.sh` green (import → boot → test → export); the new `.wav` imports
  cleanly and rides the export.
- Audio can't be heard headless → judged **wired + gated + a warmer real spoken-word asset
  loaded under the cue**; the on-device listen + the warm **human** voice remain on the
  narrowed flag (not closed by this task — this closes *robotic → warm-neural*, not
  *synthetic → human*).
- Record the exact Piper invocation + voice id in Results (provenance, like task 035's espeak line).

## Acceptance Criteria

- [ ] `assets/audio/bra_tts_placeholder.wav` is a Piper `nb_NO` neural "Bra!", mono/16-bit/22050 Hz.
- [ ] No GDScript change; `test_voice_is_the_real_spoken_asset_when_present` still green.
- [ ] Gate intact: silent on MISS/dead; PERFECT louder + slightly higher than OK.
- [ ] `verify.sh` green; `.wav` + regenerated `.import` committed.
- [ ] Exact Piper invocation + voice id recorded in Results (provenance).
- [ ] Narrowed human-voice flag left open (this task does not close it).
