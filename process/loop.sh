#!/usr/bin/env bash
# Ralph loop (external / headless). Each iteration is a fresh `claude -p` with a
# clean context; state survives on disk via the task board. Two roles alternate:
#
#   MOTHER (mother_prompt.md) — the dev loop. Reads the board, scans for work,
#     builds tasks test-first, runs the gate. Treats .docs/specs.md as read-only.
#   FATHER (father_prompt.md) — the Product Owner. Runs and play-tests the actual
#     game, is critical, and its ONLY output is PO notes appended to specs.md.
#     The mother's scan-project then turns those notes into tasks.
#
# The father runs every FATHER_EVERY iterations OR whenever an iteration creates
# no new work (scan ran on an empty board and still left it empty). The loop only
# stops for real when the father play-tests and finds nothing left to change.
#
#   WARNING: runs with --dangerously-skip-permissions — claude can run ANY command
#   with no gate. Only run this in a throwaway / sandboxed environment.
#
# Usage: scripts/loop.sh [max_iterations]   (default 20)

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/.." || exit 1

# Prompts live next to this script (process/); resolve them absolutely so they're
# found regardless of the working directory we cd into above.
MOTHER_PROMPT="$SCRIPT_DIR/mother_prompt.md"
FATHER_PROMPT="$SCRIPT_DIR/father_prompt.md"
MODEL="${MODEL:-opus}"   # driver model; override: MODEL=sonnet scripts/loop.sh
MAX_ITER="${1:-20}"
FATHER_EVERY="${FATHER_EVERY:-5}"  # run the PO review at least this often
MAX_TURNS=600          # per-invocation turn cap (scan + implement + gate)
SOFT_CTX_WARN=150000   # warn if any single turn's prompt exceeds this (context heavy)
MAX_RETRY=3            # attempts per invocation before giving up on a *non-session* failure
RETRY_BASE=30          # backoff seconds; grows 30 -> 60 -> 120 across retries
SESSION_RETRY="${SESSION_RETRY:-1}"            # 1 = treat usage-limit / overload / auth-expiry as transient and retry forever
SESSION_BACKOFF="${SESSION_BACKOFF:-300}"      # wait between session retries when no reset time is known (s)
SESSION_MAX_WAIT="${SESSION_MAX_WAIT:-21600}"  # cap on a single session wait (s, 6h) — guards a bogus reset timestamp
ITER_TIMEOUT="${ITER_TIMEOUT:-1800}"    # hard wall-clock cap per claude invocation (s) — kills a runaway iteration
MAX_BUDGET_USD="${MAX_BUDGET_USD:-15}"  # hard per-invocation API spend cap (claude --max-budget-usd)
TOTAL_BUDGET_USD="${TOTAL_BUDGET_USD:-75}"  # cumulative spend cap across the whole run — stop the loop once exceeded
TOTAL_SPENT=0                           # running sum of per-iteration cost (accumulated in report_run)
LOG="loop.log"
ERRLOG="loop.err"      # claude stderr (API errors etc.) — the stdout JSON alone hides these

backlog_count() { find .task-board/backlog    -maxdepth 1 -name '*.md' 2>/dev/null | wc -l; }
inprog_count()  { find .task-board/in-progress -maxdepth 1 -name '*.md' 2>/dev/null | wc -l; }
spec_hash()     { sha1sum .docs/specs.md 2>/dev/null | cut -d' ' -f1; }

# Distinguish a *temporarily unavailable session* (subscription usage-limit reset,
# API overload / 429 / 5xx, OAuth/credential expiry) from a real failure. The first
# kind is worth waiting out and retrying indefinitely — each `claude -p` is stateless,
# so a later retry just resumes from disk once the window reopens. Inspects globals
# `out` (stdout JSON) and `err` (stderr text); on a usage-limit hit it also sets
# `session_reset_epoch` to the unix time the limit resets (0 if unknown).
session_reset_epoch=0
is_session_expiry() {
  session_reset_epoch=0
  local res api
  res=$(jq -r '.result // empty' <<<"$out" 2>/dev/null)
  # Claude subscription cap surfaces as "Claude AI usage limit reached|<reset-epoch>".
  if grep -qi 'usage limit reached' <<<"$res$err"; then
    session_reset_epoch=$(grep -oiE 'usage limit reached[^0-9]*[0-9]{8,}' <<<"$res$err" | grep -oE '[0-9]{8,}' | tail -1)
    session_reset_epoch=${session_reset_epoch:-0}
    return 0
  fi
  # API overload / rate limit / transient server errors.
  api=$(jq -r '.api_error_status // empty' <<<"$out" 2>/dev/null)
  case "$api" in 429|500|502|503|529) return 0 ;; esac
  grep -qiE 'overloaded|rate.?limit|\b(429|529|503)\b|service unavailable|connection reset|timed out|temporarily unavailable' <<<"$err" && return 0
  # Auth / OAuth session expiry — transient once the token refreshes.
  grep -qiE 'oauth|token (has )?expired|session (has )?expired|please (run )?/?login|unauthorized|\b401\b' <<<"$err" && return 0
  return 1
}

