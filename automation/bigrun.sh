#!/bin/bash
# Long one-off run: expand every slice in slices.txt, then enrich rows without details.
# usage: bigrun.sh [count_per_slice=55] [enrich_fit=3] [enrich_batch=12]
set -uo pipefail
DIR="$(cd "$(dirname "$0")/.." && pwd)"; cd "$DIR" || exit 1
PER="${1:-55}"; FIT="${2:-3}"; EB="${3:-12}"
LOCK="/tmp/upgrade-update.lock"
notify(){ osascript -e "display notification \"$1\" with title \"upgrade\"" >/dev/null 2>&1 || true; }
if ! mkdir "$LOCK" 2>/dev/null; then echo "another run is in progress"; exit 1; fi
trap 'rmdir "$LOCK"' EXIT
if [ -n "$(git status --porcelain)" ]; then echo "commit or stash your changes first"; exit 1; fi

SLICES=(); while IFS= read -r line; do SLICES+=("$line"); done < <(grep -v '^#' automation/slices.txt | grep -v '^$')
for line in "${SLICES[@]}"; do
  label="${line%%|*}"; desc="${line#*|}"
  [ -n "${UPGRADE_ONLY:-}" ] && [ "$label" != "$UPGRADE_ONLY" ] && continue
  bash automation/batch.sh expand "$label" "$desc" "$PER" </dev/null
done
notify "Expand phase done: $(python3 -c 'import json;print(json.load(open("data.json"))["total"])') entries"

while :; do
  NAMES="$(python3 - "$FIT" "$EB" <<'PY'
import json, sys
fit, n = sys.argv[1], int(sys.argv[2])
d = json.load(open('data.json'))
todo = [r['name'] for r in d['rows'] if r['fit'] >= fit and 'details' not in r]
print('\n'.join(f'- {x}' for x in todo[:n]))
PY
)"
  [ -z "$NAMES" ] && break
  BEFORE="$(python3 -c 'import json;print(json.load(open("data.json")).get("detailed",0))')"
  bash automation/batch.sh enrich "fit$FIT" "$NAMES" </dev/null
  AFTER="$(python3 -c 'import json;print(json.load(open("data.json")).get("detailed",0))')"
  [ "$AFTER" = "$BEFORE" ] && { echo "no progress in enrich batch, stopping"; break; }
done
notify "Big run finished: $(python3 -c 'import json;d=json.load(open("data.json"));print(d["total"],"entries,",d["detailed"],"with details")')"
