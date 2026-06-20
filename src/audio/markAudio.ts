import type { MarkResult } from '../core/mark';

// SoundSpec is pure data — no WebAudio imports here.
export interface SoundSpec {
  freq: number;
  durationMs: number;
  type: OscillatorType;
  gain: number;
}

export function soundForResult(result: MarkResult): SoundSpec {
  switch (result) {
    case 'PERFECT':
      return { freq: 880, durationMs: 200, type: 'sine', gain: 0.9 };
    case 'OK':
      return { freq: 660, durationMs: 150, type: 'sine', gain: 0.6 };
    case 'MISS':
      return { freq: 440, durationMs: 100, type: 'sine', gain: 0.15 };
    case 'FALSE_MARK':
      return { freq: 180, durationMs: 80, type: 'sawtooth', gain: 0.5 };
  }
}

// A mark = a crisp click transient layered under a short praise tone.
// Click: short high-freq square burst (≈12 ms) — the tactile "tick".
// Praise tone: brief sine ping tuned per result quality.
// MISS: click only, at low gain (subtle).
// FALSE_MARK: distinct low sawtooth (no click/praise — a dull negative buzz).
export function markLayers(result: MarkResult): SoundSpec[] {
  const click: SoundSpec = { freq: 2000, durationMs: 12, type: 'square', gain: 0.35 };
  switch (result) {
    case 'PERFECT':
      return [click, { freq: 880, durationMs: 140, type: 'sine', gain: 0.9 }];
    case 'OK':
      return [click, { freq: 660, durationMs: 120, type: 'sine', gain: 0.5 }];
    case 'MISS':
      return [{ ...click, gain: 0.12 }];
    case 'FALSE_MARK':
      return [{ freq: 180, durationMs: 90, type: 'sawtooth', gain: 0.5 }];
  }
}

/** True when a clip is registered for this cue; otherwise the caller synthesizes. */
export function shouldUseClip(cue: string, registry: ReadonlyMap<string, AudioBuffer>): boolean {
  return registry.has(cue);
}

export function masterySound(): SoundSpec[] {
  return [
    { freq: 523, durationMs: 120, type: 'sine', gain: 0.5 },
    { freq: 659, durationMs: 120, type: 'sine', gain: 0.5 },
    { freq: 784, durationMs: 200, type: 'sine', gain: 0.6 },
  ];
}

export function tapSound(): SoundSpec {
  return { freq: 600, durationMs: 40, type: 'sine', gain: 0.08 };
}

// ambientSpec: pure data — no WebAudio/DOM. A low, quiet pad for looping.
// Returns the primary partial of the ambient bed (back-compat: same as ambientLayers()[0]).
export function ambientSpec(): SoundSpec {
  return ambientLayers()[0];
}

export type DogFoleyEvent = 'idle-pant' | 'mastery-bark' | 'false-huff';

// Synthesised dog foley — subtle, gains well under the mark SFX (PERFECT praise = 0.9)
// so it never masks the praise tone. Layers are played sequentially (like masterySound).
export function foleyLayers(event: DogFoleyEvent): SoundSpec[] {
  switch (event) {
    case 'idle-pant': // two soft breath puffs (in/out) — barely there
      return [
        { freq: 300, durationMs: 70, type: 'sine', gain: 0.04 },
        { freq: 340, durationMs: 60, type: 'sine', gain: 0.03 },
      ];
    case 'mastery-bark': // bright, longer two-syllable happy bark
      return [
        { freq: 520, durationMs: 90, type: 'triangle', gain: 0.22 },
        { freq: 430, durationMs: 110, type: 'triangle', gain: 0.18 },
      ];
    case 'false-huff': // single low, short disappointed huff
      return [{ freq: 170, durationMs: 70, type: 'sine', gain: 0.12 }];
  }
}

// Ambient bed = a few low detuned partials (a ~3 Hz beat shimmer + a soft fifth for body),
// not a lone drone. Still quiet (sum of gains well under 0.12) and lazy/mute-aware at play time.
export function ambientLayers(): SoundSpec[] {
  return [
    { freq: 160, durationMs: 0, type: 'sine', gain: 0.04 },
    { freq: 163, durationMs: 0, type: 'sine', gain: 0.03 },
    { freq: 240, durationMs: 0, type: 'triangle', gain: 0.025 },
  ];
}

// MarkAudio is a thin side-effect wrapper. AudioContext is only touched inside
// play() so importing this module in Node (tests) does not crash.
export class MarkAudio {
  private ctx: AudioContext | null = null;
  private _muted = false;
  private _ambientOn = false;
  private _ambientStarted = false;
  private _ambientOscs: OscillatorNode[] = [];
  private clips = new Map<string, AudioBuffer>();

