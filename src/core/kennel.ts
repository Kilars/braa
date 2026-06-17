// Kennel — idle income and upgrade multipliers (pure, no DOM)

export interface KennelUpgrade {
  id: string;
  name: string;
  cost: number;
  payoutMultiplier: number;
}

export const KENNEL_UPGRADES: KennelUpgrade[] = [
  { id: 'treats-pouch',   name: 'Treats Pouch',      cost: 100, payoutMultiplier: 1.2 },
  { id: 'clicker-pro',    name: 'Pro Clicker',        cost: 250, payoutMultiplier: 1.5 },
  { id: 'training-dummy', name: 'Training Dummy',     cost: 500, payoutMultiplier: 2.0 },
];

/** Coins earned per millisecond while idle. */
export const IDLE_RATE_PER_MS: number = 0.001; // 1 coin per second

/** Maximum coins collectible per return (well below one active session). */
export const IDLE_CAP_COINS: number = 110;

/**
 * Composite payout multiplier from all owned kennel upgrades.
 * Returns 1 when no upgrades are owned (identity for multiplication).
 */
export function kennelMultiplier(ownedIds: string[]): number {
  if (ownedIds.length === 0) return 1;
  return ownedIds.reduce((acc, id) => {
    const upgrade = KENNEL_UPGRADES.find((u) => u.id === id);
    return upgrade ? acc * upgrade.payoutMultiplier : acc;
  }, 1);
}

/**
 * Whether the player can buy an upgrade.
 * Returns false if already owned, false if coins < cost, true otherwise.
 */
export function canBuy(ownedIds: string[], upgrade: KennelUpgrade, coins: number): boolean {
  if (ownedIds.includes(upgrade.id)) return false;
  if (coins < upgrade.cost) return false;
  return true;
}

/**
 * Coins earned from idle time between `idleTimestamp` and `now`.
 * Returns 0 if elapsed is zero or negative. Capped at IDLE_CAP_COINS. Integer result.
 */
export function idleIncome(idleTimestamp: number, now: number): number {
  const elapsed = now - idleTimestamp;
  if (elapsed <= 0) return 0;
  return Math.min(Math.floor(elapsed * IDLE_RATE_PER_MS), IDLE_CAP_COINS);
}
