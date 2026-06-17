import { describe, it, expect } from 'vitest';
import { unlockedAchievements } from './achievements';
import type { AchState } from './achievements';

// ── helpers ──────────────────────────────────────────────────────────────────

function freshState(): AchState {
  return {
    roster: [{ id: 'rex', name: 'Rex', breedId: 'labrador', masteredTrickIds: [] }],
    coins: 0,
    prestigePoints: 0,
    bestCombo: 0,
  };
}

// ── Cycle 1: fresh state returns [] ──────────────────────────────────────────

describe('unlockedAchievements — fresh state', () => {
  it('returns [] when nothing has been accomplished', () => {
    expect(unlockedAchievements(freshState())).toEqual([]);
  });
});

// ── Cycle 2: first-mark ──────────────────────────────────────────────────────

describe('unlockedAchievements — first-mark', () => {
  it('is NOT unlocked when no dog has any mastered trick', () => {
    expect(unlockedAchievements(freshState())).not.toContain('first-mark');
  });

  it('IS unlocked when a dog has at least 1 mastered trick', () => {
    const s: AchState = {
      ...freshState(),
      roster: [{ id: 'rex', name: 'Rex', breedId: 'labrador', masteredTrickIds: ['sitt'] }],
    };
    expect(unlockedAchievements(s)).toContain('first-mark');
  });
});

// ── Cycle 3: full-repertoire ──────────────────────────────────────────────────

describe('unlockedAchievements — full-repertoire', () => {
  it('is NOT unlocked when a dog has only some STARTER_TRICKS mastered', () => {
    const s: AchState = {
      ...freshState(),
      roster: [{ id: 'rex', name: 'Rex', breedId: 'labrador', masteredTrickIds: ['sitt', 'ligg'] }],
    };
    expect(unlockedAchievements(s)).not.toContain('full-repertoire');
  });

  it('IS unlocked when a dog has mastered all STARTER_TRICKS (sitt, ligg, legg-deg)', () => {
    const s: AchState = {
      ...freshState(),
      roster: [{ id: 'rex', name: 'Rex', breedId: 'labrador', masteredTrickIds: ['sitt', 'ligg', 'legg-deg'] }],
    };
    expect(unlockedAchievements(s)).toContain('full-repertoire');
  });
});

// ── Cycle 4: collector ────────────────────────────────────────────────────────

describe('unlockedAchievements — collector', () => {
  it('is NOT unlocked with only 1 dog in roster', () => {
    expect(unlockedAchievements(freshState())).not.toContain('collector');
  });

  it('IS unlocked when roster has 2 or more dogs', () => {
    const s: AchState = {
      ...freshState(),
      roster: [
        { id: 'rex', name: 'Rex', breedId: 'labrador', masteredTrickIds: [] },
        { id: 'border-collie', name: 'Buddy', breedId: 'border-collie', masteredTrickIds: [] },
      ],
    };
    expect(unlockedAchievements(s)).toContain('collector');
  });
});

// ── Cycle 5: combo-10 ─────────────────────────────────────────────────────────

describe('unlockedAchievements — combo-10', () => {
  it('is NOT unlocked when bestCombo is 9', () => {
    expect(unlockedAchievements({ ...freshState(), bestCombo: 9 })).not.toContain('combo-10');
  });

  it('IS unlocked when bestCombo is exactly 10', () => {
    expect(unlockedAchievements({ ...freshState(), bestCombo: 10 })).toContain('combo-10');
  });

  it('IS unlocked when bestCombo exceeds 10', () => {
    expect(unlockedAchievements({ ...freshState(), bestCombo: 15 })).toContain('combo-10');
  });
});

// ── Cycle 6: graduate ─────────────────────────────────────────────────────────

describe('unlockedAchievements — graduate', () => {
  it('is NOT unlocked when prestigePoints is 0', () => {
    expect(unlockedAchievements(freshState())).not.toContain('graduate');
  });

  it('IS unlocked when prestigePoints is 1', () => {
    expect(unlockedAchievements({ ...freshState(), prestigePoints: 1 })).toContain('graduate');
  });
});

// ── Cycle 7: wealthy ──────────────────────────────────────────────────────────

describe('unlockedAchievements — wealthy', () => {
  it('is NOT unlocked when coins is 499', () => {
    expect(unlockedAchievements({ ...freshState(), coins: 499 })).not.toContain('wealthy');
  });

  it('IS unlocked when coins is exactly 500', () => {
    expect(unlockedAchievements({ ...freshState(), coins: 500 })).toContain('wealthy');
  });
});
