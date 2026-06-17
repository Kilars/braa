import './hud.css';
import { HudViewModel } from './viewModel';
import type { Phrase, PhraseEntry } from '../core/phrases';
import { isReady } from '../core/phrases';
import type { DifficultyMode } from '../core/difficulty';
import type { Trick } from '../core/tricks';
import { KENNEL_UPGRADES, kennelMultiplier, canBuy } from '../core/kennel';
import type { Revealed } from '../core/onboarding';
import type { Dog } from '../core/roster';
import type { Breed } from '../core/breeds';
import type { Achievement } from '../core/achievements';

const RESULT_FLASH_MS = 700;

export interface HudCallbacks {
  onBraTap: () => void;
  /** @deprecated use getLoadoutState instead — kept for backward compat */
  getPhrase: () => { phrase: Phrase; lastUsedAt: number | null };
  onSelectMode: (mode: DifficultyMode) => void;
  initialMode: DifficultyMode;
  // Select-screen
  onSelectTrick: (trick: Trick) => void;
  getTricks: () => { trick: Trick; mastered: boolean }[];
  getDogName: () => string;
  // Roster: pick active dog
  getRoster: () => { dog: Dog; isActive: boolean }[];
  onSelectDog: (dogId: string) => void;
  // Adopt shop
  getAdoptableBreeds: () => { breed: Breed; affordable: boolean; levelGated: boolean }[];
  onAdoptBreed: (breedId: string) => void;
  // Kennel shop
  getKennelState: () => { kennelUpgradeIds: string[]; coins: number };
  onBuyUpgrade: (upgradeId: string) => void;
  // Phrase loadout switcher
  onCyclePhrase: () => void;
  onUnlockNextPhrase: () => boolean;
  getLoadoutState: () => {
    loadedPhrase: Phrase;
    lastUsedAt: number | null;
    available: Phrase[];
    nextLocked: PhraseEntry | null;
    /** True when nextLocked is blocked by level (not by coins). */
    nextLockedIsLevelGated: boolean;
    coins: number;
  };
  // Onboarding staged reveal flags
  revealed: Revealed;
  // Prestige / graduation
  canGraduateActiveDog: () => boolean;
  onGraduate: () => void;
  getPrestigePoints: () => number;
  // Settings panel
  isMuted: () => boolean;
  onToggleMute: (muted: boolean) => void;
  onResetProgress: () => Promise<void>;
  getStats: () => { prestigePoints: number; coins: number; level: number; tricksMastered: number; streak: number };
  // Achievements panel
  getAchievementsState: () => { achievements: Achievement[]; unlockedIds: string[] };
}

/**
 * Creates the DOM HUD overlay and returns an update function.
 * The overlay sits above the Babylon canvas (z-index: 10).
 * All logic lives in viewModel.ts — this file only touches the DOM.
 */
