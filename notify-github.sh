#!/usr/bin/env bash
# notify-github.sh — fyrer en macOS-banner for NYE mentions og review-forespørsler.
# Leser samlet JSON fra stdin (eller kaller fetch-github.sh om stdin er tom).
# Husker hva den allerede har varslet om, så den ikke maser om det samme.
set -uo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

DIR="$(cd "$(dirname "$0")" && pwd)"
FETCH="$DIR/fetch-github.sh"

STATE_DIR="${GH_NOTIFY_STATE_DIR:-$HOME/Library/Caches/github-widgets}"
STATE_FILE="$STATE_DIR/notified.txt"
mkdir -p "$STATE_DIR"

# Data fra stdin, ellers hent selv
DATA="$(cat)"
[[ -z "${DATA//[[:space:]]/}" ]] && DATA="$("$FETCH")"

ok="$(echo "$DATA" | jq -r '.ok // false')"
[[ "$ok" != "true" ]] && exit 0

# Tekst-escape for AppleScript-strenger (titler kan inneholde anførselstegn)
esc() { local s="$1"; s="${s//\\/\\\\}"; s="${s//\"/\\\"}"; printf '%s' "$s"; }

notify() { # $1=reason $2=repo $3=title
  local head
  case "$1" in
    mention)          head="🔔 Du ble nevnt" ;;
    review_requested) head="✓ Review etterspurt" ;;
    *)                head="GitHub" ;;
  esac
  if [[ "${GH_NOTIFY_DRY:-}" == "1" ]]; then
    printf 'NOTIFY\t%s\t%s\n' "$1" "$3"
  else
    osascript -e "display notification \"$(esc "$3")\" with title \"$(esc "$head")\" subtitle \"$(esc "$2")\"" >/dev/null 2>&1
  fi
}

# Første kjøring (ingen state-fil) = sett baseline uten å varsle
first_run=0
[[ ! -f "$STATE_FILE" ]] && first_run=1

NEW_STATE="$(mktemp)"
# Relevante varsler: reason mention eller review_requested. Format: url<TAB>reason<TAB>repo<TAB>title
while IFS=$'\t' read -r url reason repo title; do
  [[ -z "$url" ]] && continue
  printf '%s\n' "$url" >> "$NEW_STATE"
  if [[ "$first_run" -eq 0 ]] && ! grep -Fxq "$url" "$STATE_FILE" 2>/dev/null; then
    notify "$reason" "$repo" "$title"
  fi
done < <(echo "$DATA" | jq -r '
  .notifications[]
  | select(.reason == "mention" or .reason == "review_requested")
  | [.url, .reason, .repo, .title] | @tsv')

mv "$NEW_STATE" "$STATE_FILE"
