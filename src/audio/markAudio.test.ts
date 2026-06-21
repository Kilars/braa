import { describe, it, expect } from 'vitest';
import { soundForResult, masterySound, tapSound, ambientSpec, MarkAudio, markLayers, shouldUseClip, foleyLayers, ambientLayers, voiceCue, selectVoiceClip } from './markAudio';
import type { MarkResult } from '../core/mark';
import type { DogFoleyEvent } from './markAudio';

describe('soundForResult', () => {
  it('returns a SoundSpec for PERFECT', () => {
    const spec = soundForResult('PERFECT');
    expect(spec).toMatchObject({
      freq: expect.any(Number),
      durationMs: expect.any(Number),
      type: expect.any(String),
      gain: expect.any(Number),
    });
  });

  it('PERFECT is brighter than OK (higher freq AND higher gain)', () => {
    const perfect = soundForResult('PERFECT');
    const ok = soundForResult('OK');
    expect(perfect.freq).toBeGreaterThan(ok.freq);
    expect(perfect.gain).toBeGreaterThan(ok.gain);
  });

  it('FALSE_MARK is the lowest freq of all results (negative/dull blip)', () => {
    const falseMark = soundForResult('FALSE_MARK');
    const perfect = soundForResult('PERFECT');
    const ok = soundForResult('OK');
    const miss = soundForResult('MISS');
    expect(falseMark.freq).toBeLessThan(perfect.freq);
    expect(falseMark.freq).toBeLessThan(ok.freq);
    expect(falseMark.freq).toBeLessThan(miss.freq);
  });

  it('FALSE_MARK is clearly distinct from PERFECT (freq at least 4x lower)', () => {
    const falseMark = soundForResult('FALSE_MARK');
    const perfect = soundForResult('PERFECT');
    expect(perfect.freq / falseMark.freq).toBeGreaterThanOrEqual(4);
  });

  it('MISS is the quietest result (lowest gain of all four)', () => {
    const miss = soundForResult('MISS');
    const perfect = soundForResult('PERFECT');
    const ok = soundForResult('OK');
    const falseMark = soundForResult('FALSE_MARK');
    expect(miss.gain).toBeLessThan(perfect.gain);
    expect(miss.gain).toBeLessThan(ok.gain);
    expect(miss.gain).toBeLessThan(falseMark.gain);
  });

  it('is deterministic — same MarkResult returns identical SoundSpec each call', () => {
    const results: MarkResult[] = ['PERFECT', 'OK', 'MISS', 'FALSE_MARK'];
    for (const result of results) {
      const first = soundForResult(result);
      const second = soundForResult(result);
      expect(first).toEqual(second);
    }
  });
});

// ─── masterySound ────────────────────────────────────────────────────────────

describe('masterySound', () => {
  it('returns an array of at least 3 notes', () => {
    expect(masterySound().length).toBeGreaterThanOrEqual(3);
  });

  it('has strictly ascending frequencies (arpeggio goes up)', () => {
    const notes = masterySound();
    for (let i = 1; i < notes.length; i++) {
      expect(notes[i].freq).toBeGreaterThan(notes[i - 1].freq);
    }
  });

  it('all gains are finite and positive', () => {
    const notes = masterySound();
    for (const note of notes) {
      expect(Number.isFinite(note.gain)).toBe(true);
      expect(note.gain).toBeGreaterThan(0);
    }
  });

  it('is deterministic — same result on repeated calls', () => {
    expect(masterySound()).toEqual(masterySound());
  });
});

// ─── tapSound ────────────────────────────────────────────────────────────────

describe('tapSound', () => {
  it('returns a low-gain, short-duration click spec (gain < 0.2, durationMs ≤ 60)', () => {
    const spec = tapSound();
    expect(spec.gain).toBeLessThan(0.2);
    expect(spec.durationMs).toBeLessThanOrEqual(60);
  });

  it('is deterministic — same result on repeated calls', () => {
    expect(tapSound()).toEqual(tapSound());
  });
});

