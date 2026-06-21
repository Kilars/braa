// @vitest-environment jsdom
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { createHud } from './hud';
import type { HudCallbacks } from './hud';
import type { HudViewModel } from './viewModel';
import { BASE_PHRASE, type Phrase, type PhraseEntry } from '../core/phrases';
import type { DisengageBeat } from '../core/engagement';

// A phrase with a real cooldown, used to exercise the --cooldown-pct sweep.
const FLINK: Phrase = {
  id: 'flink', word: 'flink', windowBonusMs: 150, rewardBonus: 0.1,
  cooldownMs: 8000, peakRadiusPenaltyMs: 0,
};

type LoadoutState = ReturnType<HudCallbacks['getLoadoutState']>;

// Minimal, fully-revealed loadout: base phrase, ready, only one phrase available,
// nothing left to unlock. Individual tests override the slice they care about.
function defaultLoadout(): LoadoutState {
  return {
    loadedPhrase: BASE_PHRASE,
    lastUsedAt: null,
    available: [BASE_PHRASE],
    nextLocked: null,
    nextLockedIsLevelGated: false,
    coins: 0,
  };
}

// A complete HudViewModel with neutral defaults; tests override the fields they assert on.
function makeVm(overrides: Partial<HudViewModel> = {}): HudViewModel {
  return {
    learnedPercent: 0,
    mastered: false,
    lastResult: null,
    confused: false,
    coins: 0,
    level: 1,
    attemptActive: false,
    tellStrength: 0,
    peakProximity: 0,
    combo: 0,
    engagement: 1,
    engagementBeat: 'engaged',
    disengaged: false,
    ...overrides,
  };
}

// A full callbacks object so createHud can be instantiated as-is (no seam needed).
// getLoadoutState is the one slice renderTraining reads for the chip, so it is overridable.
function makeCallbacks(getLoadoutState: () => LoadoutState = defaultLoadout): HudCallbacks {
  return {
    onBraTapDown: () => {},
    onBraTapCommit: () => {},
    onSwapPhrase: () => {},
    onTogglePause: () => {},
    onSelectMode: () => {},
    initialMode: 'NORMAL',
    onSelectTrick: () => {},
    getTricks: () => [],
    getDogName: () => 'Rex',
    getRoster: () => [],
    onSelectDog: () => {},
    getAdoptableBreeds: () => [],
    onAdoptBreed: () => {},
    getKennelState: () => ({ kennelUpgradeIds: [], coins: 0 }),
    onBuyUpgrade: () => {},
    onCyclePhrase: () => {},
    onUnlockNextPhrase: () => false,
    getLoadoutState,
    revealed: { distractors: true, economy: true, phrases: true, difficulty: true, kennel: true },
    canGraduateActiveDog: () => false,
    onGraduate: () => {},
    getPrestigePoints: () => 0,
    isMuted: () => false,
    onToggleMute: () => {},
    onResetProgress: async () => {},
    getStats: () => ({ prestigePoints: 0, coins: 0, level: 1, tricksMastered: 0, streak: 0 }),
    getAchievementsState: () => ({ achievements: [], unlockedIds: [] }),
  };
}

const chip = () => document.querySelector('#hud-loadout-chip') as HTMLElement;
const unlockBtn = () => document.querySelector('#hud-loadout-unlock') as HTMLButtonElement;
const comboEl = () => document.querySelector('#hud-combo') as HTMLElement;
const engagementEl = () => document.querySelector('#hud-engagement') as HTMLElement;
const engagementFill = () => document.querySelector('#hud-engagement-fill') as HTMLElement;

beforeEach(() => {
  document.body.innerHTML = '';
});

afterEach(() => {
  vi.restoreAllMocks();
});

