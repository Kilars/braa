import { describe, it, expect } from 'vitest';
import { STARTER_TRICKS, UNTRAIN_TRICKS, SIGNATURE_TRICKS, lookupTrick, tricksForBreed } from './tricks';
import type { Trick } from './tricks';
import { STARTER_BREED, BREED_CATALOG } from './breeds';

// ─── Cycle 1: STARTER_TRICKS has the three Norwegian starter commands ─────────

describe('STARTER_TRICKS', () => {
  it('has exactly three entries', () => {
    expect(STARTER_TRICKS).toHaveLength(3);
  });

  it('contains Sitt as the first trick', () => {
    expect(STARTER_TRICKS[0]).toMatchObject<Partial<Trick>>({
      id: 'sitt',
      name: 'Sitt',
    });
  });

  it('contains Ligg as the second trick', () => {
    expect(STARTER_TRICKS[1]).toMatchObject<Partial<Trick>>({
      id: 'ligg',
      name: 'Ligg',
    });
  });

  it('contains Legg deg as the third trick', () => {
    expect(STARTER_TRICKS[2]).toMatchObject<Partial<Trick>>({
      id: 'legg-deg',
      name: 'Legg deg',
    });
  });
});

// ─── Cycle 3 (new fields): difficulty profile fields are present and monotonic ─

describe('STARTER_TRICKS difficulty profiles', () => {
  const [sitt, ligg, leggDeg] = STARTER_TRICKS;

  it('Sitt has baseline profile (learnMult=1, windowMult=1, distractorBonus=0)', () => {
    expect(sitt.learnMult).toBe(1);
    expect(sitt.windowMult).toBe(1);
    expect(sitt.distractorBonus).toBe(0);
  });

  it('Ligg is harder than Sitt: smaller learnMult', () => {
    expect(ligg.learnMult).toBeLessThan(sitt.learnMult);
  });

  it('Ligg is harder than Sitt: smaller windowMult', () => {
    expect(ligg.windowMult).toBeLessThan(sitt.windowMult);
  });

  it('Ligg is harder than Sitt: larger distractorBonus', () => {
    expect(ligg.distractorBonus).toBeGreaterThan(sitt.distractorBonus);
  });

  it('Legg deg is harder than Ligg: smaller learnMult (monotonic)', () => {
    expect(leggDeg.learnMult).toBeLessThan(ligg.learnMult);
  });

  it('Legg deg is harder than Ligg: smaller windowMult (monotonic)', () => {
    expect(leggDeg.windowMult).toBeLessThan(ligg.windowMult);
  });

  it('Legg deg is harder than Ligg: larger distractorBonus (monotonic)', () => {
    expect(leggDeg.distractorBonus).toBeGreaterThan(ligg.distractorBonus);
  });
});

// ─── Untraining trick: no-jump has untrain=true; normal tricks are falsy ─────

describe('UNTRAIN_TRICKS', () => {
  it('contains no-jump as the first untraining trick', () => {
    expect(UNTRAIN_TRICKS[0]).toMatchObject<Partial<Trick>>({
      id: 'no-jump',
      name: 'Ikke hopp',
    });
  });

  it('no-jump has untrain: true', () => {
    expect(UNTRAIN_TRICKS[0].untrain).toBe(true);
  });

  it('no-jump has sensible difficulty mults', () => {
    const t = UNTRAIN_TRICKS[0];
    expect(t.learnMult).toBeGreaterThan(0);
    expect(t.windowMult).toBeGreaterThan(0);
    expect(t.distractorBonus).toBeGreaterThanOrEqual(0);
  });

  it('all STARTER_TRICKS have untrain falsy (not true)', () => {
    for (const t of STARTER_TRICKS) {
      expect(t.untrain).toBeFalsy();
    }
  });
});

// ─── Cycle 2: lookupTrick returns the correct trick by id ────────────────────

describe('lookupTrick', () => {
  it('returns the trick for a known id', () => {
    const trick = lookupTrick('ligg');
    expect(trick).not.toBeUndefined();
    expect(trick?.id).toBe('ligg');
    expect(trick?.name).toBe('Ligg');
  });

  it('returns undefined for an unknown id', () => {
    expect(lookupTrick('unknown-trick')).toBeUndefined();
  });

  it('works for all starter trick ids', () => {
    for (const trick of STARTER_TRICKS) {
      expect(lookupTrick(trick.id)).toBe(trick);
    }
  });
});

// ─── Cycle: SIGNATURE_TRICKS — rull, ul, sov exist with valid difficulty profiles ─

