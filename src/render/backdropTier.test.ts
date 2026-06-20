import { describe, it, expect } from 'vitest';
import { kennelTier, backdropTierConfig } from './backdropTier';

// ─── Cycle 1: kennelTier with no upgrades returns 0 ──────────────────────────

describe('kennelTier — no upgrades', () => {
  it('returns 0 when no upgrades are owned', () => {
    expect(kennelTier([])).toBe(0);
  });
});

// ─── Cycle 2: kennelTier scales with valid owned upgrade count ───────────────

describe('kennelTier — owned upgrade count', () => {
  it('returns 1 when one valid upgrade is owned', () => {
    expect(kennelTier(['treats-pouch'])).toBe(1);
  });

  it('returns 2 when two valid upgrades are owned', () => {
    expect(kennelTier(['treats-pouch', 'clicker-pro'])).toBe(2);
  });

  it('returns 3 when all three valid upgrades are owned', () => {
    expect(kennelTier(['treats-pouch', 'clicker-pro', 'training-dummy'])).toBe(3);
  });
});

// ─── Cycle 3: kennelTier ignores unknown upgrade ids ──────────────────────────

describe('kennelTier — unknown ids ignored', () => {
  it('ignores unknown upgrade ids (returns 1 when one valid id present)', () => {
    expect(kennelTier(['bogus', 'treats-pouch'])).toBe(1);
  });

  it('ignores only unknown ids; counts valid ones (1 valid + 2 invalid = 1)', () => {
    expect(kennelTier(['treats-pouch', 'fake1', 'fake2'])).toBe(1);
  });

  it('counts only valid ids when mixed with unknowns (2 valid + 1 invalid = 2)', () => {
    expect(kennelTier(['treats-pouch', 'bogus', 'clicker-pro'])).toBe(2);
  });
});

// ─── Cycle 4: kennelTier clamps to maximum tier of 3 ──────────────────────────

describe('kennelTier — clamped to [0,3]', () => {
  it('never exceeds 3 even with duplicate valid ids', () => {
    expect(kennelTier(['treats-pouch', 'treats-pouch', 'treats-pouch'])).toBe(1);
  });

  it('clamps all three valid ids to tier 3 (no over-counting)', () => {
    expect(kennelTier(['treats-pouch', 'clicker-pro', 'training-dummy', 'treats-pouch'])).toBe(3);
  });

  it('remains at tier 3 with duplicates of all three distinct upgrades', () => {
    expect(kennelTier(['treats-pouch', 'clicker-pro', 'training-dummy', 'treats-pouch', 'clicker-pro'])).toBe(3);
  });
});

// ─── Cycle 5: backdropTierConfig is defined for all tiers 0-3 ────────────────

describe('backdropTierConfig — defined for tiers 0-3', () => {
  it('returns a config object for tier 0', () => {
    const config = backdropTierConfig(0);
    expect(config).toBeDefined();
    expect(typeof config).toBe('object');
  });

  it('returns a config object for tier 1', () => {
    const config = backdropTierConfig(1);
    expect(config).toBeDefined();
    expect(typeof config).toBe('object');
  });

  it('returns a config object for tier 2', () => {
    const config = backdropTierConfig(2);
    expect(config).toBeDefined();
    expect(typeof config).toBe('object');
  });

  it('returns a config object for tier 3', () => {
    const config = backdropTierConfig(3);
    expect(config).toBeDefined();
    expect(typeof config).toBe('object');
  });
});

// ─── Cycle 6: backdropTierConfig.lushness is monotonically non-decreasing ────

describe('backdropTierConfig — lushness monotonic', () => {
  it('has a lushness property on the returned config', () => {
    const config = backdropTierConfig(0);
    expect(config).toHaveProperty('lushness');
    expect(typeof config.lushness).toBe('number');
  });

  it('tier 0 lushness <= tier 1 lushness', () => {
    const tier0 = backdropTierConfig(0);
    const tier1 = backdropTierConfig(1);
    expect(tier1.lushness).toBeGreaterThanOrEqual(tier0.lushness);
  });

  it('tier 1 lushness <= tier 2 lushness', () => {
    const tier1 = backdropTierConfig(1);
    const tier2 = backdropTierConfig(2);
    expect(tier2.lushness).toBeGreaterThanOrEqual(tier1.lushness);
  });

  it('tier 2 lushness <= tier 3 lushness', () => {
    const tier2 = backdropTierConfig(2);
    const tier3 = backdropTierConfig(3);
    expect(tier3.lushness).toBeGreaterThanOrEqual(tier2.lushness);
  });

  it('tier 0 lushness is strictly less than tier 3 lushness (tiers are visually distinct)', () => {
    const tier0 = backdropTierConfig(0);
    const tier3 = backdropTierConfig(3);
    expect(tier3.lushness).toBeGreaterThan(tier0.lushness);
  });
});
