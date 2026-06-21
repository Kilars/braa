// Generates public/audio/bra-placeholder.wav — a PLACEHOLDER marker-voice clip
// for task 116. It is a fully SYNTHESIZED, original tone (a warm two-segment
// "bra!"-like chime), NOT a voice recording. License-clean: no Maren likeness,
// no third-party sample. The real Maren marker line is the standing owner gate
// (tech-decisions §4) and drops into the same cue with no call-site change.
//
// Run: node scripts/gen-voice-placeholder.mjs
// Output: a small 16-bit mono PCM WAV the browser's decodeAudioData can read.

import { writeFileSync, mkdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const SAMPLE_RATE = 44100;
const DURATION_S = 0.42;
const total = Math.floor(SAMPLE_RATE * DURATION_S);

// Two pitched segments read as a friendly two-syllable "bra!": a lower body that
// lifts brighter on the tail. A light second harmonic gives it warmth; a fast
// attack + smooth release keeps it crisp and non-fatiguing under repeated marks.
const samples = new Float32Array(total);
for (let i = 0; i < total; i++) {
  const t = i / SAMPLE_RATE;
  const p = i / total; // 0..1 progress
  // Pitch glides up from ~330 Hz to ~470 Hz across the clip (the rising "-a!").
  const freq = 330 + 140 * p;
  const tone =
    Math.sin(2 * Math.PI * freq * t) +
    0.35 * Math.sin(2 * Math.PI * freq * 2 * t) +
    0.12 * Math.sin(2 * Math.PI * freq * 3 * t);
  // Amplitude envelope: 6 ms attack, gentle 70 ms release at the end.
  const attack = Math.min(1, t / 0.006);
  const release = Math.min(1, (DURATION_S - t) / 0.07);
  const env = Math.max(0, attack * release);
  samples[i] = 0.5 * env * tone;
}

// Normalize to avoid clipping from the summed harmonics, then to 16-bit PCM.
let peak = 0;
for (const s of samples) peak = Math.max(peak, Math.abs(s));
const norm = peak > 0 ? 0.89 / peak : 1;

const bytesPerSample = 2;
const dataSize = total * bytesPerSample;
const buf = Buffer.alloc(44 + dataSize);
// RIFF header
buf.write('RIFF', 0);
buf.writeUInt32LE(36 + dataSize, 4);
buf.write('WAVE', 8);
// fmt chunk
buf.write('fmt ', 12);
buf.writeUInt32LE(16, 16); // PCM chunk size
buf.writeUInt16LE(1, 20); // audio format = PCM
buf.writeUInt16LE(1, 22); // channels = mono
buf.writeUInt32LE(SAMPLE_RATE, 24);
buf.writeUInt32LE(SAMPLE_RATE * bytesPerSample, 28); // byte rate
buf.writeUInt16LE(bytesPerSample, 32); // block align
buf.writeUInt16LE(16, 34); // bits per sample
// data chunk
buf.write('data', 36);
buf.writeUInt32LE(dataSize, 40);
for (let i = 0; i < total; i++) {
  const v = Math.max(-1, Math.min(1, samples[i] * norm));
  buf.writeInt16LE(Math.round(v * 32767), 44 + i * bytesPerSample);
}

const here = dirname(fileURLToPath(import.meta.url));
const outDir = join(here, '..', 'public', 'audio');
mkdirSync(outDir, { recursive: true });
const outPath = join(outDir, 'bra-placeholder.wav');
writeFileSync(outPath, buf);
console.log(`wrote ${outPath} (${buf.length} bytes, ${DURATION_S}s mono 16-bit @ ${SAMPLE_RATE}Hz)`);
