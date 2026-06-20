import type { createScene } from './render/scene';
import { breedAppearance } from './render/dogAppearance';
import { createHud } from './ui/hud';
import { toViewModel } from './ui/viewModel';
import { createRound, replaceTimeline, RoundState } from './core/round';
import { buildTimeline, SchedulerConfig, attemptAt, untrainAttemptAt } from './core/scheduler';
import { effectiveDifficulty, applyTrickProfile, confuseDifficulty, DifficultyMode, type EffectiveDifficulty } from './core/difficulty';
import { Profile, newProfile, award, spend } from './core/economy';
import { completeMastery, completePractice } from './core/game';
import { canGraduate, graduate, PRESTIGE_PER_GRADUATION } from './core/prestige';
import { kennelMultiplier, idleIncome, KENNEL_UPGRADES } from './core/kennel';
import { IndexedDbStorage } from './state/storage';
import { STARTER_ROSTER } from './state/save';
import { classifyMark } from './core/mark';
import { applyMark, isConfused } from './core/session';
import { comboAfter, comboMultiplier } from './core/combo';
import { engagement, ENGAGEMENT_FULL, rewardLatencyMs } from './core/engagement';
import { cycleIndex } from './core/swipeGesture';
import { BASE_PHRASE, PHRASE_CATALOG, availablePhrases, nextPurchasableEntry, type Phrase } from './core/phrases';
import { resolvePhraseMark } from './core/markWithPhrase';
import { RESUME_GRACE_MS, isWithinResumeGrace } from './core/resumeGrace';
import { MarkAudio } from './audio/markAudio';
import { dogVisualState } from './render/dogState';
import { STARTER_BREED, BREED_CATALOG, adoptableBreeds, canAdopt, isBreedLevelLocked, composeDifficulty, type Breed } from './core/breeds';
import type { Dog } from './core/roster';
import { recordMastery, addDog } from './core/roster';
import { STARTER_TRICKS, UNTRAIN_TRICKS, SIGNATURE_TRICKS, tricksForBreed, graduationTrickIds, type Trick } from './core/tricks';
import { onboardingStage, untrainTricksUnlocked } from './core/onboarding';
import { totalMasteredCount, buildSchedulerCfg, boostedDeltas, buildGameSave, restoreLearnedBar, BASE_SCHEDULER_TIMING } from './app/gameHelpers';
import { updateStreak } from './core/streak';
import { ACHIEVEMENTS, unlockedAchievements } from './core/achievements';

// ── Scene ──────────────────────────────────────────────────────────────────
const canvas = document.getElementById('scene');
if (!(canvas instanceof HTMLCanvasElement)) {
  throw new Error('#scene canvas not found');
}

// sceneApi is populated asynchronously via a dynamic import kicked off after
// the select screen mounts. Guard every call with `if (sceneApi)`.
let sceneApi: ReturnType<typeof createScene> | null = null;

// ── Difficulty & scheduler config ──────────────────────────────────────────
// MODE is mutable — setMode() rebuilds everything when the player changes it.
let MODE: DifficultyMode = 'NORMAL';
let difficulty = effectiveDifficulty(MODE);

// roundDifficulty = effectiveDifficulty × active trick's profile.
// Rebuilt whenever MODE changes or a new trick is selected.
let roundDifficulty: EffectiveDifficulty = difficulty; // starts as plain difficulty (no trick selected yet)

let SCHEDULER_CFG: SchedulerConfig = {
  ...BASE_SCHEDULER_TIMING,
  ...difficulty.scheduler,
  distractorRate: 0,      // gated to 0 until onboarding reveals distractors (see buildSchedulerCfg)
};

const TIMELINE_EVENTS = 20; // events per segment; loops on exhaustion

// ── Phrase loadout ─────────────────────────────────────────────────────────
// Phrases are sourced from PHRASE_CATALOG; loaded phrase cycles among available.

