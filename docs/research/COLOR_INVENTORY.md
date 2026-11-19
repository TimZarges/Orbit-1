# ORBIT — Bestands- und Farb-Inventur (Read-Only Snapshot)

**Stand:** 2026-11-19 (`v1.0.1`)  
**Hinweis:** Reine Bestandsaufnahme ohne Code-, Theme- oder HTML-Änderungen.

---

## 1. Logo- & Marken-Assets

| Asset / Datei | Auflösung / Format | Exakte Hex-Farben & Rolle |
|---|---|---|
| [`assets/images/logo.png`](../../assets/images/logo.png) | `300x300` PNG | Orbit-Bogen: `#CDFB17` · Punkt & Wortmarke „ORBIT“: `#FFFFFF` · Hintergrund-Verlauf (Navy): `#002E6B` (oben/links) bis `#002555` (unten/rechts) · definierte Markenfarbe lt. XML/Code `#001F47` |
| [`public/logo.png`](../../public/logo.png) | `300x300` PNG | Identisch zu `assets/images/logo.png` (`#CDFB17`, `#FFFFFF`, Verlauf `#002E6B`–`#002555`) |
| [`android/app/src/main/res/drawable/ic_launcher_foreground.xml`](../../android/app/src/main/res/drawable/ic_launcher_foreground.xml) | VectorDrawable (`108dp`) | Orbit-Bogen: `#CDFB17` · Satelliten-Punkt & „ORBIT“-Schriftzug: `#FFFFFF` |
| [`android/app/src/main/res/values/colors.xml`](../../android/app/src/main/res/values/colors.xml) | Android XML | `orbit_navy`: `#001F47` · `orbit_volt`: `#CDFB17` · `orbit_white`: `#FFFFFF` · `ic_launcher_background`: `#001F47` |
| [`android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`](../../android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml) | Adaptive Icon | Hintergrund `@color/ic_launcher_background` (`#001F47`) + `@drawable/ic_launcher_foreground` |
| [`android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`](../../android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png) (u. `hdpi`–`xxhdpi`) | `192x192` PNG | Identisches ORBIT-Motiv (`#CDFB17`, `#FFFFFF`, Navy-Verlauf `#00275A`–`#002C66`) |
| [`android/app/src/main/res/drawable/ic_stat_orbit.xml`](../../android/app/src/main/res/drawable/ic_stat_orbit.xml) | VectorDrawable (`24dp`) | Monochromes Notification-Signet: `#FFFFFF` |
| [`android/app/src/main/res/drawable/launch_background.xml`](../../android/app/src/main/res/drawable/launch_background.xml) / [`drawable-v21`](../../android/app/src/main/res/drawable-v21/launch_background.xml) | Layer-List | `@android:color/white` (`#FFFFFF`) bzw. `?android:colorBackground` |
| [`web/manifest.json`](../../web/manifest.json) / [`public/app/manifest.json`](../../public/app/manifest.json) | PWA Manifest | `background_color`: `#001F47` · `theme_color`: `#001F47` (referenziert `logo.png` + `icons/`) |
| [`web/favicon.png`](../../web/favicon.png), [`web/icons/Icon-192.png`](../../web/icons/Icon-192.png) (u. `Icon-512`, `Icon-maskable-*`, gespiegelt in `public/app/`) | `16x16` / `192x192` / `512x512` PNG | **Auffälligkeit:** Enthalten noch das Standard-Flutter-Blau (`#FFFFFF`, `#54C5F8`, `#01579B`, `#29B6F6`), während `public/index.html`, `help.html`, `privacy.html`, `imprint.html` bereits `/logo.png` als Favicon nutzen. |

---

## 2. Flutter App Theme- & Farbdateien (`lib/`)

