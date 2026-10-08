# Manuelle Schritte (nur ich kann das)

> Antigravity ergänzt diese Datei, sobald etwas dazukommt. Status: ☐ offen · ☑ erledigt. Spalte „Wann" = spätestens vor Phase.

## Konten und Projekte
| ☐ | Aufgabe | Wann |
|---|---|---|
| ☐ | Zwei Firebase-Projekte anlegen: `orbit-dev`, `orbit-prod`. Region für Firestore/Storage/Functions **`europe-west3` (Frankfurt)** wählen (nachträglich nicht änderbar!). | 00 |
| ☐ | Beide Projekte auf **Blaze-Tarif** stellen (Cloud Functions erfordern ihn). Budget-Alarm einrichten. | 00 |
| ☐ | Firebase CLI installieren und `firebase login`. FlutterFire CLI (`flutterfire configure`) für beide Projekte/Flavors ausführen. | 00 |
| ☐ | Android-App in beiden Projekten registrieren (Package-ID je Flavor, z. B. `…orbit.dev`/`…orbit`). **Package-ID festlegen** und mitteilen. | 00 |
| ☐ | SHA-1 und SHA-256 (Debug und später Release) der Android-App in Firebase eintragen (nötig für Google Sign-In). | 01 |
| ☐ | Auth-Anbieter aktivieren: Google, E-Mail/Passwort. | 01 |
| ☐ | **App Check** (Play Integrity für Android) aktivieren; für Debug Debug-Token registrieren. | 01 |
| ☐ | Crashlytics und App Distribution aktivieren, Tester eintragen, damit du früh auf dem echten Gerät testest. | 00/01 |
| ☐ | GitHub Actions: nötige Secrets hinterlegen (falls Deploy gewünscht). | 00 |

## Garmin
| ☐ | Aufgabe | Wann |
|---|---|---|
| ☐ | **Antrag beim Garmin Connect Developer Program stellen** (Activity-/Health-API). Bearbeitung kann dauern, daher **jetzt** beantragen. | sofort |
| ☐ | Nach Freigabe: Consumer-Key/Secret im Secret Manager hinterlegen, Webhook-URLs im Garmin-Portal eintragen. | 06 |
| ☐ | `assetlinks.json` für Android App Links hosten (Domain nötig, z. B. über Firebase Hosting) und Fingerprints eintragen. | 06 |

## Recht und Datenschutz
| ☐ | Aufgabe | Wann |
|---|---|---|
| ☐ | Datenschutz-Folgenabschätzung (Art. 35) und Verarbeitungsverzeichnis prüfen lassen (Gesundheitsdaten). Datenschutzbeauftragten/Anwalt einbinden. | vor 06 |
| ☐ | Auftragsverarbeitung mit Google (Firebase) abschließen. | 01 |
| ☐ | Impressum und Datenschutzerklärung erstellen und hosten (Web-Link auch für Account-Löschung, Play-Pflicht). | 16 |
| ☐ | Markenrechte-Check für Begriffe (z. B. TSS, NP, IF) und den Namen „ORBIT". | vor Release |

## Release
| ☐ | Aufgabe | Wann |
|---|---|---|
| ☐ | Play-Console-Konto, Upload-Key/Signierung, „Data Safety"-Formular. | 16 |
| ☐ | Apple Developer Account (erst bei iOS-Start), Apple Sign-In einrichten. | später |

## Antigravity-Einrichtung
| ☐ | Aufgabe | Wann |
|---|---|---|
| ☐ | Berechtigungen einrichten (Allow-/Deny-/Ask-Listen aus `02_PERMISSIONS.md`). Diese liegen **nicht im Repo**, sondern in deinen Antigravity-Einstellungen. | 00 |
| ☐ | Unter **Customizations** prüfen, dass `AGENTS.md`, die 4 Regeln und die 10 Skills erkannt werden. | 00 |
| ☐ | Eventuell vorhandene globale Regeln (`~/.gemini/GEMINI.md`) auf Widersprüche zu `AGENTS.md` prüfen. | 00 |
