import type { Attempt } from './mark';
import type { Phrase } from './phrases';
import { isReady, applyPhraseToAttempt } from './phrases';

export interface PhraseMark {
  attempt: Attempt | null;
  fired: boolean;
}

export function resolvePhraseMark(
  active: Attempt | null,
  phrase: Phrase,
  now: number,
  lastUsedAt: number | null,
): PhraseMark {
  const ready = isReady(phrase, now, lastUsedAt);
  if (active === null) {
    return { attempt: null, fired: ready };
  }
  if (ready) {
    return { attempt: applyPhraseToAttempt(active, phrase), fired: true };
  }
  return { attempt: active, fired: false };
}
