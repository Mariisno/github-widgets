#!/usr/bin/env bash
# <bitbar.title>GitHub</bitbar.title>
# <bitbar.version>1.0</bitbar.version>
# <bitbar.author>Mari</bitbar.author>
# <bitbar.desc>Varsler, reviews, PR-er og issues for din valgte GitHub-org.</bitbar.desc>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
set -uo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

DIR="$(cd "$(dirname "$0")" && pwd)"
FETCH="$DIR/../fetch-github.sh"

get_data() {
  if [[ -n "${GH_WIDGET_DATA_FILE:-}" ]]; then
    cat "$GH_WIDGET_DATA_FILE"
  else
    "$FETCH"
  fi
}
DATA="$(get_data)"

ok="$(echo "$DATA" | jq -r '.ok // false')"
if [[ "$ok" != "true" ]]; then
  err="$(echo "$DATA" | jq -r '.error // "ukjent feil"')"
  echo "⚠️ GitHub"
  echo "---"
  echo "Kunne ikke hente data | color=#f85149"
  echo "$err"
  echo "---"
  echo "Åpne GitHub | href=https://github.com/notifications"
  exit 0
fi

nNotif="$(echo "$DATA"  | jq '.notifications  | length')"
nReview="$(echo "$DATA" | jq '.reviewRequested | length')"
nMine="$(echo "$DATA"   | jq '.myPullRequests  | length')"
nIssues="$(echo "$DATA" | jq '.assignedIssues  | length')"
updated="$(echo "$DATA" | jq -r '.updatedAtLocal // ""')"

# --- Menylinje (utelat nuller) ---
menu=""
[[ "$nNotif"  -gt 0 ]] && menu+="🔔$nNotif "
[[ "$nReview" -gt 0 ]] && menu+="✓$nReview "
[[ "$nMine"   -gt 0 ]] && menu+="⊙$nMine "
[[ "$nIssues" -gt 0 ]] && menu+="◇$nIssues "
[[ -z "$menu" ]] && menu="GitHub ✓ "
echo "${menu% }"
echo "---"

# --- Nedtrekk ---
print_section() { # $1=tittel $2=jq-filter
  echo "$1"
  local lines; lines="$(echo "$DATA" | jq -r "$2")"
  if [[ -n "$lines" ]]; then echo "$lines"; else echo "(ingen) | color=gray"; fi
  echo "---"
}

print_section "🔔 Notifications ($nNotif)" \
  '.notifications[] | "\(.title)  ·  \(.repo) | href=\(.url) | length=50"'
print_section "✓ Venter på din review ($nReview)" \
  '.reviewRequested[] | "#\(.number) \(.title)  ·  \(.repo) | href=\(.url) | length=50"'
print_section "⊙ Dine åpne PR-er ($nMine)" \
  '.myPullRequests[] | "#\(.number) \(.title)  ·  \(.repo) | href=\(.url) | length=50"'
print_section "◇ Tildelte issues ($nIssues)" \
  '.assignedIssues[] | "#\(.number) \(.title)  ·  \(.repo) | href=\(.url) | length=50"'

echo "↻ Oppdatert $updated | color=gray"
echo "Åpne GitHub | href=https://github.com/notifications"