describe('SIGNATURE_TRICKS', () => {
  it('contains rull (Rull / roll over) with id "rull"', () => {
    const t = SIGNATURE_TRICKS.find(t => t.id === 'rull');
    expect(t).toBeDefined();
    expect(t?.name).toBe('Rull');
  });

  it('contains ul (Ul / howl) with id "ul"', () => {
    const t = SIGNATURE_TRICKS.find(t => t.id === 'ul');
    expect(t).toBeDefined();
    expect(t?.name).toBe('Ul');
  });

  it('contains sov (Sov / play dead) with id "sov"', () => {
    const t = SIGNATURE_TRICKS.find(t => t.id === 'sov');
    expect(t).toBeDefined();
    expect(t?.name).toBe('Sov');
  });

  it('all signature tricks have positive learnMult and windowMult', () => {
    for (const t of SIGNATURE_TRICKS) {
      expect(t.learnMult).toBeGreaterThan(0);
      expect(t.windowMult).toBeGreaterThan(0);
    }
  });

  it('all signature tricks have non-negative distractorBonus', () => {
    for (const t of SIGNATURE_TRICKS) {
      expect(t.distractorBonus).toBeGreaterThanOrEqual(0);
    }
  });
});

describe('lookupTrick — finds signature tricks', () => {
  it('finds rull by id', () => {
    expect(lookupTrick('rull')?.id).toBe('rull');
  });

  it('finds ul by id', () => {
    expect(lookupTrick('ul')?.id).toBe('ul');
  });

  it('finds sov by id', () => {
    expect(lookupTrick('sov')?.id).toBe('sov');
  });
});

// ─── Cycle: tricksForBreed ────────────────────────────────────────────────────

describe('tricksForBreed', () => {
  it('Labrador (no signatureTrickId) returns exactly STARTER_TRICKS', () => {
    const result = tricksForBreed(STARTER_BREED);
    const resultIds = result.map(t => t.id);
    const starterIds = STARTER_TRICKS.map(t => t.id);
    expect(resultIds).toEqual(starterIds);
  });

  it('Border Collie returns starters + rull', () => {
    const borderCollie = BREED_CATALOG.find(b => b.id === 'border-collie')!;
    const result = tricksForBreed(borderCollie);
    const ids = result.map(t => t.id);
    expect(ids).toContain('rull');
    for (const t of STARTER_TRICKS) {
      expect(ids).toContain(t.id);
    }
    expect(result).toHaveLength(STARTER_TRICKS.length + 1);
  });

  it('Husky returns starters + ul', () => {
    const husky = BREED_CATALOG.find(b => b.id === 'husky')!;
    const result = tricksForBreed(husky);
    const ids = result.map(t => t.id);
    expect(ids).toContain('ul');
    expect(result).toHaveLength(STARTER_TRICKS.length + 1);
  });

  it('Bulldog returns starters + sov', () => {
    const bulldog = BREED_CATALOG.find(b => b.id === 'bulldog')!;
    const result = tricksForBreed(bulldog);
    const ids = result.map(t => t.id);
    expect(ids).toContain('sov');
    expect(result).toHaveLength(STARTER_TRICKS.length + 1);
  });
});

// ─── Cycle: non-starter breeds have signatureTrickId resolving via lookupTrick ─

describe('breeds signatureTrickId resolves via lookupTrick', () => {
  it('every non-starter breed has a signatureTrickId that resolves', () => {
    const nonStarter = BREED_CATALOG.filter(b => b.id !== STARTER_BREED.id);
    for (const breed of nonStarter) {
      expect(breed.signatureTrickId).toBeDefined();
      const trick = lookupTrick(breed.signatureTrickId!);
      expect(trick).toBeDefined();
    }
  });
});

// ─── Cycle: snurr — Puddel's signature trick ─────────────────────────────────

// ─── Cycle: tricksForBreed includes snurr for puddel ─────────────────────────

describe('tricksForBreed — puddel returns starters + snurr', () => {
  it('Puddel returns starters + snurr', () => {
    const puddel = BREED_CATALOG.find(b => b.id === 'puddel')!;
    const result = tricksForBreed(puddel);
    const ids = result.map(t => t.id);
    expect(ids).toContain('snurr');
    for (const t of STARTER_TRICKS) {
      expect(ids).toContain(t.id);
    }
    expect(result).toHaveLength(STARTER_TRICKS.length + 1);
  });
});

// ─── Cycle: snurr — Puddel's signature trick ─────────────────────────────────

describe('SIGNATURE_TRICKS — snurr (spin)', () => {
  it('contains snurr with id "snurr" and name "Snurr"', () => {
    const t = SIGNATURE_TRICKS.find(t => t.id === 'snurr');
    expect(t).toBeDefined();
    expect(t?.name).toBe('Snurr');
  });

  it('snurr has positive learnMult and windowMult', () => {
    const t = SIGNATURE_TRICKS.find(t => t.id === 'snurr')!;
    expect(t.learnMult).toBeGreaterThan(0);
    expect(t.windowMult).toBeGreaterThan(0);
  });

  it('snurr has non-negative distractorBonus', () => {
    const t = SIGNATURE_TRICKS.find(t => t.id === 'snurr')!;
    expect(t.distractorBonus).toBeGreaterThanOrEqual(0);
  });

  it('lookupTrick finds snurr by id', () => {
    expect(lookupTrick('snurr')?.id).toBe('snurr');
  });
});
