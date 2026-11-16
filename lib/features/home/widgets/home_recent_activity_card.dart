/// Datei-Header: `lib/features/home/widgets/home_recent_activity_card.dart`
/// Zweck: Einheitliche COROS-Trainings-Vorschaukarte (`TrainingPreviewCard` /
/// `HomeRecentActivityCard`) für Heute-Ansicht und alle Kalender-Ansichten (Woche,
/// Monat, Liste) im Clean Professional Design (Hell & Dunkel).
/// Architektur-Einordnung: Präsentationsschicht (`lib/features/home/widgets/`),
/// nutzt granulare Riverpod-Selektoren (`.select(...)`), `CountryDateTimeFormatter`
/// (`dd.mm.yy • 24h`), `FitDownloadService` und `ReleaseConfig`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/release_config.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/utils/country_date_time_formatter.dart';
import '../../activities/models/activity.dart';
import '../../activities/services/fit_download_service.dart';
import '../../onboarding/widgets/triathlon_combined_icon.dart';
import '../../settings/providers/settings_provider.dart';

/// Abwärtskompatibler Alias für bestehende Referenzen auf [TrainingPreviewCard].
typedef HomeRecentActivityCard = TrainingPreviewCard;

/// Einheitliche COROS-inspirierte Trainings-Vorschaukarte für absolvierte Einheiten.
///
/// Was:
/// - **Linke Spalte (~68 % Breite):**
///   - Zeile 1: Sportart-Icon in definierter Sport-Akzentfarbe (Triathlon, Radfahren,
///     Laufen, Schwimmen, Kraft, Sonstige) + Hauptmetrik groß & fett (`km`/`m` bei
///     Outdoor/Ausdauer bzw. `hh:mm:ss` bei Indoor/Kraft).
///   - Zeile 2: Sekundärmetriken kompakt in gedämpfter Farbe (Dauer, Pace `/km`
///     bzw. Ø-Leistung `W`, Ø-Herzfrequenz `bpm`, Energie `kcal`).
///   - Zeile 3: Titel der Einheit + Datum & Uhrzeit via [CountryDateTimeFormatter] (`dd.mm.yy • 24h`).
/// - **Rechte Spalte (~32 % Breite):**
///   - Interaktiver `.FIT`-Download-Button mit Ladeindikator (ohne GPX-Grafik).
/// - **Klick-Verhalten:**
///   - Im V1.0.0-Modus (`ReleaseConfig.isV2Enabled == false`) ist der Kartenkörper
///     strikt nicht klickbar; nur der `.FIT`-Download-Button rechts ist interaktiv.
/// Warum: Garantiert identisches Layout auf Heute- und Kalender-Screen sowie 120 FPS
/// durch minimale, selektive Rebuilds (`AGENTS.md` Regel 10).
class TrainingPreviewCard extends ConsumerWidget {
  /// Die darzustellende absolvierte Trainingseinheit.
  final Activity activity;

  /// Callback zum Öffnen des Analyse-Cockpits (nur aktiv, wenn `ReleaseConfig.isV2Enabled == true`).
  final VoidCallback? onOpenCockpit;

  /// Optionaler externer Callback für den `.FIT`-Download-Button (z. B. für Tests).
  final VoidCallback? onDownloadFit;

