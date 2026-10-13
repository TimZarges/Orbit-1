# Google Play Store – Data Safety Deklaration

> Leitfaden zum Ausfüllen des Formulars „Datensicherheit" in der Google Play Console für **ORBIT**.

---

## 1. Übersicht über die Sicherheitsverfahren

| Frage | Antwort | Begründung / Nachweis |
|---|---|---|
| **Werden Daten bei der Übertragung verschlüsselt?** | **Ja** | Sämtlicher Datenverkehr zwischen App und Firebase / Cloud Storage erfolgt über HTTPS / TLS 1.3. |
| **Können Nutzer die Löschung ihrer Daten beantragen?** | **Ja** | Über In-App-Funktion (`Einstellungen -> Datenschutz -> Konto löschen`) sowie über öffentlich erreichbare Löschseite `https://orbit-training.web.app/delete-account.html`. |
| **Bietet die App eine Methode, mit der Nutzer die Löschung bestimmter Daten anfordern können?** | **Ja** | Löschen einzelner Chat-Nachrichten (Soft-Delete) und Trennung von Garmin-Daten. |

---

## 2. Erfasste und geteilte Datenarten

### 2.1 Standortdaten (Location)
- **Typ:** Ungefährer & Genauer Standort (`Approximate location` & `Precise location`).
- **Erfasst:** **Ja** (aus importierten FIT-Dateien und Garmin GPS-Streams).
- **Geteilt:** **Nein**.
- **Zweck:** App-Funktionalität (Geschwindigkeits-, Distanz- und Höhenmeterauswertung, Streckenvisualisierung).
- **Verarbeitung:** Nur nach Einwilligung (Aktivitäts-Import).

### 2.2 Personenbezogene Informationen (Personal info)
- **Typ:** Name, E-Mail-Adresse, Nutzer-IDs.
- **Erfasst:** **Ja** (Authentifizierung & Profil).
- **Geteilt:** **Nein** (außer Anzeige des Namens für verknüpfte Trainer bei bestehendem Link).
- **Zweck:** Kontoverwaltung, Authentifizierung, App-Funktionalität.

### 2.3 Gesundheits- und Fitnessdaten (Health and fitness)
- **Typ:** Fitnessdaten & Gesundheitsdaten (Herzfrequenz, Watt, Trittfrequenz, HRV, Schlaf, Ruhepuls).
- **Erfasst:** **Ja**.
- **Geteilt:** **Ja (selektiv / nutzergesteuert):** Nur für verknüpfte Trainer, sofern der Athlet die Berechtigung `permissions.health == true` bzw. `permissions.activities == true` erteilt hat.
- **Zweck:** App-Funktionalität, Trainingsbelastungsberechnung (CTL/ATL, ORBIT Score), Regenerationsauswertung.
- **Verarbeitung:** Ausdrückliche Einwilligung (Art. 9 DSGVO).

### 2.4 Nachrichten (Messages)
- **Typ:** Sonstige In-App-Nachrichten (1:1 Chat zwischen Trainer und Athlet).
- **Erfasst:** **Ja**.
- **Geteilt:** **Nein** (ausschließlich für die beiden Teilnehmer sichtbar).
- **Zweck:** App-Funktionalität, Kommunikation.

### 2.5 Fotos und Videos (Photos and videos)
- **Typ:** Fotos (Chat-Anhänge).
- **Erfasst:** **Ja** (optional beim Versenden von Bildern im Chat).
- **Geteilt:** **Nein**.
- **Zweck:** App-Funktionalität.

### 2.6 App-Informationen und Leistung (App info and performance)
- **Typ:** Absturzprotokolle (Crash logs) und Diagnoseinformationen via Firebase Crashlytics.
- **Erfasst:** **Ja** (anonymisiert, Standard-Opt-In).
- **Geteilt:** **Nein**.
- **Zweck:** Analysen, App-Stabilität.

### 2.7 Geräte- oder sonstige IDs (Device or other IDs)
- **Typ:** FCM Geräte-Token für Push-Benachrichtigungen.
- **Erfasst:** **Ja**.
- **Geteilt:** **Nein**.
- **Zweck:** App-Funktionalität, Zustellung von Benachrichtigungen.

---

## 3. Play Store Datenschutz-URL

- **Datenschutzerklärung:** `https://orbit-training.web.app/privacy.html` (oder Repository-Link)
- **Lösch-URL:** `https://orbit-training.web.app/delete-account.html`
