import { describe, it, expect } from 'vitest';
import { MASTERY_BASE_PAYOUT, completeMastery, PRACTICE_BASE_PAYOUT, completePractice } from './game';
import { newProfile } from './economy';
import { kennelMultiplier, KENNEL_UPGRADES } from './kennel';
import { lookupTrick } from './tricks';

// ─── Cycle 1: completeMastery NORMAL awards base payout (mult = 1) ────────────

describe('completeMastery — NORMAL', () => {
  it('adds MASTERY_BASE_PAYOUT coins to a fresh profile', () => {
    const p = newProfile();
    const result = completeMastery(p, 'NORMAL');
    expect(result.coins).toBe(p.coins + MASTERY_BASE_PAYOUT.coins);
  });
});

// ─── Cycle 2: completeMastery HARD awards strictly more than NORMAL ───────────

describe('completeMastery — HARD vs NORMAL', () => {
  it('HARD awards more coins than NORMAL (rewardMultiplier > 1)', () => {
    const p = newProfile();
    const normal = completeMastery(p, 'NORMAL');
    const hard   = completeMastery(p, 'HARD');
    expect(hard.coins).toBeGreaterThan(normal.coins);
  });

  it('HARD awards more xp than NORMAL', () => {
    const p = newProfile();
    const normal = completeMastery(p, 'NORMAL');
    const hard   = completeMastery(p, 'HARD');
    expect(hard.xp).toBeGreaterThan(normal.xp);
  });
});

// ─── Cycle 8: completeMastery with kennel multiplier ─────────────────────────

describe('completeMastery — kennel multiplier', () => {
  it('kennelMult=1 (default) equals no-arg payout on NORMAL', () => {
    const p = newProfile();
    const withOne   = completeMastery(p, 'NORMAL', 1);
    const withNone  = completeMastery(p, 'NORMAL');
    expect(withOne.coins).toBe(withNone.coins);
    expect(withOne.xp).toBe(withNone.xp);
  });

  it('kennel multiplier > 1 yields more coins than kennelMult=1 on NORMAL', () => {
    const p = newProfile();
    const km = kennelMultiplier([KENNEL_UPGRADES[0].id]);
    const withKennel  = completeMastery(p, 'NORMAL', km);
    const withoutKennel = completeMastery(p, 'NORMAL', 1);
    expect(withKennel.coins).toBeGreaterThan(withoutKennel.coins);
  });
});

// ─── Cycle 30: completeMastery with prestige multiplier ──────────────────────

describe('completeMastery — prestige multiplier', () => {
  it('prestigePoints=0 (default) equals no-prestige payout on NORMAL', () => {
    const p = newProfile();
    const withZero = completeMastery(p, 'NORMAL', 1, 0);
    const withNone = completeMastery(p, 'NORMAL');
    expect(withZero.coins).toBe(withNone.coins);
    expect(withZero.xp).toBe(withNone.xp);
  });

  it('prestigePoints > 0 yields more coins than no prestige on NORMAL', () => {
    const p = newProfile();
    const withPrestige = completeMastery(p, 'NORMAL', 1, 1);
    const withoutPrestige = completeMastery(p, 'NORMAL', 1, 0);
    expect(withPrestige.coins).toBeGreaterThan(withoutPrestige.coins);
  });

  it('payout scales: difficulty × kennel × prestige all compound', () => {
    const p = newProfile();
    const km = kennelMultiplier([KENNEL_UPGRADES[0].id]);
    const withAll = completeMastery(p, 'HARD', km, 2);
    const withNone = completeMastery(p, 'NORMAL', 1, 0);
    expect(withAll.coins).toBeGreaterThan(withNone.coins);
  });
});

// ─── Cycle N: completePractice / reduced re-practice payout ──────────────────

describe('completePractice / reduced re-practice payout', () => {
  // ─ Behaviour 1: completePractice awards PRACTICE_BASE_PAYOUT coins ×
  // the same multiplier stack as mastery (difficulty × kennel × prestige)
  it('awards PRACTICE_BASE_PAYOUT coins × multiplier stack (HARD, prestige=2)', () => {
    const p = newProfile();
    const result = completePractice(p, 'HARD', 1, 2);
    // HARD rewardMultiplier = 1.3, kennelMult = 1, prestigeMultiplier(2) = 1 + 0.2 = 1.2
    // Expected: round(15 * 1.3 * 1 * 1.2) = round(23.4) = 23
    const expectedCoins = 23;
    expect(result.coins).toBe(p.coins + expectedCoins);
  });

  // ─ Behaviour 2: PRACTICE_BASE_PAYOUT.coins < MASTERY_BASE_PAYOUT.coins
  // AND PRACTICE_BASE_PAYOUT.xp === 0
  it('PRACTICE_BASE_PAYOUT.coins < MASTERY_BASE_PAYOUT.coins', () => {
    expect(PRACTICE_BASE_PAYOUT.coins).toBeLessThan(MASTERY_BASE_PAYOUT.coins);
  });

  it('PRACTICE_BASE_PAYOUT.xp === 0 (no XP from re-practice)', () => {
    expect(PRACTICE_BASE_PAYOUT.xp).toBe(0);
  });

  // ─ Behaviour 3: completePractice does NOT change profile.level
  // (xp unchanged, so level unchanged) for a profile whose coins increase
  it('does not change profile.level (xp unchanged) while coins increase', () => {
    const p = newProfile();
    const startLevel = p.level;
    const startXp = p.xp;
    const result = completePractice(p, 'HARD', 1, 0);
    expect(result.level).toBe(startLevel);
    expect(result.xp).toBe(startXp);
    expect(result.coins).toBeGreaterThan(p.coins);
  });

  // ─ Behaviour 4 (Regression): completeMastery still awards full MASTERY_BASE_PAYOUT
  it('completeMastery still awards full MASTERY_BASE_PAYOUT (coins + xp)', () => {
    const p = newProfile();
    const result = completeMastery(p, 'NORMAL', 1, 0);
    // NORMAL rewardMultiplier = 1, kennelMult = 1, prestigeMultiplier(0) = 1
    // Expected: coins = round(50 * 1) = 50, xp = round(30 * 1) = 30
    expect(result.coins).toBe(p.coins + MASTERY_BASE_PAYOUT.coins);
    expect(result.xp).toBe(p.xp + MASTERY_BASE_PAYOUT.xp);
  });
});

