# GitHub-widgets for Mac

To små Mac-widgets som viser GitHub-aktiviteten din med et blikk:

- **Menylinje (SwiftBar):** kompakte tellere + et nedtrekk med klikkbare issues/PR-er.
- **Skrivebord (Übersicht):** et glass-kort med fire fargekodede tall-fliser
  (Varsler, Review, PR-er, Issues). Hver flis er klikkbar og åpner riktig GitHub-side.

Widgeten viser *din egen* aktivitet i en GitHub-org du velger: tildelte issues,
PR-er du har laget, PR-er som venter på din review, og uleste varsler. Alt henter
fra `fetch-github.sh`, som bruker `gh` (GitHub CLI). **Ingen tokens lagres** –
`gh` bruker din egen innlogging i macOS-nøkkelringen.

---

## Oppsett (steg for steg)

### 1. Forutsetninger

Installer verktøyene (hopp over det du har):

```bash
brew install gh jq
brew install --cask swiftbar ubersicht
```

- **`gh`** – GitHub CLI (henter dataene)
- **`jq`** – behandler JSON
- **SwiftBar** – menylinje-widgets
- **Übersicht** – skrivebords-widgets

Logg inn på GitHub med din egen konto:

```bash
gh auth login
```

### 2. Hent koden

```bash
git clone https://github.com/<din-bruker>/github-widgets.git
cd github-widgets
```

### 3. Kjør oppsett-scriptet

```bash
./install.sh
```

Dette gjør tre ting:
1. Lager `config.sh` (din lokale konfig – blir aldri publisert).
2. Installerer Übersicht-widgeten med riktig sti for din maskin.
3. Minner deg om SwiftBar-mappa (neste steg).

### 4. Velg org

Åpne `config.sh` og sett organisasjonen din:

```sh
ORG="din-github-org"
```

(Det er org-en du vil se din aktivitet i. Lagre fila.)

### 5. Koble til SwiftBar

Åpne **SwiftBar** → første gang spør den om en plugin-mappe. Velg `swiftbar/`-mappa
inne i dette repoet. (Eller: SwiftBar-meny → Preferences → Plugin Folder.)
Du skal nå se tellere i menylinjen øverst.

### 6. Sjekk skrivebordet

Übersicht-widgeten ligger **øverst til høyre på skrivebordet** – bak vinduene dine.
Trykk `fn + F11` (eller minimer vinduene) for å se den.

Ferdig! 🎉

---

## Verifisering

Kjør datalaget direkte for å se nøyaktig hva widgetene viser:

```bash
./fetch-github.sh | jq
```

Du skal få et JSON-objekt med `ok: true` og dine issues/PR-er/varsler.

---

## Feilsøking

| Problem | Løsning |
|---|---|
| **Übersicht viser ingenting** | Du ser på et vindu, ikke skrivebordet. `fn + F11`. Hvis fortsatt tomt: avslutt og åpne Übersicht på nytt (den skanner nye widgets ved oppstart). |
| **Klikk på fliser gjør ingenting** | Krever nyere Übersicht (importerer `run` fra `uebersicht`). Oppdater appen. |
| **SwiftBar viser `⚠️ GitHub`** | Klikk for å se feilen. Vanligvis: ikke innlogget – kjør `gh auth login`. |
| **Tomme tall / `gh`-feil** | Du kan ha nådd GitHubs rate-limit (5000/time, nullstilles hver time). Sjekk: `gh api rate_limit`. Normal bruk treffer ikke taket. |
| **Übersicht-mappa finnes ikke** | Åpne Übersicht én gang først, kjør så `./install.sh` på nytt. |

---

## Hvordan det henger sammen

```
fetch-github.sh            # gh → vasker med jq → samlet JSON til stdout
├── swiftbar/github.1m.sh  # menylinje (oppdaterer hvert 1. min)
└── ubersicht/github-rings.jsx  # skrivebord (glass-kort med fliser)
```

Endrer du noe i widget-koden, kjør `./install.sh` på nytt for å oppdatere
Übersicht-kopien.

## Test

```bash
./test/test-fetch.sh      # datalaget (fixtures, ingen nettverk)
./test/test-swiftbar.sh   # menylinje-utdata
./test/test-notify.sh     # banner-logikk (se under)
```

## Valgfritt: banner-varsler

`notify-github.sh` kan fyre en macOS-banner for nye mentions / review-forespørsler
(den husker hva den har varslet om). Den er ikke koblet inn som standard, fordi
macOS-varsler via `osascript` er upålitelige. For å ta den i bruk: installer
`terminal-notifier` (`brew install terminal-notifier`), bytt leveringen i
`notify-github.sh`, og kall den fra `swiftbar/github.1m.sh`.

## Lisens

Bruk fritt. Ingen garantier.
