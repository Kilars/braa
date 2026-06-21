# FEATURE: Spoken Norwegian "Bra!" marker voice (replace synth chime)

**Status**: Done (2026-06-21)
**Created**: 2026-06-21 (owner request)
**Priority**: High
**Labels**: audio, feel, gap:marker-voice
**Estimated Effort**: Small-Medium

## Context & Motivation

The owner asked for "good sounds" and to **source real "Bra!" noises without blocking
on a human listen**. The §4a/task-116 placeholder was an abstract synthesized **chime**,
not the actual word — so the signature praise sound didn't read as "Bra!". The
clip-playback pipeline (074/116) already supports registered voice clips over the synth
fallback; only an asset and wiring were missing.

## What shipped

- **Real spoken Norwegian "Bra!"** marker clips, registered under the `PERFECT` and `OK`
  cues at bootstrap (off the tap path, rejection-safe):
  - `public/audio/mark-bra-perfect.wav` — PERFECT, brighter, ~0.67 s
  - `public/audio/mark-bra-ok.wav` — OK, softer/snappier, ~0.44 s
- **Reproducible generator** `scripts/gen-marker-voice.sh`: espeak-ng (Norwegian Bokmål
  female voice) → ffmpeg warming chain (trim silence, slight pitch lift, warmth/air EQ,
  vocal presence, gentle de-robotize via chorus + a tiny room, `loudnorm` ≈−16 LUFS, fades).
- **No-sudo toolchain note:** espeak-ng was installed by extracting the `.deb`s locally
  (`apt-get download` → `dpkg-deb -x`) — recorded so this isn't re-parked as "no TTS in env".
- Old chime asset removed; `main.ts` loads the two new cues; CREDITS + tech-decisions §4b updated.

## Verification

- Gate green: typecheck · tests (873) · build · e2e.
- Audio is not headless-verifiable (precedent 074/094/116). License/likeness is clean
  (machine-generated TTS — no human recording, no imitation of an identifiable person).
- **Still the owner gate:** the real "sound like Maren" line (§4) drops into the same cues
  with no code change. One non-blocking follow-up: an on-device listen to judge the robotic edge.
