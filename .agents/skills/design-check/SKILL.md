---
name: design-check
description: "Prüft zuletzt geänderte Flutter-Screens gegen docs/DESIGN.md (Tokens, Typografie, Volt-Regel, Tippflächen, Textskalierung, Zonenfarben, Erfahrungsstufen). Nur auf Aufruf /design-check."
---

# Design-Check

Prüfe die zuletzt geänderten Screens und Widgets (siehe `git diff`/`git log`) gegen `docs/DESIGN.md`:

- hartkodierte Farben, Größen, Abstände oder Texte,
- Typografie-Skala, Inter Black erst ab ca. 24 sp, tabular figures bei Metriken,
- Volt-Regel (nie Volt-Text auf Weiß), Daily Ring auf Navy-Hero-Card,
- Tippflächen ≥ 48 dp, primäre Aktionen im Daumenbereich,
- Textskalierung 1,3 ohne Layoutbruch,
- Zonen **nie nur über Farbe** erkennbar, Farbsysteme (Zonen/Kanäle/Sport) nicht vermischt,
- Erfahrungsstufen-Begriffe, Info-Icons bei Kennzahlen,
- Lade-, Fehler- und Leerzustand vorhanden.

Liste Abweichungen mit **Datei und Zeile** auf und behebe sie. Ergänze fehlende Einträge in der Widget-Galerie und fehlende Golden Tests.
