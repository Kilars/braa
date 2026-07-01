#!/usr/bin/env bash
# Regenerate the spoken "Bra!" mark-payoff cue at assets/audio/bra_tts_placeholder.wav.
#
# Task 060 (P1-6 owner directive, 2026-07-01): a BRIGHT, LIGHT, FEMALE voice. The cue is
# a native-Swedish Piper neural voice — "bra" is the same word, same meaning, near-identical
# /brɑː/ pronunciation in Swedish as in Norwegian, so a Swedish female speaker says the cue
# correctly while giving the brighter/lighter female timbre the owner asked for. Fully
# offline + no owner action (X-7-safe: this bakes a static .wav at authoring time; the game
# runtime never touches the network). Supersedes task 044's neutral no_NO male-ish voice.
#
# Voice: sv_SE-alma-medium (rhasspy/piper-voices) — single female speaker, 22050 Hz native.
#   Measured "Bra!": f0 ~227 Hz (female), spectral centroid ~1030 Hz — vs the 044 NO clip's
#   f0 149 Hz / centroid 811 Hz. Auditioned against sv_SE-lisa (f0 208) and sv_SE-nst (MALE,
#   f0 90) — alma was the brightest + clearly female (see task 060 Results for the sweep).
#
# The filename keeps its "placeholder" name on purpose: a neural synth is still a stand-in
# for the owner's warm HUMAN "Maren" recording, which drops in at this same path with no
# code change (narrowed voice flag in .task-board/FLAGS.md — this script does NOT close it).
#
# Run inside the Nix devshell:  nix develop -c bash tools/gen_bra_voice.sh
set -euo pipefail

VOICE=sv_SE-alma-medium
VOICE_PATH=sv/sv_SE/alma/medium              # path within the piper-voices HF repo
LENGTH_SCALE=1.0                             # snappy single word (~0.5 s pre-trim)
SHELF_DB=3.0                                 # gentle +3 dB high-shelf @ 3.5 kHz — "brighter"
TARGET_PEAK_DBFS=-5.0                        # match the 044/espeak headroom (loudness contract)
MIX_RATE=22050                               # == PayoffPlayer.MIX_RATE — no resample artefacts

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${1:-$ROOT/assets/audio/bra_tts_placeholder.wav}"
CACHE="${TMPDIR:-/tmp}/bra_voice_cache"
mkdir -p "$CACHE"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

BASE=https://huggingface.co/rhasspy/piper-voices/resolve/main

# 1. Fetch the voice model (cached across runs; ~61 MB onnx + json). env -u LD_LIBRARY_PATH
#    dodges the devshell glibc clash that otherwise kills nix-provided binaries locally.
for ext in onnx onnx.json; do
  if [ ! -s "$CACHE/$VOICE.$ext" ]; then
    echo "fetching $VOICE.$ext ..."
    env -u LD_LIBRARY_PATH curl -fsSL -o "$CACHE/$VOICE.$ext" "$BASE/$VOICE_PATH/$VOICE.$ext"
  fi
done

# 2. Synth "Bra!" (Piper emits 16-bit mono 22050 Hz natively).
echo "rendering Bra! from $VOICE ..."
env -u LD_LIBRARY_PATH nix shell nixpkgs#piper-tts -c bash -c \
  "echo 'Bra!' | piper -m '$CACHE/$VOICE.onnx' --length-scale $LENGTH_SCALE --sentence-silence 0.0 -f '$WORK/raw.wav'" \
  >/dev/null 2>&1

# 3. Post: trim silence (keep 20 ms pre / 60 ms tail), +3 dB high-shelf brighten,
#    5 ms/15 ms declick fades, peak-normalise to -5 dBFS. Pure stdlib wave + numpy.
echo "post-processing ..."
env -u LD_LIBRARY_PATH python3 - "$WORK/raw.wav" "$OUT" "$MIX_RATE" "$SHELF_DB" "$TARGET_PEAK_DBFS" <<'PY'
import sys, wave, numpy as np
inp, outp, SR, SHELF_DB, PEAK_DB = sys.argv[1], sys.argv[2], int(sys.argv[3]), float(sys.argv[4]), float(sys.argv[5])
w = wave.open(inp, 'rb'); ch = w.getnchannels(); sr = w.getframerate()
d = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16).astype(np.float64) / 32768.0
if ch > 1: d = d.reshape(-1, ch).mean(axis=1)
assert sr == SR, f"expected {SR} Hz from piper, got {sr}"
# trim to the voiced span at -45 dBFS of peak, keeping a little air either side
thr = np.abs(d).max() * (10 ** (-45 / 20))
idx = np.where(np.abs(d) > thr)[0]
s = max(0, idx[0] - int(0.02 * SR)); e = min(len(d), idx[-1] + int(0.06 * SR)); d = d[s:e]
# RBJ high-shelf brighten @ 3.5 kHz
A = 10 ** (SHELF_DB / 40.0); w0 = 2 * np.pi * 3500.0 / SR; cw = np.cos(w0); sw = np.sin(w0)
alpha = sw / (2 * 0.707); tsa = 2 * np.sqrt(A) * alpha
b = np.array([A * ((A+1)+(A-1)*cw+tsa), -2*A*((A-1)+(A+1)*cw), A*((A+1)+(A-1)*cw-tsa)])
a = np.array([(A+1)-(A-1)*cw+tsa, 2*((A-1)-(A+1)*cw), (A+1)-(A-1)*cw-tsa])
b /= a[0]; a = a / a[0]
y = np.zeros_like(d); x1 = x2 = y1 = y2 = 0.0
for i, xi in enumerate(d):
    yi = b[0]*xi + b[1]*x1 + b[2]*x2 - a[1]*y1 - a[2]*y2
    x2, x1 = x1, xi; y2, y1 = y1, yi; y[i] = yi
d = y
# declick fades + peak-normalise
fi, fo = int(0.005 * SR), int(0.015 * SR)
d[:fi] *= np.linspace(0, 1, fi); d[-fo:] *= np.linspace(1, 0, fo)
peak = np.abs(d).max()
if peak > 0: d *= (10 ** (PEAK_DB / 20)) / peak
w2 = wave.open(outp, 'wb'); w2.setnchannels(1); w2.setsampwidth(2); w2.setframerate(SR)
w2.writeframes((np.clip(d, -1, 1) * 32767).astype('<i2').tobytes()); w2.close()
print(f"wrote {outp}: {len(d)/SR:.3f}s mono 16-bit {SR} Hz")
PY

echo "done -> $OUT"