// ─── Cycle: completeMastery with trick parameter — harder tricks pay more ─────

describe('completeMastery with trick parameter', () => {
  it('harder trick (legg-deg) yields MORE coins than easier trick (sitt) at same mode/kennel/prestige', () => {
    const p = newProfile();
    const leggDeg = lookupTrick('legg-deg')!;
    const sitt = lookupTrick('sitt')!;

    const hardResult = completeMastery(p, 'NORMAL', 1, 0, leggDeg);
    const easyResult = completeMastery(p, 'NORMAL', 1, 0, sitt);

    expect(hardResult.coins).toBeGreaterThan(easyResult.coins);
  });

  it('harder trick (legg-deg) yields MORE xp than easier trick (sitt) at same mode/kennel/prestige', () => {
    const p = newProfile();
    const leggDeg = lookupTrick('legg-deg')!;
    const sitt = lookupTrick('sitt')!;

    const hardResult = completeMastery(p, 'NORMAL', 1, 0, leggDeg);
    const easyResult = completeMastery(p, 'NORMAL', 1, 0, sitt);

    expect(hardResult.xp).toBeGreaterThan(easyResult.xp);
  });

  it('backward-compatible: completeMastery without trick param equals trick=sitt (1× uplift)', () => {
    const p = newProfile();
    const sitt = lookupTrick('sitt')!;

    const noTrickResult = completeMastery(p, 'NORMAL', 1, 0);
    const sittResult = completeMastery(p, 'NORMAL', 1, 0, sitt);

    expect(noTrickResult.coins).toBe(sittResult.coins);
    expect(noTrickResult.xp).toBe(sittResult.xp);
  });

  it('trick param composes multiplicatively with mode/kennel/prestige in documented order', () => {
    const p = newProfile();
    const leggDeg = lookupTrick('legg-deg')!;
    const sitt = lookupTrick('sitt')!;

    // Verify no double-counting: HARD × legg-deg should be significantly more
    // than HARD alone, not exponentially more
    const hardAlone = completeMastery(p, 'HARD', 1, 0, sitt);
    const hardLeggDeg = completeMastery(p, 'HARD', 1, 0, leggDeg);

    const hardSittCoins = hardAlone.coins - p.coins;
    const hardLeggDegCoins = hardLeggDeg.coins - p.coins;

    // hardLeggDeg should be more, but not more than hardSitt × 2.2 (cap)
    expect(hardLeggDegCoins).toBeGreaterThan(hardSittCoins);
    expect(hardLeggDegCoins).toBeLessThanOrEqual(hardSittCoins * 2.2);
  });
});

// ─── Cycle: completePractice with trick parameter — applies uplift to coins, keeps XP=0 ───

describe('completePractice with trick parameter', () => {
  it('harder trick (legg-deg) yields MORE coins than easier trick (sitt) at same mode/kennel/prestige', () => {
    const p = newProfile();
    const leggDeg = lookupTrick('legg-deg')!;
    const sitt = lookupTrick('sitt')!;

    const hardResult = completePractice(p, 'NORMAL', 1, 0, leggDeg);
    const easyResult = completePractice(p, 'NORMAL', 1, 0, sitt);

    expect(hardResult.coins).toBeGreaterThan(easyResult.coins);
  });

  it('re-practice keeps no-XP invariant WITH trick uplift: xp stays unchanged for both tricks', () => {
    const p = newProfile();
    const leggDeg = lookupTrick('legg-deg')!;
    const sitt = lookupTrick('sitt')!;
    const startXp = p.xp;

    const hardResult = completePractice(p, 'NORMAL', 1, 0, leggDeg);
    const easyResult = completePractice(p, 'NORMAL', 1, 0, sitt);

    // Both must grant 0 XP (task 070 invariant)
    expect(hardResult.xp).toBe(startXp);
    expect(easyResult.xp).toBe(startXp);

    // But harder trick grants more coins
    expect(hardResult.coins).toBeGreaterThan(easyResult.coins);
  });

  it('backward-compatible: completePractice without trick param equals trick=sitt', () => {
    const p = newProfile();
    const sitt = lookupTrick('sitt')!;

    const noTrickResult = completePractice(p, 'NORMAL', 1, 0);
    const sittResult = completePractice(p, 'NORMAL', 1, 0, sitt);

    expect(noTrickResult.coins).toBe(sittResult.coins);
    expect(noTrickResult.xp).toBe(sittResult.xp);
  });
});