describe('renderTraining — phrase cooldown sweep', () => {
  it('a cooling phrase sets --cooldown-pct to the remaining fraction and on-cooldown class', () => {
    // now is fixed; lastUsedAt is half a cooldown ago → 50% remaining.
    vi.spyOn(performance, 'now').mockReturnValue(10_000);
    const hud = createHud(makeCallbacks(() => ({
      ...defaultLoadout(),
      loadedPhrase: FLINK,
      lastUsedAt: 10_000 - 4_000, // 4s elapsed of an 8s cooldown
      available: [BASE_PHRASE, FLINK],
    })));
    hud.renderTraining(makeVm());
    expect(chip().style.getPropertyValue('--cooldown-pct')).toBe('50.0%');
    expect(chip().classList.contains('on-cooldown')).toBe(true);
  });

  it('a ready phrase (off cooldown) clears on-cooldown and zeroes --cooldown-pct', () => {
    vi.spyOn(performance, 'now').mockReturnValue(10_000);
    const hud = createHud(makeCallbacks(() => ({
      ...defaultLoadout(),
      loadedPhrase: FLINK,
      lastUsedAt: 10_000 - 9_000, // 9s elapsed > 8s cooldown → ready
      available: [BASE_PHRASE, FLINK],
    })));
    hud.renderTraining(makeVm());
    expect(chip().classList.contains('on-cooldown')).toBe(false);
    expect(chip().style.getPropertyValue('--cooldown-pct')).toBe('0%');
  });

  it('0% cooldown — exactly at cooldown elapsed reads ready', () => {
    vi.spyOn(performance, 'now').mockReturnValue(10_000);
    const hud = createHud(makeCallbacks(() => ({
      ...defaultLoadout(),
      loadedPhrase: FLINK,
      lastUsedAt: 10_000 - 8_000, // exactly 8s elapsed → isReady true (>=)
      available: [BASE_PHRASE, FLINK],
    })));
    hud.renderTraining(makeVm());
    expect(chip().classList.contains('on-cooldown')).toBe(false);
    expect(chip().style.getPropertyValue('--cooldown-pct')).toBe('0%');
  });

  it('100% cooldown — just used reads full remaining cooldown', () => {
    vi.spyOn(performance, 'now').mockReturnValue(10_000);
    const hud = createHud(makeCallbacks(() => ({
      ...defaultLoadout(),
      loadedPhrase: FLINK,
      lastUsedAt: 10_000, // used this instant → 0 elapsed → 100% remaining
      available: [BASE_PHRASE, FLINK],
    })));
    hud.renderTraining(makeVm());
    expect(chip().classList.contains('on-cooldown')).toBe(true);
    expect(chip().style.getPropertyValue('--cooldown-pct')).toBe('100.0%');
  });
});

describe('renderTraining — combo indicator', () => {
  it('is hidden below the visibility threshold (combo = 1)', () => {
    const hud = createHud(makeCallbacks());
    hud.renderTraining(makeVm({ combo: 1 }));
    expect(comboEl().classList.contains('visible')).toBe(false);
    expect(comboEl().hasAttribute('data-combo')).toBe(false);
  });

  it('combo exactly at the threshold (2) is visible with the right multiplier text', () => {
    const hud = createHud(makeCallbacks());
    hud.renderTraining(makeVm({ combo: 2 }));
    expect(comboEl().classList.contains('visible')).toBe(true);
    expect(comboEl().textContent).toBe('x2');
    expect(comboEl().getAttribute('data-combo')).toBe('2');
  });

  it('above the threshold shows the current multiplier (combo = 5)', () => {
    const hud = createHud(makeCallbacks());
    hud.renderTraining(makeVm({ combo: 5 }));
    expect(comboEl().classList.contains('visible')).toBe(true);
    expect(comboEl().textContent).toBe('x5');
    expect(comboEl().getAttribute('data-combo')).toBe('5');
  });
});

describe('renderTraining — engagement meter', () => {
  it('rounds the meter to a whole percent for fill width + aria-valuenow', () => {
    const hud = createHud(makeCallbacks());
    // 0.426 → 42.6 → rounds to 43
    hud.renderTraining(makeVm({ engagement: 0.426, engagementBeat: 'flop' as DisengageBeat }));
    expect(engagementFill().style.width).toBe('43%');
    expect(engagementEl().getAttribute('aria-valuenow')).toBe('43');
  });

  it('reflects the disengage beat on the meter via data-beat', () => {
    const hud = createHud(makeCallbacks());
    hud.renderTraining(makeVm({ engagement: 0.2, engagementBeat: 'bark' as DisengageBeat }));
    expect(engagementEl().getAttribute('data-beat')).toBe('bark');
  });

  it('engagement 0 → empty meter, walk-off beat', () => {
    const hud = createHud(makeCallbacks());
    hud.renderTraining(makeVm({ engagement: 0, engagementBeat: 'walk-off' as DisengageBeat }));
    expect(engagementFill().style.width).toBe('0%');
    expect(engagementEl().getAttribute('aria-valuenow')).toBe('0');
    expect(engagementEl().getAttribute('data-beat')).toBe('walk-off');
  });

  it('engagement 1 → full meter, engaged beat', () => {
    const hud = createHud(makeCallbacks());
    hud.renderTraining(makeVm({ engagement: 1, engagementBeat: 'engaged' as DisengageBeat }));
    expect(engagementFill().style.width).toBe('100%');
    expect(engagementEl().getAttribute('aria-valuenow')).toBe('100');
    expect(engagementEl().getAttribute('data-beat')).toBe('engaged');
  });
});

