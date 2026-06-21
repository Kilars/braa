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
cd "$(dirname "$0")/.." || exit 1

MOTHER_PROMPT="mother_prompt.md"
FATHER_PROMPT="father_prompt.md"
MODEL="${MODEL:-opus}"   # driver model; override: MODEL=sonnet scripts/loop.sh
MAX_ITER="${1:-20}"
FATHER_EVERY="${FATHER_EVERY:-5}"  # run the PO review at least this often
MAX_TURNS=600          # per-invocation turn cap (scan + implement + gate)
SOFT_CTX_WARN=150000   # warn if any single turn's prompt exceeds this (context heavy)
MAX_RETRY=3            # attempts per invocation before giving up on a failing claude
RETRY_BASE=30          # backoff seconds; grows 30 -> 60 -> 120 across retries
ITER_TIMEOUT="${ITER_TIMEOUT:-1800}"    # hard wall-clock cap per claude invocation (s) — kills a runaway iteration
MAX_BUDGET_USD="${MAX_BUDGET_USD:-15}"  # hard per-invocation API spend cap (claude --max-budget-usd)
TOTAL_BUDGET_USD="${TOTAL_BUDGET_USD:-75}"  # cumulative spend cap across the whole run — stop the loop once exceeded
TOTAL_SPENT=0                           # running sum of per-iteration cost (accumulated in report_run)
LOG="loop.log"
ERRLOG="loop.err"      # claude stderr (API errors etc.) — the stdout JSON alone hides these

backlog_count() { find .task-board/backlog    -maxdepth 1 -name '*.md' 2>/dev/null | wc -l; }
inprog_count()  { find .task-board/in-progress -maxdepth 1 -name '*.md' 2>/dev/null | wc -l; }
spec_hash()     { sha1sum .docs/specs.md 2>/dev/null | cut -d' ' -f1; }

# Invoke claude on a prompt file, retrying transient failures (API 5xx / overload
# surface as a non-zero exit) with exponential backoff. Each invocation is
# stateless — disk (task board, source tree, specs) carries across retries, so a
# retry just resumes from disk. Sets global `out` (the result JSON); returns rc.
run_claude() {  # $1 = prompt file, $2 = label
  local pf="$1" label="$2" attempt=1 backoff rc
  while :; do
    # Two hard guards so one iteration can't run away on time or money:
    #   timeout            — wall-clock cap; SIGTERM the invocation past ITER_TIMEOUT.
    #   --max-budget-usd   — claude stops once it has spent MAX_BUDGET_USD on API.
    out=$(timeout --signal=TERM "$ITER_TIMEOUT" \
          claude -p "$(cat "$pf")" \
          --model "$MODEL" \
          --output-format json \
          --dangerously-skip-permissions \
          --max-turns "$MAX_TURNS" \
          --max-budget-usd "$MAX_BUDGET_USD" \
          2> >(tee -a "$ERRLOG" >&2))
    rc=$?
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