// ─── ambientSpec ─────────────────────────────────────────────────────────────

describe('ambientSpec', () => {
  it('returns a low-freq (120–220 Hz) spec', () => {
    const spec = ambientSpec();
    expect(spec.freq).toBeGreaterThanOrEqual(120);
    expect(spec.freq).toBeLessThanOrEqual(220);
  });

  it('returns a low-gain (0.03–0.06) spec', () => {
    const spec = ambientSpec();
    expect(spec.gain).toBeGreaterThanOrEqual(0.03);
    expect(spec.gain).toBeLessThanOrEqual(0.06);
  });

  it('uses sine or triangle wave type', () => {
    const spec = ambientSpec();
    expect(['sine', 'triangle']).toContain(spec.type);
  });

  it('is deterministic — same result on repeated calls', () => {
    expect(ambientSpec()).toEqual(ambientSpec());
  });
});

// ─── MarkAudio ambient ───────────────────────────────────────────────────────

describe('MarkAudio — ambient', () => {
  it('stopAmbient() does not throw when ambient was never started (idempotent)', () => {
    const audio = new MarkAudio();
    expect(() => audio.stopAmbient()).not.toThrow();
  });

  it('setMuted(true) stops a running ambient — subsequent stopAmbient() is still idempotent', () => {
    const audio = new MarkAudio();
    // startAmbient() in Node won't create a real oscillator (no AudioContext),
    // but _ambientStarted is set and the guard flow is exercised.
    audio.startAmbient();
    // Now mute — must call stopAmbient() internally
    audio.setMuted(true);
    expect(audio.isMuted()).toBe(true);
    // Calling stopAmbient() again must not throw (idempotent)
    expect(() => audio.stopAmbient()).not.toThrow();
  });

  it('startAmbient() while muted does not activate the ambient (isMuted() guard)', () => {
    const audio = new MarkAudio();
    audio.setMuted(true);
    audio.startAmbient();
    // In Node (no AudioContext), ambient stays off regardless; AND with muted=true
    // the guard must return early before touching WebAudio.
    // Observable: isMuted() remains true and startAmbient returned without throwing.
    expect(audio.isMuted()).toBe(true);
    expect(() => audio.stopAmbient()).not.toThrow(); // idempotent — nothing to stop
  });
});

// ─── MarkAudio muted flag ────────────────────────────────────────────────────

describe('MarkAudio — muted flag', () => {
  it('isMuted() returns false by default', () => {
    const audio = new MarkAudio();
    expect(audio.isMuted()).toBe(false);
  });

  it('setMuted(true) makes isMuted() return true', () => {
    const audio = new MarkAudio();
    audio.setMuted(true);
    expect(audio.isMuted()).toBe(true);
  });

  it('setMuted(false) after setMuted(true) makes isMuted() false again', () => {
    const audio = new MarkAudio();
    audio.setMuted(true);
    audio.setMuted(false);
    expect(audio.isMuted()).toBe(false);
  });

  it('play() while muted does not throw (no AudioContext in Node)', () => {
    const audio = new MarkAudio();
    audio.setMuted(true);
    // Should return early before touching AudioContext
    expect(() => audio.play('PERFECT')).not.toThrow();
  });
});

// ─── markLayers ──────────────────────────────────────────────────────────────