  /// Erstellt eine [TrainingPreviewCard].
  const TrainingPreviewCard({
    super.key,
    required this.activity,
    this.onOpenCockpit,
    this.onDownloadFit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Granulare Riverpod-Selektoren gemäß Effizienz-Gebot (AGENTS.md Regel 10)
    final lang = ref.watch(
      settingsControllerProvider.select((s) => s.languageCode),
    );
    final countryCode = ref.watch(
      settingsControllerProvider.select((s) => s.countryCode),
    );
    final isV2Enabled = ref.watch(
      releaseConfigProvider.select((cfg) => cfg.isV2Enabled),
    );
    final isDownloading = ref.watch(
      fitDownloadingIdsProvider.select((ids) => ids.contains(activity.id)),
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
    final sportAccent = _resolveSportColor(activity.sport, isDark: isDark);

    // Berechnet Haupt- und Sekundärmetriken außerhalb des Widget-Baums
    final primaryMetric = _formatPrimaryMetric(activity);
    final secondaryMetrics = _buildSecondaryMetrics(activity, lang: lang);
    final formattedDateTime = CountryDateTimeFormatter.formatDateTime(
      activity.startTimeUtc,
      countryCode: countryCode,
    );

    // Kartenkörper: In V1.0.0 strikt ohne InkWell/onTap auf dem Container
    return Container(
      key: Key('coros_activity_card_${activity.id}'),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Linke Spalte (~68 % Breite): Sport-Icon + Hauptmetrik, Sekundärmetriken, Titel + Datum
              Expanded(
                flex: 68,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Zeile 1: Sportart-Icon in Sport-Akzentfarbe + Hauptmetrik groß & fett
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: sportAccent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: _buildSportIconWidget(
                            activity.sport,
                            color: sportAccent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            primaryMetric,
                            key: Key('activity_primary_metric_${activity.id}'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.headline.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: primaryTextColor,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Zeile 2: Sekundärmetriken kompakt in gedämpfter Farbe
                    if (secondaryMetrics.isNotEmpty) ...[
                      Text(
                        secondaryMetrics.join(' • '),
                        key: Key('activity_secondary_metrics_${activity.id}'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],

                    // Zeile 3: Titel der Einheit + lokalisiertes Datum & Uhrzeit (dd.mm.yy • 24h)
                    Text(
                      activity.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formattedDateTime,
                      key: Key('activity_card_datetime_${activity.id}'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.label.copyWith(
                        fontSize: 11.5,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Rechte Spalte (~32 % Breite): Direkter .FIT-Download-Button
              Expanded(
                flex: 32,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Tooltip(
                    message: AppStrings.fitDownloadAction(lang: lang),
                    child: Material(
                      color: isDark ? AppColors.volt : AppColors.navy,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        key: Key('fit_download_button_${activity.id}'),
                        borderRadius: BorderRadius.circular(12),
                        onTap: isDownloading
                            ? null
                            : (onDownloadFit ??
                                () => _handleFitDownload(
                                      context,
                                      ref,
                                      lang: lang,
                                    )),
                        child: Container(
                          constraints: const BoxConstraints(
                            minHeight: 46,
                            minWidth: 82,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isDownloading)
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color:
                                        isDark ? AppColors.navy : AppColors.white,
                                  ),
                                )
                              else
                                Icon(
                                  Icons.download_rounded,
                                  size: 18,
                                  color:
                                      isDark ? AppColors.navy : AppColors.white,
                                ),
                              const SizedBox(width: 5),
                              Text(
                                '.FIT',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color:
                                      isDark ? AppColors.navy : AppColors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Optionaler Cockpit-CTA (nur ab V2.0.0 sichtbar; in V1.0.0 ist die Karte nicht klickbar)
          if (isV2Enabled && onOpenCockpit != null) ...[
            const SizedBox(height: 12),
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

  /// Führt den echten `.FIT`-Download über [FitDownloadService] aus und meldet das Ergebnis.
  Future<void> _handleFitDownload(
    BuildContext context,
    WidgetRef ref, {
    required String lang,
  }) async {
    final idsNotifier = ref.read(fitDownloadingIdsProvider.notifier);
    idsNotifier.state = {...idsNotifier.state, activity.id};

    try {
      final result = await ref
          .read(fitDownloadServiceProvider)
          .downloadFitFile(activity, lang: lang);

      if (!context.mounted) return;
      switch (result.status) {
        case FitDownloadStatus.success:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppStrings.fitDownloadSuccess(
                  result.fileName ?? '${activity.id}.fit',
                  lang: lang,
                ),
              ),
            ),
          );
        case FitDownloadStatus.notFound:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.fitDownloadNotFound(lang: lang)),
            ),
          );
        case FitDownloadStatus.cancelled:
          break;
        case FitDownloadStatus.error:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppStrings.fitDownloadError(
                  result.errorMessage ?? 'Unbekannter Fehler',
                  lang: lang,
                ),
              ),
            ),
          );
      }
    } finally {
      // Ladeindikator für diese Aktivität sicher zurücksetzen
      final current = ref.read(fitDownloadingIdsProvider);
      if (current.contains(activity.id)) {
        idsNotifier.state = current.where((id) => id != activity.id).toSet();
      }
    }
  }

  /// Baut das passende Sportart-Widget (inkl. [TriathlonCombinedIcon]).
  Widget _buildSportIconWidget(String sport, {required Color color}) {
    final upper = sport.toUpperCase();
    if (upper == 'TRIATHLON') {
      return TriathlonCombinedIcon(size: 16, color: color);
    }
    return Icon(_getSportIcon(upper), size: 20, color: color);
  }

  /// Liefert die definierte Sport-Akzentfarbe.
  static Color _resolveSportColor(String sport, {required bool isDark}) {
    switch (sport.toUpperCase()) {
      case 'BIKE':
        return AppColors.sportBike;
      case 'RUN':
        return AppColors.sportRun;
      case 'SWIM':
        return AppColors.sportSwim;
      case 'TRIATHLON':
        return isDark ? AppColors.volt : AppColors.navy;
      case 'STRENGTH':
        return AppColors.sportStrength;
      default:
        return isDark ? AppColors.volt : AppColors.navy;
    }
  }

  /// Ermittelt das Material-Icon für eine Sportart.
  static IconData _getSportIcon(String sportUpper) {
    switch (sportUpper) {
      case 'BIKE':
        return Icons.directions_bike_rounded;
      case 'RUN':
        return Icons.directions_run_rounded;
      case 'SWIM':
        return Icons.pool_rounded;
      case 'STRENGTH':
        return Icons.fitness_center_rounded;
      default:
        return Icons.bolt_rounded;
    }
  }

  /// Berechnet die große Hauptmetrik für Zeile 1:
  /// - Outdoor/Ausdauer (`distanceM > 0` und nicht Kraft): Distanz in `km` (bzw. `m` bei Schwimmen).
  /// - Indoor/Kraft (`distanceM <= 0` oder `STRENGTH`): Dauer als `hh:mm:ss`.
  static String _formatPrimaryMetric(Activity activity) {
    final upper = activity.sport.toUpperCase();
    if (upper == 'STRENGTH' || activity.distanceM <= 0) {
      return _formatHms(activity.durationSec.round());
    }
    if (upper == 'SWIM') {
      return '${activity.distanceM.round()} m';
    }
    return '${(activity.distanceM / 1000).toStringAsFixed(1)} km';
  }

  /// Erstellt die kompakten Sekundärmetriken für Zeile 2 (Dauer, Pace/Watt, HF, kcal).
  static List<String> _buildSecondaryMetrics(
    Activity activity, {
    required String lang,
  }) {
    final items = <String>[];
    final upper = activity.sport.toUpperCase();

    // Dauer ergänzen, sofern sie nicht schon Hauptmetrik ist
    if (upper != 'STRENGTH' && activity.distanceM > 0) {
      items.add(_formatShortDuration(activity.durationSec.round()));
    }

    // Pace bei Lauf/Schwimmen oder Ø Leistung in W bei Rad/Triathlon
    final avgPower = activity.summary?.avgPowerW;
    final avgPace = activity.summary?.avgPaceSecPerKm;
    if (upper == 'RUN' && (avgPace != null && avgPace > 0)) {
      items.add(_formatRunPace(avgPace));
    } else if (upper == 'RUN' &&
        activity.distanceM > 0 &&
        activity.durationSec > 0) {
      final paceSecPerKm = activity.durationSec / (activity.distanceM / 1000.0);
      items.add(_formatRunPace(paceSecPerKm));
    } else if (avgPower != null && avgPower > 0) {
      items.add('${avgPower.round()} W');
    }

    // Ø Herzfrequenz
    final avgHr = activity.summary?.avgHr;
    if (avgHr != null && avgHr > 0) {
      items.add('${avgHr.round()} bpm');
    }

    // Energie in kcal (falls vorhanden)
    final kcal = activity.summary?.calories;
    if (kcal != null && kcal > 0) {
      items.add('${kcal.round()} kcal');
    }

    return items;
  }

  /// Formatiert Sekunden als `hh:mm:ss` (für Indoor/Kraft-Hauptmetrik).
  static String _formatHms(int totalSeconds) {
    final safeSec = totalSeconds < 0 ? 0 : totalSeconds;
    final h = safeSec ~/ 3600;
    final m = (safeSec % 3600) ~/ 60;
    final s = safeSec % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// Formatiert Sekunden kompakt als `Xh Ym` oder `Y min`.
  static String _formatShortDuration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '$m min';
  }

  /// Formatiert Lauf-Pace als `m:ss /km`.
  static String _formatRunPace(double secPerKm) {
    final total = secPerKm.round();
    final m = total ~/ 60;
    final s = total % 60;
    return '$m:${s.toString().padLeft(2, '0')} /km';
  }
}
