#!/bin/bash
# Weekly job: let Claude Code research new opportunities and re-verify old ones,
# then validate, commit and push. Safe by design:
#   - skips if the repo has uncommitted changes (so it never mixes with your edits)
#   - restores data on any failure, and only pushes if build.py validates the data
set -uo pipefail
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$DIR" || exit 1
LOG="$DIR/automation/update.log"
LOCK="/tmp/upgrade-update.lock"
NEW="${UPGRADE_NEW:-25}"
RECHECK="${UPGRADE_RECHECK:-20}"
BUDGET="${UPGRADE_BUDGET_USD:-5}"
TODAY="$(date +%F)"

log()    { echo "[$(date '+%F %T')] $*" | tee -a "$LOG"; }
notify() { osascript -e "display notification \"$1\" with title \"upgrade\"" >/dev/null 2>&1 || true; }
restore(){ git checkout -- data.txt details.json opportunities.csv data.json DATABASE.md automation/last-run.md 2>/dev/null; }

if ! mkdir "$LOCK" 2>/dev/null; then log "another run is in progress, skipping"; exit 0; fi
trap 'rmdir "$LOCK"' EXIT

log "=== start (new=$NEW, recheck=$RECHECK, budget=\$$BUDGET) ==="
if [ -n "$(git status --porcelain -- . ':!automation/update.log')" ]; then
  log "repo has uncommitted changes, skipping this week"; notify "Skipped: uncommitted changes in upgrade/"; exit 0
fi
git pull --rebase --quiet >>"$LOG" 2>&1 || { log "git pull failed"; notify "Update failed: git pull"; exit 1; }

PROMPT="$(sed -e "s/{{TODAY}}/$TODAY/g" -e "s/{{NEW}}/$NEW/g" -e "s/{{RECHECK}}/$RECHECK/g" -e "s/{{DETAILS}}/${UPGRADE_DETAILS:-15}/g" automation/prompt.md)"
"${UPGRADE_CLAUDE_BIN:-claude}" -p "$PROMPT" \
  --allowedTools "WebSearch" "WebFetch" "Read" "Edit" "Write" "Glob" "Grep" "Bash(python3 build.py)" \
  --max-budget-usd "$BUDGET" </dev/null >>"$LOG" 2>&1
RC=$?
log "claude exited with $RC"

if ! python3 build.py >>"$LOG" 2>&1; then
  log "validation failed, restoring data"; restore; notify "Update failed validation, nothing changed"; exit 1
fi
# only data files may change
OTHER="$(git status --porcelain | awk '{print $2}' | grep -vE '^(data.txt|details.json|opportunities.csv|data.json|DATABASE.md|automation/last-run.md|automation/update.log)$')"
if [ -n "$OTHER" ]; then
  log "unexpected files changed: $OTHER — restoring"; git checkout -- $OTHER 2>/dev/null; git clean -fdq -- $OTHER 2>/dev/null
fi
if git diff --quiet -- data.txt details.json; then log "no data changes"; notify "Weekly run: no changes"; exit 0; fi

TOTAL="$(python3 -c 'import json;d=json.load(open("data.json"));print(d["total"],d["verified"])')"
git add data.txt details.json opportunities.csv data.json DATABASE.md automation/last-run.md
git commit -qm "chore(data): weekly update $TODAY ($TOTAL total/verified)" && git push -q >>"$LOG" 2>&1 \
  && { log "pushed: $TOTAL"; notify "Updated: $TOTAL (total/verified). See automation/last-run.md"; } \
  || { log "commit/push failed"; notify "Update committed locally but push failed"; }
