// Economy & Progression — pure functions, immutable Profile
//
// Level table (simple quadratic progression):
//   Level 1:    0 XP
//   Level 2:  100 XP
//   Level 3:  300 XP
//   Level 4:  600 XP
//   Level 5: 1000 XP
//   Level N: (N-1)*N/2 * 100  (triangular × 100)

export interface Profile { coins: number; xp: number; level: number; }
export interface Payout  { coins: number; xp: number; }

// XP thresholds for each level — index = level number, value = XP required to reach it.
// Level 1 requires 0 XP; level 2 requires 100 XP; etc.
const LEVEL_THRESHOLDS: number[] = [
  0,     // sentinel — level 0 unused
  0,     // level 1:    0 XP
  100,   // level 2:  100 XP
  300,   // level 3:  300 XP
  600,   // level 4:  600 XP
  1000,  // level 5: 1000 XP
];

export function newProfile(): Profile {
  return { coins: 0, xp: 0, level: 1 };
}

export function levelForXp(xp: number): number {
  let level = 1;
  for (let i = 1; i < LEVEL_THRESHOLDS.length; i++) {
    if (xp >= LEVEL_THRESHOLDS[i]) {
      level = i;
    }
  }
  return level;
}

export function award(p: Profile, base: Payout, multiplier: number): Profile {
  const newCoins = p.coins + Math.round(base.coins * multiplier);
  const newXp    = p.xp    + Math.round(base.xp    * multiplier);
  return { coins: newCoins, xp: newXp, level: levelForXp(newXp) };
}

export function spend(p: Profile, price: number): Profile | null {
  if (p.coins < price) return null;
  return { ...p, coins: p.coins - price };
}

export function isTierUnlocked(level: number, requiredLevel: number): boolean {
  return level >= requiredLevel;
}
