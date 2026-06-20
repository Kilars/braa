// @vitest-environment jsdom
import { describe, it, expect, beforeEach } from 'vitest';
import { createAchievementsPanel } from './achievementsPanel';
import type { Achievement } from '../../core/achievements';

const achievements: Achievement[] = [
  { id: 'first-mark', name: 'First Mark', description: 'Master a trick.' },
  { id: 'combo-king', name: 'Combo King', description: 'Reach a big combo.' },
];

beforeEach(() => {
  document.body.innerHTML = '';
});

describe('createAchievementsPanel — locked vs unlocked rendering', () => {
  it('renders an unlocked achievement with the unlocked class and a ✓ icon', () => {
    const handle = createAchievementsPanel({
      getAchievementsState: () => ({ achievements, unlockedIds: ['first-mark'] }),
    });
    handle.open();
    const rows = handle.el.querySelectorAll('.achievement-row');
    expect(rows.length).toBe(2);

    const unlocked = rows[0];
    expect(unlocked.classList.contains('unlocked')).toBe(true);
    expect(unlocked.querySelector('.achievement-icon')!.textContent).toBe('✓');
    expect(unlocked.querySelector('.achievement-name')!.textContent).toBe('First Mark');
  });

  it('renders a locked achievement with the locked class and a ○ icon', () => {
    const handle = createAchievementsPanel({
      getAchievementsState: () => ({ achievements, unlockedIds: ['first-mark'] }),
    });
    handle.open();
    const locked = handle.el.querySelectorAll('.achievement-row')[1];
    expect(locked.classList.contains('locked')).toBe(true);
    expect(locked.querySelector('.achievement-icon')!.textContent).toBe('○');
  });

  it('re-reads the unlocked set on each open (reflects newly earned achievements)', () => {
    let unlockedIds: string[] = [];
    const handle = createAchievementsPanel({
      getAchievementsState: () => ({ achievements, unlockedIds }),
    });
    handle.open();
    expect(handle.el.querySelectorAll('.achievement-row.unlocked').length).toBe(0);

    unlockedIds = ['first-mark', 'combo-king'];
    handle.close();
    handle.open();
    expect(handle.el.querySelectorAll('.achievement-row.unlocked').length).toBe(2);
  });
});
