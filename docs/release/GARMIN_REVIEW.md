# Garmin Health API – Vorbereitung auf das Production Review

> Leitfaden zur Beantragung des Produktionszugriffs für die Garmin Connect Developer API (Activity API & Health API).
> **Referenz:** Garmin Brand Guidelines & Developer Agreement.

---

## 1. Voraussetzungen vor Einreichung

1. **Vollständig funktionierender OAuth 1.0a / 2.0 Flow:**
   - Der Autorisierungs- und Rückkehr-Flow muss in der App nahtlos durchlaufen werden können (`/settings/garmin` und OAuth-Rücksprung).
2. **Branding & Quellenangabe (Garmin Vorgaben):**
   - Aktivitäten, die von Garmin importiert wurden, tragen den Hinweis oder das Logo: *„Synced with Garmin Connect"*.
   - Das Garmin-Logo darf nicht verändert, verzerrt oder farblich umgefärbt werden.
   - Kein Eindruck erwecken, ORBIT sei ein offizielles Produkt von Garmin („Powered by Garmin" / „Compatible with Garmin").
3. **Datenschutzerklärung:**
   - Erwähnung der Datenübertragung zwischen Garmin und ORBIT in der Datenschutzerklärung (`docs/PRIVACY.md` §2 & §5).

---

## 2. Reviewer-Zugang (Demo-Konto für Garmin Auditoren)

Für das Review-Team von Garmin Connect muss ein Test-Account bereitgestellt werden:
- **E-Mail:** `garmin-review@orbit-training.app`
- **Passwort:** (Wird sicher im Entwickler-Portal übermittelt)
- **Rolle:** `ATHLETE`
- **Vorhandene Daten:** Ein bereits verknüpfter Demo-Datensatz mit 3 Aktivitäten (Rad, Lauf, Swim) und synchronisierten Health-Tagesmetriken.

---

## 3. Benötigte Screenshots & Nachweise für das Antragsformular

1. **Screenshot 1: Kontoverknüpfung:**
   - Screen `Settings -> Garmin Connect verbinden` mit deutlich lesbarem Hinweis auf die angefragten Datenarten (Aktivitäten, tägliche Zusammenfassungen).
2. **Screenshot 2: Importierte Aktivität:**
   - Aktivitäts-Cockpit mit importierten Telemetriedaten (Puls, Watt, Trittfrequenz) und Garmin-Herkunfts-Badge (`source: "GARMIN"`).
3. **Screenshot 3: Trennung der Verknüpfung:**
   - Einstellungsdialog zur Trennung des Garmin-Kontos und Löschung der Tokens.

---

## 4. Endpunkte & Webhooks für Produktion

- **Webhook URL:** `https://europe-west3-orbit-app-prod.cloudfunctions.net/garminWebhook`
- **OAuth Callback URL:** `https://orbit-training.web.app/auth/garmin/callback`
- **Deduplizierung:** Gewährleistet über die Kombination aus `(source: "GARMIN", externalId)`.
