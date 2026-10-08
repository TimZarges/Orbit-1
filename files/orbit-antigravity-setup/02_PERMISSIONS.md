# Berechtigungen für Antigravity (zum Einfügen)

**Wichtig:** Berechtigungen sind in Antigravity **Nutzereinstellungen** und liegen nicht im Repo (anders als `.claude/settings.json` bei Claude Code). Du richtest sie einmal ein. Format: `aktion(ziel)`. Reihenfolge der Auswertung: **Deny > Ask > Allow**.

## 1. Preset wählen
`Settings → General → Permission Settings` (oder pro Projekt unter `Settings → Projects`).

| Preset | Empfehlung |
|---|---|
| **Default** (Terminal-Sandbox, kein Netzwerk in der Sandbox, Workspace-Dateien erlaubt) | **Empfohlen.** Für `pub get`, `npm ci`, Emulator und `adb` fragt Antigravity außerhalb der Sandbox nach, sofern nicht unten erlaubt |
| Request Review | Gut für die ersten Phasen, wenn du alles sehen willst (jeder Befehl fragt) |
| **Turbo** | **Nicht verwenden.** Voller Dateizugriff, uneingeschränkte Befehle, MCP und Web ohne Rückfrage |

Auf **Windows** gilt laut Doku noch das ältere Berechtigungssystem. Die Regeln unten funktionieren dort gleich, bei Befehlen mit komplexer Syntax kann Exakt-Matching nötig sein (dann `regex:` verwenden).

## 2. Allow-Liste (ohne Rückfrage)
```
command(flutter analyze)
command(flutter test)
command(flutter pub get)
command(flutter pub add)
command(flutter gen-l10n)
command(dart format)
command(dart run build_runner)
command(npm ci)
command(regex:npm run (build|lint|test))
command(firebase emulators:start)
command(firebase emulators:exec)
command(git status)
command(git diff)
command(git log)
command(git add)
command(git commit)
command(git checkout)
command(git switch)
read_url(pub.dev)
read_url(dart.dev)
read_url(docs.flutter.dev)
read_url(api.flutter.dev)
read_url(firebase.google.com)
read_url(registry.npmjs.org)
read_url(developer.garmin.com)
```
Hinweis: `read_url`-Freigaben werden laut Doku auch in die Netzwerk-Erlaubnisliste der Terminal-Sandbox übernommen. Das kann `pub get` und `npm ci` auch in der Sandbox ermöglichen.

## 3. Deny-Liste (immer blockiert)
```
command(rm -rf)
command(sudo)
command(git push --force)
command(git push -f)
command(git reset --hard)
command(git clean)
write_file(.git/)
read_file(.env)
read_file(functions/.env)
read_file(android/key.properties)
```
Passe Pfade an, falls deine Geheimnisdateien anders heißen (z. B. Keystore-Dateien unter `android/app/`). Ob Platzhalter wie `.env.*` in Dateipfaden unterstützt werden, ist in der Doku nicht beschrieben, deshalb sind die Pfade einzeln aufgeführt.

## 4. Ask-Liste (immer nachfragen)
```
command(git push)
write_file(AGENTS.md)
write_file(.agents/)
```
Damit kann der Agent Regeln und Skills **nie stillschweigend** ändern (auch nicht über `/learn`), und er pusht nicht ohne dein Okay.

## 5. Antigravity CLI (`agy`): Datei statt Oberfläche
Trage dasselbe in `~/.gemini/antigravity-cli/settings.json` ein (Datei ggf. neu anlegen, bestehenden Inhalt beibehalten):
```json
{
  "permissions": {
    "allow": [
      "command(flutter analyze)",
      "command(flutter test)",
      "command(flutter pub get)",
      "command(flutter pub add)",
      "command(flutter gen-l10n)",
      "command(dart format)",
      "command(dart run build_runner)",
      "command(npm ci)",
      "command(regex:npm run (build|lint|test))",
      "command(firebase emulators:start)",
      "command(firebase emulators:exec)",
      "command(git status)",
      "command(git diff)",
      "command(git log)",
      "command(git add)",
      "command(git commit)",
      "command(git checkout)",
      "command(git switch)",
      "read_url(pub.dev)",
      "read_url(dart.dev)",
      "read_url(docs.flutter.dev)",
      "read_url(api.flutter.dev)",
      "read_url(firebase.google.com)",
      "read_url(registry.npmjs.org)",
      "read_url(developer.garmin.com)"
    ],
    "deny": [
      "command(rm -rf)",
      "command(sudo)",
      "command(git push --force)",
      "command(git push -f)",
      "command(git reset --hard)",
      "command(git clean)",
      "write_file(.git/)",
      "read_file(.env)",
      "read_file(functions/.env)",
      "read_file(android/key.properties)"
    ],
    "ask": [
      "command(git push)",
      "write_file(AGENTS.md)",
      "write_file(.agents/)"
    ]
  }
}
```

## 6. Gut zu wissen
- Befehle mit Shell-Konstrukten wie `$(...)`, Backticks oder Brace-Expansion werden **nur bei zeichengenauer Übereinstimmung** automatisch erlaubt, sonst fragt Antigravity nach. Ein `git commit -m "$(…)"` oder ein Heredoc kann deshalb nachfragen. Das ist gewollt.
- Mit `/permissions` (CLI) kannst du Regeln interaktiv verwalten.
- Auf der Rückfrage-Karte kannst du bei Dateien/URLs das Ziel vor dem Bestätigen erweitern (z. B. auf den Elternordner).

## 7. Zusätzlich für den Autopilot (`/phase-run`)
- Der Autopilot soll **ohne dich** durchlaufen. Jede Rückfrage-Karte hält ihn an. Prüfe nach den ersten Minuten, **welche Befehle nachfragen**, und nimm sichere in die Allow-Liste auf (Phase 00 braucht oft zusätzlich `command(flutter create)`, `command(flutter build)`, `command(flutter pub)`, `command(npm install)`, `command(npm init)`).
- Halte `command(git push)` in **Ask**. Der Autopilot pusht nicht.
- `read_url(developer.garmin.com)` ist erlaubt, damit der Agent in Phase 06 die aktuelle Garmin-Doku lesen kann. Ohne Freigabe würde er dort anhalten.
