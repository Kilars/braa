import { describe, it, expect } from 'vitest';
import { createPauseClock } from './pauseClock';

describe('createPauseClock', () => {
  it('elapsed advances normally before any pause', () => {
    const clock = createPauseClock(1000);
    expect(clock.elapsed(1000)).toBe(0);
    expect(clock.elapsed(1500)).toBe(500);
  });

  it('starts not paused', () => {
    const clock = createPauseClock(1000);
    expect(clock.isPaused()).toBe(false);
  });

  it('reports paused after pause()', () => {
    const clock = createPauseClock(1000);
    clock.pause(1500);
    expect(clock.isPaused()).toBe(true);
  });

  it('freezes elapsed at the pause instant while paused', () => {
    const clock = createPauseClock(1000);
    clock.pause(1500);
    expect(clock.elapsed(2000)).toBe(500); // wall-clock advanced, round time frozen
    expect(clock.elapsed(5000)).toBe(500);
  });

  it('continues from the frozen value after resume (paused span is lost)', () => {
    const clock = createPauseClock(1000);
    clock.pause(1500); // frozen at 500
    clock.resume(1800); // lost 300 ms of wall time
    expect(clock.isPaused()).toBe(false);
    expect(clock.elapsed(2000)).toBe(700); // 500 + (2000 - 1800)
  });

  it('accumulates lost time across multiple pause/resume cycles', () => {
    const clock = createPauseClock(0);
    clock.pause(100); // elapsed 100, lost 0
    clock.resume(300); // lost 200
    clock.pause(500); // elapsed 300
    clock.resume(900); // lost 200 + 400 = 600
    expect(clock.elapsed(1000)).toBe(400); // 1000 - 0 - 600
  });

  it('double pause is idempotent (keeps the first pause instant)', () => {
    const clock = createPauseClock(1000);
    clock.pause(1500);
    clock.pause(1700); // ignored — still frozen at the first pause
    expect(clock.elapsed(2000)).toBe(500);
    clock.resume(1900); // only the first pause span (1900 - 1500 = 400) is lost
    expect(clock.elapsed(2000)).toBe(600); // 2000 - 1000 - 400
  });

  it('resume while not paused is a no-op', () => {
    const clock = createPauseClock(1000);
    clock.resume(1500); // never paused — nothing lost
    expect(clock.elapsed(2000)).toBe(1000);
  });
});