### Zentrale Theme- & Token-Dateien
1. [`lib/core/design/app_colors.dart`](../../lib/core/design/app_colors.dart) — Zentrale Farbkonstanten (Brand, Surfaces, Zonen Z1–Z7, Telemetrie-Kanäle, Sportarten, Status)
2. [`lib/core/theme/orbit_professional_theme.dart`](../../lib/core/theme/orbit_professional_theme.dart) — Aktives Clean Professional Material-3 Theme (`buildLightTheme()`, `buildDarkTheme()`)
3. [`lib/core/design/app_theme.dart`](../../lib/core/design/app_theme.dart) — Fassade (`AppTheme.lightTheme` / `AppTheme.darkTheme`) auf `OrbitProfessionalTheme`
4. [`lib/core/design/theme_tokens.dart`](../../lib/core/design/theme_tokens.dart) — Ältere/alternative `OrbitThemeTokens` (Dark-Cockpit `#001F47`/`#002A5C` vs. Light `#F8FAFC`)
5. [`lib/core/metrics/training_zones_model.dart`](../../lib/core/metrics/training_zones_model.dart) — Coggan/Friel Zonen-Definition mit Material-Standardfarben (`Colors.grey`, `blue`, `green`, `yellow`, `orange`, `red`, `deepPurple`)
6. Feature-Modelle & -Widgets mit eigenen/abgeleiteten Farben:
   - [`lib/features/analysis/models/zone_distribution.dart`](../../lib/features/analysis/models/zone_distribution.dart) (nutzt `AppColors.zone1`–`zone7`)
   - [`lib/features/analysis/models/sport_distribution.dart`](../../lib/features/analysis/models/sport_distribution.dart) (nutzt `AppColors.sport*` + Fallback `#94A3B8`)
   - [`lib/features/home/widgets/home_recent_activity_card.dart`](../../lib/features/home/widgets/home_recent_activity_card.dart) (V1-Vorschaukarte: Surfaces, Sport-Akzente, Triathlon-Farbwechsel)
   - [`lib/features/onboarding/widgets/triathlon_combined_icon.dart`](../../lib/features/onboarding/widgets/triathlon_combined_icon.dart) (Default `#CDFB17`)
   - [`lib/features/health/widgets/three_rings_hero_card.dart`](../../lib/features/health/widgets/three_rings_hero_card.dart), [`lib/features/home/widgets/daily_ring_widget.dart`](../../lib/features/home/widgets/daily_ring_widget.dart), [`lib/features/health/screens/health_cockpit_screen.dart`](../../lib/features/health/screens/health_cockpit_screen.dart), [`lib/features/health/widgets/sleep_breakdown_card.dart`](../../lib/features/health/widgets/sleep_breakdown_card.dart), [`lib/features/health/widgets/readiness_card.dart`](../../lib/features/health/widgets/readiness_card.dart) (V2/V3 Health & Recovery)
   - [`lib/features/dashboard/screens/dashboard_screen.dart`](../../lib/features/dashboard/screens/dashboard_screen.dart), [`lib/features/calendar/screens/calendar_screen.dart`](../../lib/features/calendar/screens/calendar_screen.dart), [`lib/features/analysis/widgets/fitness_fatigue_trend_chart.dart`](../../lib/features/analysis/widgets/fitness_fatigue_trend_chart.dart)

### Extrahierte Light Mode vs. Dark Mode Werte (Aktives Theme: `OrbitProfessionalTheme` + `AppColors`)

