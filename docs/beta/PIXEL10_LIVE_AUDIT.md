# ORBIT — Live-Hardware-Audit & E2E-Prüfbericht (Google Pixel 10 Pro)

> **Datum:** 17. Oktober 2026  
> **Prüfgerät:** Google Pixel 10 Pro (`58251FDCR00EQ2`, Codename `frankel`, Android 16)  
> **Backend-Umgebung:** Google Cloud / Firebase Live-Produktivsystem Frankfurt (`europe-west3`)  
> **App-ID:** `app.orbit.training` (Version `1.0.0+1`, Branch `feature/phase-25-pixel10-autonomous-audit`)  
> **Grafik-Backend:** Flutter Impeller Engine (Vulkan, 120 Hz ProMotion OLED)

---

## 1. Management Summary

Im Rahmen von **Phase 25** wurde die ORBIT-App vollautonom über USB-Debugging (`adb`) auf dem echten **Google Pixel 10 Pro** von Tim Zarges installiert, gestartet und gegen das Live-Backend (`europe-west3`) in Frankfurt getestet.

### Kern-Ergebnis:
- **UI & Performance:** Das Design-System (Konzept 01 *Orbital Rings + Volt* `#001F47` Navy & `#CDFB17` Volt) rendert auf dem 120-Hz-OLED des Pixel 10 Pro extrem scharf, ruhig und flüssig. Die Impeller-Engine läuft stabil.
- **Kernfunktionen intakt:** Die 3 ORBIT-Ringe (Erholung, Belastung, Schlaf), das Health-Cockpit mit 30-Tage-Normbändern, der Kalender mit Wochensoll und Trainingsplanungs-Sheet sowie der Android SAF Dateiupload funktionieren.
- **Exakte Ursachen der Live-Probleme gefunden:**
  1. **Garmin Connect Fehler:** Es liegt ein **Triple-Blocker** vor (1. Firebase App Check weist Sideloaded APKs im Release-Modus ab; 2. In `AndroidManifest.xml` fehlen `<queries>` für `https://`, wodurch `canLaunchUrl` auf Android 11–16 `false` liefert; 3. Es fehlt der Deep-Link Intent-Filter für den Rücksprung).
  2. **DSGVO-Verstoß bei Cloud Functions:** Die Funktion `deleteActivity` ist als v1-Funktion versehentlich in `us-central1` statt `europe-west3` deklariert!
  3. **Avatar-Menü Navigation:** `showMenu` schließt sich mit `Navigator.pop()`, was asynchrones `context.go()` im `PopupMenuItem` verschluckt.
  4. **Bug-Reporter Kontrast:** Das `BetaBugReporterSheet` besitzt im Dark Mode gravierende Farbkontrast-Mängel (dunkelblaue Schrift auf dunklem Grund, weiße Diagnosebox mit weißem Text).

---

## 2. Test-Matrix der 7 Funktionsbereiche

| Bereich | Getestete Funktion | Status | Befund / Nachweis |
| :--- | :--- | :---: | :--- |
| **1. Start & Auth** | APK-Installation & Start | **✅ BEHOBEN** | Initialer Crash (`ClassNotFoundException: MainActivity`) durch ProGuard-Rules & Java-Klasse behoben. App startet stabil. |
| **2. Garmin Sync** | `garminAuthStart` & OAuth-Flow | **❌ BLOCKIERT** | Triple-Blocker: App Check Rejection (401/403), fehlende `<queries>` für Android 11–16, fehlender Deep-Link. |
| **3. Heute & Ringe** | 3 ORBIT-Ringe & Tagesform | **✅ ERFOLGREICH** | Renderschönheit auf `#001F47` Navy, Volt-Leitring, Klick auf Details öffnet Modal. Klick auf Ringe öffnet `/health`. |
| **4. Plan & Kalender** | Wochensoll & Training planen | **✅ ERFOLGREICH** | Umschaltung Woche/Monat/Liste, Sheet „Training planen“ öffnet mit Sportart-Chips und Speichern. |
| **5. Datei-Upload** | Manueller Import (.fit/.tcx/.gpx) | **✅ ERFOLGREICH** | FAB `+` ruft `ActivityUploadNotifier` auf, Android SAF Dokumenten-Picker öffnet zuverlässig. |
| **6. Analyse & Health** | Form-Ampel, PMC & 30d-Baselines | **✅ ERFOLGREICH** | Form-Ampel (Fitness 53, Ermüdung 46, Frische +7), Ruhepuls- & HRV-Normbänder ($\mu \pm 1\sigma$) im `/health`-Cockpit. |
| **7. Coach & Feedback**| Coach-Tab & Bug-Reporter | **⚠️ NACHBESSERN**| Empty State & Einladungscode-Modal sauber. Bug-Reporter Sheet hat gravierende Kontrastprobleme; Menü verschluckt Navigation. |

