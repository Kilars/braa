import { describe, it, expect } from 'vitest';
import { breedAppearance } from './dogAppearance';
import { Color3 } from '@babylonjs/core/Maths/math.color';

// ─── Slice 1: labrador returns the warm-tan baseline coat ────────────────────

describe('breedAppearance — labrador baseline', () => {
  it('returns a warm-tan coat for labrador', () => {
    const appearance = breedAppearance('labrador');
    // Warm tan: R > G > B, all in mid-range (0.6–0.85)
    expect(appearance.coat.r).toBeGreaterThan(0.7);
    expect(appearance.coat.g).toBeGreaterThan(0.5);
    expect(appearance.coat.b).toBeLessThan(0.55);
  });
});

// ─── Slice 2: each catalog breed returns a DISTINCT primary coat ─────────────

const CATALOG_IDS = ['labrador', 'border-collie', 'bulldog', 'husky', 'puddel'];

function coatKey(c: Color3): string {
  return `${c.r.toFixed(3)},${c.g.toFixed(3)},${c.b.toFixed(3)}`;
}

describe('breedAppearance — distinct coats per breed', () => {
  it('no two catalog breeds share the same primary coat color', () => {
    const keys = CATALOG_IDS.map(id => coatKey(breedAppearance(id).coat));
    const unique = new Set(keys);
    expect(unique.size).toBe(CATALOG_IDS.length);
  });
});

// ─── Slice 3: unknown id falls back to the Labrador baseline — no throw ──────

describe('breedAppearance — unknown id fallback', () => {
  it('returns the labrador baseline coat for an unknown breed id', () => {
    const labrador = breedAppearance('labrador');
    const unknown = breedAppearance('golden-retriever-not-in-catalog');
    expect(coatKey(unknown.coat)).toBe(coatKey(labrador.coat));
  });

  it('does not throw for an unknown breed id', () => {
    expect(() => breedAppearance('totally-unknown-breed')).not.toThrow();
  });
});

// ─── Slice 4: proportion cues differ where the breed implies it ───────────────

describe('breedAppearance — proportion cues', () => {
  it('bulldog is stockier than labrador (bodyGirth > 1)', () => {
    expect(breedAppearance('bulldog').bodyGirth).toBeGreaterThan(
      breedAppearance('labrador').bodyGirth,
    );
  });

  it('bulldog has shorter legs than labrador (legLength < 1)', () => {
    expect(breedAppearance('bulldog').legLength).toBeLessThan(
      breedAppearance('labrador').legLength,
    );
  });

  it('husky has pricked ears', () => {
    expect(breedAppearance('husky').earStyle).toBe('pricked');
  });

  it('border-collie has pricked ears', () => {
    expect(breedAppearance('border-collie').earStyle).toBe('pricked');
  });

  it('labrador has floppy ears', () => {
    expect(breedAppearance('labrador').earStyle).toBe('floppy');
  });

  it('labrador bodyGirth is 1 (baseline)', () => {
    expect(breedAppearance('labrador').bodyGirth).toBe(1);
  });

  it('labrador legLength is 1 (baseline)', () => {
    expect(breedAppearance('labrador').legLength).toBe(1);
  });
});