| Rolle | Light Mode (`buildLightTheme`) | Dark Mode (`buildDarkTheme`) | Tokens / Hinweise |
|---|---|---|---|
| **Scaffold / Hintergrund** | `#F4F6F9` (Alabaster) | `#0D0F12` (Carbon) | `lightBackground` / `darkBackground` (`OrbitThemeTokens`: `#F8FAFC` / `#001F47`; `HealthCockpitScreen`: `#0B132B`) |
| **Karten / Surface** | `#FFFFFF` (Reinweiß) | `#16181D` (Anthrazit) | `lightCardSurface` / `darkCardSurface` (`OrbitThemeTokens`: `#FFFFFF` / `#002A5C`) |
| **Erhöhte Surface / ContainerHighest** | `#F4F6F9` | `#1E2128` | `surfaceContainerHighest` / `darkElevatedSurface` (Dialogs, Inputs teilweise `#F1F5F9` / `#0F172A` / `#1E293B`) |
| **AppBar Hintergrund** | `#FFFFFF` | `#0D0F12` | `appBarTheme.backgroundColor` |
| **BottomNav & Web NavigationRail** | `#FFFFFF` | `#16181D` | `bottomNavigationBarTheme.backgroundColor`, `NavigationRail.backgroundColor` |
| **Navigation Selektiert / Aktive Indikatoren** | `#001F47` (Navy) | `#CDFB17` (Volt) | Rail-Indicator: `#CDFB17` mit 22 % Alpha (`0.22`) |
| **Navigation Unselektiert** | `#475569` | `#94A3B8` | `lightTextSecondary` / `darkTextSecondary` |
| **Primärfarbe (`colorScheme.primary`)** | `#001F47` (Navy) | `#CDFB17` (Volt) | `onPrimary`: `#FFFFFF` (Light) / `#001F47` (Dark) |
| **Sekundärfarbe (`colorScheme.secondary`)** | `#00357A` (`navyLight`) | `#CDFB17` (Volt) | `onSecondary`: `#FFFFFF` (Light) / `#001F47` (Dark) |
| **Primärer Text (`onSurface` / Body)** | `#0F172A` | `#F8FAFC` (bzw. `#FFFFFF` in Cards) | `lightTextPrimary` / `darkTextPrimary` |
| **Sekundärer / Gedämpfter Text** | `#475569` / `#64748B` | `#94A3B8` / `#64748B` | `lightTextSecondary` / `darkTextSecondary` / `techGrey` |
| **Rahmen / Borders / Divider** | `#E2E8F0` (1px) | `0x14FFFFFF` (8 % Weiß) | `lightSubtleBorder` / `darkSubtleBorder` (Legacy V2/Health auch `#003D82`, `#1E293B`, `#334155`) |
| **Primary ElevatedButton** | BG `#001F47` · Text `#FFFFFF` | BG `#CDFB17` · Text `#001F47` | `elevatedButtonTheme` |
| **OutlinedButton** | Border `#E2E8F0` · Text `#0F172A` | Border `#CDFB17` · Text `#CDFB17` | `outlinedButtonTheme` |
| **Input Focus Border** | `#001F47` (2px) | `#CDFB17` (2px) | `inputDecorationTheme.focusedBorder` |
| **Fehler (`colorScheme.error`)** | `#E53E3E` (`AppColors.z5`) | `#FF6B6B` (`channelHeartRate`) | Alerts/Löschaktionen nutzen zudem `#EF4444` (`AppColors.coral`/`red`) |

### Sportarten, Status, Zonen & Telemetrie (`AppColors` & Feature-Widgets)

- **Sportarten (`AppColors` + `TrainingPreviewCard`):**
  - Schwimmen (`sportSwim`): `#0EA5E9`
  - Radfahren (`sportBike`): `#F59E0B`
  - Laufen (`sportRun`): `#10B981`
  - Kraft (`sportStrength`): `#64748B`
  - Triathlon (`TrainingPreviewCard`): `#001F47` (Light) / `#CDFB17` (Dark) · (`sportMulti`: `#001F47`) · Fallback: `#94A3B8`
- **Status- & Ampelfarben:**
  - Erfolg / Grün (`emerald`/`green`/`success`): `#10B981` (teilweise `#047857` für Kontrast auf Hell in Trend-Badges)
  - Warnung / Amber (`amber`/`warning`): `#F59E0B` (teilweise `#B45309` auf Hell, `#DD6B20` in `weekly_load_summary`)
  - Fehler / Kritisch (`coral`/`red`/`error`): `#EF4444` (Soft-BG `#FEF2F2`, Soft-Border `#FCA5A5`)
  - Info / Blau / Cyan: `#0EA5E9` (`accentBlue`), `#22D3EE` (`cyan`), `#00D2FF` (Charts/Races), `#3B82F6`
