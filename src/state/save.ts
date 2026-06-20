import type { Profile } from '../core/economy';
import type { DifficultyMode } from '../core/difficulty';
import type { Dog } from '../core/roster';
import { STARTER_BREED } from '../core/breeds';

export const STARTER_ROSTER: Dog[] = [
  { id: 'rex', name: 'Rex', breedId: STARTER_BREED.id, masteredTrickIds: [] },
];

export interface GameSave {
  profile: Profile;
  idleTimestamp: number;
  kennelUpgradeIds: string[];
  difficultyMode: DifficultyMode;
  roster: Dog[];
  /** Phrase ids the player has unlocked; base phrase ('bra') is always available implicitly. */
  unlockedPhraseIds: string[];
  /** Accumulated prestige points from graduating dogs; defaults 0 for old saves. */
  prestigePoints: number;
  /** Whether audio is muted; defaults false for old saves. */
  muted: boolean;
  /** Best combo streak ever reached; defaults 0 for old saves. */
  bestCombo: number;
  /** Consecutive days played; defaults 0 for old saves. */
  streak: number;
  /** Last day played as YYYY-MM-DD; defaults '' for old saves. */
  lastPlayedYmd: string;
  /** Dog id of the round in progress, or null if none. Defaults null for old saves. */
  activeRoundDogId: string | null;
  /** Trick id of the round in progress, or null if none. Defaults null for old saves. */
  activeTrickId: string | null;
  /** Partial learned-bar (0–100) of the in-progress round. Defaults 0 for old saves. */
  learnedBar: number;
}

export function serialize(save: GameSave): string {
  return JSON.stringify(save);
}

export function deserialize(raw: string): GameSave | null {
  try {
    const parsed = JSON.parse(raw) as Partial<GameSave> & Pick<GameSave, 'profile' | 'idleTimestamp'>;
    return {
      profile: parsed.profile,
      idleTimestamp: parsed.idleTimestamp,
      kennelUpgradeIds: parsed.kennelUpgradeIds ?? [],
      difficultyMode: parsed.difficultyMode ?? 'NORMAL',
      roster: parsed.roster ?? STARTER_ROSTER,
      unlockedPhraseIds: parsed.unlockedPhraseIds ?? [],
      prestigePoints: parsed.prestigePoints ?? 0,
      muted: parsed.muted ?? false,
      bestCombo: parsed.bestCombo ?? 0,
      streak: parsed.streak ?? 0,
      lastPlayedYmd: parsed.lastPlayedYmd ?? '',
      activeRoundDogId: parsed.activeRoundDogId ?? null,
      activeTrickId: parsed.activeTrickId ?? null,
      learnedBar: parsed.learnedBar ?? 0,
    };
  } catch {
    return null;
  }
}
