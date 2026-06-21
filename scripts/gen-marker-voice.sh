#!/usr/bin/env bash
# Generates the marker-voice clips in public/audio/ — a warm, spoken Norwegian
# "Bra!" for the BRA marker (the game's signature praise sound).
#
#   public/audio/mark-bra-perfect.wav   (PERFECT — brighter, slightly longer)
#   public/audio/mark-bra-ok.wav        (OK      — softer, snappier)
#
# Pipeline: espeak-ng (Norwegian Bokmål female voice) -> ffmpeg warming chain
# (trim silence, slight pitch lift, warmth/air EQ, vocal presence, gentle
# de-robotize via chorus + a tiny room, loudness-normalise, fades).
#
# WHY this is committed as an asset, not generated in CI: espeak-ng is a dev-only
# tool (not a project dependency); CI just serves the committed WAVs. This script
# is provenance + a one-command rebuild, mirroring scripts/gen-voice-placeholder.mjs.
#
# LICENSE / LIKENESS: the output is MACHINE-GENERATED TTS (espeak-ng), not a human
# voice recording and not an imitation of any identifiable person — so there is no
# personality/likeness exposure (cf. tech-decisions §4). Synthesized speech output
# is treated as license-clean / public-domain (espeak-ng claims no copyright over
# generated audio). It is an honest PLACEHOLDER: the real "sound like Maren" marker
# line stays the owner gate (§4) and drops into the same cue with no code change.
#
# Requires: espeak-ng + ffmpeg on PATH. If espeak-ng is not installable system-wide
# (no sudo), extract the .deb locally and point the env overrides at it:
#   apt-get download espeak-ng espeak-ng-data libespeak-ng1
#   for d in *.deb; do dpkg-deb -x "$d" ./espeak-root; done
#   ESPEAK_BIN=./espeak-root/usr/bin/espeak-ng \
#   ESPEAK_LIB=./espeak-root/usr/lib/x86_64-linux-gnu \
#   ESPEAK_DATA=./espeak-root/usr/lib/x86_64-linux-gnu/espeak-ng-data \
#   bash scripts/gen-marker-voice.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/public/audio"
mkdir -p "$OUT"

ESPEAK_BIN="${ESPEAK_BIN:-espeak-ng}"
ESPEAK_LIB="${ESPEAK_LIB:-}"
ESPEAK_DATA="${ESPEAK_DATA:-}"

say() {
  # espeak-ng can interfere with ffmpeg's nix glibc via LD_LIBRARY_PATH, so it gets
  # its own scoped lib/data path here and ffmpeg runs with LD_LIBRARY_PATH cleared.
  local args=("$@")
  if [[ -n "$ESPEAK_DATA" ]]; then args=(--path="$(dirname "$ESPEAK_DATA")" "${args[@]}"); fi
  LD_LIBRARY_PATH="$ESPEAK_LIB" "$ESPEAK_BIN" "${args[@]}"
}

ff() { env -u LD_LIBRARY_PATH ffmpeg -hide_banner -loglevel error "$@"; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Raw takes — Norwegian Bokmål, female variant, punchy and praising.
say -v "nb+f4" -s 165 -p 78 -w "$TMP/raw_perfect.wav" "Braa"
say -v "nb+f3" -s 175 -p 62 -w "$TMP/raw_ok.wav"      "Bra"

# Warming chain. `rate` slightly lifts pitch (a brighter, more encouraging lilt);
# the reverse/afade/reverse trick fades the tail without knowing its length.
warm() {
  local in="$1" out="$2" rate="$3"
  ff -i "$in" -af "\
silenceremove=start_periods=1:start_threshold=-45dB:detection=peak,\
areverse,silenceremove=start_periods=1:start_threshold=-45dB:detection=peak,areverse,\
asetrate=22050*${rate},aresample=44100,\
bass=g=3:f=170,treble=g=2.5:f=6500,equalizer=f=2700:t=q:w=1.3:g=3,\
chorus=0.7:0.9:55:0.3:0.25:2,aecho=0.85:0.9:14:0.16,\
afade=t=in:d=0.01,areverse,afade=t=in:d=0.05,areverse,\
loudnorm=I=-15:TP=-1.5:LRA=11,\
aformat=channel_layouts=mono" \
    -ar 44100 -ac 1 -sample_fmt s16 -y "$out"
}

warm "$TMP/raw_perfect.wav" "$OUT/mark-bra-perfect.wav" 1.06
warm "$TMP/raw_ok.wav"      "$OUT/mark-bra-ok.wav"      1.00

echo "Wrote:"
echo "  $OUT/mark-bra-perfect.wav"
echo "  $OUT/mark-bra-ok.wav"
