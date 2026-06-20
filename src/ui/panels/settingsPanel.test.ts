// @vitest-environment jsdom
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { createSettingsPanel, type SettingsPanelDeps } from './settingsPanel';

const pointerdown = (el: Element) =>
  el.dispatchEvent(new window.Event('pointerdown', { bubbles: true, cancelable: true }));

function deps(overrides: Partial<SettingsPanelDeps> = {}): SettingsPanelDeps {
  return {
    isMuted: () => false,
    onToggleMute: () => {},
    onResetProgress: async () => {},
    getStats: () => ({ prestigePoints: 0, coins: 0, level: 1, tricksMastered: 0, streak: 0 }),
    onOpenAchievements: () => {},
    ...overrides,
  };
}

beforeEach(() => {
  document.body.innerHTML = '';
});

describe('createSettingsPanel — mute toggle', () => {
  it('reflects the current mute state on open', () => {
    const handle = createSettingsPanel(deps({ isMuted: () => true }));
    handle.open();
    expect(handle.el.querySelector<HTMLInputElement>('#settings-mute-toggle')!.checked).toBe(true);
  });

  it('fires onToggleMute with the new value when toggled', () => {
    const onToggleMute = vi.fn();
    const handle = createSettingsPanel(deps({ onToggleMute }));
    handle.open();
    const toggle = handle.el.querySelector<HTMLInputElement>('#settings-mute-toggle')!;
    toggle.checked = true;
    toggle.dispatchEvent(new window.Event('change', { bubbles: true }));
    expect(onToggleMute).toHaveBeenCalledWith(true);
  });
});

describe('createSettingsPanel — stats readout', () => {
  it('renders the live stats', () => {
    const handle = createSettingsPanel(deps({
      getStats: () => ({ prestigePoints: 2, coins: 320, level: 4, tricksMastered: 7, streak: 3 }),
    }));
    handle.open();
    const text = handle.el.querySelector('#settings-stats')!.textContent!;
    expect(text).toContain('320');
    expect(text).toContain('★2');
    expect(text).toContain('3-day streak');
  });
});

describe('createSettingsPanel — two-tap reset', () => {
  it('requires confirmation: the first tap arms, the second resets', () => {
    const onResetProgress = vi.fn(async () => {});
    const handle = createSettingsPanel(deps({ onResetProgress }));
    handle.open();
    const btn = handle.el.querySelector<HTMLButtonElement>('#settings-reset-btn')!;

    pointerdown(btn);
    expect(onResetProgress).not.toHaveBeenCalled();
    expect(btn.textContent).toMatch(/confirm/i);
    expect(btn.classList.contains('settings-reset-confirm')).toBe(true);

    pointerdown(btn);
    expect(onResetProgress).toHaveBeenCalledOnce();
  });

  it('disarms the reset confirmation on close', () => {
    const handle = createSettingsPanel(deps());
    handle.open();
    const btn = handle.el.querySelector<HTMLButtonElement>('#settings-reset-btn')!;
    pointerdown(btn); // arm
    handle.close();
    expect(btn.classList.contains('settings-reset-confirm')).toBe(false);
    expect(btn.textContent).toBe('Reset progress');
  });
});

describe('createSettingsPanel — achievements entry', () => {
  it('routes the achievements button to onOpenAchievements', () => {
    const onOpenAchievements = vi.fn();
    const handle = createSettingsPanel(deps({ onOpenAchievements }));
    handle.open();
    pointerdown(handle.el.querySelector('#settings-achievements-btn')!);
    expect(onOpenAchievements).toHaveBeenCalledOnce();
  });
});