describe('markLayers', () => {
  it('PERFECT returns at least 2 layers; first layer is a short click (durationMs <= 30)', () => {
    const layers = markLayers('PERFECT');
    expect(layers.length).toBeGreaterThanOrEqual(2);
    expect(layers[0].durationMs).toBeLessThanOrEqual(30);
  });

  it('PERFECT has a later layer that is a praise tone (durationMs >= 100)', () => {
    const layers = markLayers('PERFECT');
    // At least one layer after the click must have durationMs >= 100
    const hasPraiseTone = layers.slice(1).some(layer => layer.durationMs >= 100);
    expect(hasPraiseTone).toBe(true);
  });

  it("PERFECT's praise tone layer has higher gain than OK's praise tone layer (punchier on better marks)", () => {
    const perfectLayers = markLayers('PERFECT');
    const okLayers = markLayers('OK');
    // Find praise tone layers (durationMs >= 100)
    const perfectPraise = perfectLayers.find(layer => layer.durationMs >= 100);
    const okPraise = okLayers.find(layer => layer.durationMs >= 100);
    expect(perfectPraise).toBeDefined();
    expect(okPraise).toBeDefined();
    expect(perfectPraise!.gain).toBeGreaterThan(okPraise!.gain);
  });

  it('FALSE_MARK is a distinct low cue (differs in type or has freq < 300 vs success cues)', () => {
    const falseMarkLayers = markLayers('FALSE_MARK');
    const perfectLayers = markLayers('PERFECT');
    const okLayers = markLayers('OK');

    const falseMark = falseMarkLayers[0];
    const perfectFirst = perfectLayers[0];
    const okFirst = okLayers[0];

    // Assert FALSE_MARK differs in type OR has significantly lower frequency
    const differsInType = falseMark.type !== perfectFirst.type || falseMark.type !== okFirst.type;
    const hasLowFreq = falseMark.freq < 300;
    expect(differsInType || hasLowFreq).toBe(true);
  });
});

// ─── shouldUseClip ───────────────────────────────────────────────────────────

describe('shouldUseClip', () => {
  it('returns false for an empty registry (synthesize when no clip registered)', () => {
    const emptyRegistry = new Map<string, AudioBuffer>();
    const result = shouldUseClip('PERFECT', emptyRegistry);
    expect(result).toBe(false);
  });

  it('returns true only when registry has a clip for that exact cue', () => {
    // Create a registry with PERFECT but not OK
    const registry = new Map<string, AudioBuffer>();
    registry.set('PERFECT', {} as unknown as AudioBuffer);

    expect(shouldUseClip('PERFECT', registry)).toBe(true);
  });

  it('returns false for a queried cue when a different cue is registered (not the queried one)', () => {
    // Register PERFECT but query for OK
    const registry = new Map<string, AudioBuffer>();
    registry.set('PERFECT', {} as unknown as AudioBuffer);

    expect(shouldUseClip('OK', registry)).toBe(false);
  });
});

// ─── foleyLayers ─────────────────────────────────────────────────────────────

describe('foleyLayers', () => {
  it('foleyLayers(\'mastery-bark\') returns a non-empty array; every layer has freq in canine range (>= 150 and <= 1200), durationMs <= 400, and gain > 0 and <= 0.5', () => {
    const layers = foleyLayers('mastery-bark');
    expect(layers.length).toBeGreaterThan(0);
    for (const layer of layers) {
      expect(layer.freq).toBeGreaterThanOrEqual(150);
      expect(layer.freq).toBeLessThanOrEqual(1200);
      expect(layer.durationMs).toBeLessThanOrEqual(400);
      expect(layer.gain).toBeGreaterThan(0);
      expect(layer.gain).toBeLessThanOrEqual(0.5);
    }
  });

  it('the three events produce distinct signatures — idle-pant, mastery-bark, and false-huff are pairwise NOT deep-equal', () => {
    const pant = foleyLayers('idle-pant');
    const bark = foleyLayers('mastery-bark');
    const huff = foleyLayers('false-huff');

    expect(pant).not.toEqual(bark);
    expect(bark).not.toEqual(huff);
    expect(pant).not.toEqual(huff);
  });

  it('false-huff is low + short while mastery-bark is brighter + longer: huff first-layer freq < bark first-layer freq AND huff total duration < bark total duration; also huff first-layer freq <= 220 and huff total duration <= 100', () => {
    const huff = foleyLayers('false-huff');
    const bark = foleyLayers('mastery-bark');

    const huffFirstFreq = huff[0].freq;
    const barkFirstFreq = bark[0].freq;
    const huffTotalDuration = huff.reduce((sum, layer) => sum + layer.durationMs, 0);
    const barkTotalDuration = bark.reduce((sum, layer) => sum + layer.durationMs, 0);

    expect(huffFirstFreq).toBeLessThan(barkFirstFreq);
    expect(huffTotalDuration).toBeLessThan(barkTotalDuration);
    expect(huffFirstFreq).toBeLessThanOrEqual(220);
    expect(huffTotalDuration).toBeLessThanOrEqual(100);
  });

  it('annoyance budget: across all three events, every layer gain is < 0.5 (foley never as loud as the PERFECT praise tone, gain 0.9)', () => {
    const pant = foleyLayers('idle-pant');
    const bark = foleyLayers('mastery-bark');
    const huff = foleyLayers('false-huff');
    const allLayers = [...pant, ...bark, ...huff];

    for (const layer of allLayers) {
      expect(layer.gain).toBeLessThan(0.5);
    }
  });

  it('deterministic — foleyLayers(e) deep-equals itself on repeated calls for each event', () => {
    const events: Array<'idle-pant' | 'mastery-bark' | 'false-huff'> = ['idle-pant', 'mastery-bark', 'false-huff'];
    for (const event of events) {
      const first = foleyLayers(event);
      const second = foleyLayers(event);
      expect(first).toEqual(second);
    }
  });
});

