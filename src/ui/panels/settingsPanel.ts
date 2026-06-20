import type { PanelHandle } from './panelManager';

export interface SettingsPanelDeps {
  isMuted: () => boolean;
  onToggleMute: (muted: boolean) => void;
  onResetProgress: () => Promise<void>;
  getStats: () => { prestigePoints: number; coins: number; level: number; tricksMastered: number; streak: number };
  /** Open the achievements panel (routed through the HUD's panel manager). */
  onOpenAchievements: () => void;
}

/**
 * Settings overlay: mute toggle, achievements entry, two-tap reset, stats
 * readout. The reset-confirm timer is panel-local state reset on close. DOM
 * ids/classes match the former inline block in hud.ts exactly.
 */
export function createSettingsPanel(deps: SettingsPanelDeps): PanelHandle {
  const settingsPanelEl = document.createElement('div');
  settingsPanelEl.id = 'settings-panel';
  settingsPanelEl.setAttribute('role', 'dialog');
  settingsPanelEl.setAttribute('aria-modal', 'true');
  settingsPanelEl.setAttribute('aria-label', 'Settings');

  const settingsHeaderEl = document.createElement('div');
  settingsHeaderEl.id = 'settings-panel-header';

  const settingsTitleEl = document.createElement('div');
  settingsTitleEl.id = 'settings-panel-title';
  settingsTitleEl.textContent = 'Settings';

  const settingsCloseBtn = document.createElement('button');
  settingsCloseBtn.id = 'settings-panel-close';
  settingsCloseBtn.type = 'button';
  settingsCloseBtn.textContent = '✕';
  settingsCloseBtn.setAttribute('aria-label', 'Close settings');

  settingsHeaderEl.appendChild(settingsTitleEl);
  settingsHeaderEl.appendChild(settingsCloseBtn);

  const settingsBodyEl = document.createElement('div');
  settingsBodyEl.id = 'settings-panel-body';

  // ── Mute toggle row ──────────────────────────────────────────────────
  const muteRowEl = document.createElement('div');
  muteRowEl.className = 'settings-row';

  const muteLabelEl = document.createElement('label');
  muteLabelEl.className = 'settings-row-label';
  muteLabelEl.textContent = 'Mute audio';
  muteLabelEl.setAttribute('for', 'settings-mute-toggle');

  const muteToggleEl = document.createElement('input');
  muteToggleEl.id = 'settings-mute-toggle';
  muteToggleEl.type = 'checkbox';
  muteToggleEl.className = 'settings-toggle';
  muteToggleEl.setAttribute('aria-label', 'Mute audio');

  muteRowEl.appendChild(muteLabelEl);
  muteRowEl.appendChild(muteToggleEl);

  // ── Reset progress row ───────────────────────────────────────────────
  const resetRowEl = document.createElement('div');
  resetRowEl.className = 'settings-row settings-row--reset';

  const resetBtnEl = document.createElement('button');
  resetBtnEl.id = 'settings-reset-btn';
  resetBtnEl.type = 'button';
  resetBtnEl.textContent = 'Reset progress';
  resetBtnEl.setAttribute('aria-label', 'Reset all progress');

  resetRowEl.appendChild(resetBtnEl);

  // ── Stats readout row ────────────────────────────────────────────────
  const statsRowEl = document.createElement('div');
  statsRowEl.id = 'settings-stats';
  statsRowEl.className = 'settings-row settings-row--stats';

  // ── Achievements button row ──────────────────────────────────────────
  const achievementsBtnRowEl = document.createElement('div');
  achievementsBtnRowEl.className = 'settings-row settings-row--achievements';

  const achievementsBtnEl = document.createElement('button');
  achievementsBtnEl.id = 'settings-achievements-btn';
  achievementsBtnEl.type = 'button';
  achievementsBtnEl.textContent = '🏆 Achievements';
  achievementsBtnEl.setAttribute('aria-label', 'View achievements');

  achievementsBtnRowEl.appendChild(achievementsBtnEl);

  settingsBodyEl.appendChild(muteRowEl);
  settingsBodyEl.appendChild(achievementsBtnRowEl);
  settingsBodyEl.appendChild(resetRowEl);
  settingsBodyEl.appendChild(statsRowEl);

  settingsPanelEl.appendChild(settingsHeaderEl);
  settingsPanelEl.appendChild(settingsBodyEl);
  document.body.appendChild(settingsPanelEl);

  // ── Panel wiring ─────────────────────────────────────────────────────
  let resetConfirmPending = false;
  let resetConfirmTimer: ReturnType<typeof setTimeout> | null = null;

  function refresh(): void {
    muteToggleEl.checked = deps.isMuted();
    const { prestigePoints, coins, level, tricksMastered, streak } = deps.getStats();
    statsRowEl.innerHTML = '';

    const items: [string, string | number][] = [
      ['Prestige', prestigePoints > 0 ? `★${prestigePoints}` : '—'],
      ['Coins', `🪙 ${coins}`],
      ['Level', level],
      ['Tricks mastered', tricksMastered],
      ['Streak', `🔥 ${streak}-day streak`],
    ];
    for (const [label, value] of items) {
      const itemEl = document.createElement('div');
      itemEl.className = 'settings-stat-item';
      const labelEl = document.createElement('span');
      labelEl.className = 'settings-stat-label';
      labelEl.textContent = label;
      const valueEl = document.createElement('span');
      valueEl.className = 'settings-stat-value';
      valueEl.textContent = String(value);
      itemEl.appendChild(labelEl);
      itemEl.appendChild(valueEl);
      statsRowEl.appendChild(itemEl);
    }

    // Reset confirm button state
    resetConfirmPending = false;
    if (resetConfirmTimer !== null) {
      clearTimeout(resetConfirmTimer);
      resetConfirmTimer = null;
    }
    resetBtnEl.textContent = 'Reset progress';
    resetBtnEl.classList.remove('settings-reset-confirm');
  }

  function open(): void {
    refresh();
    settingsPanelEl.style.display = 'flex';
  }

  function close(): void {
    settingsPanelEl.style.display = 'none';
    resetConfirmPending = false;
    if (resetConfirmTimer !== null) {
      clearTimeout(resetConfirmTimer);
      resetConfirmTimer = null;
    }
    resetBtnEl.textContent = 'Reset progress';
    resetBtnEl.classList.remove('settings-reset-confirm');
  }

  muteToggleEl.addEventListener('change', () => {
    deps.onToggleMute(muteToggleEl.checked);
  });

  resetBtnEl.addEventListener('pointerdown', (e) => {
    e.preventDefault();
    if (!resetConfirmPending) {
      resetConfirmPending = true;
      resetBtnEl.textContent = 'Tap again to confirm';
      resetBtnEl.classList.add('settings-reset-confirm');
      resetConfirmTimer = setTimeout(() => {
        resetConfirmPending = false;
        resetBtnEl.textContent = 'Reset progress';
        resetBtnEl.classList.remove('settings-reset-confirm');
        resetConfirmTimer = null;
      }, 3000);
    } else {
      resetConfirmPending = false;
      if (resetConfirmTimer !== null) {
        clearTimeout(resetConfirmTimer);
        resetConfirmTimer = null;
      }
      void deps.onResetProgress();
    }
  });

  settingsCloseBtn.addEventListener('pointerdown', (e) => {
    e.preventDefault();
    close();
  });

  achievementsBtnEl.addEventListener('pointerdown', (e) => {
    e.preventDefault();
    deps.onOpenAchievements();
  });

  settingsPanelEl.style.display = 'none';

  return { el: settingsPanelEl, open, close };
}
