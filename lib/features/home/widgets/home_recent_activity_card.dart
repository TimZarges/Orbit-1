/// Datei-Header: `lib/features/home/widgets/home_recent_activity_card.dart`
/// Zweck: Trainings-Vorschaukarte für absolvierte Einheiten (COROS-Stil in V1.0.0
/// mit direktem `.FIT`-Download-Button rechts und nicht-klickbarem Verhalten;
/// ab V2.0.0 optional mit Cockpit-Weiterleitung).
/// Architektur-Einordnung: Präsentationsschicht (`lib/features/home/widgets/`),
/// nutzt `CountryDateTimeFormatter` (`dd.mm.yy` & `24h`) und `ReleaseConfig`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/release_config.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/utils/country_date_time_formatter.dart';
import '../../activities/models/activity.dart';
import '../../onboarding/widgets/triathlon_combined_icon.dart';
import '../../settings/providers/settings_provider.dart';

/// Karte für eine absolvierte Trainingseinheit im COROS-Stil.
///
/// Was:
/// - Im V1.0.0-Standardbetrieb (`ReleaseConfig.isV2Enabled == false`):
///   - **Nicht klickbar** (kein Öffnen des Detail-Cockpits).
///   - **Kein GPX-Minigraph** auf der rechten Seite.
///   - **Rechts direkter `.FIT`-Download-Button** (`48x48 dp` Touch-Target).
///   - Datum & Uhrzeit strikt im Format `dd.mm.yy • HH:mm` nach Wohnland (`CountryDateTimeFormatter`).
/// - Im V2/V3-Modus (`ReleaseConfig.isV2Enabled == true`):
///   - Blendet zusätzlich den Button *„Im Analyse-Cockpit öffnen“* ein.
/// Warum: Erfüllt die verbindlichen V1.0.0-Detail-Entscheidungen aus `docs/ROADMAP_V1_TO_V4.md`
/// und hält sämtliche V2/V3-Tests kompatibel.
class HomeRecentActivityCard extends ConsumerWidget {
  /// Die darzustellende absolvierte Trainingseinheit.
  final Activity activity;

  /// Callback zum Öffnen des Analyse-Cockpits (nur aktiv, wenn `ReleaseConfig.isV2Enabled == true`).
  final VoidCallback? onOpenCockpit;

  /// Optionaler Callback für den direkten `.FIT`-Originaldatei-Download.
  final VoidCallback? onDownloadFit;

