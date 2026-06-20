import { describe, it, expect } from 'vitest';
import { selectDogRenderMode, resolveLoadState, type DogLoadState } from './dogModelLoader';

describe('selectDogRenderMode', () => {
  it('returns procedural when the imported-dog flag is off, regardless of load state', () => {
    expect(selectDogRenderMode({ flagEnabled: false, loadState: 'ready' })).toBe('procedural');
  });

  it('returns imported when the flag is on and the model has loaded (ready)', () => {
    expect(selectDogRenderMode({ flagEnabled: true, loadState: 'ready' })).toBe('imported');
  });

  // Fallback is mandatory: with the flag on but the load not cleanly ready, the
  // dog must still render procedurally — never a blank scene.
  it.each<DogLoadState>(['idle', 'loading', 'failed', 'timeout'])(
    'falls back to procedural when the flag is on but load state is %s',
    (loadState) => {
      expect(selectDogRenderMode({ flagEnabled: true, loadState })).toBe('procedural');
    },
  );
});

describe('resolveLoadState (timeout budget)', () => {
  it('promotes a still-loading state to timeout once elapsed exceeds the budget', () => {
    expect(resolveLoadState({ state: 'loading', elapsedMs: 5001, budgetMs: 5000 })).toBe('timeout');
  });

  it('keeps a still-loading state while within the budget', () => {
    expect(resolveLoadState({ state: 'loading', elapsedMs: 5000, budgetMs: 5000 })).toBe('loading');
  });

  it('passes non-loading states through unchanged regardless of elapsed time', () => {
    expect(resolveLoadState({ state: 'ready', elapsedMs: 9999, budgetMs: 5000 })).toBe('ready');
    expect(resolveLoadState({ state: 'failed', elapsedMs: 9999, budgetMs: 5000 })).toBe('failed');
  });
});
