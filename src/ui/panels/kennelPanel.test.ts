// @vitest-environment jsdom
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { createKennelPanel } from './kennelPanel';

const pointerdown = (el: Element) =>
  el.dispatchEvent(new window.Event('pointerdown', { bubbles: true, cancelable: true }));

beforeEach(() => {
  document.body.innerHTML = '';
});

describe('createKennelPanel — upgrade row states', () => {
  it('marks an owned upgrade owned, with an "Owned" cost and a disabled ✓ button', () => {
    const handle = createKennelPanel({
      getKennelState: () => ({ kennelUpgradeIds: ['treats-pouch'], coins: 0 }),
      onBuyUpgrade: () => {},
    });
    handle.open();
    const row = handle.el.querySelector('[data-upgrade-id="treats-pouch"]')!.closest('.kennel-upgrade-row')!;
    expect(row.classList.contains('owned')).toBe(true);
    expect(row.querySelector('.kennel-upgrade-cost')!.textContent).toBe('Owned');
    expect(handle.el.querySelector<HTMLButtonElement>('[data-upgrade-id="treats-pouch"]')!.disabled).toBe(true);
  });

  it('marks an affordable upgrade affordable and an unaffordable one too-expensive', () => {
    const handle = createKennelPanel({
      getKennelState: () => ({ kennelUpgradeIds: [], coins: 100 }), // buys treats-pouch (100), not clicker-pro (250)
      onBuyUpgrade: () => {},
    });
    handle.open();
    const treats = handle.el.querySelector('[data-upgrade-id="treats-pouch"]')!.closest('.kennel-upgrade-row')!;
    const clicker = handle.el.querySelector('[data-upgrade-id="clicker-pro"]')!.closest('.kennel-upgrade-row')!;
    expect(treats.classList.contains('affordable')).toBe(true);
    expect(clicker.classList.contains('too-expensive')).toBe(true);
  });

  it('shows the composed payout multiplier for the owned set', () => {
    const handle = createKennelPanel({
      getKennelState: () => ({ kennelUpgradeIds: ['treats-pouch'], coins: 0 }),
      onBuyUpgrade: () => {},
    });
    handle.open();
    // treats-pouch = ×1.2
    expect(handle.el.querySelector('#kennel-panel-multiplier')!.textContent).toContain('×1.20');
  });
});

describe('createKennelPanel — buy flow + update', () => {
  it('buying an affordable upgrade invokes onBuyUpgrade with its id', () => {
    const onBuyUpgrade = vi.fn();
    const handle = createKennelPanel({
      getKennelState: () => ({ kennelUpgradeIds: [], coins: 100 }),
      onBuyUpgrade,
    });
    handle.open();
    pointerdown(handle.el.querySelector('[data-upgrade-id="treats-pouch"]')!);
    expect(onBuyUpgrade).toHaveBeenCalledWith('treats-pouch');
  });

  it('exposes update() to re-render the list (PanelHandle.update)', () => {
    const handle = createKennelPanel({
      getKennelState: () => ({ kennelUpgradeIds: [], coins: 0 }),
      onBuyUpgrade: () => {},
    });
    expect(typeof handle.update).toBe('function');
    expect(() => handle.update!()).not.toThrow();
  });
});