describe('renderTraining — call-back affordance (task 107)', () => {
  const callbackHint = () => document.querySelector('#hud-callback-hint') as HTMLElement;

  it('shows the call-back hint while the dog is disengaged (walk-off)', () => {
    const hud = createHud(makeCallbacks());
    hud.renderTraining(makeVm({ disengaged: true, engagement: 0, engagementBeat: 'walk-off' as DisengageBeat }));
    expect(callbackHint().classList.contains('visible')).toBe(true);
  });

  it('hides the call-back hint during normal play (not disengaged)', () => {
    const hud = createHud(makeCallbacks());
    hud.renderTraining(makeVm({ disengaged: false, engagement: 0.6, engagementBeat: 'itch' as DisengageBeat }));
    expect(callbackHint().classList.contains('visible')).toBe(false);
  });

  it('toggles back off once the dog has been called back', () => {
    const hud = createHud(makeCallbacks());
    hud.renderTraining(makeVm({ disengaged: true }));
    expect(callbackHint().classList.contains('visible')).toBe(true);
    hud.renderTraining(makeVm({ disengaged: false }));
    expect(callbackHint().classList.contains('visible')).toBe(false);
  });
});

describe('renderTraining — unlock affordance (level gate vs coin gate)', () => {
  const flinkEntry: PhraseEntry = { phrase: FLINK, unlockCost: 50, unlockLevel: 3 };

  it('a level-gated next phrase shows a "Lvl N" badge, too-expensive, disabled', () => {
    const hud = createHud(makeCallbacks(() => ({
      ...defaultLoadout(),
      nextLocked: flinkEntry,
      nextLockedIsLevelGated: true,
      coins: 9999, // plenty of coins, but the gate is the level wall
    })));
    hud.renderTraining(makeVm());
    expect(unlockBtn().textContent).toBe('Lvl 3');
    expect(unlockBtn().style.display).toBe('inline-flex');
    expect(unlockBtn().classList.contains('too-expensive')).toBe(true);
    expect(unlockBtn().classList.contains('affordable')).toBe(false);
    expect(unlockBtn().disabled).toBe(true);
  });

  it('a coin-priced next phrase the player can afford shows "+word 🪙cost", affordable, enabled', () => {
    const hud = createHud(makeCallbacks(() => ({
      ...defaultLoadout(),
      nextLocked: flinkEntry,
      nextLockedIsLevelGated: false,
      coins: 50, // exactly affordable (>=)
    })));
    hud.renderTraining(makeVm());
    expect(unlockBtn().textContent).toBe('+flink 🪙50');
    expect(unlockBtn().style.display).toBe('inline-flex');
    expect(unlockBtn().classList.contains('affordable')).toBe(true);
    expect(unlockBtn().disabled).toBe(false);
  });

  it('a coin-priced next phrase the player cannot afford is too-expensive + disabled', () => {
    const hud = createHud(makeCallbacks(() => ({
      ...defaultLoadout(),
      nextLocked: flinkEntry,
      nextLockedIsLevelGated: false,
      coins: 10, // below the 50 cost
    })));
    hud.renderTraining(makeVm());
    expect(unlockBtn().textContent).toBe('+flink 🪙50');
    expect(unlockBtn().classList.contains('too-expensive')).toBe(true);
    expect(unlockBtn().classList.contains('affordable')).toBe(false);
    expect(unlockBtn().disabled).toBe(true);
  });

  it('no next phrase to unlock hides the unlock button', () => {
    const hud = createHud(makeCallbacks(() => ({ ...defaultLoadout(), nextLocked: null })));
    hud.renderTraining(makeVm());
    expect(unlockBtn().style.display).toBe('none');
  });
});

const coachEl = () => document.querySelector('#hud-coach') as HTMLElement;

describe('setCoachVisible — first-run core-verb coach', () => {
  it('the coach is gated (hidden) by default', () => {
    createHud(makeCallbacks());
    expect(coachEl()).not.toBeNull();
    expect(coachEl().classList.contains('hud-gated')).toBe(true);
  });

  it('setCoachVisible(true) reveals the coach (removes the gated class)', () => {
    const hud = createHud(makeCallbacks());
    hud.setCoachVisible(true);
    expect(coachEl().classList.contains('hud-gated')).toBe(false);
  });

  it('setCoachVisible(false) re-hides the coach (auto-dismiss path)', () => {
    const hud = createHud(makeCallbacks());
    hud.setCoachVisible(true);
    hud.setCoachVisible(false);
    expect(coachEl().classList.contains('hud-gated')).toBe(true);
  });

  it('carries the core-verb instruction text (announced via aria-live)', () => {
    createHud(makeCallbacks());
    expect(coachEl().getAttribute('aria-live')).toBe('polite');
    expect(coachEl().textContent).toMatch(/BRA/);
  });
});

