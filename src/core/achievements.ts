import type { Dog } from './roster';
import { STARTER_TRICKS } from './tricks';

export interface Achievement {
  id: string;
  name: string;
  description: string;
}

export interface AchState {
  roster: Dog[];
  coins: number;
  prestigePoints: number;
  bestCombo: number;
}

export const ACHIEVEMENTS: Achievement[] = [
  {
    id: 'first-mark',
    name: 'First Mark',
    description: 'Have any dog master their first trick.',
  },
  {
    id: 'full-repertoire',
    name: 'Full Repertoire',
    description: 'Have a dog master all starter tricks.',
  },
  {
    id: 'collector',
    name: 'Collector',
    description: 'Adopt a second dog.',
  },
  {
    id: 'combo-10',
    name: 'Combo Master',
    description: 'Reach a combo streak of 10.',
  },
  {
    id: 'graduate',
    name: 'Graduate',
    description: 'Graduate a fully-trained dog for prestige.',
  },
  {
    id: 'wealthy',
    name: 'Wealthy',
    description: 'Accumulate 500 coins.',
  },
];

export function unlockedAchievements(s: AchState): string[] {
  const ids: string[] = [];

  // first-mark: any dog has >= 1 mastered trick
  if (s.roster.some(d => d.masteredTrickIds.length >= 1)) {
    ids.push('first-mark');
  }

  // full-repertoire: some dog mastered all STARTER_TRICKS
  const starterIds = STARTER_TRICKS.map(t => t.id);
  if (s.roster.some(d => starterIds.every(id => d.masteredTrickIds.includes(id)))) {
    ids.push('full-repertoire');
  }

  // collector: roster has >= 2 dogs
  if (s.roster.length >= 2) {
    ids.push('collector');
  }

  // combo-10: bestCombo >= 10
  if (s.bestCombo >= 10) {
    ids.push('combo-10');
  }

  // graduate: prestigePoints >= 1
  if (s.prestigePoints >= 1) {
    ids.push('graduate');
  }

  // wealthy: coins >= 500
  if (s.coins >= 500) {
    ids.push('wealthy');
  }

  return ids;
}
