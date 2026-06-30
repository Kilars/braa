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

- [x] `assets/audio/bra_tts_placeholder.wav` is a Piper neural "Bra!", mono/16-bit/22050 Hz.
- [x] No GDScript change; `test_voice_is_the_real_spoken_asset_when_present` still green.
- [x] Gate intact: silent on MISS/dead; PERFECT louder + slightly higher than OK.
- [x] `verify.sh` green; `.wav` committed (`.import` sidecar byte-identical — see Results).
- [x] Exact Piper invocation + voice id recorded in Results (provenance).
- [x] Narrowed human-voice flag left open (this task does not close it).

## Results (2026-06-30)

**What shipped:** the espeak-ng robotic clip at `assets/audio/bra_tts_placeholder.wav` is
replaced by a **Piper local-neural** "Bra!" — warm, single-speaker Norwegian Bokmål. Same
path, same cue id → **zero GDScript change** (`payoff_player.gd:27` `VOICE_ASSET` unchanged),
123/123 tests green incl. `test_voice_is_the_real_spoken_asset_when_present`, verify gate green
(import · boot · test · export).

**Voice model:** `no_NO-talesyntese-medium` (the Norwegian Bokmål voices live under `no_NO`,
NOT `nb_NO`) from **rhasspy/piper-voices** (HuggingFace), file
`no/no_NO/talesyntese/medium/no_NO-talesyntese-medium.onnx` (+ `.onnx.json`). Config:
`sample_rate 22050` (== `PayoffPlayer.MIX_RATE`, no resample), `num_speakers 1`, dataset
`talesyntese` (Norwegian NST corpus). Authoring-time download only — **X-7-safe** (runtime
still plays a static `.wav`, never hits the network).

**Provenance (pinned, mirrors task 035's espeak line):**
```sh
# 1. fetch the voice model (HuggingFace, ~63 MB onnx)
curl -fsSL -o no_NO-talesyntese-medium.onnx{,.json} \
  https://huggingface.co/rhasspy/piper-voices/resolve/main/no/no_NO/talesyntese/medium/no_NO-talesyntese-medium.onnx{,.json}
# 2. synth (Piper 1.4.2 emits 16-bit mono 22050 Hz natively)
nix shell nixpkgs#piper-tts -c sh -c \
  'echo "Bra!" | piper -m no_NO-talesyntese-medium.onnx --length-scale 1.3 --sentence-silence 0.0 -f bra_ls1.3.wav'
# 3. post (stdlib `wave`, no extra deps): trim silence (keep 20 ms pre-roll, 60 ms tail),
#    5 ms fade-in + 15 ms fade-out (declick), peak-normalize to -5 dBFS to MATCH the espeak
#    headroom (so the swap changes timbre, not loudness; avoids clipping under the layered click).
```
Final clip: **0.479 s, mono 16-bit 22050 Hz, peak -5.0 dBFS (RMS 3857), 21172 bytes.** The old
espeak clip (0.827 s, peak -5.1 dBFS, RMS 2073) is recoverable from git history (parent of this
commit); the Piper clip is audibly warmer/fuller at the same headroom (an on-device listen still
rides the human-voice flag).

**`.import` note:** the sidecar is **byte-identical** after re-import — its
`.godot/imported/…sample` filename hashes the import *params* (`compress/mode=2`, etc.), not the
source bytes. The regenerated `.sample` lives under gitignored `.godot/` and CI reproduces it via
`godot --import` from the committed `.wav` + unchanged `.import` (the export verify leg confirms
the new bytes ride the Web export). So there is nothing new to commit for `.import`.

**Flag:** the narrowed human-voice flag stays **open** — this closes *robotic → warm-neural*,
not *synthetic → human Maren*. FLAGS.md "Assumption" updated to note 044's Piper voice has landed.