# Invoke claude on a prompt file. A *session-expiry* failure (usage-limit reset /
# overload / auth) is waited out and retried indefinitely (see is_session_expiry);
# any other transient failure is retried with exponential backoff up to MAX_RETRY,
# then gives up. Each invocation is stateless — disk (task board, source tree,
# specs) carries across retries, so a retry just resumes from disk. Sets global
# `out` (the result JSON); returns rc.
run_claude() {  # $1 = prompt file, $2 = label
  local pf="$1" label="$2" attempt=1 backoff rc errfile err now wait
  while :; do
    # Two hard guards so one iteration can't run away on time or money:
    #   timeout            — wall-clock cap; SIGTERM the invocation past ITER_TIMEOUT.
    #   --max-budget-usd   — claude stops once it has spent MAX_BUDGET_USD on API.
    # stderr is captured to a temp file (not a process-sub) so we can both log it and
    # classify the failure below; json-mode emits nothing on stderr unless it errors.
    errfile=$(mktemp)
    out=$(timeout --signal=TERM "$ITER_TIMEOUT" \
          claude -p "$(cat "$pf")" \
          --model "$MODEL" \
          --output-format json \
          --dangerously-skip-permissions \
          --max-turns "$MAX_TURNS" \
          --max-budget-usd "$MAX_BUDGET_USD" \
          2>"$errfile")
    rc=$?
    err=$(<"$errfile")
    if [[ -s "$errfile" ]]; then
      { echo "--- stderr claude($label) @ $(date -u) ---"; cat "$errfile"; } >>"$ERRLOG"
      cat "$errfile" >&2
    fi
    rm -f "$errfile"
    (( rc == 0 )) && return 0
    # The old failure path lost everything (stderr was empty, stdout discarded), so
    # a usage-cap / budget stop looked identical to a code crash. Capture the stdout
    # JSON's error fields here so the NEXT failure is diagnosable, not guessed at.
    {
      echo "--- claude($label) FAILED rc=$rc @ $(date -u) ---"
      (( rc == 124 )) && echo "rc=124 -> hit ITER_TIMEOUT=${ITER_TIMEOUT}s wall-clock cap (runaway iteration killed)."
      jq -r '"is_error=\(.is_error) subtype=\(.subtype) api_error=\(.api_error_status) cost=$\(.total_cost_usd // 0)\nresult: \(.result // "" | .[0:400])"' <<<"$out" 2>/dev/null \
        || echo "stdout (non-JSON, first 400): ${out:0:400}"
    } | tee -a "$ERRLOG" >>"$LOG"

    # Session temporarily unavailable (usage-limit reset / overload / auth expiry):
    # wait it out and retry forever — don't spend the MAX_RETRY budget on it. If the
    # usage-limit error carried a reset epoch, sleep until just past it; otherwise
    # back off a fixed interval. Either way `attempt` is NOT incremented.
    if (( SESSION_RETRY == 1 )) && is_session_expiry; then
      now=$(date +%s)
      if (( session_reset_epoch > now )); then
        wait=$(( session_reset_epoch - now + 30 ))
      else
        wait="$SESSION_BACKOFF"
      fi
      (( wait > SESSION_MAX_WAIT )) && wait="$SESSION_MAX_WAIT"
      if (( session_reset_epoch > now )); then
        echo "claude($label): session/usage limit hit — resets $(date -u -d "@$session_reset_epoch" 2>/dev/null || echo "at epoch $session_reset_epoch"); waiting ${wait}s then retrying (no attempt cap)." | tee -a "$LOG"
      else
        echo "claude($label): session unavailable (overload/usage/auth) — waiting ${wait}s then retrying (no attempt cap)." | tee -a "$LOG"
      fi
      sleep "$wait"
      continue
    fi

    if (( attempt >= MAX_RETRY )); then
      echo "claude($label) exited rc=$rc after $attempt attempt(s) — see $ERRLOG." | tee -a "$LOG"
      return "$rc"
    fi
    backoff=$(( RETRY_BASE * (1 << (attempt - 1)) ))   # 30s -> 60s -> 120s
    echo "claude($label) exited rc=$rc (attempt $attempt/$MAX_RETRY) — retrying in ${backoff}s." | tee -a "$LOG"
    sleep "$backoff"
    (( attempt++ ))
  done
}

