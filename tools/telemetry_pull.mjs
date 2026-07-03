#!/usr/bin/env node
// Telemetry pull (ADR-0007). Queries the PostHog EU query API (HogQL) with the personal
// read key + project id, aggregates the metrics that matter for Bra!, and prints ONE JSON
// blob to stdout for the analyst pass (process/analyst_prompt.md) to read.
//
// Design contract:
//   - NO-OP on no data. If it can't be configured, the API errors, or there are zero
//     sessions in the window, it prints {"no_data": true, ...} and exits 0. The loop then
//     skips the analyst entirely — so this costs ~nothing until there are real players.
//   - Read-only. It never writes the repo; loop.sh redirects stdout into gitignored
//     .telemetry/ (the raw pull can contain feedback PII — never commit it).
//
// Config (env; loop.sh sources a gitignored process/.env):
//   POSTHOG_API_KEY   personal API key (read) — the secret one, NOT the client project token
//   POSTHOG_ID        numeric project id
//   POSTHOG_HOST      default https://eu.posthog.com
//   TELEMETRY_WINDOW_DAYS  rolling window, default 7

const API_KEY = process.env.POSTHOG_API_KEY || "";
const PROJECT_ID = process.env.POSTHOG_ID || "";
const HOST = (process.env.POSTHOG_HOST || "https://eu.posthog.com").replace(/\/+$/, "");
const WINDOW = parseInt(process.env.TELEMETRY_WINDOW_DAYS || "7", 10);

// Emit a no-op result and exit cleanly — the ONLY failure mode this tool has (never throws).
function noData(reason) {
  process.stdout.write(JSON.stringify({ no_data: true, reason }) + "\n");
  process.exit(0);
}

if (!API_KEY || !PROJECT_ID) noData("unconfigured (POSTHOG_API_KEY / POSTHOG_ID not set locally)");

// Run one HogQL query; return its rows ([[...],...]) or [] on any error (so a single bad
// query can never crash the daily pull — a partial report beats no report).
async function hogql(query) {
  try {
    const res = await fetch(`${HOST}/api/projects/${PROJECT_ID}/query/`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ query: { kind: "HogQLQuery", query } }),
    });
    if (!res.ok) return { error: `${res.status} ${res.statusText}`, results: [] };
    const json = await res.json();
    return { results: json.results || [], columns: json.columns || [] };
  } catch (e) {
    return { error: String(e), results: [] };
  }
}

const W = `now() - INTERVAL ${WINDOW} DAY`;

// --- Sentinel: any sessions at all in the window? If not, no-op. --------------------------
const sessionsQ = await hogql(
  `SELECT count(DISTINCT properties.$session_id) FROM events WHERE timestamp > ${W}`
);
const sessions = Number(sessionsQ.results?.[0]?.[0] || 0);
if (sessionsQ.error && !sessions) noData(`query API error: ${sessionsQ.error}`);
if (!sessions) noData("no sessions in window");

// --- The metrics (each degrades to [] on error; the report is best-effort) ----------------
const [events, buckets, started, mastered, timing, quits, features, feedback] = await Promise.all([
  // event volume
  hogql(`SELECT event, count() AS n FROM events WHERE timestamp > ${W} GROUP BY event ORDER BY n DESC`),
  // BRA timing quality per trick (the primary signal)
  hogql(`SELECT properties.trick AS trick, properties.bucket AS bucket, count() AS n
          FROM events WHERE event = 'bra_tapped' AND timestamp > ${W}
          GROUP BY trick, bucket ORDER BY trick, n DESC`),
  // sessions that STARTED training each trick
  hogql(`SELECT properties.trick AS trick, count(DISTINCT properties.$session_id) AS started
          FROM events WHERE event = 'bra_tapped' AND timestamp > ${W} GROUP BY trick`),
  // sessions that MASTERED each trick → completion rate = mastered / started
  hogql(`SELECT properties.trick AS trick, count(DISTINCT properties.$session_id) AS mastered
          FROM events WHERE event = 'trick_mastered' AND timestamp > ${W} GROUP BY trick`),
  // time-to-first-successful-BRA (median ms since session start on a perfect/good tap)
  hogql(`SELECT quantile(0.5)(properties.ms_since_session_start)
          FROM events WHERE event = 'bra_tapped' AND properties.bucket IN ('perfect','good')
          AND timestamp > ${W}`),
  // where players leave
  hogql(`SELECT properties.last_trick AS last_trick, properties.best_progress AS best_progress, count() AS n
          FROM events WHERE event = 'session_end' AND timestamp > ${W}
          GROUP BY last_trick, best_progress ORDER BY n DESC`),
  // optional-feature usage (ascending → lowest are review candidates)
  hogql(`SELECT properties.feature AS feature, count(DISTINCT properties.$session_id) AS sessions
          FROM events WHERE event = 'feature_used' AND timestamp > ${W} GROUP BY feature ORDER BY sessions ASC`),
  // RAW feedback verbatim — the qualitative "why" (may contain PII → gitignored, never committed raw)
  hogql(`SELECT properties.text AS text, properties.tags AS tags, properties.rating AS rating,
          properties.screen_context AS screen_context, toString(timestamp) AS ts
          FROM events WHERE event = 'feedback_submitted' AND timestamp > ${W}
          ORDER BY timestamp DESC LIMIT 500`),
]);

// Zip [rows] + columns → array of objects, so the analyst reads named fields not positions.
function rows(q) {
  const cols = q.columns || [];
  return (q.results || []).map((r) => Object.fromEntries(cols.map((c, i) => [c, r[i]])));
}

// Distinct feedback-giving sessions in the window — the F that scales the analyst's
// suggestion threshold T = max(2, ceil(0.2 * F)).
const feedbackSessionsQ = await hogql(
  `SELECT count(DISTINCT properties.$session_id) FROM events WHERE event = 'feedback_submitted' AND timestamp > ${W}`
);
const feedbackSessions = Number(feedbackSessionsQ.results?.[0]?.[0] || 0);

process.stdout.write(
  JSON.stringify(
    {
      no_data: false,
      window_days: WINDOW,
      host: HOST,
      sessions,
      feedback_sessions: feedbackSessions,
      event_counts: rows(events),
      bra_buckets_by_trick: rows(buckets),
      trick_started: rows(started),
      trick_mastered: rows(mastered),
      time_to_first_success_ms_median: timing.results?.[0]?.[0] ?? null,
      quit_points: rows(quits),
      feature_usage_ascending: rows(features),
      feedback: rows(feedback),
    },
    null,
    2
  ) + "\n"
);
