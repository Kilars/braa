import type { PanelHandle } from './panelManager';
import type { Breed } from '../../core/breeds';

export interface AdoptPanelDeps {
  getAdoptableBreeds: () => { breed: Breed; affordable: boolean; levelGated: boolean }[];
  onAdoptBreed: (breedId: string) => void;
  /** Re-render the select screen after a successful adoption (HUD's showSelect). */
  onAdopted: () => void;
}

/**
 * Adopt-a-dog shop overlay. Refreshes its breed list on open; on a successful
 * adopt it returns the player to the refreshed select screen and dismisses
 * itself. DOM ids/classes match the former inline block in hud.ts exactly.
 */
export function createAdoptPanel(deps: AdoptPanelDeps): PanelHandle {
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

  function refresh(): void {
    adoptListEl.innerHTML = '';
    const breeds = deps.getAdoptableBreeds();
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
          deps.onAdoptBreed(breed.id);
          // Return to the refreshed select screen and dismiss the adopt panel
          deps.onAdopted();
          close();
        });
      }

      rowEl.appendChild(infoEl);
      rowEl.appendChild(adoptBtn);
      adoptListEl.appendChild(rowEl);
    }
  }

  function open(): void {
    refresh();
    adoptPanelEl.style.display = 'flex';
  }

  function close(): void {
    adoptPanelEl.style.display = 'none';
  }

  adoptCloseBtn.addEventListener('pointerdown', (e) => {
    e.preventDefault();
    close();
  });

  adoptPanelEl.style.display = 'none';

  return { el: adoptPanelEl, open, close };
}