# Parse the last run's result JSON (global `out`): append its text to the log and
# report is_error / context high-water mark / cost. Sets global `is_err`.
#
# Context-window high-water mark = the largest single turn's prompt size (input +
# cache reads + cache creation). The result JSON's own .usage sums every turn
# (millions of tokens) and is NOT a context-window measure, so we take the
# per-message peak from this session's transcript instead.
report_run() {  # $1 = label
  local cost sid tfile ctx
  is_err=$(jq -r '.is_error' <<<"$out" 2>/dev/null)
  cost=$(jq -r '.total_cost_usd // 0' <<<"$out" 2>/dev/null)
  jq -r '.result // empty' <<<"$out" >>"$LOG" 2>/dev/null
  sid=$(jq -r '.session_id // empty' <<<"$out" 2>/dev/null)
  tfile="$HOME/.claude/projects/$(pwd | sed 's#[/.]#-#g')/$sid.jsonl"
  ctx=$(grep -h '"type":"assistant"' "$tfile" 2>/dev/null \
        | jq -r 'select(.message.usage) | (.message.usage.input_tokens // 0) + (.message.usage.cache_read_input_tokens // 0) + (.message.usage.cache_creation_input_tokens // 0)' 2>/dev/null \
        | sort -n | tail -1)
  ctx=${ctx:-0}
  TOTAL_SPENT=$(LC_ALL=C awk -v a="$TOTAL_SPENT" -v b="$cost" 'BEGIN{printf "%.4f", a + b}')
  echo "$1: is_error=$is_err ctx_peak=$ctx cost=\$$cost (run total \$$TOTAL_SPENT / \$$TOTAL_BUDGET_USD)" | tee -a "$LOG"
  if [[ "$ctx" =~ ^[0-9]+$ ]] && (( ctx > SOFT_CTX_WARN )); then
    echo "WARN: $1 peak turn used $ctx ctx (> $SOFT_CTX_WARN) — context getting heavy." | tee -a "$LOG"
  fi
}

# True (rc 0) once cumulative spend has reached the whole-run cap.
over_budget() { LC_ALL=C awk -v s="$TOTAL_SPENT" -v c="$TOTAL_BUDGET_USD" 'BEGIN{exit !(s+0 >= c+0)}'; }

echo "=== loop start $(date -u) — max $MAX_ITER iters, PO review every $FATHER_EVERY ===" | tee -a "$LOG"

since_father=0
for ((i=1; i<=MAX_ITER; i++)); do
  echo "=== iter $i/$MAX_ITER $(date -u) ===" | tee -a "$LOG"

  # Snapshot the board BEFORE the iteration. Only an iteration that *starts*
  # empty runs scan-project (per mother_prompt.md step 2); we use this to tell
  # "drained a pre-seeded backlog" apart from "scan ran and found nothing".
  start_empty=$(( $(backlog_count) == 0 && $(inprog_count) == 0 ? 1 : 0 ))

  # --- Mother: one build iteration -------------------------------------------
  if ! run_claude "$MOTHER_PROMPT" mother; then
    echo "mother failed after retries — stopping. See $ERRLOG." | tee -a "$LOG"
    break
  fi
  report_run "iter $i (mother)"
  if [[ "$is_err" == "true" ]]; then
    echo "mother reported error — stopping." | tee -a "$LOG"
    break
  fi
  if over_budget; then
    echo "TOTAL_BUDGET_USD cap reached (spent \$$TOTAL_SPENT / \$$TOTAL_BUDGET_USD) — stopping." | tee -a "$LOG"
    break
  fi

  # --- Father: PO review on schedule or when the dev side is starved ---------
  # "No new work created" = scan ran on an empty board and still left it empty.
  # Either way the father play-tests the real game and writes PO notes into
  # specs.md; the next mother iteration's scan-project turns them into tasks.
  board_empty=$(( $(backlog_count) == 0 && $(inprog_count) == 0 ? 1 : 0 ))
  no_work_created=$(( start_empty == 1 && board_empty == 1 ? 1 : 0 ))
  (( since_father++ ))

  if (( no_work_created == 1 || since_father >= FATHER_EVERY )); then
    if (( no_work_created == 1 )); then why="no new work created"; else why="every $FATHER_EVERY iters"; fi
    echo "--- father (PO) review: $why ---" | tee -a "$LOG"
    before=$(spec_hash)
    if ! run_claude "$FATHER_PROMPT" father; then
      echo "father failed after retries — stopping. See $ERRLOG." | tee -a "$LOG"
      break
    fi
    report_run "iter $i (father)"
    after=$(spec_hash)
    since_father=0
    if over_budget; then
      echo "TOTAL_BUDGET_USD cap reached (spent \$$TOTAL_SPENT / \$$TOTAL_BUDGET_USD) — stopping." | tee -a "$LOG"
      break
    fi

    # The ONLY genuine stop: the dev side had no work AND the PO, after actually
    # play-testing, left specs byte-for-byte unchanged (nothing left to improve).
    if (( no_work_created == 1 )) && [[ "$before" == "$after" ]]; then
      echo "father play-tested and added no new PO notes — game matches the spec. Stopping." | tee -a "$LOG"
      break
    fi
    if [[ "$before" == "$after" ]]; then
      echo "father review done — specs unchanged; resuming build loop." | tee -a "$LOG"
    else
      echo "father review done — specs updated with PO notes; resuming build loop." | tee -a "$LOG"
    fi
  elif (( board_empty == 1 )); then
    echo "Board drained this iteration — next iteration will run scan-project." | tee -a "$LOG"
  fi
done

echo "=== loop end $(date -u) ===" | tee -a "$LOG"
