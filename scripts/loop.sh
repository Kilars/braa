#!/usr/bin/env bash
# Ralph loop (external / headless). Each iteration is a fresh `claude -p` with a
# clean context; state survives on disk via the task board. See mother_prompt.md.
#
#   WARNING: runs with --dangerously-skip-permissions — claude can run ANY command
#   with no gate. Only run this in a throwaway / sandboxed environment.
#
# Usage: scripts/loop.sh [max_iterations]   (default 20)

set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

PROMPT_FILE="mother_prompt.md"
MODEL="${MODEL:-opus}"   # driver model; override: MODEL=sonnet scripts/loop.sh
MAX_ITER="${1:-20}"
MAX_TURNS=600          # per-invocation turn cap (scan + implement + gate)
SOFT_CTX_WARN=150000   # warn if any single turn's prompt exceeds this (context heavy)
MAX_RETRY=3            # attempts per iteration before giving up on a failing claude
RETRY_BASE=30          # backoff seconds; grows 30 -> 60 -> 120 across retries
LOG="loop.log"
ERRLOG="loop.err"      # claude stderr (API errors etc.) — the stdout JSON alone hides these

backlog_count() { find .task-board/backlog    -maxdepth 1 -name '*.md' 2>/dev/null | wc -l; }
inprog_count()  { find .task-board/in-progress -maxdepth 1 -name '*.md' 2>/dev/null | wc -l; }

echo "=== loop start $(date -u) — max $MAX_ITER iters ===" | tee -a "$LOG"

for ((i=1; i<=MAX_ITER; i++)); do
  echo "=== iter $i/$MAX_ITER $(date -u) ===" | tee -a "$LOG"

  # Snapshot the board BEFORE the iteration. Only an iteration that *starts*
  # empty runs scan-project (per mother_prompt.md step 2); we use this to tell
  # "drained a pre-seeded backlog" apart from "scan ran and found nothing".
  start_empty=$(( $(backlog_count) == 0 && $(inprog_count) == 0 ? 1 : 0 ))

  # Invoke claude, retrying transient failures (API 5xx / overload surface as a
  # non-zero exit) with exponential backoff. Each invocation is stateless — the
  # task board on disk carries across retries, so a retry just resumes the board.
  attempt=1
  while :; do
    out=$(claude -p "$(cat "$PROMPT_FILE")" \
          --model "$MODEL" \
          --output-format json \
          --dangerously-skip-permissions \
          --max-turns "$MAX_TURNS" \
          2> >(tee -a "$ERRLOG" >&2))
    rc=$?
    (( rc == 0 )) && break
    if (( attempt >= MAX_RETRY )); then
      echo "claude exited rc=$rc after $attempt attempt(s) — stopping. See $ERRLOG." | tee -a "$LOG"
      break 2
    fi
    backoff=$(( RETRY_BASE * (1 << (attempt - 1)) ))   # 30s -> 60s -> 120s
    echo "claude exited rc=$rc (attempt $attempt/$MAX_RETRY) — retrying in ${backoff}s." | tee -a "$LOG"
    sleep "$backoff"
    (( attempt++ ))
  done

  is_err=$(jq -r '.is_error' <<<"$out" 2>/dev/null)
  cost=$(jq -r '.total_cost_usd // 0' <<<"$out" 2>/dev/null)
  jq -r '.result // empty' <<<"$out" >>"$LOG" 2>/dev/null

  # Context-window high-water mark: the largest single turn's prompt size
  # (input + cache reads + cache creation). The result JSON's own .usage sums
  # every turn (millions of tokens) and is NOT a context-window measure, so we
  # take the per-message peak from this session's transcript instead.
  sid=$(jq -r '.session_id // empty' <<<"$out" 2>/dev/null)
  tfile="$HOME/.claude/projects/$(pwd | sed 's#[/.]#-#g')/$sid.jsonl"
  ctx=$(grep -h '"type":"assistant"' "$tfile" 2>/dev/null \
        | jq -r 'select(.message.usage) | (.message.usage.input_tokens // 0) + (.message.usage.cache_read_input_tokens // 0) + (.message.usage.cache_creation_input_tokens // 0)' 2>/dev/null \
        | sort -n | tail -1)
  ctx=${ctx:-0}

  echo "iter $i: is_error=$is_err ctx_peak=$ctx cost=\$$cost" | tee -a "$LOG"

  if [[ "$is_err" == "true" ]]; then
    echo "iteration reported error — stopping." | tee -a "$LOG"
    break
  fi

  if [[ "$ctx" =~ ^[0-9]+$ ]] && (( ctx > SOFT_CTX_WARN )); then
    echo "WARN: peak turn used $ctx ctx (> $SOFT_CTX_WARN) — context getting heavy." | tee -a "$LOG"
  fi

  # Terminate only when scan-project actually ran (board was empty at the start
  # of THIS iteration) and still produced no work. If the board merely drained
  # during the iteration (started non-empty), keep going so the next iteration
  # starts empty and triggers a replenishing scan-project pass.
  if (( $(backlog_count) == 0 && $(inprog_count) == 0 )); then
    if (( start_empty == 1 )); then
      echo "scan-project ran and found no new work. Spec complete." | tee -a "$LOG"
      break
    fi
    echo "Board drained this iteration — next iteration will run scan-project." | tee -a "$LOG"
  fi
done

echo "=== loop end $(date -u) ===" | tee -a "$LOG"
