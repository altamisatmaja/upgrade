#!/bin/bash
# One validated batch: run Claude headless with a prompt, check data, commit and push.
# usage: batch.sh expand "<label>" "<slice description>" [count]
#        batch.sh enrich "<label>" "<names, one per line>"
set -uo pipefail
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
DIR="$(cd "$(dirname "$0")/.." && pwd)"; cd "$DIR" || exit 1
LOG="$DIR/automation/update.log"; TODAY="$(date +%F)"
MODE="$1"; LABEL="$2"; ARG="$3"; COUNT="${4:-50}"
BUDGET="${UPGRADE_BUDGET_USD:-8}"
log(){ echo "[$(date '+%F %T')] [$MODE:$LABEL] $*" | tee -a "$LOG"; }
restore(){ git checkout -- data.txt details.json opportunities.csv data.json DATABASE.md 2>/dev/null; }
count(){ python3 -c 'import json;d=json.load(open("data.json"));print(d["total"], d.get("detailed",0))'; }

BEFORE="$(count)"
python3 - "$MODE" "$TODAY" "$ARG" "$COUNT" > /tmp/upgrade-prompt.txt <<'PY'
import sys
mode, today, arg, count = sys.argv[1:5]
t = open(f'automation/{mode}-prompt.md', encoding='utf-8').read()
print(t.replace('{{TODAY}}', today).replace('{{SLICE}}', arg).replace('{{NAMES}}', arg).replace('{{COUNT}}', count))
PY
log "start (budget \$$BUDGET)"
"${UPGRADE_CLAUDE_BIN:-claude}" -p "$(cat /tmp/upgrade-prompt.txt)" \
  --allowedTools "WebSearch" "WebFetch" "Read" "Edit" "Glob" "Grep" "Bash(python3 build.py)" \
  --max-budget-usd "$BUDGET" </dev/null >>"$LOG" 2>&1
log "claude exited with $?"

if ! python3 build.py >>"$LOG" 2>&1; then log "validation failed, restoring"; restore; exit 1; fi
OTHER="$(git status --porcelain | awk '{print $2}' | grep -vE '^(data.txt|details.json|opportunities.csv|data.json|DATABASE.md|automation/update.log)$')"
[ -n "$OTHER" ] && { log "unexpected files changed, reverting: $OTHER"; git checkout -- $OTHER 2>/dev/null; git clean -fdq -- $OTHER 2>/dev/null; }
if git diff --quiet -- data.txt details.json; then log "no changes"; exit 0; fi

AFTER="$(count)"
read -r T0 D0 <<<"$BEFORE"; read -r T1 D1 <<<"$AFTER"
if [ "$MODE" = expand ]; then MSG="feat(data): add $((T1-T0)) $LABEL opportunities"
else MSG="feat(data): add details for $((D1-D0)) opportunities"; fi
git add data.txt details.json opportunities.csv data.json DATABASE.md
git commit -qm "$MSG" && git push -q >>"$LOG" 2>&1 && log "pushed: $MSG (now $T1 entries, $D1 detailed)" || log "commit/push failed"
