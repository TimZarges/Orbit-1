# PHASE 29 — Live-Test Trainer-Kopplung, Echter Push-Test aufs Pixel 10 Pro & Finales Beta-Release-Gate

## Modus & Leitplanken
- **Modus:** STANDARDMODUS (RISIKO: HOCH — Finale Abnahme, Live-Kopplung, Echte FCM-Push-Benachrichtigungen & Store-Bereitstellung).
- **Zero-Trust-Regel (AGENTS.md):** Kein Release-Gate wird ohne explizite Live-Freigabe durch Tim auf dem Pixel 10 Pro und in der Google Play Console abgehakt.

---

## Arbeitspakete

### 29.1 Live-Test der Trainer-Kopplung (Smartphone & Web)
1. Vollständiger Interaktions-Test zwischen Athlet (Pixel 10 Pro) und Trainer (Web-Dashboard auf `orbit-app-mvp.web.app/app`):
   - Trainer generiert Einladungscode.
   - Athlet löst Code auf dem Handy ein.
   - Granulare Freigaben (Art. 9 DSGVO) anpassen und sofortige Reflektion im Coach-Dashboard prüfen.
   - Trennung (`revokeLink`) testen: Sofortiger Rechtestopp belegt durch Rules und UI.

### 29.2 Echte FCM Push-Notifications auf das Pixel 10 Pro
1. Test-Push an das Pixel 10 Pro senden (`sendTestPushNotification`).
2. Prüfung der Darstellung in der Android-Statusleiste:
   - Monochromes ORBIT-Logo (`ic_stat_orbit`).
   - Dunkelblauer Marken-Akzent (`#001F47`).
   - Korrektes Deep-Linking beim Antippen (z. B. Öffnen der Aktivitätsanalyse).

### 29.3 Finales Google Play Store & Firebase Distribution Release-Gate
1. Erstellung des finalen signierten Android App Bundles (`flutter build appbundle --release`).
2. Aktualisierung von `docs/beta/PLAY_STORE_SUBMISSION_GUIDE.md` und Vorbereitung der Verteilung in den Closed Testing Track.
3. Bereitstellung der Release-APK für Tester via Firebase App Distribution.
4. Alle Kriterien aus `BASELINE.md` und `BUGS.md` (0 Blocker, 0 Kritisch) nachgewiesen.

---

## Finaler STOPP-Punkt (Release-Freigabe v0.29.0-beta.1)
- Vorlage aller Abnahmenachweise in `docs/CHECKPOINTS.md`.
- Warten auf Tims finales GO nach erfolgreichem Testlauf auf dem Pixel 10 Pro.
- Nach Freigabe: Merge in `main`, Setzen des Release-Tags **`v0.29.0-beta.1`** und Push zu GitHub.
