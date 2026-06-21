import './hud.css';
import { HudViewModel } from './viewModel';
import type { Phrase, PhraseEntry } from '../core/phrases';
import { isReady } from '../core/phrases';
import { classifySwipe } from '../core/swipeGesture';
import type { DifficultyMode } from '../core/difficulty';
import type { Trick } from '../core/tricks';
import type { Revealed } from '../core/onboarding';
import type { Dog } from '../core/roster';
import type { Breed } from '../core/breeds';
import type { Achievement } from '../core/achievements';
import { RESULT_FLASH_MS } from '../core/tuning';
import { createPanelManager } from './panels/panelManager';
import type { PanelHandle } from './panels/panelManager';
import { createAdoptPanel } from './panels/adoptPanel';
import { createKennelPanel } from './panels/kennelPanel';
import { createSettingsPanel } from './panels/settingsPanel';
import { createHelpPanel } from './panels/helpPanel';
import { createAchievementsPanel } from './panels/achievementsPanel';

// How long the idle "welcome back" toast stays up before auto-fading. A UI
// presentation timeout paired with the CSS fade — kept local (not a gameplay
// tunable), per the tech-decisions §8 render/CSS-timeout convention.
const IDLE_WELCOME_MS = 4200;

export interface HudCallbacks {
  /** BRA pressed — record the press instant (scoring uses this, not release). */
  onBraTapDown: () => void;
  /** BRA released as a tap (not a swipe) — commit the timing mark. */
  onBraTapCommit: () => void;
  /** BRA released as a horizontal swipe — swap the loaded phrase instead of marking. */
  onSwapPhrase: (dir: 'next' | 'prev') => void;
  /** Pause control toggled (pause button or resume button / overlay) — flip in-round pause. */
  onTogglePause: () => void;
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
 *
 * The five overlay panels (adopt / kennel / settings / help / achievements)
 * live in ui/panels/* factories; createHud orchestrates them through a
 * panel manager that enforces one-open-at-a-time exclusivity (task 071).
 */
export function createHud(callbacks: HudCallbacks): {
  renderTraining: (vm: HudViewModel) => void;
  showSelect: () => void;
  showTraining: (trickName: string) => void;
  refreshKennelPanel: () => void;
  applyRevealed: (revealed: Revealed) => void;
  setCoachVisible: (visible: boolean, text?: string) => void;
  showIdleWelcome: (coins: number) => void;
  setPaused: (paused: boolean) => void;
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

  // ── Idle "welcome back" toast (task 115) ──────────────────────────────
  // The kennel idle trickle is granted at load; this announces it on return so
  // the "gentle reason to come back" payoff is visible. Shown on the select
  // screen at bootstrap (driven by main.ts behind shouldShowIdleWelcome), then
  // auto-fades. Hidden by default via the shared .hud-gated class.
  const idleWelcomeEl = document.createElement('div');
  idleWelcomeEl.id = 'hud-idle-welcome';
  idleWelcomeEl.setAttribute('aria-live', 'polite');
  idleWelcomeEl.classList.add('hud-gated');
  document.body.appendChild(idleWelcomeEl);

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

  // ── Overlay panels ─────────────────────────────────────────────────────
  // Each panel's DOM construction lives in its own ui/panels/* factory. They
  // are created here in the same order they were formerly appended inline
  // (adopt → kennel → settings → help → achievements) so document.body child
  // order — and therefore hud.css / stacking — is unchanged. The panel manager
  // enforces one-open-at-a-time exclusivity (task 071).
  const panelManager = createPanelManager();

  const adoptPanel = createAdoptPanel({
    getAdoptableBreeds: callbacks.getAdoptableBreeds,
    onAdoptBreed: callbacks.onAdoptBreed,
    // Return to the refreshed select screen after a successful adoption.
    onAdopted: () => showSelect(),
  });

  const kennelPanel = createKennelPanel({
    getKennelState: callbacks.getKennelState,
    onBuyUpgrade: callbacks.onBuyUpgrade,
  });

  // The achievements panel is opened from a button inside the settings panel.
  // Declare it before settings so the open callback can reference it, but
  // assign it after help so the body append order stays settings → help →
  // achievements (the closure runs only on click, well after assignment).
  let achievementsPanel: PanelHandle;

  const settingsPanel = createSettingsPanel({
    isMuted: callbacks.isMuted,
    onToggleMute: callbacks.onToggleMute,
    onResetProgress: callbacks.onResetProgress,
    getStats: callbacks.getStats,
    onOpenAchievements: () => panelManager.open(achievementsPanel),
  });

  const helpPanel = createHelpPanel();

  achievementsPanel = createAchievementsPanel({
    getAchievementsState: callbacks.getAchievementsState,
  });

  panelManager.register(adoptPanel);
  panelManager.register(kennelPanel);
  panelManager.register(settingsPanel);
  panelManager.register(helpPanel);
  panelManager.register(achievementsPanel);

  // Select-screen buttons open their panel exclusively (closing any other).
  adoptBtnEl.addEventListener('pointerdown', (e) => {
    e.preventDefault();
    panelManager.open(adoptPanel);
  });

  kennelBtnEl.addEventListener('pointerdown', (e) => {
    e.preventDefault();
    panelManager.open(kennelPanel);
  });

  settingsBtnEl.addEventListener('pointerdown', (e) => {
    e.preventDefault();
    panelManager.open(settingsPanel);
  });

  helpBtnEl.addEventListener('pointerdown', (e) => {
    e.preventDefault();
    panelManager.open(helpPanel);
  });

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

  // First-run coach: an in-context prompt teaching the one core verb on the very
  // first round (specs.md §Onboarding). Shown only to a brand-new player and
  // auto-dismissed on the first successful mark — visibility is driven by main.ts
  // via setCoachVisible (pure gate: shouldCoachCoreVerb). Hidden by default.
  const COACH_CORE_VERB_TEXT = 'Vent på pulsen — trykk BRA!';
  const coachEl = document.createElement('div');
  coachEl.id = 'hud-coach';
  coachEl.setAttribute('aria-live', 'polite');
  coachEl.textContent = COACH_CORE_VERB_TEXT;
  coachEl.classList.add('hud-gated');

  // Call-back affordance (task 107): when the dog walks off (engagement empty),
  // a faint pill tells the player a tap now calls the dog back rather than marks.
  // Shown only while disengaged (toggled in renderTraining), mirroring the coach.
  const callbackHintEl = document.createElement('div');
  callbackHintEl.id = 'hud-callback-hint';
  callbackHintEl.setAttribute('aria-live', 'polite');
  callbackHintEl.textContent = 'Hunden gikk — trykk for å kalle den tilbake';

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

  // ── Engagement mood meter (top-right, below stats) ─────────────────────────
  // The dog's eagerness this round: drains on sloppy/false marks, refills on
  // precise ones. The fill colour escalates with the disengage beat
  // (engaged → itch → flop → bark → walk-off). Revealed with the economy stage,
  // when wrong-behavior beats begin to matter. Spec §Mistakes.
  const engagementEl = document.createElement('div');
  engagementEl.id = 'hud-engagement';
  engagementEl.setAttribute('role', 'meter');
  engagementEl.setAttribute('aria-label', 'Dog engagement');
  engagementEl.setAttribute('aria-valuemin', '0');
  engagementEl.setAttribute('aria-valuemax', '100');

  const engagementIconEl = document.createElement('span');
  engagementIconEl.id = 'hud-engagement-icon';
  engagementIconEl.setAttribute('aria-hidden', 'true');
  engagementIconEl.textContent = '🐾';

  const engagementTrackEl = document.createElement('div');
  engagementTrackEl.id = 'hud-engagement-track';
  const engagementFillEl = document.createElement('div');
  engagementFillEl.id = 'hud-engagement-fill';
  engagementTrackEl.appendChild(engagementFillEl);

  engagementEl.appendChild(engagementIconEl);
  engagementEl.appendChild(engagementTrackEl);

  // Top-right cluster: stacks the stats pill and the engagement meter as one
  // unit so the meter always sits directly under coins/level (one flow slot,
  // so it never drifts mid-screen via the HUD's space-between distribution).
  const statsClusterEl = document.createElement('div');
  statsClusterEl.id = 'hud-stats-cluster';
  statsClusterEl.appendChild(statsEl);
  statsClusterEl.appendChild(engagementEl);

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

  // Swipe affordance: a faint "‹ swipe ›" hint shown only when more than one phrase
  // is available, and a word chip that flashes the new phrase when a swap happens.
  const braSwipeHintEl = document.createElement('div');
  braSwipeHintEl.id = 'hud-bra-swipe-hint';
  braSwipeHintEl.setAttribute('aria-hidden', 'true');
  braSwipeHintEl.textContent = '‹ swipe ›';

  const braSwapWordEl = document.createElement('div');
  braSwapWordEl.id = 'hud-bra-swap-word';
  braSwapWordEl.setAttribute('aria-hidden', 'true');

  tellWrapEl.appendChild(tellRingEl);
  tellWrapEl.appendChild(braBtn);
  tellWrapEl.appendChild(braSwipeHintEl);
  tellWrapEl.appendChild(braSwapWordEl);

  bottomEl.appendChild(masteredEl);
  bottomEl.appendChild(tellWrapEl);

  // Combo indicator — shown when combo >= 2; hidden at 0/1
  const comboEl = document.createElement('div');
  comboEl.id = 'hud-combo';
  comboEl.setAttribute('aria-live', 'polite');
  comboEl.setAttribute('aria-label', 'Combo streak');

  // ── Pause control (specs.md §Round States: "Pause/resume supported") ────────
  // A small pause button (top-left of the training HUD) freezes the round; a
  // dimmed full-overlay with a Resume button covers the scene while paused. While
  // paused, taps are ignored (no false mark) and the timeline does not advance.
  const pauseBtnEl = document.createElement('button');
  pauseBtnEl.id = 'hud-pause-btn';
  pauseBtnEl.type = 'button';
  pauseBtnEl.textContent = '⏸';
  pauseBtnEl.setAttribute('aria-label', 'Pause round');
  pauseBtnEl.setAttribute('aria-pressed', 'false');

  const pauseOverlayEl = document.createElement('div');
  pauseOverlayEl.id = 'hud-pause-overlay';
  pauseOverlayEl.setAttribute('role', 'dialog');
  pauseOverlayEl.setAttribute('aria-modal', 'true');
  pauseOverlayEl.setAttribute('aria-label', 'Paused');

  const pauseLabelEl = document.createElement('div');
  pauseLabelEl.id = 'hud-pause-label';
  pauseLabelEl.textContent = 'Paused';

  const resumeBtnEl = document.createElement('button');
  resumeBtnEl.id = 'hud-pause-resume';
  resumeBtnEl.type = 'button';
  resumeBtnEl.textContent = '▶ Resume';
  resumeBtnEl.setAttribute('aria-label', 'Resume round');

  pauseOverlayEl.appendChild(pauseLabelEl);
  pauseOverlayEl.appendChild(resumeBtnEl);

  hud.appendChild(trickLabelEl);
  hud.appendChild(coachEl);
  hud.appendChild(callbackHintEl);
  hud.appendChild(barTrack);
  hud.appendChild(statsClusterEl);
  hud.appendChild(diffSelectorEl);
  hud.appendChild(resultEl);
  hud.appendChild(comboEl);
  hud.appendChild(loadoutChipEl);
  hud.appendChild(pauseBtnEl);
  hud.appendChild(bottomEl);
  hud.appendChild(pauseOverlayEl);

  document.body.appendChild(hud);

  // Pause / resume wiring — all routed through the single onTogglePause callback.
  pauseBtnEl.addEventListener('pointerdown', (e) => {
    e.preventDefault();
    callbacks.onTogglePause();
  });
  resumeBtnEl.addEventListener('pointerdown', (e) => {
    e.preventDefault();
    callbacks.onTogglePause();
  });
  // Tapping the dimmed backdrop (not the Resume button) also resumes.
  pauseOverlayEl.addEventListener('pointerdown', (e) => {
    if (e.target === pauseOverlayEl) {
      e.preventDefault();
      callbacks.onTogglePause();
    }
  });

  /**
   * Show/hide the paused overlay and reflect state on the pause button.
   * Driven by main.ts so the pure pause clock stays the single source of truth.
   */
  function setPaused(paused: boolean): void {
    pauseOverlayEl.classList.toggle('visible', paused);
    pauseBtnEl.classList.toggle('is-paused', paused);
    pauseBtnEl.setAttribute('aria-pressed', String(paused));
    pauseBtnEl.setAttribute('aria-label', paused ? 'Resume round' : 'Pause round');
  }

  // ── Wire tap ────────────────────────────────────────────────
  let flashTimer: ReturnType<typeof setTimeout> | null = null;

  // BRA is press-then-release: a quick tap fires the timing mark (scored at the
  // pointerdown instant, recorded in onBraTapDown), while a horizontal swipe swaps the
  // loaded phrase instead of marking (specs §Marker Phrases). classifySwipe keeps a
  // normal wobble/vertical drag a tap, so the timing tap is never lost.
  let braDownX = 0;
  let braDownY = 0;
  let braPressed = false;
  let swapAnimTimer: ReturnType<typeof setTimeout> | null = null;

  function animatePhraseSwap(dir: 'next' | 'prev'): void {
    // Read the just-updated loaded phrase so the marker briefly shows the new word.
    braSwapWordEl.textContent = callbacks.getLoadoutState().loadedPhrase.word;
    tellWrapEl.classList.remove('swap-next', 'swap-prev');
    void tellWrapEl.offsetWidth; // restart the animation if mid-flight
    tellWrapEl.classList.add(dir === 'next' ? 'swap-next' : 'swap-prev');
    if (swapAnimTimer !== null) clearTimeout(swapAnimTimer);
    swapAnimTimer = setTimeout(() => {
      tellWrapEl.classList.remove('swap-next', 'swap-prev');
      swapAnimTimer = null;
    }, 360);
  }

  braBtn.addEventListener('pointerdown', (e) => {
    e.preventDefault();
    braDownX = e.clientX;
    braDownY = e.clientY;
    braPressed = true;
    // Capture so the release still lands on the button if the finger drifts off.
    // Guarded: synthetic events (e2e) have no active pointer and would throw.
    try { braBtn.setPointerCapture?.(e.pointerId); } catch { /* no active pointer */ }
    callbacks.onBraTapDown();
  });

  function finishBraPress(e: PointerEvent): void {
    if (!braPressed) return;
    braPressed = false;
    const outcome = classifySwipe(e.clientX - braDownX, e.clientY - braDownY);
    if (outcome.type === 'swipe') {
      callbacks.onSwapPhrase(outcome.dir);
      animatePhraseSwap(outcome.dir);
    } else {
      callbacks.onBraTapCommit();
    }
  }

  braBtn.addEventListener('pointerup', finishBraPress);
  braBtn.addEventListener('pointercancel', finishBraPress);

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

    // Engagement mood meter — fill width + beat-coloured class
    const engagementPct = Math.round(vm.engagement * 100);
    engagementFillEl.style.width = `${engagementPct}%`;
    engagementEl.setAttribute('data-beat', vm.engagementBeat);
    engagementEl.setAttribute('aria-valuenow', String(engagementPct));

    // Call-back affordance — visible only while the dog has walked off (task 107):
    // a tap now calls it back instead of marking. Mirrors the swipe/coach hint.
    callbackHintEl.classList.toggle('visible', vm.disengaged);
    // While disengaged, the call-back hint replaces the first-run coach so the two
    // prompts never contradict each other ("trykk BRA" vs "kalle hunden tilbake").
    // Orthogonal to setCoachVisible's .hud-gated gate — the coach returns to its
    // gated state automatically once the dog is called back.
    coachEl.classList.toggle('coach-suppressed', vm.disengaged);

    // Loadout chip (switcher)
    const { loadedPhrase, lastUsedAt, available, nextLocked, nextLockedIsLevelGated, coins } = callbacks.getLoadoutState();
    const now = performance.now();
    const ready = isReady(loadedPhrase, now, lastUsedAt);
    chipWordEl.textContent = loadedPhrase.word;
    loadoutChipEl.classList.toggle('on-cooldown', !ready);
    loadoutChipEl.classList.toggle('can-cycle', available.length > 1);
    // Surface the swipe affordance on the BRA marker only when there's a phrase to
    // swap to (more than just base "bra"); also keep it current for the swap-word chip.
    tellWrapEl.classList.toggle('swipeable', available.length > 1);
    braSwapWordEl.textContent = loadedPhrase.word;
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
    // Coins/level stats: hidden until the first payout (economy stage), so a
    // brand-new player never sees "COINS 0 / LEVEL 1" before earning anything.
    statsEl.classList.toggle('hud-gated', !revealed.economy);
    // Engagement mood meter: revealed alongside the economy stage, when the
    // dog's wrong-behavior beats begin to matter.
    engagementEl.classList.toggle('hud-gated', !revealed.economy);
    // Loadout chip (phrases): hidden until phrases stage
    loadoutChipEl.classList.toggle('hud-gated', !revealed.phrases);
    // Difficulty selector: hidden until difficulty stage
    diffSelectorEl.classList.toggle('hud-gated', !revealed.difficulty);
    // Kennel button: hidden until kennel stage
    kennelBtnEl.classList.toggle('hud-gated', !revealed.kennel);
  }

