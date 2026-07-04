#!/usr/bin/env bash
# Regenerate the Phase-5 marker-word voice cues (P5-1: "each new word has its own voiced line").
#
# The player unlocks alternative Norwegian marker words beyond base "bra" — dyktig, flink,
# super, kjempebra. Each is synthesized through the EXACT same neural pipeline as base "bra"
# (tools/gen_bra_voice.sh: Piper sv_SE-alma-medium, +3 dB high-shelf, peak-normalise -5 dBFS,
# mono 16-bit 22050 Hz) so all five clips share one timbre + loudness contract.
#
# The words are the same in Swedish and Norwegian (or near-identical) — alma (a Swedish female
# speaker) says each correctly while giving the bright/light female voice the owner asked for:
#   bra, dyktig, flink, super, kjempebra — all real Norwegian praise words.
#
# Filenames keep the "_placeholder" suffix on purpose: a neural synth is still a stand-in for
# the owner's warm HUMAN "Maren" recording, which drops in at these same paths with no code
# change (voice flag in .task-board/FLAGS.md — this script does NOT close it).
#
# Run inside the Nix devshell:  nix develop -c bash tools/gen_marker_words.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GEN="$ROOT/tools/gen_bra_voice.sh"

# id -> spoken sentence. Base "bra" already ships as bra_tts_placeholder.wav (gen_bra_voice.sh).
declare -A WORDS=(
  [dyktig]="Dyktig!"
  [flink]="Flink!"
  [super]="Super!"
  [kjempebra]="Kjempebra!"
)

for id in dyktig flink super kjempebra; do
  out="$ROOT/assets/audio/word_${id}_placeholder.wav"
  echo "=== ${id} -> ${out} ==="
  bash "$GEN" "$out" "${WORDS[$id]}"
done

echo "done -> 4 marker-word cues written under assets/audio/"
