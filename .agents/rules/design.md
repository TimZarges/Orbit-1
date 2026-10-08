---
trigger: glob
globs: "lib/**/*.dart, lib/l10n/*.arb, assets/**"
description: "UI-Regeln für ORBIT: Design-Tokens, Typografie, Farbsysteme, Mobile-First, Navigation, Erfahrungsstufen. Gilt bei jeder Arbeit an Flutter-UI."
---

# UI-Regeln (Kurzfassung)

**Vor UI-Arbeit vollständig lesen:** @docs/DESIGN.md. Bei Abweichung zwischen Doku und bestehendem Code gilt der Code. Abweichung in `docs/DECISIONS.md` notieren.

Nicht verhandelbar:
1. **Keine hartkodierten** Farben, Schriftgrößen, Abstände oder Texte. Nur `lib/core/design/` und ARB-Lokalisierung (de + en).
2. **Volt `#CDFB17`** nur als Fläche mit Navy-Text oder auf dunklem Grund, **nie als Textfarbe auf Weiß**. Daily Ring auf Navy-Hero-Card.
3. **Drei getrennte Farbsysteme** (Zonen Z1–Z7, Telemetrie-Kanäle, Sport-Identität) nie vermischen. Zonen **nie nur über Farbe** erkennbar (Nummer/Label dazu).
4. **Mobile-First:** Basis 360×800 dp, Tippflächen ≥ 48 dp, primäre Aktionen unten, Textskalierung bis 1,3 ohne Layoutbruch.
5. **Navigation rollenabhängig:** Athlet `Heute · Plan · Analyse · Coach`, Trainer `Athleten · Kalender · Nachrichten · Bibliothek`. Profil hinter dem Avatar.
6. **Erfahrungsstufen** (Einfach/Fortgeschritten/Experte) steuern Datendichte und Begriffe. Jede Kennzahl hat ein Info-Icon mit verständlicher Erklärung.
7. Jeder Screen hat **Lade-, Fehler- und Leerzustand** (Skeleton statt Spinner bei Listen, gestalteter Empty State).
8. Chart-Scrubbing per **Long-Press** oder Querformat, nie als Konkurrenz zum Seiten-Scrollen.
9. Neue Kernkomponenten bekommen einen Eintrag in der Widget-Galerie und einen Golden Test.
