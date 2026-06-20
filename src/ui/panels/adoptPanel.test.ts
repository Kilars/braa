// @vitest-environment jsdom
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { createAdoptPanel } from './adoptPanel';
import type { Breed } from '../../core/breeds';

// Minimal breed fixtures — only the fields the panel reads.
const husky: Breed = {
  id: 'husky', name: 'Husky', intrinsic: 1.8, learnSpeed: 1.1, distractibility: 0.95,
  adoptCost: 300, requiredLevel: 5,
};
const bulldog: Breed = {
  id: 'bulldog', name: 'Bulldog', intrinsic: 1.3, learnSpeed: 0.7, distractibility: 0.3,
  adoptCost: 150, requiredLevel: 2,
};

beforeEach(() => {
  document.body.innerHTML = '';
});

describe('createAdoptPanel — gate legibility', () => {
  it('renders a level-gated breed with a "Lvl N" badge and the level-locked class', () => {
    const handle = createAdoptPanel({
      getAdoptableBreeds: () => [{ breed: husky, affordable: false, levelGated: true }],
      onAdoptBreed: () => {},
      onAdopted: () => {},
    });
    handle.open();

    const row = handle.el.querySelector('.adopt-breed-row')!;
    expect(row.classList.contains('level-locked')).toBe(true);
    expect(row.querySelector('.adopt-breed-cost')!.textContent).toBe('Lvl 5');
    // The adopt button is disabled when not purchasable
    expect(handle.el.querySelector<HTMLButtonElement>('.adopt-buy-btn')!.disabled).toBe(true);
  });

  it('shows a coin price (not a level badge) for an affordable breed', () => {
    const handle = createAdoptPanel({
      getAdoptableBreeds: () => [{ breed: bulldog, affordable: true, levelGated: false }],
      onAdoptBreed: () => {},
      onAdopted: () => {},
    });
    handle.open();

    const row = handle.el.querySelector('.adopt-breed-row')!;
    expect(row.classList.contains('affordable')).toBe(true);
    expect(row.querySelector('.adopt-breed-cost')!.textContent).toBe('🪙 150');
    expect(handle.el.querySelector<HTMLButtonElement>('.adopt-buy-btn')!.disabled).toBe(false);
  });

  it('marks an unlocked-but-unaffordable breed too-expensive (coin gate, not level gate)', () => {
    const handle = createAdoptPanel({
      getAdoptableBreeds: () => [{ breed: bulldog, affordable: false, levelGated: false }],
      onAdoptBreed: () => {},
      onAdopted: () => {},
    });
    handle.open();
    const row = handle.el.querySelector('.adopt-breed-row')!;
    expect(row.classList.contains('too-expensive')).toBe(true);
  });
});

describe('createAdoptPanel — adoption flow', () => {
  it('adopting an affordable breed invokes onAdoptBreed + onAdopted and closes the panel', () => {
    const onAdoptBreed = vi.fn();
    const onAdopted = vi.fn();
    const handle = createAdoptPanel({
      getAdoptableBreeds: () => [{ breed: bulldog, affordable: true, levelGated: false }],
      onAdoptBreed,
      onAdopted,
    });
    handle.open();
    expect(handle.el.style.display).toBe('flex');

    handle.el.querySelector('.adopt-buy-btn')!
      .dispatchEvent(new window.Event('pointerdown', { bubbles: true, cancelable: true }));

    expect(onAdoptBreed).toHaveBeenCalledWith('bulldog');
    expect(onAdopted).toHaveBeenCalledOnce();
    expect(handle.el.style.display).toBe('none');
  });
});

describe('createAdoptPanel — open/close + empty state', () => {
  it('open() shows the panel, close() hides it', () => {
    const handle = createAdoptPanel({
      getAdoptableBreeds: () => [],
      onAdoptBreed: () => {},
      onAdopted: () => {},
    });
    handle.open();
    expect(handle.el.style.display).toBe('flex');
    handle.close();
    expect(handle.el.style.display).toBe('none');
  });

  it('renders an empty-state message when no breeds are adoptable', () => {
    const handle = createAdoptPanel({
      getAdoptableBreeds: () => [],
      onAdoptBreed: () => {},
      onAdopted: () => {},
    });
    handle.open();
    expect(handle.el.querySelector('.adopt-empty')!.textContent).toMatch(/own all/i);
  });
});