  // Coach-pill visibility — driven by main.ts from the pure onboarding gates
  // (shouldCoachCoreVerb / shouldCoachDistractors). Reuses the shared .hud-gated
  // hide class so the coach occupies no space and is aria-hidden while gated off.
  // Pass `text` to show the contextual distractor hint (task 109): the longer copy
  // gets the .coach-wide modifier so it wraps instead of overflowing the viewport;
  // omitting `text` restores the short core-verb prompt (task 108). One element,
  // swapped text — keeps HUD stacking unchanged.
  function setCoachVisible(visible: boolean, text?: string): void {
    if (text !== undefined) {
      coachEl.textContent = text;
      coachEl.classList.add('coach-wide');
    } else {
      coachEl.textContent = COACH_CORE_VERB_TEXT;
      coachEl.classList.remove('coach-wide');
    }
    coachEl.classList.toggle('hud-gated', !visible);
  }

  // Idle "welcome back" toast — announces the idle-income trickle collected on
  // return (specs.md §Kennel). Driven by main.ts behind shouldShowIdleWelcome;
  // shows the coin count, then auto-fades so it never blocks play.
  let idleWelcomeTimer: ReturnType<typeof setTimeout> | undefined;
  function showIdleWelcome(coins: number): void {
    idleWelcomeEl.textContent = `Velkommen tilbake! +${coins} 🪙`;
    idleWelcomeEl.classList.remove('hud-gated');
    idleWelcomeEl.classList.add('idle-welcome-in');
    if (idleWelcomeTimer !== undefined) clearTimeout(idleWelcomeTimer);
    idleWelcomeTimer = setTimeout(() => {
      idleWelcomeEl.classList.remove('idle-welcome-in');
      idleWelcomeEl.classList.add('hud-gated');
    }, IDLE_WELCOME_MS);
  }

  // Apply initial reveal flags from callbacks
  applyRevealed(callbacks.revealed);

  // Public kennel refresh — delegates to the kennel panel factory.
  function refreshKennelPanel(): void {
    kennelPanel.update?.();
  }

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

  return { renderTraining, showSelect, showTraining, refreshKennelPanel, applyRevealed, setCoachVisible, showIdleWelcome, setPaused, showLoading, hideLoading, celebrate };
}
