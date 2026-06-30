#!/usr/bin/env bash
# fetch-github.sh — henter GitHub-data for en valgt org og skriver samlet JSON til stdout.
# Deles av SwiftBar- og Übersicht-widgetene.
set -uo pipefail

# PATH-gotcha: SwiftBar/Übersicht kjører med minimal PATH. Sørg for at gh og jq finnes.
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

# Konfig: ekte verdi i config.sh (gitignorert), placeholder i config.example.sh.
# Hoppes over i fixture-modus så tester er deterministiske (ORG settes da av testen).
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
if [[ -z "${GH_FIXTURE_DIR:-}" ]]; then
  if [[ -f "$SELF_DIR/config.sh" ]]; then
    # shellcheck disable=SC1091
    source "$SELF_DIR/config.sh"
  elif [[ -f "$SELF_DIR/config.example.sh" ]]; then
    # shellcheck disable=SC1091
    source "$SELF_DIR/config.example.sh"
  fi
fi
ORG="${ORG:-your-github-org}"
LIMIT=30

# Test-seam: les fra fixtures hvis GH_FIXTURE_DIR er satt, ellers kall gh.
_fetch() { # $1=fixture-navn, resten=ekte kommando
  local name="$1"; shift
  if [[ -n "${GH_FIXTURE_DIR:-}" ]]; then
    cat "$GH_FIXTURE_DIR/$name.json"
  else
    "$@"
  fi
}

emit_error() { # $1=melding
  jq -n --arg err "$1" --arg local "$(date +%H:%M)" \
    '{ok:false, error:$err, updatedAt:null, updatedAtLocal:$local,
      notifications:[], reviewRequested:[], myPullRequests:[], assignedIssues:[]}'
}

# Sjekk gh kun i ekte modus
if [[ -z "${GH_FIXTURE_DIR:-}" ]]; then
  command -v gh >/dev/null 2>&1 || { emit_error "gh CLI er ikke installert"; exit 0; }
  gh auth status >/dev/null 2>&1 || { emit_error "Ikke innlogget i gh (kjør: gh auth login)"; exit 0; }
fi

# Hent rådata; fall tilbake til tom array ved feil
notifications_raw="$(_fetch notifications gh api notifications 2>/dev/null)" || notifications_raw="[]"
review_raw="$(_fetch review gh search prs --review-requested=@me --state=open --owner="$ORG" --limit "$LIMIT" --json number,title,url,repository 2>/dev/null)" || review_raw="[]"
mine_raw="$(_fetch mine gh search prs --author=@me --state=open --owner="$ORG" --limit "$LIMIT" --json number,title,url,repository 2>/dev/null)" || mine_raw="[]"
issues_raw="$(_fetch issues gh search issues --assignee=@me --state=open --owner="$ORG" --limit "$LIMIT" --json number,title,url,repository,isPullRequest 2>/dev/null)" || issues_raw="[]"

# Tomme strenger → tom array (beskytter --argjson)
[[ -z "$notifications_raw" ]] && notifications_raw="[]"
[[ -z "$review_raw"        ]] && review_raw="[]"
[[ -z "$mine_raw"          ]] && mine_raw="[]"
[[ -z "$issues_raw"        ]] && issues_raw="[]"

UPDATED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
UPDATED_LOCAL="$(date +%H:%M)"

jq -n \
  --arg updatedAt "$UPDATED_AT" \
  --arg updatedAtLocal "$UPDATED_LOCAL" \
  --arg org "$ORG" \
  --argjson notifications "$notifications_raw" \
  --argjson review "$review_raw" \
  --argjson mine "$mine_raw" \
  --argjson issues "$issues_raw" \
  '
  def toBrowserUrl:
    gsub("api\\.github\\.com/repos/"; "github.com/") | gsub("/pulls/"; "/pull/");
  {
    ok: true,
    error: null,
    updatedAt: $updatedAt,
    updatedAtLocal: $updatedAtLocal,
    notifications: ($notifications
      | map(select(.repository.owner.login == $org))
      | map({title: .subject.title, repo: .repository.full_name, reason: .reason,
             url: ((.subject.url // "") | toBrowserUrl)})),
    reviewRequested: ($review  | map({number, title, repo: .repository.nameWithOwner, url})),
    myPullRequests:  ($mine    | map({number, title, repo: .repository.nameWithOwner, url})),
    assignedIssues:  ($issues  | map(select(.isPullRequest == false))
                               | map({number, title, repo: .repository.nameWithOwner, url}))
  }
  '
