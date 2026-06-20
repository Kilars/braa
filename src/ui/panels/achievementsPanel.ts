import type { PanelHandle } from './panelManager';
import type { Achievement } from '../../core/achievements';

export interface AchievementsPanelDeps {
  getAchievementsState: () => { achievements: Achievement[]; unlockedIds: string[] };
}

/**
 * Achievements list overlay. Refreshes its rows from the latest unlocked set
 * on open. DOM ids/classes match the former inline block in hud.ts exactly.
 */
export function createAchievementsPanel(deps: AchievementsPanelDeps): PanelHandle {
  const achievementsPanelEl = document.createElement('div');
  achievementsPanelEl.id = 'achievements-panel';
  achievementsPanelEl.setAttribute('role', 'dialog');
  achievementsPanelEl.setAttribute('aria-modal', 'true');
  achievementsPanelEl.setAttribute('aria-label', 'Achievements');

  const achievementsHeaderEl = document.createElement('div');
  achievementsHeaderEl.id = 'achievements-panel-header';

  const achievementsTitleEl = document.createElement('div');
  achievementsTitleEl.id = 'achievements-panel-title';
  achievementsTitleEl.textContent = '🏆 Achievements';

  const achievementsCloseBtn = document.createElement('button');
  achievementsCloseBtn.id = 'achievements-panel-close';
  achievementsCloseBtn.type = 'button';
  achievementsCloseBtn.textContent = '✕';
  achievementsCloseBtn.setAttribute('aria-label', 'Close achievements');

  achievementsHeaderEl.appendChild(achievementsTitleEl);
  achievementsHeaderEl.appendChild(achievementsCloseBtn);

  const achievementsListEl = document.createElement('div');
  achievementsListEl.id = 'achievements-panel-list';

  achievementsPanelEl.appendChild(achievementsHeaderEl);
  achievementsPanelEl.appendChild(achievementsListEl);
  document.body.appendChild(achievementsPanelEl);

  function refresh(): void {
    const { achievements, unlockedIds } = deps.getAchievementsState();
    achievementsListEl.innerHTML = '';
    for (const ach of achievements) {
      const unlocked = unlockedIds.includes(ach.id);
      const rowEl = document.createElement('div');
      rowEl.className = 'achievement-row' + (unlocked ? ' unlocked' : ' locked');

      const iconEl = document.createElement('div');
      iconEl.className = 'achievement-icon';
      iconEl.textContent = unlocked ? '✓' : '○';
      iconEl.setAttribute('aria-hidden', 'true');

      const infoEl = document.createElement('div');
      infoEl.className = 'achievement-info';

      const nameEl = document.createElement('div');
      nameEl.className = 'achievement-name';
      nameEl.textContent = ach.name;

      const descEl = document.createElement('div');
      descEl.className = 'achievement-desc';
      descEl.textContent = ach.description;

      infoEl.appendChild(nameEl);
      infoEl.appendChild(descEl);

      rowEl.appendChild(iconEl);
      rowEl.appendChild(infoEl);
      achievementsListEl.appendChild(rowEl);
    }
  }

  function open(): void {
    refresh();
    achievementsPanelEl.style.display = 'flex';
  }

  function close(): void {
    achievementsPanelEl.style.display = 'none';
  }

  achievementsCloseBtn.addEventListener('pointerdown', (e) => {
    e.preventDefault();
    close();
  });

  achievementsPanelEl.style.display = 'none';

  return { el: achievementsPanelEl, open, close };
}