// ── Bootstrap (async IIFE so we can await storage without top-level await) ─
void (async () => {
  // ── Profile (load from IndexedDB or start fresh) ─────────────────────────
  const storage = new IndexedDbStorage();
  let profile: Profile = newProfile();
  let kennelUpgradeIds: string[] = [];
  let unlockedPhraseIds: string[] = [];
  let prestigePoints: number = 0;

  // Roster — default starter dog
  let roster: Dog[] = [...STARTER_ROSTER];

  // Active dog — mutable; updated when player picks a different dog
  let activeDogId = 'rex';

  // Persisted muted flag — restored from save before markAudio is created
  let savedMuted = false;

  // Best combo streak ever reached — persisted and restored from save
  let bestCombo = 0;

  // Daily streak — consecutive days played; updated on every load from today's date
  let streak = 0;
  let lastPlayedYmd = '';

  // Active-round snapshot from the loaded save — used once on round-start to resume.
  // These are read-only once captured; the live state is tracked in activeRoundDogId / activeRoundTrickId below.
  let savedActiveRoundDogId: string | null = null;
  let savedActiveTrickId: string | null = null;
  let savedLearnedBar: number = 0;

  // Live tracking of the in-progress round; null when on the select screen.
  let activeRoundDogId: string | null = null;
  let activeRoundTrickId: string | null = null;

  // Bootstrap save: snapshots the shared state during load (idle-income reset and
  // streak update). Distinct from persist() — it runs before markAudio/round state
  // exist, so it uses savedMuted and never carries active-round fields. Reads the
  // mutable bootstrap locals at call time, so it always saves the latest values.
  function persistBootstrap(): void {
    storage.save(buildGameSave({
      profile,
      roster,
      kennelUpgradeIds,
      difficultyMode: MODE,
      unlockedPhraseIds,
      prestigePoints,
      idleTimestamp: Date.now(),
      muted: savedMuted,
      bestCombo,
      streak,
      lastPlayedYmd,
    })).catch(() => {
      // save failure is non-fatal
    });
  }

  try {
    const save = await storage.load();
    if (save?.profile) {
      profile = save.profile;
      kennelUpgradeIds = save.kennelUpgradeIds ?? [];
      unlockedPhraseIds = save.unlockedPhraseIds ?? [];
      prestigePoints = save.prestigePoints ?? 0;
      roster = save.roster ?? roster;

      // Restore saved difficulty mode (defaults NORMAL for old saves)
      MODE = save.difficultyMode ?? 'NORMAL';
      // Stash muted for application after markAudio is created
      savedMuted = save.muted ?? false;
      // Restore best combo from save
      bestCombo = save.bestCombo ?? 0;
      // Restore streak state from save
      streak = save.streak ?? 0;
      lastPlayedYmd = save.lastPlayedYmd ?? '';
      // Capture the in-progress round snapshot (new fields; null/0 for old saves)
      savedActiveRoundDogId = save.activeRoundDogId ?? null;
      savedActiveTrickId = save.activeTrickId ?? null;
      savedLearnedBar = save.learnedBar ?? 0;
      // Use composeDifficulty so the active dog's breed is factored in on load
      difficulty = composeDifficulty(MODE, getActiveBreed());
      // roundDifficulty stays as plain difficulty until a trick is selected
      roundDifficulty = difficulty;
      // buildSchedulerCfg() gates distractorRate by onboarding stage
      SCHEDULER_CFG = buildSchedulerCfg(totalMasteredCount(roster), roundDifficulty);

      // Grant idle income accumulated since last session
      const earned = idleIncome(save.idleTimestamp, Date.now());
      if (earned > 0) {
        profile = award(profile, { coins: earned, xp: 0 }, 1);
        // Persist the reset timestamp immediately so re-loading doesn't double-grant
        persistBootstrap();
      }
    }
  } catch {
    // IndexedDB unavailable (e.g. private browsing) — use fresh profile
  }

  // ── Daily streak update ───────────────────────────────────────────────────
  // Compute today's YYYY-MM-DD and advance the streak (always runs on load).
  {
    const todayYmd = new Date().toISOString().slice(0, 10);
    const updated = updateStreak(lastPlayedYmd, todayYmd, streak);
    streak = updated.streak;
    lastPlayedYmd = updated.lastPlayedYmd;
    // Persist the updated streak immediately
    persistBootstrap();
  }

  // ── Timeline helpers ──────────────────────────────────────────────────────
  function makeTimeline(offset: number) {
    const raw = buildTimeline(SCHEDULER_CFG, Math.random, TIMELINE_EVENTS);
    // Shift all timestamps so the new segment starts after the current clock
    return raw.map((ev) => ({
      ...ev,
      activeStart: ev.activeStart + offset,
      activeEnd: ev.activeEnd + offset,
      attempt: ev.attempt
        ? {
            ...ev.attempt,
            start: ev.attempt.start + offset,
            end: ev.attempt.end + offset,
            peak: ev.attempt.peak + offset,
          }
        : undefined,
    }));
  }

  // ── Round state ───────────────────────────────────────────────────────────
  let timelineOffset = 0;
  let state: RoundState = createRound(makeTimeline(timelineOffset));
  let prevMastered = false;
  let prevConfused = false;
  let wasAlreadyMastered = false;

  // ── Combo state ───────────────────────────────────────────────────────────
  let combo = 0;

  // ── Engagement meter (0..1) ───────────────────────────────────────────────
  // The dog's eagerness this round: good marks refill it, sloppy/false marks
  // drain it (src/core/engagement.ts). A transient session feel — like combo,
  // it is not persisted; every fresh round starts with an eager dog.
  let engagementMeter = ENGAGEMENT_FULL;

  // ── BRA press disambiguation (tap vs phrase-swipe) ────────────────────────
  // The press records its instant on pointerdown; the mark only commits on
  // pointerup IF the gesture wasn't a horizontal swipe (which swaps the phrase
  // instead). Scoring still uses this recorded pointerdown instant, so swipe
  // support never adds latency to the timing tap. null = no press in flight.
  let pendingDownAt: number | null = null;

  // ── Idle-pant throttle ────────────────────────────────────────────────────
  // Foley pant plays at most once per PANT_INTERVAL_MS while the dog is idle.
  const PANT_INTERVAL_MS = 7000;
  let lastPantAt = -Infinity;

  // ── Phrase state ──────────────────────────────────────────────────────────
  // Start on BASE_PHRASE; after loading save, loadedPhrase is the first available.
  let loadedPhrase: Phrase = BASE_PHRASE;
  let lastUsedAt: number | null = null;

  // ── App state machine: 'select' | 'training' ──────────────────────────────
  type AppState = 'select' | 'training';
  let appState: AppState = 'select';
  let activeTrick: Trick = STARTER_TRICKS[0]; // will be set on selection

  // ── Mobile resume grace (specs.md §Mistakes → Mobile grace) ────────────────
  // Timestamp of the most recent foreground resume. Starts in the far past so the
  // first taps of a fresh session are never swallowed. A tap within RESUME_GRACE_MS
  // of a resume (notification dismiss / lock wake / fat-finger) is ignored.
  let resumedAt = -Infinity;
  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'visible') resumedAt = performance.now();
  });

  function persist(): void {
    const inRound = appState === 'training' && activeRoundDogId !== null && activeRoundTrickId !== null;
    storage.save(buildGameSave({
      profile,
      roster,
      kennelUpgradeIds,
      difficultyMode: MODE,
      unlockedPhraseIds,
      prestigePoints,
      idleTimestamp: Date.now(),
      muted: markAudio.isMuted(),
      bestCombo,
      streak,
      lastPlayedYmd,
      activeRoundDogId: inRound ? activeRoundDogId : null,
      activeTrickId: inRound ? activeRoundTrickId : null,
      learnedBar: inRound ? state.session.learned : 0,
    })).catch(() => {
      // save failure is non-fatal
    });
  }

  /** Cycle loadedPhrase to the next/previous available phrase (wraps around). */
  function cyclePhrase(dir: 'next' | 'prev' = 'next'): void {
    const available = availablePhrases(profile, unlockedPhraseIds);
    if (available.length <= 1) return;
    const idx = available.findIndex(p => p.id === loadedPhrase.id);
    loadedPhrase = available[cycleIndex(Math.max(0, idx), available.length, dir)];
    lastUsedAt = null; // reset cooldown on switch
  }

  /** Unlock the next level-eligible phrase by spending coins; returns true on success. */
  function unlockNextPhrase(): boolean {
    // Only purchase a phrase that the player's level already unlocks (level gate first)
    const nextEntry = nextPurchasableEntry(profile.level, unlockedPhraseIds);
    if (!nextEntry) return false;
    const updated = spend(profile, nextEntry.unlockCost);
    if (!updated) return false; // insufficient coins
    profile = updated;
    unlockedPhraseIds = [...unlockedPhraseIds, nextEntry.phrase.id];
    persist();
    return true;
  }

  /**
   * Returns the next phrase entry for the unlock affordance UI.
   * - If the player is level-eligible for at least one entry, returns the first such entry
   *   (coin affordability is surfaced separately via coins in the loadout state).
   * - If no entry is level-eligible, returns the next entry the player hasn't yet reached
   *   by level (so the HUD can show "Lvl N" as the blocker).
   * - Returns null when all phrases are owned.
   */
  function nextLockedEntry() {
    // First: level-eligible entries (not owned, cost > 0, level OK)
    const purchasable = nextPurchasableEntry(profile.level, unlockedPhraseIds);
    if (purchasable) return purchasable;
    // Second: next not-owned entry beyond the player's current level (level-locked)
    return PHRASE_CATALOG.find(
      e => e.unlockCost > 0 && !unlockedPhraseIds.includes(e.phrase.id)
    ) ?? null;
  }

  function startFreshRound(now: number): void {
    timelineOffset = now;
    state = createRound(makeTimeline(timelineOffset));
    prevMastered = false;
    prevConfused = false;
    combo = 0;
    engagementMeter = ENGAGEMENT_FULL;
  }

  function regenerateTimeline(now: number): void {
    // Build a fresh segment starting from now, but PRESERVE learned progress —
    // the bar must not reset just because the placeholder timeline looped.
    timelineOffset = now;
    state = replaceTimeline(state, makeTimeline(timelineOffset));
  }

  // ── Active breed lookup ───────────────────────────────────────────────────
  function getActiveBreed(): Breed {
    const dog = roster.find(d => d.id === activeDogId);
    return BREED_CATALOG.find(b => b.id === dog?.breedId) ?? STARTER_BREED;
  }

  // ── Mode switching ────────────────────────────────────────────────────────
  function setMode(mode: DifficultyMode): void {
    MODE = mode;
    difficulty = composeDifficulty(mode, getActiveBreed());
    // Reapply the active trick's profile on top of the new mode × breed
    roundDifficulty = applyTrickProfile(difficulty, activeTrick);
    SCHEDULER_CFG = buildSchedulerCfg(totalMasteredCount(roster), roundDifficulty);
    // Start a fresh round so new scheduler params take effect immediately.
    if (appState === 'training') {
      startFreshRound(performance.now());
    }
    persist();
  }

  // ── Onboarding helpers (pure; defined in src/app/gameHelpers.ts) ──────────
  // totalMasteredCount, effectiveDistractorRate, buildSchedulerCfg are imported.

  // ── Audio ─────────────────────────────────────────────────────────────────
  const markAudio = new MarkAudio();
  // Apply muted flag restored from save
  markAudio.setMuted(savedMuted);

  // Ambient starts on first user gesture (autoplay policy). Only called once.
  let ambientStarted = false;
  function ensureAmbient(): void {
    if (ambientStarted) return;
    ambientStarted = true;
    markAudio.startAmbient();
  }

  // ── HUD ───────────────────────────────────────────────────────────────────
  const { renderTraining, showSelect, showTraining, applyRevealed, showLoading, hideLoading, celebrate } = createHud({
    // The BRA marker is press-then-release so a horizontal swipe can swap the phrase
    // (specs §Marker Phrases) without ever firing a stray mark. The press instant is
    // recorded here; the mark commits on release only if it wasn't a swipe.
    onBraTapDown() {
      ensureAmbient();
      pendingDownAt = performance.now();
    },
    // A horizontal swipe consumed the press → swap the loaded phrase, never mark.
    onSwapPhrase(dir: 'next' | 'prev') {
      pendingDownAt = null;
      cyclePhrase(dir);
    },
    onBraTapCommit() {
      const downAt = pendingDownAt;
      pendingDownAt = null;
      if (downAt === null) return;
      if (appState !== 'training') return;
      // Score using the *pointerdown* instant, not release — swipe support adds no
      // latency to the timing tap (the whole game is precise timing).
      const now = downAt;
      // Mobile grace: swallow stray taps right after returning from background
      // (notification dismiss / lock wake / fat-finger) so they never false-mark + confuse.
      if (isWithinResumeGrace(now, resumedAt, RESUME_GRACE_MS)) return;
      // For untraining tricks, the markable window is the calm gap (inverted).
      // For normal tricks, use the regular attemptAt.
      const active = activeTrick.untrain
        ? untrainAttemptAt(state.timeline, now)
        : attemptAt(state.timeline, now);
      const { attempt, fired } = resolvePhraseMark(active, loadedPhrase, now, lastUsedAt);
      const result = classifyMark(now, attempt);
      // Apply combo multiplier to the learned-bar deltas (positive deltas only).
      const mult = comboMultiplier(combo);
      const deltas = boostedDeltas(roundDifficulty.deltas, mult);
      // Pass roundDifficulty.deltas so trick profile (learnMult) and difficulty mode
      // both influence how much each mark advances the learned bar.
      state = { ...state, session: applyMark(state.session, result, now, deltas), lastResult: result };
      // Advance or reset combo based on this mark.
      combo = comboAfter(combo, result);
      // Track all-time best combo
      bestCombo = Math.max(bestCombo, combo);
      // Drain/refill the engagement meter: precise marks keep the dog eager,
      // sloppy/false marks bore it (drives the HUD mood meter + disengage beat).
      engagementMeter = engagement(engagementMeter, { kind: 'mark', result });
      // "Slow rewards drain it" (spec §Mistakes): on a real reward (PERFECT/OK), how
      // promptly the player marked the apex also nudges engagement. Pure timing —
      // no dog clips, so this is unblocked (corrects 098's over-broad 079 deferral).
      if ((result === 'PERFECT' || result === 'OK') && attempt) {
        engagementMeter = engagement(engagementMeter, {
          kind: 'reward',
          latencyMs: rewardLatencyMs(now, attempt.peak),
        });
      }
      if (fired && loadedPhrase.cooldownMs > 0) {
        lastUsedAt = now;
      }
      markAudio.play(result);
      if (result === 'FALSE_MARK') markAudio.playFoley('false-huff');
      // Notify the 3D scene on every successful mark so the dog gives a brief
      // reward pulse (bounce + tail flick). PERFECT pops more than OK (per D8).
      // Subsequent calls REPLACE the stored mark (refresh-not-stack).
      if (result === 'PERFECT' || result === 'OK') {
        sceneApi?.notifyMark(result, now);
      }
    },
    onSelectMode(mode: DifficultyMode) {
      setMode(mode);
    },
    initialMode: MODE,

    // Select-screen callbacks
    onSelectTrick(trick: Trick) {
      ensureAmbient();
      markAudio.playTap();
      activeTrick = trick;
      // Capture mastery state BEFORE the round starts (recordMastery mutates roster on mastery edge)
      wasAlreadyMastered = roster.find(d => d.id === activeDogId)?.masteredTrickIds.includes(trick.id) ?? false;
      // Derive round config from mode × breed × trick profile
      difficulty = composeDifficulty(MODE, getActiveBreed());
      roundDifficulty = applyTrickProfile(difficulty, trick);
      SCHEDULER_CFG = buildSchedulerCfg(totalMasteredCount(roster), roundDifficulty);
      appState = 'training';
      // Track the in-progress round so persist() can snapshot it
      activeRoundDogId = activeDogId;
      activeRoundTrickId = trick.id;
      startFreshRound(performance.now());
      // Resume partial learned-bar from save — only for tricks not already mastered
      // (re-practice always starts fresh). restoreLearnedBar returns 0 on any mismatch.
      if (!wasAlreadyMastered) {
        const resumedBar = restoreLearnedBar({
          savedDogId: savedActiveRoundDogId,
          savedTrickId: savedActiveTrickId,
          savedBar: savedLearnedBar,
          startDogId: activeDogId,
          startTrickId: trick.id,
        });
        if (resumedBar > 0) {
          state = { ...state, session: { ...state.session, learned: resumedBar } };
        }
      }
      showTraining(trick.name);
      // Show loading indicator only if the scene is not yet ready
      if (sceneApi === null) {
        showLoading();
      }
    },
    getTricks() {
      const dog = roster.find(d => d.id === activeDogId);
      const masteredIds = dog?.masteredTrickIds ?? [];
      const activeBreed = getActiveBreed();
      const breedTricks = tricksForBreed(activeBreed);
      const untrain = untrainTricksUnlocked(masteredIds.length) ? UNTRAIN_TRICKS : [];
      return [...breedTricks, ...untrain].map(trick => ({
        trick,
        mastered: masteredIds.includes(trick.id),
      }));
    },
    getDogName() {
      return roster.find(d => d.id === activeDogId)?.name ?? 'Rex';
    },
    // Roster: pick active dog
    getRoster() {
      return roster.map(dog => ({ dog, isActive: dog.id === activeDogId }));
    },
    onSelectDog(dogId: string) {
      if (!roster.some(d => d.id === dogId)) return;
      markAudio.playTap();
      activeDogId = dogId;
      // Rebuild difficulty for the newly active dog's breed
      difficulty = composeDifficulty(MODE, getActiveBreed());
      roundDifficulty = applyTrickProfile(difficulty, activeTrick);
      SCHEDULER_CFG = buildSchedulerCfg(totalMasteredCount(roster), roundDifficulty);
      // Update the dog's visual appearance to match the newly selected breed
      if (sceneApi) sceneApi.setBreed(getActiveBreed().id);
      // Refresh select screen to show the new dog's tricks
      showSelect();
    },
    // Adopt shop callbacks
    getAdoptableBreeds() {
      return adoptableBreeds(roster).map(breed => ({
        breed,
        affordable: canAdopt(breed, profile.coins, profile.level, roster),
        levelGated: isBreedLevelLocked(breed, profile.level), // blocked by level, not coins
      }));
    },
    onAdoptBreed(breedId: string) {
      const breed = BREED_CATALOG.find(b => b.id === breedId);
      if (!breed || !canAdopt(breed, profile.coins, profile.level, roster)) return;
      const updated = spend(profile, breed.adoptCost ?? 0);
      if (!updated) return;
      profile = updated;
      const newDog: Dog = {
        id: breedId,
        name: breed.name,
        breedId: breed.id,
        masteredTrickIds: [],
      };
      roster = addDog(roster, newDog);
      // Switch to the newly adopted dog so the user sees it immediately
      activeDogId = breedId;
      // Update the 3D scene's breed appearance for the newly active dog
      if (sceneApi) sceneApi.setBreed(breedId);
      persist();
    },
    // Kennel shop callbacks
    getKennelState() {
      return { kennelUpgradeIds, coins: profile.coins };
    },
    onBuyUpgrade(upgradeId: string) {
      const upgrade = KENNEL_UPGRADES.find(u => u.id === upgradeId);
      if (!upgrade) return;
      const updated = spend(profile, upgrade.cost);
      if (!updated) return; // guard: insufficient coins
      profile = updated;
      kennelUpgradeIds = [...kennelUpgradeIds, upgradeId];
      // Update the backdrop tier live — no reload needed
      sceneApi?.setKennelUpgrades(kennelUpgradeIds);
      persist();
    },
    // Phrase loadout switcher callbacks
    onCyclePhrase() {
      cyclePhrase();
    },
    onUnlockNextPhrase() {
      return unlockNextPhrase();
    },
    getLoadoutState() {
      const nextLocked = nextLockedEntry();
      // True when the next phrase entry exists but is blocked by level (not coin-blocked)
      const nextLockedIsLevelGated = nextLocked !== null
        && !nextPurchasableEntry(profile.level, unlockedPhraseIds);
      return {
        loadedPhrase,
        lastUsedAt,
        available: availablePhrases(profile, unlockedPhraseIds),
        nextLocked,
        nextLockedIsLevelGated,
        coins: profile.coins,
      };
    },
    // Onboarding: initial reveal state based on roster at load time
    revealed: onboardingStage(totalMasteredCount(roster)),
    // Prestige / graduation
    canGraduateActiveDog() {
      const dog = roster.find(d => d.id === activeDogId);
      if (!dog) return false;
      return canGraduate(dog, graduationTrickIds(getActiveBreed()));
    },
    onGraduate() {
      const dog = roster.find(d => d.id === activeDogId);
      if (!dog) return;
      if (!canGraduate(dog, graduationTrickIds(getActiveBreed()))) return;
      prestigePoints += PRESTIGE_PER_GRADUATION;
      roster = roster.map(d => d.id === activeDogId ? graduate(d) : d);
      persist();
    },
    getPrestigePoints() {
      return prestigePoints;
    },
    // Settings panel
    isMuted() {
      return markAudio.isMuted();
    },
    onToggleMute(muted: boolean) {
      markAudio.setMuted(muted);
      persist();
    },
    async onResetProgress() {
      await storage.clear();
      location.reload();
    },
    getStats() {
      return {
        prestigePoints,
        coins: profile.coins,
        level: profile.level,
        tricksMastered: totalMasteredCount(roster),
        streak,
      };
    },
    // Achievements panel
    getAchievementsState() {
      const unlocked = unlockedAchievements({ roster, coins: profile.coins, prestigePoints, bestCombo });
      return { achievements: ACHIEVEMENTS, unlockedIds: unlocked };
    },
  });

  // ── rAF clock ─────────────────────────────────────────────────────────────
  const TIMELINE_DURATION_MS =
    TIMELINE_EVENTS * SCHEDULER_CFG.attemptInterval + SCHEDULER_CFG.activeSpan;

  function tick(): void {
    if (appState !== 'training') {
      requestAnimationFrame(tick);
      return;
    }

    const now = performance.now();

    // Detect mastered false→true transition
    const currentlyMastered = state.session.mastered;
    if (!prevMastered && currentlyMastered) {
      // Record mastery in roster
      roster = recordMastery(roster, activeDogId, activeTrick.id);

      // Play mastery jingle (ascending arpeggio reward)
      markAudio.playMastery();
      markAudio.playFoley('mastery-bark');

      // Fire celebratory visual burst (CSS-only, transient, pointer-events:none)
      celebrate();

      // Trigger the bigger/longer mastery hand gesture in the 3D scene
      sceneApi?.notifyMastery(now);

      // New mastery pays full; re-practicing an already-mastered trick pays the reduced
      // income floor (reduced coins, no XP) — keeps unlock-gating skill-driven.
      profile = wasAlreadyMastered
        ? completePractice(profile, MODE, kennelMultiplier(kennelUpgradeIds), prestigePoints, activeTrick)
        : completeMastery(profile, MODE, kennelMultiplier(kennelUpgradeIds), prestigePoints, activeTrick);
      // Clear the in-progress round snapshot so the mastered trick doesn't resume
      activeRoundDogId = null;
      activeRoundTrickId = null;
      persist();

      // Re-evaluate onboarding stage after mastery — may reveal new systems
      applyRevealed(onboardingStage(totalMasteredCount(roster)));

      // Render one happy frame so the 3D scene shows the mastery pose
      // (session.mastered=true → dogVisualState returns 'happy').
      // Delay showSelect() by one rAF so the WebGL render loop paints
      // the gold bounce before the select screen overlays the canvas.
      if (sceneApi) sceneApi.updateDog(state, now, { trickId: activeTrick.id, untrain: activeTrick.untrain });

      // Transition back to select screen (deferred one frame so happy pose renders)
      appState = 'select';
      requestAnimationFrame(() => showSelect());

      requestAnimationFrame(tick);
      return;
    }
    prevMastered = currentlyMastered;

    // Confuse debuff: while confused, the active timeline uses a tighter window and
    // more distractors (spec "Mistakes"). Rebuild only on the on/off edge.
    const confusedNow = isConfused(state.session, now);
    if (confusedNow !== prevConfused) {
      const eff = confusedNow ? confuseDifficulty(roundDifficulty) : roundDifficulty;
      SCHEDULER_CFG = buildSchedulerCfg(totalMasteredCount(roster), eff);
      regenerateTimeline(now);
      prevConfused = confusedNow;
    }

    // When the timeline is exhausted (and not yet mastered), loop it
    if (!state.session.mastered) {
      const elapsed = now - timelineOffset;
      if (elapsed > TIMELINE_DURATION_MS) {
        regenerateTimeline(now);
      }
    }

    // Soft idle pant — only while the dog is genuinely idle (waiting), infrequent.
    if (now - lastPantAt > PANT_INTERVAL_MS) {
      const visual = dogVisualState(state, now, { trickId: activeTrick.id, untrain: activeTrick.untrain });
      if (visual === 'idle') {
        markAudio.playFoley('idle-pant');
        lastPantAt = now;
      }
    }

    const vm = toViewModel(state, now, profile, roundDifficulty.tellIntensity, combo, engagementMeter);
    renderTraining(vm);
    if (sceneApi) sceneApi.updateDog(state, now, {
      trickId: activeTrick.id,
      untrain: activeTrick.untrain,
      // Thread the same peak signal driving the UI apex ring into the dog pose —
      // one source of truth so the on-dog apex and UI gold ring crest together.
      peakProximity: vm.peakProximity,
      tellStrength: vm.tellStrength,
    });

    requestAnimationFrame(tick);
  }

  // Start in select state
  showSelect();

  // ── Dev-only test hook ────────────────────────────────────────────────────
  // Exposes a minimal read-only API on window.__bra for e2e tests.
  // Gated to DEV builds only — absent from production bundles (tree-shaken by Vite).
  // Cast import.meta to access Vite's env extension without requiring vite/client types.
  const importMetaEnv = (import.meta as unknown as { env: { DEV?: boolean } }).env;
  if (importMetaEnv.DEV) {
    (window as unknown as Record<string, unknown>)['__bra'] = {
      /** Current coin balance (read-only). */
      coins: () => profile.coins,
      /** Current app screen: 'select' | 'training'. */
      screen: () => appState,
      /** Current learned-bar value (0–100). */
      learnedBar: () => state.session.learned,
    };
  }

  // Kick off Babylon scene import in the background — non-blocking.
  // The app always passes through select before training, so this resolves
  // well before the first trick is picked. Guard every updateDog call in
  // case training somehow starts before the import resolves.
  import('./render/scene').then(mod => {
    // Pass the active breed's appearance so the dog renders with the right coat on load
    sceneApi = mod.createScene(canvas, breedAppearance(getActiveBreed().id), kennelUpgradeIds);
    // Dev/screenshot hook — allows headless scripts to switch breed without UI interaction.
    // Safe to ship: no-ops in production if never called; no security surface.
    (window as unknown as Record<string, unknown>)['__setBreed'] = (id: string) => sceneApi?.setBreed(id);
    // Dev/screenshot hook — force-switch to any trick id for visual review screenshots.
    // Injects a synthetic trick into activeTrick and transitions to training so the
    // dog rendering loop immediately uses the new trickId. No-op outside dev use.
    (window as unknown as Record<string, unknown>)['__setTrick'] = (id: string) => {
      const found = [...STARTER_TRICKS, ...UNTRAIN_TRICKS, ...SIGNATURE_TRICKS].find(t => t.id === id);
      if (!found) return;
      activeTrick = found;
      appState = 'training';
      startFreshRound(performance.now());
      showTraining(found.name);
    };
    // Dev/screenshot hook — fire the trainer's-hand reward gesture without having
    // to land a real mark/mastery, so visual-review scripts can capture the hand
    // mid-window. 'mark' = quick treat offer; 'mastery' = bigger/longer gesture.
    // Safe to ship: no-ops in production if never called; no security surface.
    (window as unknown as Record<string, unknown>)['__notifyReward'] = (kind: string) => {
      const now = performance.now();
      if (kind === 'mastery') sceneApi?.notifyMastery(now);
      else sceneApi?.notifyMark('PERFECT', now);
    };
    // Dev/screenshot hook — drive the kennel-tier backdrop (task 095) without
    // having to earn coins and buy upgrades, so visual-review scripts can capture
    // the training ground at any tier. Pass the owned-upgrade ids; the backdrop
    // updates live. No-op outside dev use; no security surface.
    (window as unknown as Record<string, unknown>)['__setKennelUpgrades'] = (ids: string[]) => {
      kennelUpgradeIds = [...ids];
      sceneApi?.setKennelUpgrades(kennelUpgradeIds);
    };
    // Dev/screenshot hook — force the engagement meter to any 0..1 level so
    // visual-review scripts can capture the mood meter at each disengage beat
    // (engaged → itch → flop → bark → walk-off) without grinding bad marks.
    // No-op outside dev use; no security surface.
    (window as unknown as Record<string, unknown>)['__setEngagement'] = (level: number) => {
      engagementMeter = Math.max(0, Math.min(1, level));
    };
    // Dev/screenshot hook — unlock every phrase and raise the level past all gates so
    // more than one phrase is available, surfacing the BRA swipe affordance (task 099)
    // for visual review without grinding coins/levels. No-op outside dev use.
    (window as unknown as Record<string, unknown>)['__forcePhrases'] = () => {
      profile = { ...profile, level: 9 };
      unlockedPhraseIds = PHRASE_CATALOG.map(e => e.phrase.id).filter(id => id !== BASE_PHRASE.id);
    };
    // Hide the loading indicator now that the scene is ready
    hideLoading();
  }).catch(() => {
    // Scene load failure is non-fatal — training will just show a blank canvas.
    // Hide the indicator even on failure so it doesn't get stuck visible.
    hideLoading();
  });

  requestAnimationFrame(tick);
})();
