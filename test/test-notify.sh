#!/usr/bin/env bash
set -uo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$DIR")"
SCRIPT="$ROOT/notify-github.sh"
export GH_NOTIFY_DRY=1                 # ikke fyr ekte bannere; skriv ut hva som ville blitt varslet
TMP="$(mktemp -d)"
export GH_NOTIFY_STATE_DIR="$TMP"      # isolert state per testkjøring
fail=0
check() { if [[ "$2" == "$3" ]]; then echo "ok:   $1"; else echo "FEIL: $1 (fikk '$2', ventet '$3')"; fail=1; fi; }

# 1) Første kjøring = baseline, skal IKKE varsle om eksisterende
out1="$(cat "$DIR/fixtures/notify-1.json" | "$SCRIPT")"
check "første kjøring varsler ikke (baseline)" "$(printf '%s' "$out1" | grep -c NOTIFY)" "0"

# 2) Samme data igjen = ingenting nytt
out2="$(cat "$DIR/fixtures/notify-1.json" | "$SCRIPT")"
check "uendret data gir ingen nye varsler" "$(printf '%s' "$out2" | grep -c NOTIFY)" "0"

# 3) Ny mention dukker opp = nøyaktig ett varsel, og det er den nye
out3="$(cat "$DIR/fixtures/notify-2.json" | "$SCRIPT")"
check "ny mention gir ett varsel" "$(printf '%s' "$out3" | grep -c NOTIFY)" "1"
check "varselet er den nye mention" "$(printf '%s' "$out3" | grep NOTIFY | cut -f3)" "Ny mention her"

# 4) 'subscribed' skal aldri varsle
out4="$(printf '%s' "$out1$out2$out3" | grep -c '999')"
check "abonnement (subscribed) varsler aldri" "$out4" "0"

rm -rf "$TMP"
if [[ $fail -eq 0 ]]; then echo "== ALLE OK =="; else echo "== NOEN FEILET =="; fi
exit $fail
