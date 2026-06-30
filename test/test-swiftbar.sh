#!/usr/bin/env bash
set -uo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$DIR")"
SCRIPT="$ROOT/swiftbar/github.1m.sh"
fail=0
check() { # $1=beskrivelse $2=0-hvis-ok
  if [[ "$2" -eq 0 ]]; then echo "ok:   $1"; else echo "FEIL: $1"; fail=1; fi
}

out="$(GH_WIDGET_DATA_FILE="$DIR/fixtures/combined.json" "$SCRIPT")"
menubar="$(echo "$out" | head -1)"

echo "$menubar" | grep -q "🔔1"; check "menylinje viser 🔔1" $?
echo "$menubar" | grep -q "⊙1";  check "menylinje viser ⊙1 (egen PR)" $?
echo "$menubar" | grep -q "◇1";  check "menylinje viser ◇1 (issue)" $?
if echo "$menubar" | grep -q "✓"; then echo "FEIL: ✓ skulle vært utelatt"; fail=1; else echo "ok:   ✓ utelatt når review=0"; fi
echo "$out" | grep -q "href=https://github.com/your-org/design/pull/13"; check "PR-rad er klikkbar lenke" $?
echo "$out" | grep -q "Tildelte issues (1)"; check "issue-seksjon har riktig antall" $?

errout="$(GH_WIDGET_DATA_FILE="$DIR/fixtures/error.json" "$SCRIPT")"
echo "$errout" | head -1 | grep -q "⚠️ GitHub"; check "feil-tilstand viser ⚠️ i menylinjen" $?
echo "$errout" | grep -q "Ikke innlogget"; check "feilmelding vises i nedtrekk" $?

if [[ $fail -eq 0 ]]; then echo "== ALLE OK =="; else echo "== NOEN FEILET =="; fi
exit $fail