describe('setCoachVisible — distractor-reveal coach (task 109)', () => {
  const distractorText = 'Noen ganger gjør hunden noe annet — ikke trykk da. Bare BRA på «Sitt».';

  it('renders the supplied distractor text and the wide-wrap modifier', () => {
    const hud = createHud(makeCallbacks());
    hud.setCoachVisible(true, distractorText);
    expect(coachEl().textContent).toBe(distractorText);
    expect(coachEl().classList.contains('coach-wide')).toBe(true);
    expect(coachEl().classList.contains('hud-gated')).toBe(false);
    // Same announced element — aria parity with the core-verb pill.
    expect(coachEl().getAttribute('aria-live')).toBe('polite');
  });

  it('reverts to the short core-verb text and drops the modifier when text is omitted', () => {
    const hud = createHud(makeCallbacks());
    hud.setCoachVisible(true, distractorText);
    hud.setCoachVisible(true);
    expect(coachEl().textContent).toMatch(/BRA/);
    expect(coachEl().textContent).not.toBe(distractorText);
    expect(coachEl().classList.contains('coach-wide')).toBe(false);
  });
});

const pauseBtn = () => document.querySelector('#hud-pause-btn') as HTMLButtonElement;
const pauseOverlay = () => document.querySelector('#hud-pause-overlay') as HTMLElement;
const resumeBtn = () => document.querySelector('#hud-pause-resume') as HTMLButtonElement;

describe('pause control — overlay + button (task 106)', () => {
  it('the paused overlay is hidden by default (no visible class)', () => {
    createHud(makeCallbacks());
    expect(pauseOverlay()).not.toBeNull();
    expect(pauseOverlay().classList.contains('visible')).toBe(false);
  });

  it('setPaused(true) shows the overlay and marks the button pressed', () => {
    const hud = createHud(makeCallbacks());
    hud.setPaused(true);
    expect(pauseOverlay().classList.contains('visible')).toBe(true);
    expect(pauseBtn().getAttribute('aria-pressed')).toBe('true');
  });

  it('setPaused(false) hides the overlay again', () => {
    const hud = createHud(makeCallbacks());
    hud.setPaused(true);
    hud.setPaused(false);
    expect(pauseOverlay().classList.contains('visible')).toBe(false);
    expect(pauseBtn().getAttribute('aria-pressed')).toBe('false');
  });

  it('the pause button invokes onTogglePause', () => {
    let toggles = 0;
    const cbs = makeCallbacks();
    cbs.onTogglePause = () => { toggles++; };
    createHud(cbs);
    pauseBtn().dispatchEvent(new Event('pointerdown'));
    expect(toggles).toBe(1);
  });

  it('the resume button invokes onTogglePause', () => {
    let toggles = 0;
    const cbs = makeCallbacks();
    cbs.onTogglePause = () => { toggles++; };
    const hud = createHud(cbs);
    hud.setPaused(true);
    resumeBtn().dispatchEvent(new Event('pointerdown'));
    expect(toggles).toBe(1);
  });

  it('the overlay is a labelled modal dialog (a11y)', () => {
    createHud(makeCallbacks());
    expect(pauseOverlay().getAttribute('role')).toBe('dialog');
    expect(pauseOverlay().getAttribute('aria-modal')).toBe('true');
    expect(pauseOverlay().getAttribute('aria-label')).toBe('Paused');
  });
});

// ── Idle "welcome back" toast (task 115) ────────────────────────────────────
const idleWelcome = () => document.querySelector('#hud-idle-welcome') as HTMLElement;

describe('showIdleWelcome — return idle-income toast', () => {
  it('is hidden by default (gated, occupies no space until shown)', () => {
    createHud(makeCallbacks());
    expect(idleWelcome()).not.toBeNull();
    expect(idleWelcome().classList.contains('hud-gated')).toBe(true);
  });

  it('reveals and shows the earned coin count when called', () => {
    const hud = createHud(makeCallbacks());
    hud.showIdleWelcome(42);
    expect(idleWelcome().classList.contains('hud-gated')).toBe(false);
    expect(idleWelcome().textContent).toContain('42');
  });

  it('is announced once via aria-live polite', () => {
    createHud(makeCallbacks());
    expect(idleWelcome().getAttribute('aria-live')).toBe('polite');
  });
});
