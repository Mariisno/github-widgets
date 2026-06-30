#!/usr/bin/env bash
set -uo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$DIR")"
export GH_FIXTURE_DIR="$DIR/fixtures"
export ORG="your-org"   # match fixtures; fetch hopper over config.sh i fixture-modus

out="$("$ROOT/fetch-github.sh")"
fail=0
check() { # $1=beskrivelse $2=faktisk $3=forventet
  if [[ "$2" == "$3" ]]; then
    echo "ok:   $1"
  else
    echo "FEIL: $1 (fikk '$2', ventet '$3')"; fail=1
  fi
}

check "ok er true"                      "$(echo "$out" | jq -r '.ok')"                          "true"
check "1 notification etter org-filter" "$(echo "$out" | jq '.notifications | length')"         "1"
check "0 review-requested"              "$(echo "$out" | jq '.reviewRequested | length')"       "0"
check "1 egen PR"                       "$(echo "$out" | jq '.myPullRequests | length')"         "1"
check "1 issue (PR filtrert bort)"      "$(echo "$out" | jq '.assignedIssues | length')"        "1"
check "notif-URL er konvertert"         "$(echo "$out" | jq -r '.notifications[0].url' | grep -c 'api.github.com')" "0"
check "notif-URL peker på github.com"   "$(echo "$out" | jq -r '.notifications[0].url')"         "https://github.com/your-org/app/issues/142"
check "updatedAtLocal er satt"          "$(echo "$out" | jq -r '.updatedAtLocal' | grep -cE '^[0-9]{2}:[0-9]{2}$')" "1"

if [[ $fail -eq 0 ]]; then echo "== ALLE OK =="; else echo "== NOEN FEILET =="; fi
exit $fail
