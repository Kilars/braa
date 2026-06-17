import { describe, it, expect } from 'vitest';
import { soundForResult, masterySound, tapSound, ambientSpec, MarkAudio, markLayers, shouldUseClip } from './markAudio';
import type { MarkResult } from '../core/mark';

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