export function createHud(callbacks: HudCallbacks): {
  renderTraining: (vm: HudViewModel) => void;
  showSelect: () => void;
  showTraining: (trickName: string) => void;
  refreshKennelPanel: () => void;
  applyRevealed: (revealed: Revealed) => void;
  showLoading: () => void;
  hideLoading: () => void;
  celebrate: () => void;
} {
  // ── Loading indicator ─────────────────────────────────────────
  // Shown while Babylon lazy-loads; hidden by default. pointer-events:none
  // so it never blocks canvas/HUD input.
  const loadingEl = document.createElement('div');
  loadingEl.id = 'hud-loading';
  loadingEl.setAttribute('aria-live', 'polite');
  loadingEl.setAttribute('aria-label', 'Loading scene');
  const loadingSpinnerEl = document.createElement('div');
  loadingSpinnerEl.id = 'hud-loading-spinner';
  loadingSpinnerEl.setAttribute('aria-hidden', 'true');
  const loadingTextEl = document.createElement('span');
  loadingTextEl.id = 'hud-loading-text';
  loadingTextEl.textContent = 'Loading…';
  loadingEl.appendChild(loadingSpinnerEl);
  loadingEl.appendChild(loadingTextEl);
  document.body.appendChild(loadingEl);

  // ── Select screen ────────────────────────────────────────────
  const selectEl = document.createElement('div');
  selectEl.id = 'hud-select';

  const dogNameEl = document.createElement('div');
  dogNameEl.id = 'hud-select-dog';

  // Roster row: pick among owned dogs
  const rosterRowEl = document.createElement('div');
  rosterRowEl.id = 'hud-roster-row';

  const trickListEl = document.createElement('div');
  trickListEl.id = 'hud-select-tricks';

  // Prestige indicator (e.g. "Prestige ★2")
  const prestigeEl = document.createElement('div');
  prestigeEl.id = 'hud-prestige';

  // Graduate button — only shown when active dog is fully trained
  const graduateBtnEl = document.createElement('button');
  graduateBtnEl.id = 'hud-graduate-btn';
  graduateBtnEl.type = 'button';
  graduateBtnEl.textContent = '🎓 Graduate';
  graduateBtnEl.setAttribute('aria-label', 'Graduate active dog to prestige');

  // Adopt button (opens the adopt panel)
  const adoptBtnEl = document.createElement('button');
  adoptBtnEl.id = 'hud-adopt-btn';
  adoptBtnEl.type = 'button';
  adoptBtnEl.textContent = '+ Adopt Dog';

  // Kennel button on select screen (bottom-right corner)
  const kennelBtnEl = document.createElement('button');
  kennelBtnEl.id = 'hud-kennel-btn';
  kennelBtnEl.type = 'button';
  kennelBtnEl.textContent = '🏠 Kennel';

  // Settings button (top-right corner of select screen)
  const settingsBtnEl = document.createElement('button');
  settingsBtnEl.id = 'hud-settings-btn';
  settingsBtnEl.type = 'button';
  settingsBtnEl.textContent = '⚙';
  settingsBtnEl.setAttribute('aria-label', 'Settings');

  // Help button (top-left corner of select screen)
  const helpBtnEl = document.createElement('button');
  helpBtnEl.id = 'hud-help-btn';
  helpBtnEl.type = 'button';
  helpBtnEl.textContent = '?';
  helpBtnEl.setAttribute('aria-label', 'How to play');

  selectEl.appendChild(dogNameEl);
  selectEl.appendChild(rosterRowEl);
  selectEl.appendChild(trickListEl);
  selectEl.appendChild(prestigeEl);
  selectEl.appendChild(graduateBtnEl);
  selectEl.appendChild(adoptBtnEl);
  selectEl.appendChild(kennelBtnEl);
  selectEl.appendChild(settingsBtnEl);
  selectEl.appendChild(helpBtnEl);
  document.body.appendChild(selectEl);

  // ── Adopt panel (modal overlay) ────────────────────────────────────────
  const adoptPanelEl = document.createElement('div');
  adoptPanelEl.id = 'adopt-panel';
  adoptPanelEl.setAttribute('aria-modal', 'true');
  adoptPanelEl.setAttribute('role', 'dialog');
  adoptPanelEl.setAttribute('aria-label', 'Adopt a Dog');

  const adoptHeaderEl = document.createElement('div');
  adoptHeaderEl.id = 'adopt-panel-header';

  const adoptTitleEl = document.createElement('div');
  adoptTitleEl.id = 'adopt-panel-title';
  adoptTitleEl.textContent = 'Adopt a Dog';

  const adoptCloseBtn = document.createElement('button');
  adoptCloseBtn.id = 'adopt-panel-close';
  adoptCloseBtn.type = 'button';
  adoptCloseBtn.textContent = '✕';
  adoptCloseBtn.setAttribute('aria-label', 'Close adopt panel');

  adoptHeaderEl.appendChild(adoptTitleEl);
  adoptHeaderEl.appendChild(adoptCloseBtn);

  const adoptListEl = document.createElement('div');
  adoptListEl.id = 'adopt-panel-list';

  adoptPanelEl.appendChild(adoptHeaderEl);
  adoptPanelEl.appendChild(adoptListEl);
  document.body.appendChild(adoptPanelEl);

  // ── Kennel panel (modal overlay) ───────────────────────────────────────
  const kennelPanelEl = document.createElement('div');
  kennelPanelEl.id = 'kennel-panel';
  kennelPanelEl.setAttribute('aria-modal', 'true');
  kennelPanelEl.setAttribute('role', 'dialog');
  kennelPanelEl.setAttribute('aria-label', 'Kennel Shop');

  const kennelHeaderEl = document.createElement('div');
  kennelHeaderEl.id = 'kennel-panel-header';

  const kennelTitleEl = document.createElement('div');
  kennelTitleEl.id = 'kennel-panel-title';
  kennelTitleEl.textContent = 'Kennel Upgrades';

  const kennelMultiplierEl = document.createElement('div');
  kennelMultiplierEl.id = 'kennel-panel-multiplier';

  const kennelCloseBtn = document.createElement('button');
  kennelCloseBtn.id = 'kennel-panel-close';
  kennelCloseBtn.type = 'button';
  kennelCloseBtn.textContent = '✕';
  kennelCloseBtn.setAttribute('aria-label', 'Close kennel shop');

  kennelHeaderEl.appendChild(kennelTitleEl);
  kennelHeaderEl.appendChild(kennelMultiplierEl);
  kennelHeaderEl.appendChild(kennelCloseBtn);

  const kennelListEl = document.createElement('div');
  kennelListEl.id = 'kennel-panel-list';

  kennelPanelEl.appendChild(kennelHeaderEl);
  kennelPanelEl.appendChild(kennelListEl);
  document.body.appendChild(kennelPanelEl);

  // ── Settings panel (modal overlay) ────────────────────────────────────────
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

  // ── Help panel (modal overlay) ────────────────────────────────────────────
  const helpPanelEl = document.createElement('div');
  helpPanelEl.id = 'help-panel';
  helpPanelEl.setAttribute('role', 'dialog');
  helpPanelEl.setAttribute('aria-modal', 'true');
  helpPanelEl.setAttribute('aria-label', 'How to play');

  const helpHeaderEl = document.createElement('div');
  helpHeaderEl.id = 'help-panel-header';

  const helpTitleEl = document.createElement('div');
  helpTitleEl.id = 'help-panel-title';
  helpTitleEl.textContent = 'How to Play';

  const helpCloseBtn = document.createElement('button');
  helpCloseBtn.id = 'help-panel-close';
  helpCloseBtn.type = 'button';
  helpCloseBtn.textContent = '✕';
  helpCloseBtn.setAttribute('aria-label', 'Close how to play');

  helpHeaderEl.appendChild(helpTitleEl);
  helpHeaderEl.appendChild(helpCloseBtn);

  const helpBodyEl = document.createElement('div');
  helpBodyEl.id = 'help-panel-body';

  const helpItems: [string, string][] = [
    ['Watch the dog.', 'When it does the trick and a gold ring pulses around BRA, that\'s the moment.'],
    ['Tap BRA on the pulse.', 'Closer to the peak = better; fill the bar to 100% to master the trick.'],
    ['Don\'t tap the wrong thing.', 'A grey, turned-away dog is a distractor — marking it confuses your pup.'],
    ['Chain it.', 'Back-to-back good marks build a combo for bonus rewards.'],
    ['Pick your challenge.', 'Normal / Hard / Expert changes timing. Adopt new breeds and graduate fully-trained dogs for prestige.'],
  ];

  const helpListEl = document.createElement('ul');
  helpListEl.id = 'help-panel-list';

  for (const [bold, rest] of helpItems) {
    const li = document.createElement('li');
    li.className = 'help-panel-item';
    const boldEl = document.createElement('strong');
    boldEl.textContent = bold;
    li.appendChild(boldEl);
    li.appendChild(document.createTextNode(' ' + rest));
    helpListEl.appendChild(li);
  }

  const helpGotItBtn = document.createElement('button');
  helpGotItBtn.id = 'help-panel-got-it';
  helpGotItBtn.type = 'button';
  helpGotItBtn.textContent = 'Got it!';
  helpGotItBtn.setAttribute('aria-label', 'Close how to play');

  helpBodyEl.appendChild(helpListEl);
  helpBodyEl.appendChild(helpGotItBtn);

  helpPanelEl.appendChild(helpHeaderEl);
  helpPanelEl.appendChild(helpBodyEl);
  document.body.appendChild(helpPanelEl);

  // ── Achievements panel (modal overlay) ──────────────────────────────────────
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

  // ── Settings panel wiring ───────────────────────────────────────────
  let resetConfirmPending = false;
  let resetConfirmTimer: ReturnType<typeof setTimeout> | null = null;

  function refreshSettingsPanel(): void {
    muteToggleEl.checked = callbacks.isMuted();
    const { prestigePoints, coins, level, tricksMastered, streak } = callbacks.getStats();
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

  function openSettingsPanel(): void {
    closeAllPanels();
    refreshSettingsPanel();
    settingsPanelEl.style.display = 'flex';
  }

  function closeSettingsPanel(): void {
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
    callbacks.onToggleMute(muteToggleEl.checked);
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
      void callbacks.onResetProgress();
    }
  });

  settingsCloseBtn.addEventListener('pointerdown', (e) => {
    e.preventDefault();
    closeSettingsPanel();
  });

  settingsPanelEl.style.display = 'none';

  settingsBtnEl.addEventListener('pointerdown', (e) => {
    e.preventDefault();
    openSettingsPanel();
  });

  // ── Help panel wiring ───────────────────────────────────────────────────
  function openHelpPanel(): void {
    closeAllPanels();
    helpPanelEl.style.display = 'flex';
  }

  function closeHelpPanel(): void {
    helpPanelEl.style.display = 'none';
  }

  helpBtnEl.addEventListener('pointerdown', (e) => {
    e.preventDefault();
    openHelpPanel();
  });

  helpCloseBtn.addEventListener('pointerdown', (e) => {
    e.preventDefault();
    closeHelpPanel();
  });

  helpGotItBtn.addEventListener('pointerdown', (e) => {
    e.preventDefault();
    closeHelpPanel();
  });

  helpPanelEl.style.display = 'none';

  // ── Achievements panel wiring ────────────────────────────────────────────────
  function refreshAchievementsPanel(): void {
    const { achievements, unlockedIds } = callbacks.getAchievementsState();
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

  function openAchievementsPanel(): void {
    closeAllPanels();
    refreshAchievementsPanel();
    achievementsPanelEl.style.display = 'flex';
  }

  function closeAchievementsPanel(): void {
    achievementsPanelEl.style.display = 'none';
  }

  achievementsCloseBtn.addEventListener('pointerdown', (e) => {
    e.preventDefault();
    closeAchievementsPanel();
  });

  achievementsBtnEl.addEventListener('pointerdown', (e) => {
    e.preventDefault();
    openAchievementsPanel();
  });

  achievementsPanelEl.style.display = 'none';

  function refreshKennelPanel(): void {
    const { kennelUpgradeIds, coins } = callbacks.getKennelState();
    const mult = kennelMultiplier(kennelUpgradeIds);
    kennelMultiplierEl.textContent = `Payout multiplier: ×${mult.toFixed(2)}`;

    kennelListEl.innerHTML = '';
    for (const upgrade of KENNEL_UPGRADES) {
      const owned = kennelUpgradeIds.includes(upgrade.id);
      const affordable = canBuy(kennelUpgradeIds, upgrade, coins);

      const rowEl = document.createElement('div');
      rowEl.className = 'kennel-upgrade-row';
      if (owned) rowEl.classList.add('owned');
      else if (affordable) rowEl.classList.add('affordable');
      else rowEl.classList.add('too-expensive');

      const infoEl = document.createElement('div');
      infoEl.className = 'kennel-upgrade-info';

      const nameEl = document.createElement('div');
      nameEl.className = 'kennel-upgrade-name';
      nameEl.textContent = upgrade.name;

      const costEl = document.createElement('div');
      costEl.className = 'kennel-upgrade-cost';
      costEl.textContent = owned ? 'Owned' : `🪙 ${upgrade.cost}`;

      infoEl.appendChild(nameEl);
      infoEl.appendChild(costEl);

      const buyBtn = document.createElement('button');
      buyBtn.className = 'kennel-buy-btn';
      buyBtn.type = 'button';
      buyBtn.dataset['upgradeId'] = upgrade.id;

      if (owned) {
        buyBtn.textContent = '✓';
        buyBtn.disabled = true;
        buyBtn.setAttribute('aria-label', `${upgrade.name} — already owned`);
      } else if (affordable) {
        buyBtn.textContent = 'Buy';
        buyBtn.setAttribute('aria-label', `Buy ${upgrade.name} for ${upgrade.cost} coins`);
        buyBtn.addEventListener('pointerdown', (e) => {
          e.preventDefault();
          callbacks.onBuyUpgrade(upgrade.id);
          refreshKennelPanel();
        });
      } else {
        buyBtn.textContent = 'Buy';
        buyBtn.disabled = true;
        buyBtn.setAttribute('aria-label', `${upgrade.name} — not enough coins`);
      }

      rowEl.appendChild(infoEl);
      rowEl.appendChild(buyBtn);
      kennelListEl.appendChild(rowEl);
    }
  }

  function openKennelPanel(): void {
    closeAllPanels();
    refreshKennelPanel();
    kennelPanelEl.style.display = 'flex';
  }

  function closeKennelPanel(): void {
    kennelPanelEl.style.display = 'none';
  }

  kennelBtnEl.addEventListener('pointerdown', (e) => {
    e.preventDefault();
    openKennelPanel();
  });

  kennelCloseBtn.addEventListener('pointerdown', (e) => {
    e.preventDefault();
    closeKennelPanel();
  });

  kennelPanelEl.style.display = 'none';

  // ── Adopt panel wiring ──────────────────────────────────────────────────
  function refreshAdoptPanel(): void {
    adoptListEl.innerHTML = '';
    const breeds = callbacks.getAdoptableBreeds();
    if (breeds.length === 0) {
      const emptyEl = document.createElement('div');
      emptyEl.className = 'adopt-empty';
      emptyEl.textContent = 'You own all available breeds!';
      adoptListEl.appendChild(emptyEl);
      return;
    }
    for (const { breed, affordable, levelGated } of breeds) {
      const rowEl = document.createElement('div');
      // Distinguish level-locked from coin-locked so the player knows which gate blocks them
      rowEl.className = 'adopt-breed-row'
        + (affordable ? ' affordable' : levelGated ? ' level-locked' : ' too-expensive');

      const infoEl = document.createElement('div');
      infoEl.className = 'adopt-breed-info';

      const nameEl = document.createElement('div');
      nameEl.className = 'adopt-breed-name';
      nameEl.textContent = breed.name;

      const costEl = document.createElement('div');
      costEl.className = 'adopt-breed-cost';
      // Level wall: show required level, not a coin price (coins are moot until unlocked)
      costEl.textContent = levelGated ? `Lvl ${breed.requiredLevel ?? 1}` : `🪙 ${breed.adoptCost ?? 0}`;

      infoEl.appendChild(nameEl);
      infoEl.appendChild(costEl);

      const adoptBtn = document.createElement('button');
      adoptBtn.className = 'adopt-buy-btn';
      adoptBtn.type = 'button';
      adoptBtn.textContent = 'Adopt';
      adoptBtn.disabled = !affordable;
      adoptBtn.setAttribute('aria-label',
        affordable
          ? `Adopt ${breed.name} for ${breed.adoptCost ?? 0} coins`
          : levelGated
            ? `${breed.name} — reach level ${breed.requiredLevel ?? 1} to unlock`
            : `${breed.name} — not enough coins`
      );

      if (affordable) {
        adoptBtn.addEventListener('pointerdown', (e) => {
          e.preventDefault();
          callbacks.onAdoptBreed(breed.id);
          // Return to the refreshed select screen and dismiss the adopt panel
          showSelect();
          closeAdoptPanel();
        });
      }

      rowEl.appendChild(infoEl);
      rowEl.appendChild(adoptBtn);
      adoptListEl.appendChild(rowEl);
    }
  }

  function openAdoptPanel(): void {
    closeAllPanels();
    refreshAdoptPanel();
    adoptPanelEl.style.display = 'flex';
  }

  function closeAdoptPanel(): void {
    adoptPanelEl.style.display = 'none';
  }

  adoptBtnEl.addEventListener('pointerdown', (e) => {
    e.preventDefault();
    openAdoptPanel();
  });

  adoptCloseBtn.addEventListener('pointerdown', (e) => {
    e.preventDefault();
    closeAdoptPanel();
  });

  adoptPanelEl.style.display = 'none';

  // ── Panel exclusivity helper ─────────────────────────────────────────────
  // Close all overlay panels before opening a new one so at most one is
  // visible at any time. Calls each per-panel close fn so panel-local state
  // (e.g. settings reset-confirm timer) is properly reset.
  function closeAllPanels(): void {
    closeSettingsPanel();
    closeHelpPanel();
    closeAchievementsPanel();
    closeKennelPanel();
    closeAdoptPanel();
  }

  // ── Graduate button wiring ────────────────────────────────────────────────
  graduateBtnEl.addEventListener('pointerdown', (e) => {
    e.preventDefault();
    callbacks.onGraduate();
    showSelect();
  });

  // ── Training HUD ─────────────────────────────────────────────
  const hud = document.createElement('div');
  hud.id = 'hud';

  // Current trick label
  const trickLabelEl = document.createElement('div');
  trickLabelEl.id = 'hud-trick-label';

  // Learned bar track + fill
  const barTrack = document.createElement('div');
  barTrack.id = 'hud-bar-track';
  const barFill = document.createElement('div');
  barFill.id = 'hud-bar-fill';
  barFill.style.width = '0%';
  barTrack.appendChild(barFill);

  // Result flash label (center of screen)
  const resultEl = document.createElement('div');
  resultEl.id = 'hud-result';
  resultEl.setAttribute('aria-live', 'polite');

  // Top-right: coins + level badge
  const statsEl = document.createElement('div');
  statsEl.id = 'hud-stats';

  const coinsEl = document.createElement('span');
  coinsEl.id = 'hud-coins';
  coinsEl.textContent = '🪙 0';

  const levelEl = document.createElement('span');
  levelEl.id = 'hud-level';
  levelEl.textContent = 'Lv 1';

  statsEl.appendChild(coinsEl);
  statsEl.appendChild(levelEl);

  // Top-left: difficulty mode segmented control (below the bar, above loadout chip)
  const diffSelectorEl = document.createElement('div');
  diffSelectorEl.id = 'hud-diff-selector';
  diffSelectorEl.setAttribute('role', 'group');
  diffSelectorEl.setAttribute('aria-label', 'Difficulty');

  const MODES: DifficultyMode[] = ['NORMAL', 'HARD', 'EXPERT'];
  const LABELS: Record<DifficultyMode, string> = {
    NORMAL: 'Normal',
    HARD: 'Hard',
    EXPERT: 'Expert',
  };

  let activeMode: DifficultyMode = callbacks.initialMode;

  const modeButtons: Record<DifficultyMode, HTMLButtonElement> = {} as Record<DifficultyMode, HTMLButtonElement>;

  function updateModeHighlight(mode: DifficultyMode): void {
    for (const m of MODES) {
      modeButtons[m].classList.toggle('active', m === mode);
      modeButtons[m].setAttribute('aria-pressed', String(m === mode));
    }
  }

  for (const mode of MODES) {
    const btn = document.createElement('button');
    btn.className = 'hud-diff-btn';
    btn.dataset['mode'] = mode;
    btn.textContent = LABELS[mode];
    btn.type = 'button';
    btn.setAttribute('aria-pressed', String(mode === activeMode));
    btn.addEventListener('pointerdown', (e) => {
      e.preventDefault();
      activeMode = mode;
      updateModeHighlight(mode);
      callbacks.onSelectMode(mode);
    });
    modeButtons[mode] = btn;
    diffSelectorEl.appendChild(btn);
  }

  updateModeHighlight(activeMode);

  // Loadout chip — switcher: tap cycles phrases, shows unlock affordance
  const loadoutChipEl = document.createElement('div');
  loadoutChipEl.id = 'hud-loadout-chip';
  loadoutChipEl.setAttribute('role', 'button');
  loadoutChipEl.setAttribute('tabindex', '0');
  loadoutChipEl.setAttribute('aria-label', 'Switch phrase');

  const chipWordEl = document.createElement('span');
  chipWordEl.id = 'hud-loadout-word';

  const chipUnlockEl = document.createElement('button');
  chipUnlockEl.id = 'hud-loadout-unlock';
  chipUnlockEl.type = 'button';
  chipUnlockEl.setAttribute('aria-label', 'Unlock next phrase');

  loadoutChipEl.appendChild(chipWordEl);
  loadoutChipEl.appendChild(chipUnlockEl);

  // Bottom: mastered banner + BRA button (with tell-cue ring)
  const bottomEl = document.createElement('div');
  bottomEl.id = 'hud-bottom';

  const masteredEl = document.createElement('div');
  masteredEl.id = 'hud-mastered';
  masteredEl.textContent = 'MASTERED!';

  // Tell-cue wrapper: positions the ring relative to the button
  const tellWrapEl = document.createElement('div');
  tellWrapEl.id = 'hud-tell-wrap';

  const tellRingEl = document.createElement('div');
  tellRingEl.id = 'hud-tell-ring';

  const braBtn = document.createElement('button');
  braBtn.id = 'hud-bra-btn';
  braBtn.textContent = 'BRA';
  braBtn.setAttribute('aria-label', 'Mark behavior');
  braBtn.type = 'button';

  tellWrapEl.appendChild(tellRingEl);
  tellWrapEl.appendChild(braBtn);

  bottomEl.appendChild(masteredEl);
  bottomEl.appendChild(tellWrapEl);

  // Combo indicator — shown when combo >= 2; hidden at 0/1
  const comboEl = document.createElement('div');
  comboEl.id = 'hud-combo';
  comboEl.setAttribute('aria-live', 'polite');
  comboEl.setAttribute('aria-label', 'Combo streak');

  hud.appendChild(trickLabelEl);
  hud.appendChild(barTrack);
  hud.appendChild(statsEl);
  hud.appendChild(diffSelectorEl);
  hud.appendChild(resultEl);
  hud.appendChild(comboEl);
  hud.appendChild(loadoutChipEl);
  hud.appendChild(bottomEl);

  document.body.appendChild(hud);

  // ── Wire tap ────────────────────────────────────────────────
  let flashTimer: ReturnType<typeof setTimeout> | null = null;

  braBtn.addEventListener('pointerdown', (e) => {
    e.preventDefault();
    callbacks.onBraTap();
  });

  // Chip tap: cycle among available phrases
  loadoutChipEl.addEventListener('pointerdown', (e) => {
    // Don't cycle if the unlock button itself was tapped
    if ((e.target as Element).closest('#hud-loadout-unlock')) return;
    e.preventDefault();
    callbacks.onCyclePhrase();
  });

  // Keyboard support for the loadout chip (role=button div)
  loadoutChipEl.addEventListener('keydown', (e) => {
    if (e.key === 'Enter' || e.key === ' ') {
      if ((e.target as Element).closest('#hud-loadout-unlock')) return;
      e.preventDefault();
      callbacks.onCyclePhrase();
    }
  });

  chipUnlockEl.addEventListener('pointerdown', (e) => {
    e.preventDefault();
    e.stopPropagation();
    const success = callbacks.onUnlockNextPhrase();
    if (success) {
      // Brief visual feedback
      chipUnlockEl.classList.add('just-unlocked');
      setTimeout(() => chipUnlockEl.classList.remove('just-unlocked'), 600);
    }
  });

  // ── Render function ─────────────────────────────────────────
  let prevLastResult: string | null = null;

  function renderTraining(vm: HudViewModel): void {
    // Coins + level
    coinsEl.textContent = `🪙 ${vm.coins}`;
    levelEl.textContent = `Lv ${vm.level}`;

    // Bar fill
    barFill.style.width = `${vm.learnedPercent}%`;

    // State classes on root element
    hud.classList.toggle('confused', vm.confused);
    hud.classList.toggle('mastered', vm.mastered);

    // Tell cue: drive ring opacity + scale from tellStrength (0→invisible, 1→bright)
    const ts = vm.tellStrength;
    tellRingEl.style.opacity = String(ts);
    tellRingEl.style.transform = `scale(${1 + 0.18 * ts})`;
    hud.setAttribute('data-tell', ts.toFixed(3));

    // Result flash — only trigger on new result
    if (vm.lastResult !== null && vm.lastResult !== prevLastResult) {
      prevLastResult = vm.lastResult;

      resultEl.textContent = vm.lastResult === 'FALSE_MARK' ? 'FALSE MARK' : vm.lastResult;
      resultEl.setAttribute('data-result', vm.lastResult);
      resultEl.classList.add('visible');

      if (flashTimer !== null) clearTimeout(flashTimer);
      flashTimer = setTimeout(() => {
        resultEl.classList.remove('visible');
        flashTimer = null;
      }, RESULT_FLASH_MS);
    }

    // Combo indicator
    if (vm.combo >= 2) {
      comboEl.textContent = `x${vm.combo}`;
      comboEl.setAttribute('data-combo', String(vm.combo));
      comboEl.classList.add('visible');
    } else {
      comboEl.classList.remove('visible');
      comboEl.removeAttribute('data-combo');
    }

    // Loadout chip (switcher)
    const { loadedPhrase, lastUsedAt, available, nextLocked, nextLockedIsLevelGated, coins } = callbacks.getLoadoutState();
    const now = performance.now();
    const ready = isReady(loadedPhrase, now, lastUsedAt);
    chipWordEl.textContent = loadedPhrase.word;
    loadoutChipEl.classList.toggle('on-cooldown', !ready);
    loadoutChipEl.classList.toggle('can-cycle', available.length > 1);
    if (!ready && loadedPhrase.cooldownMs > 0 && lastUsedAt !== null) {
      const elapsed = now - lastUsedAt;
      const remaining = Math.max(0, loadedPhrase.cooldownMs - elapsed);
      const pct = (remaining / loadedPhrase.cooldownMs) * 100;
      loadoutChipEl.style.setProperty('--cooldown-pct', `${pct.toFixed(1)}%`);
    } else {
      loadoutChipEl.style.setProperty('--cooldown-pct', '0%');
    }
    // Unlock affordance: distinguish level-locked ("Lvl N") from coin-locked ("+word 🪙cost")
    if (nextLocked) {
      if (nextLockedIsLevelGated) {
        // Next phrase is behind a level wall — show required level, not a buy button
        chipUnlockEl.textContent = `Lvl ${nextLocked.unlockLevel}`;
        chipUnlockEl.style.display = 'inline-flex';
        chipUnlockEl.classList.remove('affordable');
        chipUnlockEl.classList.add('too-expensive');
        chipUnlockEl.disabled = true;
      } else {
        const canAfford = coins >= nextLocked.unlockCost;
        chipUnlockEl.textContent = `+${nextLocked.phrase.word} 🪙${nextLocked.unlockCost}`;
        chipUnlockEl.style.display = 'inline-flex';
        chipUnlockEl.classList.toggle('affordable', canAfford);
        chipUnlockEl.classList.toggle('too-expensive', !canAfford);
        chipUnlockEl.disabled = !canAfford;
      }
    } else {
      chipUnlockEl.style.display = 'none';
    }
  }

  function showLoading(): void {
    loadingEl.style.display = 'flex';
  }

  function hideLoading(): void {
    loadingEl.style.display = 'none';
  }

  function showSelect(): void {
    hideLoading();
    // Restore kennel button visibility for the select screen; if the
    // onboarding gate (.hud-gated) is still active it will keep it hidden.
    kennelBtnEl.classList.remove('kennel-btn-training-hidden');
    // Populate select screen
    dogNameEl.textContent = callbacks.getDogName();

    // Prestige indicator
    const pts = callbacks.getPrestigePoints();
    if (pts > 0) {
      prestigeEl.textContent = `Prestige ${'★'.repeat(pts)}${pts}`;
      prestigeEl.style.display = 'block';
    } else {
      prestigeEl.style.display = 'none';
    }

    // Graduate affordance — only shown when the active dog can graduate
    if (callbacks.canGraduateActiveDog()) {
      graduateBtnEl.style.display = 'block';
    } else {
      graduateBtnEl.style.display = 'none';
    }

    // Roster row: show all owned dogs; highlight the active one
    rosterRowEl.innerHTML = '';
    for (const { dog, isActive } of callbacks.getRoster()) {
      const btn = document.createElement('button');
      btn.className = 'hud-roster-btn' + (isActive ? ' active' : '');
      btn.dataset['dogId'] = dog.id;
      btn.type = 'button';
      btn.textContent = dog.name;
      btn.setAttribute('aria-pressed', String(isActive));
      if (!isActive) {
        btn.addEventListener('pointerdown', (e) => {
          e.preventDefault();
          callbacks.onSelectDog(dog.id);
          // showSelect is called by onSelectDog
        });
      }
      rosterRowEl.appendChild(btn);
    }

    trickListEl.innerHTML = '';
    for (const { trick, mastered } of callbacks.getTricks()) {
      const btn = document.createElement('button');
      btn.className = 'hud-trick-btn' + (mastered ? ' mastered' : '');
      btn.dataset['trickId'] = trick.id;
      btn.type = 'button';
      btn.setAttribute('aria-label', mastered ? `${trick.name} — mastered` : trick.name);
      const checkEl = document.createElement('span');
      checkEl.className = 'hud-trick-check';
      checkEl.textContent = mastered ? '✓' : '';
      checkEl.setAttribute('aria-hidden', 'true');
      const nameEl = document.createElement('span');
      nameEl.className = 'hud-trick-name';
      nameEl.textContent = trick.name;
      nameEl.setAttribute('aria-hidden', 'true');
      btn.appendChild(checkEl);
      btn.appendChild(nameEl);
      btn.addEventListener('pointerdown', (e) => {
        e.preventDefault();
        callbacks.onSelectTrick(trick);
      });
      trickListEl.appendChild(btn);
    }

    selectEl.style.display = 'flex';
    hud.style.display = 'none';
  }

  function showTraining(trickName: string): void {
    trickLabelEl.textContent = `Teaching: ${trickName}`;
    selectEl.style.display = 'none';
    hud.style.display = 'flex';
    // Kennel button is select-screen-only; hide it so the fixed overlay
    // cannot bleed onto / respond over the training HUD.
    kennelBtnEl.classList.add('kennel-btn-training-hidden');
  }

  // ── Onboarding gating ─────────────────────────────────────────────────
  function applyRevealed(revealed: Revealed): void {
    // Loadout chip (phrases): hidden until phrases stage
    loadoutChipEl.classList.toggle('hud-gated', !revealed.phrases);
    // Difficulty selector: hidden until difficulty stage
    diffSelectorEl.classList.toggle('hud-gated', !revealed.difficulty);
    // Kennel button: hidden until kennel stage
    kennelBtnEl.classList.toggle('hud-gated', !revealed.kennel);
  }

  // Apply initial reveal flags from callbacks
  applyRevealed(callbacks.revealed);

  // Start hidden — caller decides initial state
  selectEl.style.display = 'none';
  hud.style.display = 'none';
  loadingEl.style.display = 'none';

  // ── Mastery celebration burst ───────────────────────────────────────────
  /**
   * Fires a one-shot CSS celebration burst (radial gold flash + confetti dots).
   * Creates a transient #hud-celebrate overlay, then removes it ~1 s later.
   * pointer-events:none; never blocks input or return-to-select.
   */
  function celebrate(): void {
    // Create the host overlay
    const celebrateEl = document.createElement('div');
    celebrateEl.id = 'hud-celebrate';

    // Central radial flash
    const flashEl = document.createElement('div');
    flashEl.id = 'hud-celebrate-flash';
    celebrateEl.appendChild(flashEl);

    // 8 confetti dots
    for (let i = 0; i < 8; i++) {
      const dot = document.createElement('div');
      dot.className = 'hud-confetti';
      celebrateEl.appendChild(dot);
    }

    document.body.appendChild(celebrateEl);

    // Remove after longest animation (flash: 0.85 s + confetti: 0.95 s + buffer)
    setTimeout(() => {
      celebrateEl.remove();
    }, 1100);
  }

  return { renderTraining, showSelect, showTraining, refreshKennelPanel, applyRevealed, showLoading, hideLoading, celebrate };
}