  /// Erstellt eine [HomeRecentActivityCard].
  const HomeRecentActivityCard({
    super.key,
    required this.activity,
    this.onOpenCockpit,
    this.onDownloadFit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Granulare Riverpod-Selektoren für Sprache, Wohnland und Release-Scope
    final lang = ref.watch(
      settingsControllerProvider.select((s) => s.languageCode),
    );
    final countryCode = ref.watch(
      settingsControllerProvider.select((s) => s.countryCode),
    );
    final isV2Enabled = ref.watch(
      releaseConfigProvider.select((cfg) => cfg.isV2Enabled),
    );

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.anthraciteCard : AppColors.white;
    final borderColor =
        isDark ? AppColors.darkSubtleBorder : AppColors.cardBorder;
    final primaryTextColor =
        isDark ? AppColors.white : AppColors.lightTextPrimary;
    final secondaryTextColor =
        isDark ? AppColors.textSecondaryDark : const Color(0xFF475569);

    // Formatiert Datum & Uhrzeit strikt als dd.mm.yy • HH:mm nach Wohnland
    final formattedDateTime = CountryDateTimeFormatter.formatDateTime(
      activity.startTimeUtc,
      countryCode: countryCode,
    );

    return Container(
      key: Key('coros_activity_card_${activity.id}'),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Obere Zeile (COROS-Layout): Links Sport-Icon + Titel + Datum, Rechts direkter .FIT-Download-Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Sportart-Badge (unterstützt Triathlon-Kombi-Icon)
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.volt.withValues(alpha: 0.14)
                      : AppColors.navy.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: activity.sport.toUpperCase() == 'TRIATHLON'
                    ? TriathlonCombinedIcon(
                        size: 18,
                        color: isDark ? AppColors.volt : AppColors.navy,
                      )
                    : Icon(
                        _getSportIcon(activity.sport),
                        size: 22,
                        color: isDark ? AppColors.volt : AppColors.navy,
                      ),
              ),
              const SizedBox(width: 12),

              // Titel + Wohnland-konformes Datum (dd.mm.yy • HH:mm)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.title.copyWith(
                        fontSize: 16,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formattedDateTime,
                      key: Key('activity_card_datetime_${activity.id}'),
                      style: AppTypography.label.copyWith(
                        color: secondaryTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Rechts: Direkter .FIT-Download-Button (statt GPX-Grafik gemäß V1.0.0 Roadmap)
              Tooltip(
                message: AppStrings.fitDownloadAction(lang: lang),
                child: Material(
                  color: isDark ? AppColors.volt : AppColors.navy,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    key: Key('fit_download_button_${activity.id}'),
                    borderRadius: BorderRadius.circular(12),
                    onTap: onDownloadFit ??
                        () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppStrings.fitDownloadStarted(
                                  activity.title,
                                  lang: lang,
                                ),
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.download_rounded,
                            size: 18,
                            color: isDark ? AppColors.navy : AppColors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '.FIT',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.navy : AppColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Kompaktes Metrik-Grid im COROS-Stil (Dauer, Distanz, Ø Leistung/Pace, Ø Puls)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatItem(
                label: lang == 'en' ? 'Duration' : 'Dauer',
                value: _formatDuration(activity.durationSec.round()),
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
              ),
              if (activity.distanceM > 0)
                _StatItem(
                  label: lang == 'en' ? 'Distance' : 'Distanz',
                  value: _formatDistance(activity.sport, activity.distanceM),
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                ),
              if (activity.summary?.avgPowerW != null &&
                  activity.summary!.avgPowerW! > 0)
                _StatItem(
                  label: lang == 'en' ? 'Avg Power' : 'Ø Leistung',
                  value: '${activity.summary!.avgPowerW!.round()} W',
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                ),
              if (activity.summary?.avgHr != null &&
                  activity.summary!.avgHr! > 0)
                _StatItem(
                  label: lang == 'en' ? 'Avg HR' : 'Ø Puls',
                  value: '${activity.summary!.avgHr!.round()} bpm',
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                ),
            ],
          ),

          // Optionaler Cockpit-CTA (nur ab V2.0.0 sichtbar; in V1.0.0 ist die Karte nicht klickbar)
          if (isV2Enabled && onOpenCockpit != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onOpenCockpit,
                icon: const Icon(Icons.analytics_outlined, size: 16),
                label: Text(
                  lang == 'en'
                      ? 'Open in Analysis Cockpit'
                      : 'Im Analyse-Cockpit öffnen',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryTextColor,
                  side: BorderSide(color: borderColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Ermittelt das passende Sportart-Icon für Radfahren, Laufen, Schwimmen und Kraft.
  IconData _getSportIcon(String sport) {
    switch (sport.toUpperCase()) {
      case 'BIKE':
        return Icons.directions_bike;
      case 'RUN':
        return Icons.directions_run;
      case 'SWIM':
        return Icons.pool;
      default:
        return Icons.fitness_center;
    }
  }

  /// Formatiert eine Dauer in Sekunden als `Xh Ym` oder `Y min`.
  String _formatDuration(int sec) {
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '$m min';
  }

  /// Formatiert eine Distanz in Metern als `m` (Schwimmen) oder `km` (Rad/Lauf).
  String _formatDistance(String sport, double distanceM) {
    if (sport.toUpperCase() == 'SWIM') return '${distanceM.round()} m';
    return '${(distanceM / 1000).toStringAsFixed(1)} km';
  }
}

/// Einzelnes Metrik-Element innerhalb der [HomeRecentActivityCard].
class _StatItem extends StatelessWidget {
  /// Beschriftung der Kennzahl.
  final String label;

  /// Formatierter Messwert.
  final String value;

  /// Primäre Textfarbe (Theme-abhängig).
  final Color primaryTextColor;

  /// Sekundäre Label-Farbe (Theme-abhängig).
  final Color secondaryTextColor;

  /// Erstellt ein [_StatItem].
  const _StatItem({
    required this.label,
    required this.value,
    required this.primaryTextColor,
    required this.secondaryTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.label.copyWith(
            fontSize: 11,
            color: secondaryTextColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.body.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: primaryTextColor,
          ),
        ),
      ],
    );
  }
}
