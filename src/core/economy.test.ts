import { describe, it, expect } from 'vitest';
import { newProfile, levelForXp, award, spend, isTierUnlocked } from './economy';

// ─── Cycle 1: newProfile ──────────────────────────────────────────────────────

describe('newProfile', () => {
  it('returns coins 0, xp 0, level 1', () => {
    const p = newProfile();
    expect(p.coins).toBe(0);
    expect(p.xp).toBe(0);
    expect(p.level).toBe(1);
  });
});

// ─── Cycle 2: award scales and adds ───────────────────────────────────────────

describe('award', () => {
  it('adds coins and xp scaled by multiplier 1', () => {
    const p = newProfile();
    const result = award(p, { coins: 50, xp: 20 }, 1);
    expect(result.coins).toBe(50);
    expect(result.xp).toBe(20);
  });
});

// ─── Cycle 3: levelForXp raises level at exact boundary ───────────────────────
// Level table: level 1 = 0 XP, level 2 = 100 XP, level 3 = 300 XP

describe('levelForXp — boundary', () => {
  it('returns level 1 at 0 XP', () => {
    expect(levelForXp(0)).toBe(1);
  });

  it('returns level 1 at 99 XP (just below level-2 threshold)', () => {
    expect(levelForXp(99)).toBe(1);
  });

  it('returns level 2 at exactly 100 XP', () => {
    expect(levelForXp(100)).toBe(2);
  });

  it('returns level 2 at 299 XP (just below level-3 threshold)', () => {
    expect(levelForXp(299)).toBe(2);
  });

  it('returns level 3 at exactly 300 XP', () => {
    expect(levelForXp(300)).toBe(3);
  });
});

// ─── Cycle 4: award recomputes level on XP crossing threshold ─────────────────

describe('award — level recomputation', () => {
  it('level stays 1 when XP does not cross 100 threshold', () => {
    const p = newProfile(); // xp=0, level=1
    const result = award(p, { coins: 10, xp: 99 }, 1);
    expect(result.level).toBe(1);
  });

  it('level becomes 2 when XP reaches exactly 100', () => {
    const p = newProfile(); // xp=0, level=1
    const result = award(p, { coins: 10, xp: 100 }, 1);
    expect(result.level).toBe(2);
  });
});

// ─── Cycle 5: award with multiplier > 1 (HARD) yields more than multiplier 1 ──

describe('award — multiplier scaling', () => {
  it('multiplier 2 yields double the coins compared to multiplier 1', () => {
    const p = newProfile();
    const base: import('./economy').Payout = { coins: 50, xp: 20 };
    const normal = award(p, base, 1);
    const hard   = award(p, base, 2);
    expect(hard.coins).toBeGreaterThan(normal.coins);
    expect(hard.coins).toBe(100);
  });

  it('multiplier 2 yields double the xp compared to multiplier 1', () => {
    const p = newProfile();
    const base: import('./economy').Payout = { coins: 50, xp: 20 };
    const normal = award(p, base, 1);
    const hard   = award(p, base, 2);
    expect(hard.xp).toBeGreaterThan(normal.xp);
    expect(hard.xp).toBe(40);
  });
});

// ─── Cycle 6: spend reduces coins; null when unaffordable; no mutation ─────────

describe('spend', () => {
  it('reduces coins by price when affordable', () => {
    const p = { coins: 200, xp: 0, level: 1 };
    const result = spend(p, 50);
    expect(result).not.toBeNull();
    expect(result!.coins).toBe(150);
  });

  it('returns null when coins < price', () => {
    const p = { coins: 30, xp: 0, level: 1 };
    expect(spend(p, 50)).toBeNull();
  });

  it('returns null when coins === 0 and price > 0', () => {
    const p = newProfile(); // coins=0
    expect(spend(p, 1)).toBeNull();
  });

  it('does not mutate the original profile when spending', () => {
    const p = { coins: 200, xp: 0, level: 1 };
    spend(p, 50);
    expect(p.coins).toBe(200); // original unchanged
  });

  it('does not mutate the original profile when unaffordable', () => {
    const p = { coins: 10, xp: 0, level: 1 };
    spend(p, 50);
    expect(p.coins).toBe(10); // original unchanged
  });
});

// ─── Cycle 7: isTierUnlocked gates by level ───────────────────────────────────

describe('isTierUnlocked', () => {
  it('returns false when player level is below requiredLevel', () => {
    expect(isTierUnlocked(1, 3)).toBe(false);
  });

  it('returns false at one below requiredLevel', () => {
    expect(isTierUnlocked(2, 3)).toBe(false);
  });

  it('returns true when player level exactly equals requiredLevel', () => {
    expect(isTierUnlocked(3, 3)).toBe(true);
  });

  it('returns true when player level is above requiredLevel', () => {
    expect(isTierUnlocked(5, 3)).toBe(true);
  });
});

// ─── Cycle 8: Two-step unlock documented ─────────────────────────────────────
// "level makes content purchasable; coins purchase it" — must BOTH succeed

describe('two-step unlock', () => {
  it('content is accessible only when tier is unlocked AND spend succeeds', () => {
    const p: import('./economy').Profile = { coins: 200, xp: 0, level: 3 };
    const requiredLevel = 3;
    const price = 100;

    // Both conditions satisfied
    const tierOpen = isTierUnlocked(p.level, requiredLevel);
    const after    = spend(p, price);
    expect(tierOpen).toBe(true);
    expect(after).not.toBeNull();
  });

  it('purchase blocked when tier is unlocked but coins insufficient', () => {
    const p: import('./economy').Profile = { coins: 50, xp: 0, level: 3 };
    const tierOpen = isTierUnlocked(p.level, 3);
    const after    = spend(p, 100);
    expect(tierOpen).toBe(true);  // tier is open...
    expect(after).toBeNull();     // ...but can't afford it
  });

  it('purchase blocked when coins sufficient but tier not unlocked', () => {
    const p: import('./economy').Profile = { coins: 500, xp: 0, level: 1 };
    const tierOpen = isTierUnlocked(p.level, 3);
    expect(tierOpen).toBe(false); // tier closed — don't even attempt spend
  });
});
