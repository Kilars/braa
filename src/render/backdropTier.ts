/**
 * src/render/backdropTier.ts
 *
 * Pure, Babylon-free tier resolution for the kennel backdrop upgrade system.
 *
 * `kennelTier` maps a set of owned upgrade ids to a visual tier (0–3).
 * `backdropTierConfig` returns per-tier visual parameters used by backdrop.ts
 * to drive procedural prop placement and colour/light adjustments.
 *
 * No Babylon import — fully unit-testable in Vitest without a WebGL context.
 */

/** The three valid kennel upgrade ids (mirrors KENNEL_UPGRADES in core/kennel.ts). */
const KNOWN_UPGRADE_IDS = new Set(['treats-pouch', 'clicker-pro', 'training-dummy']);

/**
 * Resolve the visual tier (0–3) from the player's owned upgrade ids.
 *
 * - Unknown ids are silently ignored (stale-save safety).
 * - Duplicates are de-duplicated before counting (distinct valid ids only).
 * - Result is clamped to [0, 3].
 */
export function kennelTier(ownedUpgradeIds: string[]): 0 | 1 | 2 | 3 {
  const distinct = new Set(ownedUpgradeIds.filter(id => KNOWN_UPGRADE_IDS.has(id)));
  return Math.min(3, distinct.size) as 0 | 1 | 2 | 3;
}

/** Visual configuration for one tier of the training-ground backdrop. */
export interface BackdropTierConfig {
  /**
   * Monotonically non-decreasing scalar [0, 1] representing overall
   * environmental richness. Used by backdrop.ts to drive colour/light
   * interpolations and prop counts without needing to switch on tier.
   */
  lushness: number;

  /**
   * Number of bush props to spawn at the scene edges.
   * Each bush is a low-poly sphere; placed symmetrically in the far corners.
   */
  bushCount: number;

  /**
   * Whether to add an agility prop set (cone pair + low jump bar).
   * Placed far to one side, well outside the dog's D12 framing zone.
   */
  agilityProps: boolean;

  /**
   * Whether to add a fence-line segment in the far background.
   * Adds the fullest sense of an established training ground.
   */
  fenceLine: boolean;

  /**
   * Fill-light intensity boost applied to the HemisphericLight [0, 1].
   * Higher tiers get a slightly warmer, brighter ambient fill.
   */
  fillBoost: number;

  /**
   * Ground green tint additive [0, 1].
   * Higher tiers push the grass a little richer/greener.
   */
  groundGreenBoost: number;
}

/**
 * Return the visual configuration for a given tier.
 *
 * The `lushness` field strictly increases across tiers 0→3 so callers can
 * interpolate colours/light without branching on the tier number.
 */
export function backdropTierConfig(tier: 0 | 1 | 2 | 3): BackdropTierConfig {
  switch (tier) {
    case 0:
      return {
        lushness:        0.0,
        bushCount:       0,
        agilityProps:    false,
        fenceLine:       false,
        fillBoost:       0.0,
        groundGreenBoost: 0.0,
      };
    case 1:
      return {
        lushness:        0.33,
        bushCount:       2,
        agilityProps:    false,
        fenceLine:       false,
        fillBoost:       0.08,
        groundGreenBoost: 0.06,
      };
    case 2:
      return {
        lushness:        0.66,
        bushCount:       4,
        agilityProps:    true,
        fenceLine:       false,
        fillBoost:       0.14,
        groundGreenBoost: 0.12,
      };
    case 3:
      return {
        lushness:        1.0,
        bushCount:       6,
        agilityProps:    true,
        fenceLine:       true,
        fillBoost:       0.20,
        groundGreenBoost: 0.18,
      };
  }
}
