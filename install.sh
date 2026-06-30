#!/usr/bin/env bash
# install.sh — setter opp widgetene lokalt.
# Trygt å kjøre flere ganger.
set -uo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"

echo "GitHub-widgets — oppsett"
echo

# 1. Konfig
if [[ ! -f "$DIR/config.sh" ]]; then
  cp "$DIR/config.example.sh" "$DIR/config.sh"
  echo "→ Opprettet config.sh. REDIGER den med din GitHub-org og prosjekt-numre."
else
  echo "→ config.sh finnes allerede."
fi

# 2. Avhengigheter
command -v gh >/dev/null 2>&1 || echo "  ⚠ Mangler 'gh' (GitHub CLI). Installer: brew install gh && gh auth login"
command -v jq >/dev/null 2>&1 || echo "  ⚠ Mangler 'jq'. Installer: brew install jq"

# 3. Übersicht-widget — skriv inn med riktig absolutt sti (erstatter placeholder)
UB="$HOME/Library/Application Support/Übersicht/widgets"
if [[ -d "$UB" ]]; then
  rm -f "$UB/github-rings.jsx"   # fjern evt. gammel symlink
  sed "s|__REPO_DIR__|$DIR|g" "$DIR/ubersicht/github-rings.jsx" > "$UB/github-rings.jsx"
  echo "→ Installerte Übersicht-widget i $UB"
else
  echo "→ Übersicht ikke funnet. Installer (brew install --cask ubersicht), åpne én gang, og kjør install.sh på nytt."
fi

# 4. SwiftBar
echo "→ SwiftBar: sett plugin-mappa til:  $DIR/swiftbar"
echo "  (SwiftBar → Preferences → Plugin Folder. Installer: brew install --cask swiftbar)"

echo
echo "Ferdig. Rediger config.sh, så er du i gang."
