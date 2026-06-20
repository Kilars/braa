import type { PanelHandle } from './panelManager';
import { KENNEL_UPGRADES, kennelMultiplier, canBuy } from '../../core/kennel';

export interface KennelPanelDeps {
  getKennelState: () => { kennelUpgradeIds: string[]; coins: number };
  onBuyUpgrade: (upgradeId: string) => void;
}

/**
 * Kennel upgrades shop overlay. `update()` re-renders the buy list (exposed so
 * the HUD's public `refreshKennelPanel` can drive it). DOM ids/classes match
 * the former inline block in hud.ts exactly.
 */
export function createKennelPanel(deps: KennelPanelDeps): PanelHandle {
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

  function refresh(): void {
    const { kennelUpgradeIds, coins } = deps.getKennelState();
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
          deps.onBuyUpgrade(upgrade.id);
          refresh();
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

  function open(): void {
    refresh();
    kennelPanelEl.style.display = 'flex';
  }

  function close(): void {
    kennelPanelEl.style.display = 'none';
  }

  kennelCloseBtn.addEventListener('pointerdown', (e) => {
    e.preventDefault();
    close();
  });

  kennelPanelEl.style.display = 'none';

  return { el: kennelPanelEl, open, close, update: refresh };
}
