/**
 * A self-contained overlay panel: its DOM root plus the open/close (and
 * optional refresh) entry points the HUD needs to drive it. Panel factories in
 * this directory return one of these so `createHud` only orchestrates.
 */
export interface PanelHandle {
  /** The panel's root element (appended to document.body by the factory). */
  readonly el: HTMLElement;
  /** Show the panel (factories also refresh their content here). */
  open(): void;
  /** Hide the panel and reset any panel-local state. */
  close(): void;
  /** Optional re-render of dynamic content while open (e.g. kennel list). */
  update?(): void;
}

/**
 * Coordinates overlay panels so at most one is open at a time (task 071).
 * Panels register here; opening one closes every other registered panel.
 * Holds no DOM references itself — it only calls the handles' open/close.
 */
export function createPanelManager(): {
  register: (panel: PanelHandle) => void;
  open: (panel: PanelHandle) => void;
  closeAll: () => void;
} {
  const panels: PanelHandle[] = [];

  return {
    register(panel) {
      panels.push(panel);
    },
    open(panel) {
      for (const other of panels) {
        if (other !== panel) other.close();
      }
      panel.open();
    },
    closeAll() {
      for (const panel of panels) panel.close();
    },
  };
}
