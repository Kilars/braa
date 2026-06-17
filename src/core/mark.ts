export type MarkResult = 'PERFECT' | 'OK' | 'MISS' | 'FALSE_MARK';

export interface Attempt {
  start: number;      // ms, scoring window opens
  end: number;        // ms, scoring window closes
  peak: number;       // ms, ideal instant
  peakRadius: number; // ms, half-width of the PERFECT band
}

// Learned-bar deltas for Normal difficulty mode (spec: "PERFECT +8% OK +3% miss +0% false mark -4%")
export const NORMAL_DELTAS: Record<MarkResult, number> = {
  PERFECT: 8,
  OK: 3,
  MISS: 0,
  FALSE_MARK: -4,
};

export function classifyMark(tapTime: number, attempt: Attempt | null): MarkResult {
  if (!attempt) return 'FALSE_MARK';
  if (tapTime < attempt.start || tapTime > attempt.end) return 'MISS';
  if (Math.abs(tapTime - attempt.peak) <= attempt.peakRadius) return 'PERFECT';
  return 'OK';
}