// ─── ambientLayers ───────────────────────────────────────────────────────────

describe('ambientLayers', () => {
  it('returns an array of length >= 2', () => {
    const layers = ambientLayers();
    expect(layers.length).toBeGreaterThanOrEqual(2);
  });

  it('not every layer shares the same freq (at least two distinct freqs — a detuned/fuller bed, not a lone drone)', () => {
    const layers = ambientLayers();
    const distinctFreqs = new Set(layers.map(l => l.freq));
    expect(distinctFreqs.size).toBeGreaterThanOrEqual(2);
  });

  it('every layer freq is within 120..260, every layer gain <= 0.06, and the SUM of all gains is <= 0.12 (stays quiet)', () => {
    const layers = ambientLayers();
    let gainSum = 0;
    for (const layer of layers) {
      expect(layer.freq).toBeGreaterThanOrEqual(120);
      expect(layer.freq).toBeLessThanOrEqual(260);
      expect(layer.gain).toBeLessThanOrEqual(0.06);
      gainSum += layer.gain;
    }
    expect(gainSum).toBeLessThanOrEqual(0.12);
  });

  it('every layer type is \'sine\' or \'triangle\'', () => {
    const layers = ambientLayers();
    for (const layer of layers) {
      expect(['sine', 'triangle']).toContain(layer.type);
    }
  });

  it('deterministic — deep-equals itself on repeat', () => {
    const first = ambientLayers();
    const second = ambientLayers();
    expect(first).toEqual(second);
  });

  it('back-compat: ambientSpec() deep-equals ambientLayers()[0]', () => {
    const spec = ambientSpec();
    const firstLayer = ambientLayers()[0];
    expect(spec).toEqual(firstLayer);
  });
});

// ─── voiceCue — phrase-keyed cue selection (task 116) ────────────────────────
// Pure cue-key derivation: a phrase voices its own line when one is registered;
// otherwise the mark falls back to the result-tier key (and then synth).

describe('voiceCue', () => {
  it('returns the result-tier key when no phraseId is given', () => {
    expect(voiceCue('PERFECT')).toBe('PERFECT');
  });

  it('returns a phrase-specific key when a phraseId is given', () => {
    expect(voiceCue('PERFECT', 'flink')).toBe('voice:flink');
  });

  it('keys by phrase regardless of result tier (the phrase voices the line, not the tier)', () => {
    expect(voiceCue('OK', 'super')).toBe('voice:super');
  });
});

// ─── selectVoiceClip — phrase clip → tier clip → synth (task 116) ─────────────
// The play-site decision, made pure + registry-aware: prefer a registered phrase
// clip, else a registered result-tier clip, else null (caller synthesizes).

