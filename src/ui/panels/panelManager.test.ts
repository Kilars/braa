import { describe, it, expect, vi } from 'vitest';
import { createPanelManager } from './panelManager';
import type { PanelHandle } from './panelManager';

/** Build a stub panel whose open/close are spies, so we can assert coordination. */
function stubPanel(id: string): PanelHandle {
  return {
    el: { id } as unknown as HTMLElement,
    open: vi.fn(),
    close: vi.fn(),
  };
}

describe('createPanelManager', () => {
  it('opens the requested panel', () => {
    const mgr = createPanelManager();
    const a = stubPanel('a');
    mgr.register(a);

    mgr.open(a);

    expect(a.open).toHaveBeenCalledTimes(1);
  });

  it('closes every other registered panel when one opens (exclusivity, task 071)', () => {
    const mgr = createPanelManager();
    const a = stubPanel('a');
    const b = stubPanel('b');
    const c = stubPanel('c');
    mgr.register(a);
    mgr.register(b);
    mgr.register(c);

    mgr.open(a);

    expect(b.close).toHaveBeenCalledTimes(1);
    expect(c.close).toHaveBeenCalledTimes(1);
  });

  it('does not close the panel being opened', () => {
    const mgr = createPanelManager();
    const a = stubPanel('a');
    const b = stubPanel('b');
    mgr.register(a);
    mgr.register(b);

    mgr.open(a);

    expect(a.close).not.toHaveBeenCalled();
  });

  it('closeAll() closes every registered panel', () => {
    const mgr = createPanelManager();
    const a = stubPanel('a');
    const b = stubPanel('b');
    mgr.register(a);
    mgr.register(b);

    mgr.closeAll();

    expect(a.close).toHaveBeenCalledTimes(1);
    expect(b.close).toHaveBeenCalledTimes(1);
  });
});
