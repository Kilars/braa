# Audio credits

## `bra-placeholder.wav` — PLACEHOLDER marker voice (task 116)

- **What it is:** a fully **synthesized, original** marker tone (a warm two-segment
  "bra!"-like chime) — **not a voice recording**. Generated programmatically by
  [`scripts/gen-voice-placeholder.mjs`](../../scripts/gen-voice-placeholder.mjs)
  (16-bit mono PCM WAV, ~0.42 s). No third-party sample, no captured voice.
- **License:** original synthesized output, treated as **CC0 / public-domain** — safe
  to commit and ship. Reproducible from the generator script.
- **Why it exists:** to prove the marker-voice **clip-playback pipeline** end-to-end
  (loader → phrase-keyed cue selection → buffered playback over the synth fallback).
  It is registered under the `PERFECT` cue at bootstrap so a perfect mark voices it.
- **To be replaced by:** the real **Maren marker recording** — an owner/likeness-gated
  asset (see [`tech-decisions.md` §4](../../.docs/tech-decisions.md)) that **cannot be
  produced autonomously**. It is a **drop-in**: register the real clip under the same
  cue (or per-phrase `voice:<id>` keys) with **no call-site change**. This placeholder
  is explicitly **not** the final voice; do not ship it as Maren's line.
