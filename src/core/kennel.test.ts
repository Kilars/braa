import { describe, it, expect } from 'vitest';
import {
  kennelMultiplier,
  canBuy,
  KENNEL_UPGRADES,
  IDLE_RATE_PER_MS,
  IDLE_CAP_COINS,
  idleIncome,
} from './kennel';

// ─── Cycle 1: kennelMultiplier with no upgrades ───────────────────────────────

describe('kennelMultiplier — no upgrades', () => {
  it('returns 1 when no upgrades are owned', () => {
    expect(kennelMultiplier([])).toBe(1);
  });
});

// ─── Cycle 2: kennelMultiplier with one upgrade > 1 ──────────────────────────

describe('kennelMultiplier — one upgrade', () => {
  it('returns more than 1 when one upgrade is owned', () => {
    const oneUpgrade = [KENNEL_UPGRADES[0].id];
    expect(kennelMultiplier(oneUpgrade)).toBeGreaterThan(1);
  });
});

// ─── Cycle 3: kennelMultiplier is monotonic ───────────────────────────────────

describe('kennelMultiplier — monotonic with more upgrades', () => {
  it('two upgrades yield a higher multiplier than one', () => {
    const one = kennelMultiplier([KENNEL_UPGRADES[0].id]);
    const two = kennelMultiplier([KENNEL_UPGRADES[0].id, KENNEL_UPGRADES[1].id]);
    expect(two).toBeGreaterThan(one);
  });
});

// ─── canBuy tests ─────────────────────────────────────────────────────────────

describe('canBuy — already owned', () => {
  it('returns false when the upgrade id is already in ownedIds', () => {
    const upgrade = KENNEL_UPGRADES[0];
    expect(canBuy([upgrade.id], upgrade, 9999)).toBe(false);
  });
});

describe('canBuy — insufficient coins', () => {
  it('returns false when coins < upgrade cost', () => {
    const upgrade = KENNEL_UPGRADES[0]; // cost 100
    expect(canBuy([], upgrade, 99)).toBe(false);
  });

  it('returns false when coins is 0 and cost > 0', () => {
    const upgrade = KENNEL_UPGRADES[0];
    expect(canBuy([], upgrade, 0)).toBe(false);
  });
});

describe('canBuy — affordable and not owned', () => {
  it('returns true when not owned and coins >= cost', () => {
    const upgrade = KENNEL_UPGRADES[0]; // cost 100
    expect(canBuy([], upgrade, 100)).toBe(true);
  });

  it('returns true when not owned and coins > cost', () => {
    const upgrade = KENNEL_UPGRADES[0];
    expect(canBuy([], upgrade, 500)).toBe(true);
  });

  it('returns true for a mid-tier upgrade when other upgrades are owned but not this one', () => {
    const first = KENNEL_UPGRADES[0];
    const second = KENNEL_UPGRADES[1]; // cost 250
    expect(canBuy([first.id], second, 250)).toBe(true);
  });
});

// ─── Cycle 3b: IDLE_CAP_COINS specific value (tuning §7 — applied) ───────────

describe('IDLE_CAP_COINS — specific tuned value', () => {
  it('IDLE_CAP_COINS is 110', () => {
    expect(IDLE_CAP_COINS).toBe(110);
  });
});

// ─── Cycle 4: idleIncome at zero elapsed === 0 ────────────────────────────────

describe('idleIncome — zero elapsed', () => {
  it('returns 0 when now equals idleTimestamp', () => {
    const t = 1718000000000;
    expect(idleIncome(t, t)).toBe(0);
  });
});

// ─── Cycle 5: idleIncome grows with elapsed time ─────────────────────────────

describe('idleIncome — grows with time', () => {
  it('returns more coins for longer idle periods', () => {
    const base = 1718000000000;
    const short = idleIncome(base, base + 10_000);   // 10 s
    const long  = idleIncome(base, base + 60_000);   // 60 s
    expect(short).toBeGreaterThan(0);
    expect(long).toBeGreaterThan(short);
  });

  it('exact value: 30 s at IDLE_RATE_PER_MS = floor(30000 * rate)', () => {
    const base = 1718000000000;
    const thirtySeconds = 30_000;
    expect(idleIncome(base, base + thirtySeconds)).toBe(
      Math.min(Math.floor(thirtySeconds * IDLE_RATE_PER_MS), IDLE_CAP_COINS),
    );
  });
});

// ─── Cycle 6: idleIncome is capped at IDLE_CAP_COINS ─────────────────────────

describe('idleIncome — cap', () => {
  it('never exceeds IDLE_CAP_COINS regardless of elapsed time', () => {
    const base = 1718000000000;
    // 1 week away — should be way over cap
    const oneWeek = 7 * 24 * 60 * 60 * 1000;
    expect(idleIncome(base, base + oneWeek)).toBe(IDLE_CAP_COINS);
  });

  it('returns exactly IDLE_CAP_COINS at the boundary', () => {
    const base = 1718000000000;
    const exactCapMs = Math.ceil(IDLE_CAP_COINS / IDLE_RATE_PER_MS);
    // At the cap boundary, result must equal the cap
    expect(idleIncome(base, base + exactCapMs)).toBe(IDLE_CAP_COINS);
  });
});

// ─── Cycle 7: negative elapsed → 0 ───────────────────────────────────────────

describe('idleIncome — negative or zero elapsed', () => {
  it('returns 0 when now is before idleTimestamp', () => {
    const base = 1718000000000;
    expect(idleIncome(base, base - 5000)).toBe(0);
  });

  it('returns 0 when now is far in the past relative to idleTimestamp', () => {
    const base = 1718000000000;
    expect(idleIncome(base, 0)).toBe(0);
  });
});
