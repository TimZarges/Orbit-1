# ORBIT Design- & Farbsystem (`COLOR_SYSTEM_V1`)

**Verbindliche Single Source of Truth für Light & Dark Mode in App (Flutter) und Web (`public/*.html`)**  
**Code-Quelle:** `lib/core/design/app_colors.dart` · `lib/core/theme/orbit_professional_theme.dart` · `lib/core/design/theme_tokens.dart`

---

## 1. Drei unverrückbare Grundprinzipien

1. **Light Mode = Logo-Navy als Marken-Akzent (`#001F47`, ergänzt durch `#003B82`):**  
   Logo-Volt (`#CDFB17`) wird im **Light Mode NICHT** für Text, Icons, Rahmen oder Standard-UI-Flächen verwendet (unzureichender Kontrast auf hellen Oberflächen). Logo-Volt bleibt im Light Mode ausschließlich für die zukünftige **GPX-Spur (`#CDFB17`)** auf Karten reserviert.
2. **Dark Mode = Logo-Volt als Marken-Akzent (`#CDFB17`) auf ruhigen Dunkel-Flächen:**  
   Kontrastreiche Hervorhebung für primäre Aktionen, aktive Navigation und Fokus-Zustände auf ruhigem Tiefdunkel (`#0B0E14` / `#141923`).
3. **Keine Markenfarben auf Sportarten & Matrix:**  
   Sportarten (`Triathlon`, `Rad`, `Lauf`, `Schwimmen`, `Kraft`) sowie Trainingszonen (`Z1–Z7`), Matrix- und V2–V4-Analyse-Tokens nutzen eigene, von Logo-Navy (`#001F47`) und Logo-Volt (`#CDFB17`) vollständig unabhängige Farbtokens. Einzige Ausnahme bleibt die zukünftige **GPX-Spur (`#CDFB17`)**.

---

## 2. Verankerte Farb-Tokens nach Flächenrelevanz

### A. GROSS — Flächen & Haupttext

| Rolle | Light Mode | Dark Mode | Verwendung |
|---|---|---|---|
| **Ruhiger Hintergrund (`Scaffold` / Page)** | `#F6F8FB` | `#0B0E14` | Seiten- und Screen-Hintergrund |
| **Karten & Leisten (`Card` / `AppBar` / `Nav`)** | `#FFFFFF` | `#141923` | Karten, Navigationsleisten, Topbar |
| **Sekundär- / Erhöhte Fläche** | `#EEF2F7` | `#1B2230` | Sanfte Boxen (Light) bzw. Sheets/Dialoge/Container (Dark) |
| **Haupttext (`onSurface`)** | `#0F172A` | `#F8FAFC` | Überschriften, Metriken, Fließtext |

---

### B. MITTEL — Akzent, Struktur & Sportarten

| Rolle | Light Mode | Dark Mode | Verwendung |
|---|---|---|---|
| **Primärer Marken-Akzent** | `#001F47` | `#CDFB17` | Primärbuttons (`Elevated`/`Filled`), aktive Tabs, Fokus-Rahmen |
| **Sekundärer Marken-Akzent** | `#003B82` | `#CDFB17` | Ergänzende Navy-Nuance im Light Mode (`colorScheme.secondary`) |
| **Subtile Fläche / Hover-Container** | `#EEF2F7` | `#222B3A` | Dezent abgesetzte Chips, Pillen, Eingabeflächen |
| **Sekundärtext (`onSurfaceVariant`)** | `#64748B` | `#94A3B8` | Labels, Untertitel, Metadaten, Zeitstempel |
| **Feiner Rahmen & Trennlinien** | `#DCE3EC` | `0x24FFFFFF` (`rgba(255,255,255,0.14)`) | 1px-Kartenränder, Divider, Eingabefeld-Umrandungen |
| **Sportart: Triathlon** | `#0284C7` | `#38BDF8` | Multisport- & Triathlon-Icon / Badge |
| **Sportart: Radfahren** | `#D97706` | `#F59E0B` | Bike-Icon / Badge / Verteilung |
| **Sportart: Laufen** | `#059669` | `#10B981` | Run-Icon / Badge / Verteilung |
| **Sportart: Schwimmen** | `#2563EB` | `#60A5FA` | Swim-Icon / Badge / Verteilung |
| **Sportart: Kraft** | `#475569` | `#94A3B8` | Strength-/Indoor-Icon / Badge |

---

### C. KLEIN — Status, GPX-Spur & Zukunfts-Tokens (V2–V4)

| Kategorie / Rolle | Light Mode | Dark Mode | Hinweis |
|---|---|---|---|
| **Status: Erfolg** | `#059669` | `#10B981` | Bestätigungen, verbundene Status, Ziel erfüllt |
| **Status: Warnung / Info** | `#D97706` | `#F59E0B` | Offene Anfragen (`PENDING`), Hinweise, Verifizierungs-Banner |
| **Status: Fehler / Löschen** | `#DC2626` | `#EF4444` | Fehlermeldungen, Trennen, Konto-/Datenlöschung |
| **GPX-Route (Zukunft V2)** | `#CDFB17` | `#CDFB17` | Ausschließlich für GPS-/Karten-Streckenverlauf reserviert |
| **Zone Z1 (Erholung)** | `#94A3B8` | `#94A3B8` | Aktive Regeneration |
| **Zone Z2 (Grundlage)** | `#0284C7` | `#38BDF8` | Aerobe Basis / LIT |
| **Zone Z3 (Tempo)** | `#059669` | `#10B981` | Aerobes Tempo |
| **Zone Z4 (Schwelle)** | `#D97706` | `#F59E0B` | Laktatschwelle / FTP / CSS |
| **Zone Z5 (VO₂max)** | `#DC2626` | `#EF4444` | Maximale Sauerstoffaufnahme |
| **Zone Z6 (Anaerob)** | `#7C3AED` | `#A78BFA` | Anaerobe Kapazität |
| **Zone Z7 (Neuromuskulär)** | `#DB2777` | `#F472B6` | Maximalkraft / Sprint |
| **V2–V4: Erholung** | `#059669` | `#10B981` | Daily Health Erholungsring |
| **V2–V4: Belastung** | `#D97706` | `#F59E0B` | Daily Health Tagesbelastung |
| **V2–V4: Schlaf** | `#0284C7` | `#38BDF8` | Daily Health Schlaf-Score |
| **V2–V4: 2D-RPE Quadrant** | `#7C3AED` | `#A78BFA` | Subjektive Belastung vs. Leistung |
| **V2–V4: LIT / MIT / HIT** | `#475569` | `#94A3B8` | Intensitätsverteilung |
| **V2–V4: ML & KI** | `#4F46E5` | `#818CF8` | Machine-Learning-Prognosen & KI-Trainer |
