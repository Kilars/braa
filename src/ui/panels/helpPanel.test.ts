// @vitest-environment jsdom
import { describe, it, expect, beforeEach } from 'vitest';
import { createHelpPanel } from './helpPanel';

const pointerdown = (el: Element) =>
  el.dispatchEvent(new window.Event('pointerdown', { bubbles: true, cancelable: true }));

beforeEach(() => {
  document.body.innerHTML = '';
});

describe('createHelpPanel — content + dismissal', () => {
  it('starts hidden and opens to flex', () => {
    const handle = createHelpPanel();
    expect(handle.el.style.display).toBe('none');
    handle.open();
    expect(handle.el.style.display).toBe('flex');
  });

  it('lists the core how-to-play beats (tap BRA on the pulse)', () => {
    const handle = createHelpPanel();
    const items = handle.el.querySelectorAll('.help-panel-item');
    expect(items.length).toBe(5);
    expect(handle.el.textContent).toMatch(/tap BRA/i);
    expect(handle.el.textContent).toMatch(/distractor/i);
  });

  it('the "Got it!" button closes the panel', () => {
    const handle = createHelpPanel();
    handle.open();
    pointerdown(handle.el.querySelector('#help-panel-got-it')!);
    expect(handle.el.style.display).toBe('none');
  });

  it('the ✕ close button closes the panel', () => {
    const handle = createHelpPanel();
    handle.open();
    pointerdown(handle.el.querySelector('#help-panel-close')!);
    expect(handle.el.style.display).toBe('none');
  });
});
