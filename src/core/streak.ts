/**
 * Pure streak logic — no DOM, no Date.now(), no side effects.
 * Dates are passed in as 'YYYY-MM-DD' strings.
 */

export function updateStreak(
  lastPlayedYmd: string,
  todayYmd: string,
  currentStreak: number,
): { streak: number; lastPlayedYmd: string } {
  if (!lastPlayedYmd) {
    return { streak: 1, lastPlayedYmd: todayYmd };
  }

  if (lastPlayedYmd === todayYmd) {
    return { streak: currentStreak, lastPlayedYmd: todayYmd };
  }

  // Parse YYYY-MM-DD into a Date (midnight UTC) to compare calendar days
  const [ly, lm, ld] = lastPlayedYmd.split('-').map(Number);
  const [ty, tm, td] = todayYmd.split('-').map(Number);
  const lastMs = Date.UTC(ly, lm - 1, ld);
  const todayMs = Date.UTC(ty, tm - 1, td);
  const diffDays = Math.round((todayMs - lastMs) / 86_400_000);

  if (diffDays === 1) {
    return { streak: currentStreak + 1, lastPlayedYmd: todayYmd };
  }

  // gap >= 2 days (or negative/same handled above)
  return { streak: 1, lastPlayedYmd: todayYmd };
}