---

## 3. Detaillierte Ursachenanalyse (Evidence-Only)

### A. Garmin Connect Live-OAuth (KRITISCH – Exakt belegt)

Beim Antippen von „Garmin verbinden“ auf dem Pixel 10 Pro passierte nichts bzw. ein Fehler-SnackBar erschien.

#### 1. Ursache: Firebase App Check Rejection in Cloud Functions
- **Beweis aus Live-Logs (`firebase functions:log --only garminAuthStart`):**
  ```text
  W garminauthstart: Failed to validate AppCheck token. FirebaseAppCheckError: Decoding App Check token failed.
  W garminauthstart: {"message":"Callable request verification failed: AppCheck token was rejected.","verifications":{"auth":"VALID","app":"INVALID"}}
  ```
- **Code-Stelle:** [`lib/core/config/app_check_service.dart:18`](file:///Users/timzarges/Desktop/source/Orbit/lib/core/config/app_check_service.dart#L18)
- **Erklärung:** Im Release-Modus (`kReleaseMode`) fordert `AppCheckService` einen `AndroidProvider.playIntegrity` Token an. Da die APK per USB gesideloadet und noch nicht über den Google Play Store verteilt/signiert wurde, stuft Google Play Integrity die App als `INVALID` ein. Die Cloud Function weist den Aufruf sofort mit HTTP 401/403 ab.
- **Lösung für Phase 26/27:** Für geschlossene Beta-/Debug-Installationen einen Debug-App-Check-Provider mit hinterlegtem Secret in der Firebase Console aktivieren bzw. `enforceAppCheck: false` für Phase 26/27 nutzen.

#### 2. Ursache: Fehlende Package Visibility `<queries>` für Android 11–16
- **Code-Stelle:** [`android/app/src/main/AndroidManifest.xml:50-55`](file:///Users/timzarges/Desktop/source/Orbit/android/app/src/main/AndroidManifest.xml#L50-L55)
- **Erklärung:** In `AndroidManifest.xml` existiert nur `ACTION_PROCESS_TEXT`. Es fehlt zwingend:
  ```xml
  <queries>
      <intent>
          <action android:name="android.intent.action.VIEW" />
          <data android:scheme="https" />
      </intent>
  </queries>
  ```
  Auf modernen Android-Versionen (11 bis 16 auf dem Pixel 10 Pro) liefert `canLaunchUrl(Uri.parse(authUrl))` in [`garmin_provider.dart:40`](file:///Users/timzarges/Desktop/source/Orbit/lib/features/integrations/providers/garmin_provider.dart#L40) ohne diese Deklaration immer `false`. Der Browser kann gar nicht geöffnet werden.

#### 3. Ursache: Fehlender Intent-Filter für Deep-Link Callback
- **Code-Stelle:** [`android/app/src/main/AndroidManifest.xml`](file:///Users/timzarges/Desktop/source/Orbit/android/app/src/main/AndroidManifest.xml)
- **Erklärung:** Es existiert kein `<intent-filter>` mit `<data android:scheme="app.orbit.training" />` oder `android:host="orbit-app-mvp.web.app"`. Selbst wenn Garmin im Browser autorisiert wird, kann der Browser nach dem OAuth-Handshake nicht zurück in die App springen.

---

### B. Cloud Function Regions-Verletzung (`deleteActivity`)

- **Code-Stelle:** [`functions/src/import/deleteActivity.ts:4`](file:///Users/timzarges/Desktop/source/Orbit/functions/src/import/deleteActivity.ts#L4)
  ```typescript
  export const deleteActivity = functions.https.onCall(async (data, context) => {
  ```
- **Beweis:** Da `deleteActivity` als v1-Funktion ohne `.region('europe-west3')` deklariert ist, hat Firebase die Funktion in **`us-central1`** bereitgestellt!
- **Verstoß:** Verletzt Regel 3 aus `AGENTS.md` („Region: Alle Cloud Functions, Firestore- und Storage-Ressourcen laufen ausschließlich in `europe-west3` (Frankfurt). Abweichende Regionen sind verboten (DSGVO)“).
- **Lösung für Phase 26:** Refactoring auf v2 `onCall({ region: "europe-west3" }, ...)` und Löschung der v1-Funktion in `us-central1`.

---

### C. Navigations-Verschlucken im Avatar-Menü

- **Code-Stelle:** [`lib/features/dashboard/screens/dashboard_screen.dart:86-116`](file:///Users/timzarges/Desktop/source/Orbit/lib/features/dashboard/screens/dashboard_screen.dart#L86-L116)
- **Befund:** Im Avatar-Menü sind die Menüeinträge wie folgt verdrahtet:
  ```dart
  PopupMenuItem(
    value: 'settings',
    child: const Text('Einstellungen'),
    onTap: () => context.go('/settings'),
  )
  ```
- **Problem:** Flutter führt `PopupMenuItem.onTap` aus und schließt direkt danach die `PopupMenuRoute` per `Navigator.pop()`. Dadurch wird die eben per `context.go('/settings')` angestoßene Navigation sofort wieder gepoppt und der Screen bleibt auf dem aktuellen Tab stehen.
- **Lösung für Phase 26:**
  ```dart
  final selected = await showMenu<String>(
    context: context,
    position: ...,
    items: [...],
  );
  if (selected != null && context.mounted) {
    context.push(selected);
  }
  ```

---

### D. Kontrastmängel im Beta-Bug-Reporter Sheet

- **Code-Stelle:** [`lib/features/beta_feedback/widgets/beta_bug_reporter_sheet.dart`](file:///Users/timzarges/Desktop/source/Orbit/lib/features/beta_feedback/widgets/beta_bug_reporter_sheet.dart)
- **Beweis-Screenshot:** [`docs/beta/screenshots/11_beta_bug_reporter.png`](file:///Users/timzarges/Desktop/source/Orbit/docs/beta/screenshots/11_beta_bug_reporter.png)
- **Befunde:**
  1. Der Titel „Beta Bug- & Feedback-Reporter“ und „Kategorie wählen“ nutzt die Farbe `#001F47` (Navy). Auf dem dunklen Bottom-Sheet-Hintergrund `#0B132B` ist die Schrift fast unlesbar (Kontrast < 2:1).
  2. Die unselektierten Kategorie-Buttons haben dunkelblaue Schrift auf transparent/dunklem Grund.
  3. Die Diagnose-Box hat einen weißen Hintergrund (`#FFFFFF`) mit weißer Schrift, wodurch der Text unsichtbar wird.
  4. Der Absende-Button hat zu geringen Kontrast im Dark Mode.
- **Lösung für Phase 28:** Überarbeitung der Styling-Tokens auf `AppColors.white` für Texte, `AppColors.navyLight` für Karten und `AppColors.volt` für Buttons.

---

## 4. Screenshot-Galerie (Google Pixel 10 Pro Live)

Alle Screenshots wurden live über ADB erfasst und liegen unter `docs/beta/screenshots/`:

| Nr. | Screenshot-Pfad | Ansicht / Screen | Beschreibung |
| :---: | :--- | :--- | :--- |
| **01** | [`01_login_screen.png`](file:///Users/timzarges/Desktop/source/Orbit/docs/beta/screenshots/01_login_screen.png) | Login / Authentifizierung | Startscreen mit ORBIT-Navy-Branding `#001F47` und Volt-Buttons. |
| **02** | [`02_today_screen.png`](file:///Users/timzarges/Desktop/source/Orbit/docs/beta/screenshots/02_today_screen.png) | Heute-Dashboard (Top) | Drei-Ringe-Hero-Card (`#001F47`), Volt-Leitring, Tagesempfehlung & Form-Ampel. |
| **03** | [`03_profile_screen.png`](file:///Users/timzarges/Desktop/source/Orbit/docs/beta/screenshots/03_profile_screen.png) | Profil- & Avatar-Menü | Dropdown-Menü für Profil, Vorlagen, Baselines, Diagnostik, Einstellungen. |
| **04** | [`04_settings_screen.png`](file:///Users/timzarges/Desktop/source/Orbit/docs/beta/screenshots/04_settings_screen.png) | Einstellungen-Navigation | Dokumentation des Menü-Pop-Verhaltens bei Klick auf Einstellungen. |
| **05** | [`05_analysis_tab.png`](file:///Users/timzarges/Desktop/source/Orbit/docs/beta/screenshots/05_analysis_tab.png) | Analyse-Cockpit | Form-Ampel (Fitness 53, Ermüdung 46, Frische +7), Wochenbelastung (251). |
| **06** | [`06_health_cockpit.png`](file:///Users/timzarges/Desktop/source/Orbit/docs/beta/screenshots/06_health_cockpit.png) | `/health`-Cockpit | Drei Ringe mit ORBIT-Score 84 und 15-Sekunden-Morgen-Journal-Chips. |
| **07** | [`07_health_charts.png`](file:///Users/timzarges/Desktop/source/Orbit/docs/beta/screenshots/07_health_charts.png) | 30-Tage-Normbänder | Ruhepuls & HRV-Historie mit Standardabweichung $\mu \pm 1\sigma$ und Normbereich-Badges. |
| **08** | [`08_pmc_chart.png`](file:///Users/timzarges/Desktop/source/Orbit/docs/beta/screenshots/08_pmc_chart.png) | Konsistenz & Wochenlast | Konsistenz-Tracker (6/7 Tage aktiv) und Belastungsverlauf. |
| **09** | [`09_plan_screen.png`](file:///Users/timzarges/Desktop/source/Orbit/docs/beta/screenshots/09_plan_screen.png) | Trainings-Kalender | Woche/Monat/Liste Umschaltung, Wochensoll und Wochentage mit Heute-Badge. |
| **10** | [`10_coach_tab.png`](file:///Users/timzarges/Desktop/source/Orbit/docs/beta/screenshots/10_coach_tab.png) | Trainer-Verknüpfung | Aufgeräumter Empty State mit Volt-Button „Einladungscode eingeben“. |
| **11** | [`11_beta_bug_reporter.png`](file:///Users/timzarges/Desktop/source/Orbit/docs/beta/screenshots/11_beta_bug_reporter.png) | In-App Bug-Reporter | Bottom-Sheet zur Fehler-Meldung (deckt Kontrastproblem im Dark Mode auf). |
| **12** | [`12_coach_code_modal.png`](file:///Users/timzarges/Desktop/source/Orbit/docs/beta/screenshots/12_coach_code_modal.png) | Einladungscode-Dialog | 6-stellige Code-Eingabe mit Volt-Umrandung und nativer Tastatur. |
| **13** | [`13_plan_training_sheet.png`](file:///Users/timzarges/Desktop/source/Orbit/docs/beta/screenshots/13_plan_training_sheet.png) | Training planen | Modal-Sheet mit Sportart-Auswahl (Laufen, Rad, Schwimmen) und Dauer/Intensität. |
| **14** | [`14_today_scrolled.png`](file:///Users/timzarges/Desktop/source/Orbit/docs/beta/screenshots/14_today_scrolled.png) | Heute-Dashboard (Bottom) | Demo-Banner und Floating Action Button zum Datei-Upload. |
| **15** | [`15_fab_file_upload.png`](file:///Users/timzarges/Desktop/source/Orbit/docs/beta/screenshots/15_fab_file_upload.png) | Android File Picker | Native Dokumentenauswahl (`DocumentsUI`) für `.fit`, `.tcx`, `.gpx`. |
| **16** | [`16_workout_detail_modal.png`](file:///Users/timzarges/Desktop/source/Orbit/docs/beta/screenshots/16_workout_detail_modal.png) | Workout-Detail Sheet | Geplante Einheit (4x4min Schwellenintervalle) mit Verschiebe-Aktionen. |
| **17** | [`17_chat_list.png`](file:///Users/timzarges/Desktop/source/Orbit/docs/beta/screenshots/17_chat_list.png) | Nachrichten-Routing | Intelligentes Routing zum Coach-Tab, wenn noch kein Trainer gekoppelt ist. |
| **18** | [`18_avatar_menu.png`](file:///Users/timzarges/Desktop/source/Orbit/docs/beta/screenshots/18_avatar_menu.png) | Avatar-Dropdown | Vollständiges Schnellmenü für Profil, Vorlagen, Builder, Health & Einstellungen. |

---

## 5. Konkreter Arbeitsplan für die Folgephasen

### Phase 26 (Backend-Regionen, Package-Konsistenz, App Check & Onboarding):
1. **Cloud Functions Frankfurt-Audit:** `deleteActivity` von v1 auf v2 migrieren und strikt in `europe-west3` bereitstellen. Alle 28 Funktionen auf Region Frankfurt verifizieren.
2. **App Check Konfiguration:** Debug-Provider für Sideloaded APKs einrichten oder App Check für manuelle Beta-Builds passend konfigurieren, damit `garminAuthStart` nicht mehr mit 401 blockiert wird.
3. **Avatar-Menü Navigation:** `showMenu` Refactoring in `dashboard_screen.dart`, damit Profil und Einstellungen verlässlich per `context.push` geöffnet werden.
4. **Onboarding-Reparatur:** Vollständigen Test des 4-Schritte-Wizards inklusive `setInitialRole` und initialer Schwellenwerte.

### Phase 27 (Garmin Live-OAuth & Deep-Link):
1. **`AndroidManifest.xml` Queries:** `<queries>` für `https://` einfügen, damit `canLaunchUrl` den Garmin-Login im Browser starten kann.
2. **Deep-Link Callback:** Intent-Filter für `app.orbit.training://` und `orbit-app-mvp.web.app/callback/garmin` hinterlegen.
3. **Secret Manager & Backfill:** 90-Tage-Backfill und Garmin-Webhook-Verarbeitung live auf dem Pixel 10 Pro testen.

### Phase 28 (Kernfunktionen-Reparatur & Geschlossener Bug-/Feedback-Workflow):
1. **Bug-Reporter UI-Fix:** Kontrast in `BetaBugReporterSheet` beheben (helle Texte auf dunklem Grund, dunkle Diagnosebox mit hellem Text).
2. **Feedback-Workflow:** Kategorien *Bug melden*, *Idee/Vorschlag*, *Support-Frage*; Ticket-Vergabe `#ORB-xxx` und Admin-Push.
3. **Admin Feedback-Inbox:** Screen `/admin/feedback` in App & Web zur Verwaltung der eingehenden Meldungen.
