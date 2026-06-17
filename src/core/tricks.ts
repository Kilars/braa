export interface Trick {
  id: string;
  name: string;
  learnMult: number;       // 1 = baseline; <1 slower to learn (harder)
  windowMult: number;      // 1 = baseline; <1 tighter window (harder)
  distractorBonus: number; // added to distractorRate (harder); 0 = no extra
  untrain?: boolean;       // true = untraining trick (mark calm gaps, not behaviors)
}

export const STARTER_TRICKS: Trick[] = [
  // Sitt — baseline: easiest starter command
  { id: 'sitt',     name: 'Sitt',     learnMult: 1,    windowMult: 1,    distractorBonus: 0    },
  // Ligg — medium: hold the down position takes more repetition
  { id: 'ligg',     name: 'Ligg',     learnMult: 0.75, windowMult: 0.8,  distractorBonus: 0.1  },
  // Legg deg — hardest: settle/lie down takes a long time until it "realizes"
  { id: 'legg-deg', name: 'Legg deg', learnMult: 0.5,  windowMult: 0.6,  distractorBonus: 0.2  },
];

// Untraining tricks: mark the CALM (absence of bad habit), not the behavior.
// Distractors represent the bad habit (jumping, barking, etc).
export const UNTRAIN_TRICKS: Trick[] = [
  // Ikke hopp — medium-hard: catching the dog NOT jumping takes consistent reinforcement
  { id: 'no-jump', name: 'Ikke hopp', learnMult: 0.8, windowMult: 0.9, distractorBonus: 0.3, untrain: true },
];

// Signature tricks — one per non-starter breed; unlocked by owning that breed.
export const SIGNATURE_TRICKS: Trick[] = [
  // Rull — roll over; Border Collie's high drive makes it flashy but demanding
  { id: 'rull', name: 'Rull', learnMult: 0.65, windowMult: 0.7,  distractorBonus: 0.25 },
  // Ul — howl on cue; Husky's vocal nature makes it eager but distracted
  { id: 'ul',   name: 'Ul',   learnMult: 0.7,  windowMult: 0.75, distractorBonus: 0.2  },
  // Sov — play dead; Bulldog's stubbornness makes it slow to learn but steady once clicked
  { id: 'sov',  name: 'Sov',  learnMult: 0.55, windowMult: 0.65, distractorBonus: 0.15 },
  // Snurr — spin; Puddel's eagerness and athleticism make it snappy but a bit distracting
  { id: 'snurr', name: 'Snurr', learnMult: 0.75, windowMult: 0.8, distractorBonus: 0.2 },
];

export function lookupTrick(id: string): Trick | undefined {
  return [...STARTER_TRICKS, ...UNTRAIN_TRICKS, ...SIGNATURE_TRICKS].find(t => t.id === id);
}

// Returns the tricks available for a given breed:
// always starters + the breed's signature trick (if any).
// Untraining tricks are appended separately by main.ts based on onboarding stage.
export function tricksForBreed(breed: { signatureTrickId?: string }): Trick[] {
  if (!breed.signatureTrickId) return [...STARTER_TRICKS];
  const sig = lookupTrick(breed.signatureTrickId);
  if (!sig) return [...STARTER_TRICKS];
  return [...STARTER_TRICKS, sig];
}
