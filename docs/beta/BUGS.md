# ORBIT — Beta Bug-Tracker & Release-Gate (`BUGS.md`)

> **Projekt:** ORBIT (`app.orbit.training`)  
> **Status:** Vorbereitung Google Play Closed Beta (Launch: 31. Oktober 2026)  
> **Ziel-Gate für Store-Einreichung:** **0 Blocker, 0 Kritische Fehler!**

Hier werden alle von Vereinsathleten, Trainern oder automatisierten Tests gemeldeten Fehler, Auffälligkeiten und Regressionen zentral protokolliert.

---

## 1. Definition der Schweregrade

| Schweregrad | Kriterien | Release-Auswirkung |
| :--- | :--- | :--- |
| 🔴 **Blocker** | App stürzt ab (Crash/ANR), Datenverlust, Sicherheitslücke, DSGVO-Verletzung (unerlaubte Datensichtbarkeit), Login/Registrierung unmöglich, FIT-Import bricht ab. | **Sofortiger Release-Stopp!** Kein Release-Build bis zur vollständigen Behebung. |
| 🟠 **Kritisch** | Wesentliche Kernfunktion fehlerhaft (z. B. falsche TSS-/NP-Berechnung um > 5 %, W'bal friert ein, Push-Nachrichten kommen nicht an, Trainer sieht veralteten Kalender). Kein Workaround. | **Kein Store-Release.** Muss vor Einreichung behoben und getestet werden. |
| 🟡 **Mittel** | Funktion funktioniert mit Workaround, Layout-Verschiebung auf extremen Bildschirmgrößen, fehlende Übersetzung, leicht verzögertes Nachladen. | Kann in Closed Beta mitgenommen werden, Fix im nächsten Sprint-Update. |
| 🟢 **Kosmetisch** | Typo, minimaler Padding-Fehler (z. B. 2px Abweichung), Animation nicht 100 % weich, Icon-Ausrichtung. | Backlog / Polish nach Beta-Start. |

---

## 2. Beta-Release-Gate (Stand: v0.24.0-rc.1)

| Kriterium | Soll | Ist-Stand | Status |
| :--- | :---: | :---: | :---: |
| Offene Blocker | **0** | **0** | ✅ Bestanden |
| Offene kritische Fehler | **0** | **0** | ✅ Bestanden |
| Backend- & Rules-Tests | **100 % grün** | **95 / 95 bestanden** | ✅ Bestanden |
| Flutter-Unit- & Widget-Tests | **100 % grün** | **149 / 149 bestanden** | ✅ Bestanden |
| Statische Analyse (`flutter analyze`) | **0 Errors, 0 Warnings** | **0 Errors, 0 Warnings** | ✅ Bestanden |
| 150-Aktivitäten-Stresstest (`corpusStress`) | **100 % ohne Crash** | **125 valide, 15 abgefangen, 10 Duplikate** | ✅ Bestanden |
| 21.600-Samples LTTB-Benchmark | **< 15 ms** | **< 15 ms** | ✅ Bestanden |
| DSGVO-Löschseite (`/delete-account`) | **Live & verifiziert** | **Aktiv unter public/delete-account.html** | ✅ Bestanden |
| **Gesamt-Freigabe für Store-Upload** | **Alle Kriterien grün** | **Bereit für Live-Abnahme auf Pixel 10 Pro** | ⏳ **Warte auf Tim** |

---

## 3. Fehlerprotokoll

### Vorlage für neue Einträge:
```markdown
### [BUG-NNN] Kurztitel des Fehlers
- **Datum gemeldet:** YYYY-MM-DD
- **Melder:** Name / Tester / Crashlytics / Emulator
- **Gerät / OS:** z. B. Pixel 10 Pro (Android 15) / Web Chrome
- **Schweregrad:** [Blocker | Kritisch | Mittel | Kosmetisch]
- **Betroffener Bereich:** [Auth | Garmin | Upload | Cockpit | PMC | Coach | Health | Push]
- **Schritte zur Reproduktion:**
  1. ...
  2. ...
- **Erwartetes Verhalten:** ...
- **Tatsächliches Verhalten:** ...
- **Status:** [Offen | In Arbeit | Behoben | Verifiziert]
- **Lösung / Commit:** Commit-Hash und kurze Erklärung
```

---

### Bereits im Beta-Sprint behobene historische Blocker (aus `BASELINE.md`):

1. **[RESOLVED] Blocker 1: TypeScript-Shadowing-Bug in Cloud Functions**
   - *Status:* Behoben in Phase 17 (`0a005ae`). Top-Level-Exporte sauber getrennt.
2. **[RESOLVED] Blocker 2: Storage-Trigger `processFitUpload` fehlte**
   - *Status:* Behoben in Phase 17/18. Automatische Verarbeitung für `.fit`, `.tcx`, `.gpx` (inkl. `.gz`) aktiv.
3. **[RESOLVED] Blocker 3: 0 automatisierte Rules-Tests**
   - *Status:* Behoben in Phase 17. 18 bzw. mittlerweile 27 Rules-Tests im Firestore-Emulator laufen bei jedem Commit.
4. **[RESOLVED] Blocker 4: Coach-Dashboard UI-Mock**
   - *Status:* Behoben in Phase 18. Echte Einladungscode-, Trennungs- und Art.-9-Consent-Logik implementiert.
5. **[RESOLVED] Blocker 5: Garmin-Webhook verwarf ActivityDetails & fehlender Backfill**
   - *Status:* Behoben in Phase 18. Volle Stream-Extraktion und 90-Tage-Backfill implementiert.
6. **[RESOLVED] Blocker 6: 6 fehlschlagende Unit-Tests & Linter-Warnungen**
   - *Status:* Behoben in Phase 17/18. 0 Errors, 0 Warnings, 149/149 Flutter-Tests grün.
7. **[RESOLVED] Blocker 7: 40px-Canvas-Gitter statt echten Karten**
   - *Status:* Behoben in Phase 19. Echte `flutter_map` mit OpenStreetMap und DSGVO-Opt-in integriert.
8. **[RESOLVED] Blocker 8: Git-Chaos & Branch-Divergenz**
   - *Status:* Behoben in Phase 17. Saubere Fast-Forward-Merge- und Release-Tag-Struktur etabliert.
9. **[RESOLVED] Blocker 9: Fehlende rechtliche Pflichtseite `/delete-account`**
   - *Status:* Behoben in Phase 22. Schlüsselfertige `delete-account.html`, `privacy.html`, `imprint.html` und `help.html` deployt.

---

### Aktuelle Einträge aus dem Vereins-Beta-Test:
*(Zurzeit keine offenen Fehler. Neue Einträge werden hier während des 48-Stunden-Vereinstests eingetragen.)*
