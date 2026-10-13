# iOS Vorbereitung & App Store Readiness

> Dieser Leitfaden dokumentiert die Schritte zur Bereitstellung von ORBIT auf iOS (Apple App Store).
> **Hinweis:** Die Entwicklung erfolgte Mobile-First mit Android-Priorität. Dieser Leitfaden ermöglicht die reibungslose Xcode-Konfiguration.

---

## 1. Sign in with Apple (App Store Richtlinie 4.8)

Gemäß Apple App Store Review Guidelines ist **Sign in with Apple** verpflichtend, sobald ein Drittanbieter-Login (Google Sign-In) angeboten wird:

1. **Firebase Authentication:**
   - Provider *Apple* in der Firebase Console unter *Authentication $\rightarrow$ Sign-in method* aktivieren.
   - Apple Developer Account: *Services ID* und *Key* (.p8) erstellen und in Firebase hinterlegen.
2. **Xcode Capabilities:**
   - In Xcode: Target `Runner` $\rightarrow$ *Signing & Capabilities* $\rightarrow$ `+ Capability` $\rightarrow$ **Sign in with Apple** hinzufügen.

---

## 2. Push-Benachrichtigungen (APNs)

1. **APNs Authentication Key:**
   - Im Apple Developer Portal unter *Certificates, Identifiers & Profiles* einen **Keys**-Eintrag für *Apple Push Notifications service (APNs)* erstellen.
   - Heruntergeladene `.p8`-Schlüsseldatei in der Firebase Console unter *Project Settings $\rightarrow$ Cloud Messaging $\rightarrow$ Apple app configuration* hochladen (Key ID und Team ID angeben).
2. **Xcode Capabilities:**
   - `+ Capability` $\rightarrow$ **Push Notifications**
   - `+ Capability` $\rightarrow$ **Background Modes** $\rightarrow$ Haken bei *Remote notifications* und *Background fetch*.

---

## 3. Erforderliche `Info.plist` Berechtigungstexte (Privacy Keys)

In `ios/Runner/Info.plist` müssen vor dem Einreichen aussagekräftige Begründungen in deutscher und englischer Sprache hinterlegt sein:

```xml
<!-- Fotomediathek für Chat-Anhänge -->
<key>NSPhotoLibraryUsageDescription</key>
<string>ORBIT benötigt Zugriff auf deine Fotos, damit du Trainingsfotos und Screenshots im Chat mit deinem Trainer teilen kannst.</string>

<!-- Kamera für Chat-Fotos -->
<key>NSCameraUsageDescription</key>
<string>ORBIT benötigt Zugriff auf deine Kamera, um direkt im Chat Fotos für deinen Trainer aufzunehmen.</string>

<!-- Dateizugriff für FIT-Uploads -->
<key>UIFileSharingEnabled</key>
<true/>
<key>LSSupportsOpeningDocumentsInPlace</key>
<true/>
```

---

## 4. App Store Privacy Labels (App-Datenschutzangaben)

Beim Anlegen in App Store Connect anzugebende Datenkategorien:
- **Gesundheit und Fitness:** *Fitness* (Watt, Pace, Distanz) und *Gesundheit* (Herzfrequenz, HRV, Schlaf). Verknüpft mit der Identität des Nutzers. Nicht für Tracking genutzt.
- **Standort:** *Genauer Standort* (GPS-Tracks bei Aktivitäten). Verknüpft mit der Identität des Nutzers.
- **Benutzerinhalte:** *Nachrichten* (1:1 Chat mit Trainer) und *Fotos* (Anhänge).
- **Kontaktdaten:** *E-Mail-Adresse* und *Name*.
- **Diagnose:** *Absturzdaten* und *Leistungsdaten* (Crashlytics).
