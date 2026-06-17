import { Color3 } from '@babylonjs/core/Maths/math.color';

export interface DogAppearance {
  coat: Color3;
  coatBelly?: Color3;
  bodyGirth: number;   // proportion multiplier (1 = baseline)
  legLength: number;   // proportion multiplier (1 = baseline)
  earStyle: 'floppy' | 'pricked';
}

// Labrador baseline — warm tan, medium build, floppy ears
const LAB: DogAppearance = {
  coat: new Color3(0.76, 0.6, 0.42),
  bodyGirth: 1,
  legLength: 1,
  earStyle: 'floppy',
};

const APPEARANCE: Record<string, DogAppearance> = {
  labrador: LAB,

  // Border Collie — dark/black body, white belly, lean build, pricked ears
  'border-collie': {
    coat: new Color3(0.1, 0.1, 0.1),
    coatBelly: new Color3(0.95, 0.95, 0.95),
    bodyGirth: 0.95,
    legLength: 1.05,
    earStyle: 'pricked',
  },

  // Bulldog — orange-brindle, very stocky and short legs (unmistakably squat)
  bulldog: {
    coat: new Color3(0.88, 0.58, 0.28),
    bodyGirth: 1.35,
    legLength: 0.7,
    earStyle: 'floppy',
  },

  // Husky — cool grey body, white belly, athletic build, pricked ears
  husky: {
    coat: new Color3(0.55, 0.58, 0.62),
    coatBelly: new Color3(0.95, 0.95, 0.95),
    bodyGirth: 1.0,
    legLength: 1.1,
    earStyle: 'pricked',
  },

  // Puddel (Poodle) — off-white / pale cream; the lightest of all breeds
  // Classic silver/white poodle coat; maximally distinct from Border Collie near-black
  puddel: {
    coat: new Color3(0.90, 0.88, 0.82),
    bodyGirth: 1.05,
    legLength: 1.05,
    earStyle: 'floppy',
  },
};

/**
 * Returns the visual appearance for a given breed id.
 * Unknown ids fall back to the Labrador baseline — no throw, new breeds
 * automatically look like Labradors until given an entry.
 */
export function breedAppearance(breedId: string): DogAppearance {
  return APPEARANCE[breedId] ?? LAB;
}
