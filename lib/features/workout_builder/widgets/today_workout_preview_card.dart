import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../calendar/domain/workout_block_extractor.dart';
import '../../calendar/domain/workout_compliance_evaluator.dart';
import '../../calendar/models/planned_workout.dart';
import '../domain/workout_calculator.dart';

/// Visuelle Block-Vorschau-Karte für das heutige Training auf dem „Heute“-Tab.
///
/// Zeigt:
/// - Titel, Sportart, geplante Dauer und Belastung (TSS)
/// - Konkrete Schwellenwerte (z. B. 95–100 % FTP = 320–337 W bei FTP 337 W)
/// - Visuelles Stufen-Balkendiagramm der Workout-Blöcke
/// - Soll-/Ist-Erfüllungs-Ampel bei absolvierten Einheiten (Grün <= 15 %, Gelb 15–35 %, Rot > 35 %)
class TodayWorkoutPreviewCard extends StatelessWidget {
  final PlannedWorkout workout;
  final num? ftpWatts;
  final num? fthrBpm;
  final int? actualDurationSec;
  final double? actualLoad;
  final VoidCallback? onTap;

  const TodayWorkoutPreviewCard({
    super.key,
    required this.workout,
    this.ftpWatts,
    this.fthrBpm,
    this.actualDurationSec,
    this.actualLoad,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sportColor = _getSportColor(workout.sport);
    final blocks = _extractBlocks();
    final targetLabel = _formatTargetIntensity(workout, ftpWatts, fthrBpm);

    // Soll-/Ist-Ampel evaluieren falls abgeschlossen oder Ist-Werte vorhanden
    WorkoutComplianceResult? compliance;
    if (workout.isCompleted ||
        (actualDurationSec != null && actualDurationSec! > 0)) {
      compliance = WorkoutComplianceEvaluator.evaluate(
        plannedDurationSec: workout.plannedDurationSec,
        plannedLoad: workout.plannedLoad,
        actualDurationSec: actualDurationSec ?? workout.plannedDurationSec,
        actualLoad: actualLoad ?? workout.plannedLoad,
        isCompleted: true,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF002A5C), // Navy Card
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: compliance != null
              ? compliance.statusColor.withValues(alpha: 0.6)
              : const Color(0xFF003D82),
          width: compliance != null ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Kopfzeile: Sportart-Icon, Titel & Status/Ampel-Badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: sportColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_getSportIcon(workout.sport),
                          color: sportColor, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            workout.title,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${workout.formattedDuration}'
                            '${workout.plannedLoad != null ? " · ${workout.plannedLoad!.round()} Load" : ""}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (compliance != null)
                      _buildComplianceBadge(compliance)
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.volt.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.volt.withValues(alpha: 0.5)),
                        ),
                        child: const Text(
                          'GEPLANT',
                          style: TextStyle(
                            color: AppColors.volt,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Konkrete Zielwert-Berechnung (z. B. 95-100% FTP = 320-337 W)
                if (targetLabel.isNotEmpty) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.speed,
                            size: 14, color: AppColors.volt),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            targetLabel,
                            style: const TextStyle(
                              color: AppColors.volt,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Visuelles Stufen-Balkendiagramm der Trainingsblöcke
                _buildBlockProfileBar(blocks),

                // Detaillierter Erfüllungs-Hinweis bei Abschluss
                if (compliance != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        compliance.isGreen
                            ? Icons.check_circle_outline
                            : (compliance.isYellow
                                ? Icons.info_outline
                                : Icons.warning_amber),
                        size: 14,
                        color: compliance.statusColor,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          compliance.statusDetail,
                          style: TextStyle(
                            color: compliance.statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComplianceBadge(WorkoutComplianceResult compliance) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: compliance.statusColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: compliance.statusColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: compliance.statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            compliance.statusLabel.toUpperCase(),
            style: TextStyle(
              color: compliance.statusColor,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockProfileBar(List<_PreviewBlock> blocks) {
    if (blocks.isEmpty) {
      return Container(
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: const Text(
          'Grundlageneinheit (GA1)',
          style: TextStyle(color: Colors.white60, fontSize: 11),
        ),
      );
    }

    final totalDuration = blocks.fold<int>(0, (sum, b) => sum + b.durationSec);

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF001F47), // Deep Navy
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF003D82)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: blocks.map((b) {
          final flex = totalDuration > 0
              ? ((b.durationSec / totalDuration) * 100).round().clamp(1, 100)
              : 1;
          final heightFraction = (b.zone / 7.0).clamp(0.28, 1.0);

          return Expanded(
            flex: flex,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              height: 38 * heightFraction,
              decoration: BoxDecoration(
                color: b.color,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(3)),
              ),
              alignment: Alignment.center,
              child: flex > 10
                  ? Text(
                      'Z${b.zone}',
                      style: TextStyle(
                        color: b.zone >= 4 ? Colors.black : Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    )
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  List<_PreviewBlock> _extractBlocks() {
    final extracted = WorkoutBlockExtractor.extractSteps(
      workout,
      thresholds: AthleteThresholds(
        ftp: ftpWatts?.toDouble(),
        lthr: fthrBpm?.toInt(),
      ),
    );

    if (extracted.isEmpty) {
      final duration =
          workout.plannedDurationSec > 0 ? workout.plannedDurationSec : 3600;
      final warmup = (duration * 0.15).round();
      final cooldown = (duration * 0.15).round();
      final main = duration - warmup - cooldown;

      return [
        _PreviewBlock(durationSec: warmup, zone: 1, color: AppColors.zone1),
        _PreviewBlock(durationSec: main, zone: 2, color: AppColors.zone2),
        _PreviewBlock(durationSec: cooldown, zone: 1, color: AppColors.zone1),
      ];
    }

    return extracted
        .map((s) => _PreviewBlock(
              durationSec: s.durationSec,
              zone: s.zone,
              color: s.color,
            ))
        .toList();
  }

  String _formatTargetIntensity(PlannedWorkout workout, num? ftp, num? fthr) {
    if (workout.sport == 'BIKE' && ftp != null && ftp > 0) {
      if (workout.title.toLowerCase().contains('intervall') ||
          workout.title.toLowerCase().contains('vo2') ||
          workout.title.toLowerCase().contains('schwell')) {
        final lowW = (ftp * 0.95).round();
        final highW = (ftp * 1.05).round();
        return 'Ziel: 95–105 % FTP = $lowW–$highW W (FTP: ${ftp.round()} W)';
      } else {
        final lowW = (ftp * 0.65).round();
        final highW = (ftp * 0.75).round();
        return 'Ziel: 65–75 % FTP = $lowW–$highW W (Grundlage GA1)';
      }
    } else if (workout.sport == 'RUN' && fthr != null && fthr > 0) {
      final lowHr = (fthr * 0.75).round();
      final highHr = (fthr * 0.85).round();
      return 'Ziel: 75–85 % FTHR = $lowHr–$highHr bpm (Lauf-Grundlage)';
    }
    return '';
  }

  Color _getSportColor(String sport) {
    switch (sport.toUpperCase()) {
      case 'BIKE':
        return AppColors.sportBike;
      case 'RUN':
        return AppColors.sportRun;
      case 'SWIM':
        return AppColors.sportSwim;
      case 'STRENGTH':
        return AppColors.sportStrength;
      default:
        return const Color(0xFF94A3B8);
    }
  }

  IconData _getSportIcon(String sport) {
    switch (sport.toUpperCase()) {
      case 'BIKE':
        return Icons.directions_bike;
      case 'RUN':
        return Icons.directions_run;
      case 'SWIM':
        return Icons.pool;
      case 'STRENGTH':
        return Icons.fitness_center;
      default:
        return Icons.sports;
    }
  }
}

class _PreviewBlock {
  final int durationSec;
  final int zone;
  final Color color;

  const _PreviewBlock({
    required this.durationSec,
    required this.zone,
    required this.color,
  });
}