  registerClip(cue: string, buffer: AudioBuffer): void {
    this.clips.set(cue, buffer);
  }

  isMuted(): boolean {
    return this._muted;
  }

  setMuted(muted: boolean): void {
    this._muted = muted;
    if (muted) {
      this.stopAmbient();
    } else if (this._ambientStarted) {
      this.startAmbient();
    }
  }

  private ensureCtx(): AudioContext | null {
    if (typeof AudioContext === 'undefined') return null;
    if (!this.ctx) {
      this.ctx = new AudioContext();
    } else if (this.ctx.state === 'suspended') {
      void this.ctx.resume();
    }
    return this.ctx;
  }

  private playSpec(ctx: AudioContext, spec: SoundSpec, startAt: number): void {
    const { freq, durationMs, type, gain } = spec;
    const durationSec = durationMs / 1000;

    const osc = ctx.createOscillator();
    const gainNode = ctx.createGain();

    osc.type = type;
    osc.frequency.setValueAtTime(freq, startAt);

    gainNode.gain.setValueAtTime(gain, startAt);
    gainNode.gain.linearRampToValueAtTime(0, startAt + durationSec);

    osc.connect(gainNode);
    gainNode.connect(ctx.destination);

    osc.start(startAt);
    osc.stop(startAt + durationSec);
  }

  private playBuffer(ctx: AudioContext, buffer: AudioBuffer): void {
    const source = ctx.createBufferSource();
    const gainNode = ctx.createGain();
    source.buffer = buffer;
    gainNode.gain.setValueAtTime(1, ctx.currentTime);
    source.connect(gainNode);
    gainNode.connect(ctx.destination);
    source.start(ctx.currentTime);
  }

  play(result: MarkResult): void {
    if (this._muted) return;
    try {
      const ctx = this.ensureCtx();
      if (!ctx) return;
      if (shouldUseClip(result, this.clips)) {
        this.playBuffer(ctx, this.clips.get(result)!);
        return;
      }
      for (const layer of markLayers(result)) {
        this.playSpec(ctx, layer, ctx.currentTime);
      }
    } catch {
      // Guard: AudioContext unavailable or suspended — silent fail
    }
  }

  playMastery(): void {
    if (this._muted) return;
    try {
      const ctx = this.ensureCtx();
      if (!ctx) return;
      let cursor = ctx.currentTime;
      for (const spec of masterySound()) {
        this.playSpec(ctx, spec, cursor);
        cursor += spec.durationMs / 1000;
      }
    } catch {
      // Guard: AudioContext unavailable or suspended — silent fail
    }
  }

  playFoley(event: DogFoleyEvent): void {
    if (this._muted) return;
    try {
      const ctx = this.ensureCtx();
      if (!ctx) return;
      let cursor = ctx.currentTime;
      for (const spec of foleyLayers(event)) {
        this.playSpec(ctx, spec, cursor);
        cursor += spec.durationMs / 1000;
      }
    } catch {
      // Guard: AudioContext unavailable or suspended — silent fail
    }
  }

  startAmbient(): void {
    this._ambientStarted = true;
    if (this._muted) return;
    if (this._ambientOn) return;
    try {
      const ctx = this.ensureCtx();
      if (!ctx) return;
      for (const spec of ambientLayers()) {
        const osc = ctx.createOscillator();
        const gainNode = ctx.createGain();
        osc.type = spec.type;
        osc.frequency.setValueAtTime(spec.freq, ctx.currentTime);
        gainNode.gain.setValueAtTime(spec.gain, ctx.currentTime);
        osc.connect(gainNode);
        gainNode.connect(ctx.destination);
        osc.start();
        this._ambientOscs.push(osc);
      }
      this._ambientOn = true;
    } catch {
      // Guard: AudioContext unavailable or suspended — silent fail
    }
  }

  stopAmbient(): void {
    if (!this._ambientOn) return;
    for (const osc of this._ambientOscs) {
      try {
        osc.stop();
      } catch {
        // oscillator may already be stopped — ignore
      }
    }
    this._ambientOscs = [];
    this._ambientOn = false;
  }

  playTap(): void {
    if (this._muted) return;
    try {
      const ctx = this.ensureCtx();
      if (!ctx) return;
      this.playSpec(ctx, tapSound(), ctx.currentTime);
    } catch {
      // Guard: AudioContext unavailable or suspended — silent fail
    }
  }
}