- **Trainingszonen Z1–Z7 (`AppColors.z1`–`z7`):**
  - Z1: `#A0AEC0` · Z2: `#3182CE` · Z3: `#38A169` · Z4: `#DD6B20` · Z5: `#E53E3E` · Z6: `#9F7AEA` · Z7: `#D53F8C`
- **Telemetrie-Kanäle (`AppColors.channel*`):**
  - Power: `#F6C453` · HeartRate: `#FF6B6B` · Pace: `#22D3EE` · SwimPace: `#818CF8` · Cadence: `#4ADE80` · Altitude: `#94A3B8` · CoreTemp: `#FB923C`
- **Daily Health Ringe & Schlafphasen (V2/V3):**
  - 3-Ringe-Card (`three_rings_hero_card.dart`): Card BG `#001F47` · Erholung `#10B981`/`#F59E0B`/`#EF4444` · Belastung `#F59E0B` · Schlaf `#22D3EE`
  - Schlafphasen (`sleep_breakdown_card.dart`): Tief `#1E3A8A` · REM `#6366F1` · Leicht `#38BDF8` · Wach `#EF4444`

---

## 3. Öffentliche Webseite & Rechtsseiten (`public/`)

| Seite | Light Mode CSS-Tokens | Dark Mode CSS-Tokens | Marken- & Akzentfarben |
|---|---|---|---|
| [`public/index.html`](../../public/index.html) | `--bg-page`: `#F8FAFC` · `--bg-card`: `#FFFFFF` · `--bg-card-subtle`: `#F1F5F9` · `--text-main`: `#001F47` · `--text-muted`: `#475569` · `--text-dim`: `#64748B` · `--border-card`: `#E2E8F0` · `--hero-card-bg`: `#001F47` · `--header-bg`: `rgba(255,255,255,0.95)` | `--bg-page`: `#050B14` · `--bg-card`: `#0A1324` · `--bg-card-subtle`: `#0F1C36` · `--text-main`: `#FFFFFF` · `--text-muted`: `#94A3B8` · `--text-dim`: `#64748B` · `--border-card`: `rgba(255,255,255,0.10)` · `--hero-card-bg`: `#0A1324` · `--header-bg`: `rgba(5,11,20,0.95)` | `--brand-navy`: `#001F47` · `--brand-navy-deep`: `#00122B` · `--brand-volt`: `#CDFB17` · `--brand-volt-hover`: `#BEEA06` · `--brand-amber`: `#FF6B00` · `--brand-cyan`: `#00D2FF` · `--brand-emerald`: `#10B981` · `--brand-purple`: `#8B5CF6` |
| [`public/help.html`](../../public/help.html) | `--bg`: `#F8FAFC` · `--card`: `#FFFFFF` · `--box-bg`: `#F1F5F9` · `--text`: `#001F47` · `--muted`: `#475569` · `--border`: `#E2E8F0` | `--bg`: `#050B14` · `--card`: `#0A1324` · `--box-bg`: `#0F1C36` · `--text`: `#FFFFFF` · `--muted`: `#94A3B8` · `--border`: `rgba(255,255,255,0.10)` | `--navy`: `#001F47` · `--navy-light`: `#00357A` · `--volt`: `#CDFB17` · `--amber`: `#FF6B00` · `--cyan`: `#00D2FF` · `--emerald`: `#10B981` · `--purple`: `#8B5CF6` |
| [`public/privacy.html`](../../public/privacy.html) & [`imprint.html`](../../public/imprint.html) | `--bg`: `#F4F6F9` · `--card`: `#FFFFFF` · `--text`: `#0F172A` · `--muted`: `#475569` · `--border`: `#E2E8F0` | `--bg`: `#0D0F12` · `--card`: `#16181D` · `--text`: `#F8FAFC` · `--muted`: `#94A3B8` · `--border`: `rgba(255,255,255,0.10)` | `--navy`: `#001F47` · `--volt`: `#CDFB17` (identisch zu `OrbitProfessionalTheme`!) |
| [`public/delete-account.html`](../../public/delete-account.html) | *(Nur Dark-Theme aktiv)* | `--bg`: `#0A0F1D` · `--card`: `#0F172A` · `--text`: `#F8FAFC` · `--muted`: `#94A3B8` · `--border`: `#1E293B` | `--navy`: `#0A0F1D` · `--volt`: `#CDFB17` · `--red`: `#EF4444` · Warning-Text `#FCA5A5` |