describe('selectVoiceClip', () => {
  const buf = {} as unknown as AudioBuffer;

  it('returns null when nothing is registered (the mark synthesizes)', () => {
    const registry = new Map<string, AudioBuffer>();
    expect(selectVoiceClip('PERFECT', undefined, registry)).toBeNull();
  });

  it('returns the result-tier cue when a tier clip is registered and there is no phrase', () => {
    const registry = new Map<string, AudioBuffer>([['PERFECT', buf]]);
    expect(selectVoiceClip('PERFECT', undefined, registry)).toBe('PERFECT');
  });

  it('returns the phrase cue when a phrase clip is registered', () => {
    const registry = new Map<string, AudioBuffer>([['voice:flink', buf]]);
    expect(selectVoiceClip('PERFECT', 'flink', registry)).toBe('voice:flink');
  });

  it('prefers the phrase clip over the tier clip when both are registered', () => {
    const registry = new Map<string, AudioBuffer>([
      ['voice:flink', buf],
      ['PERFECT', buf],
    ]);
    expect(selectVoiceClip('PERFECT', 'flink', registry)).toBe('voice:flink');
  });

  it('falls back to the tier clip when the phrase has no registered clip', () => {
    const registry = new Map<string, AudioBuffer>([['PERFECT', buf]]);
    expect(selectVoiceClip('PERFECT', 'flink', registry)).toBe('PERFECT');
  });
});

// ─── MarkAudio — clip registry + loader (task 116) ───────────────────────────
// The voiced-mark path: a registered clip is preferred over synth. The loader is
// rejection-safe — a load that can't complete leaves the registry untouched so the
// mark stays on the existing synth (no throw, app unaffected).

describe('MarkAudio — clip registry + loader', () => {
  // A real AudioBuffer needs a browser AudioContext; the registry only stores +
  // looks up by key, so a stand-in buffer is enough to exercise the seam.
  const fakeBuffer = {} as unknown as AudioBuffer;

  it('a fresh instance has no clip registered for a cue', () => {
    const audio = new MarkAudio();
    expect(audio.hasClip('PERFECT')).toBe(false);
  });

  it('a registered clip is observable for its cue (the voiced path is selectable)', () => {
    const audio = new MarkAudio();
    audio.registerClip('PERFECT', fakeBuffer);
    expect(audio.hasClip('PERFECT')).toBe(true);
  });

  it('loadClip that cannot complete leaves the registry untouched (mark stays synth)', async () => {
    // In the Node test env AudioContext is undefined, so the load cannot decode;
    // loadClip must reject/bail GRACEFULLY — no throw, nothing registered.
    const audio = new MarkAudio();
    await expect(audio.loadClip('PERFECT', '/audio/mark-bra-perfect.wav')).resolves.toBeUndefined();
    expect(audio.hasClip('PERFECT')).toBe(false);
  });

  it('loadClip with a failing fetch URL does not throw and registers nothing', async () => {
    const audio = new MarkAudio();
    await expect(
      audio.loadClip('voice:flink', 'http://127.0.0.1:0/nonexistent.wav'),
    ).resolves.toBeUndefined();
    expect(audio.hasClip('voice:flink')).toBe(false);
  });

  it('play(result, phraseId) is headless-safe — no throw muted or with AudioContext undefined', () => {
    const muted = new MarkAudio();
    muted.setMuted(true);
    expect(() => muted.play('PERFECT', 'flink')).not.toThrow();
    const live = new MarkAudio();
    expect(() => live.play('PERFECT', 'flink')).not.toThrow();
  });
});

// ─── MarkAudio — foley ───────────────────────────────────────────────────────

describe('MarkAudio — foley', () => {
  it('playFoley(\'mastery-bark\') on a MUTED instance does not throw', () => {
    const audio = new MarkAudio();
    audio.setMuted(true);
    expect(() => audio.playFoley('mastery-bark')).not.toThrow();
  });

  it('playFoley(\'idle-pant\') on a default (unmuted) instance does not throw in Node (AudioContext undefined → guarded)', () => {
    const audio = new MarkAudio();
    expect(audio.isMuted()).toBe(false);
    expect(() => audio.playFoley('idle-pant')).not.toThrow();
  });
});