*(Auffälliger Kontrast im Bestand: `index.html` & `help.html` nutzen im Light Mode `#F8FAFC` / `#001F47` Text und im Dark Mode Deep-Space-Navy `#050B14` / `#0A1324`, während die Flutter-App und `privacy.html`/`imprint.html` im Light Mode `#F4F6F9` / `#0F172A` Text und im Dark Mode Carbon/Anthrazit `#0D0F12` / `#16181D` verwenden.)*

---

## 4. Einordnung nach Flächenanteil & Rolle in der App

- **Groß / Flächen prägend (Hintergründe & Kartenflächen):**
  - App Light: `#F4F6F9` (Scaffold), `#FFFFFF` (Karten/AppBar/Nav), `#0F172A` (Fließtext)
  - App Dark: `#0D0F12` (Scaffold/AppBar), `#16181D` (Karten/Nav), `#1E2128` (Sheets/Dialogs), `#F8FAFC`/`#FFFFFF` (Text)
  - Web `/` & Hilfe: `#F8FAFC` / `#FFFFFF` (Light), `#050B14` / `#0A1324` (Dark) sowie Hero-Card `#001F47` / `#0A1324`
  - Legacy/V2-Health-Karten: `#0B132B`, `#001F47`, `#002A5C`, `#0F172A`, `#1E293B`
- **Mittel / Struktur & Navigation (Leisten, Ränder, Sekundärtext, Sportart-Akzente):**
  - Borders & Divider: `#E2E8F0` (Light), `0x14FFFFFF` / `rgba(255,255,255,0.10)` (Dark), `#003D82` / `#1E293B` / `#334155` (Legacy/Health)
  - Sekundär-/Label-Text: `#475569`, `#64748B`, `#94A3B8`, `#CBD5E1`
  - Sekundäre Badges/Boxen: `#F1F5F9` (Light), `#0F1C36` (Web Dark), `#00357A` (`navyLight`)
  - Sportart-Icons: `#F59E0B` (Rad), `#10B981` (Lauf), `#0EA5E9` (Schwimmen), `#64748B` (Kraft), `#001F47`/`#CDFB17` (Triathlon)
- **Klein / Fokus & Signal (Marken-Akzent, CTAs, Status, Zonen):**
  - Primärer Marken-Fokus: `#CDFB17` (Volt — Hover Web `#BEEA06`) und `#001F47` (Navy — Light-Primary / Dark-OnPrimary)
  - Status & Warnungen: `#10B981` (Erfolg), `#F59E0B` / `#FF6B00` (Warnung), `#EF4444` / `#E53E3E` / `#FF6B6B` (Fehler/Löschen)
  - Zonen (Z1–Z7) & Telemetrie/Ringe: `#A0AEC0`, `#3182CE`, `#38A169`, `#DD6B20`, `#E53E3E`, `#9F7AEA`, `#D53F8C`, `#F6C453`, `#22D3EE`, `#00D2FF`, `#818CF8`, `#4ADE80`, `#FB923C`, `#8B5CF6`
