import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../../calendar/models/planned_workout.dart';
import '../models/daily_metrics.dart';

/// Die zentrale 3-Ringe-Hero-Card auf Deep-Navy-Hintergrund (#001F47) aus Phase 21.
///
/// Zeigt:
/// 1. Äußerer Ring: ORBIT Erholung (0–100 %) in Ampelfarbe (Grün/Gelb/Rot)
/// 2. Mittlerer Ring: ORBIT Tagesbelastung (0–100) in Amber mit markiertem Zielkorridor
/// 3. Innerer Ring: ORBIT Schlaf-Score (0–100 %) in Cyan
/// 4. ORBIT Gesamt-Score Badge (0–100) im Zentrum
/// 5. Datenbasierte Tages-Empfehlung & Graceful-Degradation-Hinweis
/// 6. Direktes Antippen des geplanten Workouts (falls vorhanden)
class ThreeRingsHeroCard extends StatefulWidget {
  final DailyMetrics? dailyMetrics;
  final double actualLoad;
  final PlannedWorkout? plannedWorkout;
  final VoidCallback? onWorkoutTap;
  final VoidCallback? onOpenHealthCockpit;

  const ThreeRingsHeroCard({
    super.key,
    this.dailyMetrics,
    required this.actualLoad,
    this.plannedWorkout,
    this.onWorkoutTap,
    this.onOpenHealthCockpit,
  });

  @override
  State<ThreeRingsHeroCard> createState() => _ThreeRingsHeroCardState();
}

class _ThreeRingsHeroCardState extends State<ThreeRingsHeroCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Color _getRecoveryColor(String classification) {
    switch (classification) {
      case 'GREEN':
        return AppColors.emerald;
      case 'RED':
        return AppColors.coral;
      case 'YELLOW':
      default:
        return AppColors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final metrics = widget.dailyMetrics;
    final recoveryScore = metrics?.effectiveRecoveryScore ?? 65;
    final classification = metrics?.recoveryTrafficLight ?? 'GREEN';
    final recoveryColor = _getRecoveryColor(classification);

    final strainScore = metrics?.effectiveStrainScore ??
        (widget.actualLoad > 0 ? (widget.actualLoad * 0.4).round() : 0);
    final targetMin = metrics?.strainTargetMin ?? 50;
    final targetMax = metrics?.strainTargetMax ?? 75;

    final sleepScore = metrics?.effectiveSleepScore ?? 80;
    final orbitScore = metrics?.effectiveOrbitScore ?? 78;
    final recommendation = metrics?.recoveryRecommendation ??
        'Exzellente Erholung. Bereit für Schwellenintervalle und intensive Einheiten.';
    final isGraceful = metrics?.hasGracefulDegradation ?? false;

    final hasPlan = widget.plannedWorkout != null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.navy, // Zwingend Deep Navy (#001F47)
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1E293B)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Kopfbereich: Titel & ORBIT Score Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HEUTE',
                    style: AppTypography.label.copyWith(
                      color: AppColors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Tagesform & Ringe',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // ORBIT Gesamt-Score Badge
              InkWell(
                onTap: widget.onOpenHealthCockpit,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.navyLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.volt.withValues(alpha: 0.8),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'ORBIT ',
                        style: TextStyle(
                          color: AppColors.volt,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '$orbitScore',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 2. Die 3 animierten Ringe & Detail-Werte
          AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              return Row(
                children: [
                  // 3 Ringe Custom Paint
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: CustomPaint(
                      painter: _ThreeRingsPainter(
                        recoveryRatio:
                            (recoveryScore / 100.0) * _animation.value,
                        recoveryColor: recoveryColor,
                        strainRatio: (strainScore / 100.0) * _animation.value,
                        strainTargetMinRatio: targetMin / 100.0,
                        strainTargetMaxRatio: targetMax / 100.0,
                        sleepRatio: (sleepScore / 100.0) * _animation.value,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              classification == 'GREEN'
                                  ? Icons.bolt
                                  : (classification == 'RED'
                                      ? Icons.battery_alert
                                      : Icons.battery_charging_full),
                              color: recoveryColor,
                              size: 20,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$recoveryScore%',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Ring-Legende & Kennzahlen
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Erholung
                        _buildRingLegendRow(
                          label: 'Erholung',
                          value: '$recoveryScore %',
                          color: recoveryColor,
                          subtext: classification == 'GREEN'
                              ? 'Bereit für Belastung'
                              : (classification == 'RED'
                                  ? 'Regeneration nötig'
                                  : 'Moderat trainieren'),
                        ),
                        const SizedBox(height: 10),

                        // Tagesbelastung mit Zielkorridor
                        _buildRingLegendRow(
                          label: 'Tagesbelastung',
                          value: '$strainScore',
                          color: AppColors.amber,
                          subtext: 'Ziel: $targetMin–$targetMax',
                        ),
                        const SizedBox(height: 10),

                        // Schlaf
                        _buildRingLegendRow(
                          label: 'Schlaf-Score',
                          value: '$sleepScore %',
                          color: AppColors.cyan,
                          subtext: metrics?.formattedSleepDuration != null
                              ? '${metrics!.formattedSleepDuration} geschlafen'
                              : 'Erholt aufgewacht',
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          // 3. Datenbasierte Tages-Empfehlung
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0A1128), // Sehr dunkles Blau
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: recoveryColor,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    recommendation,
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. Graceful Degradation Hinweis (falls z. B. keine HRV erfasst wurde)
          if (isGraceful) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 13,
                  color: AppColors.white.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Berechnet aus Ruhepuls & Schlaf (keine nächtliche HRV)',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.white.withValues(alpha: 0.5),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // 5. Heutiges Training (falls vorhanden)
          if (hasPlan) ...[
            const SizedBox(height: 16),
            const Divider(color: Color(0xFF1E293B), height: 1),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: _getSportColor(widget.plannedWorkout!.sport)
                        .withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getSportIcon(widget.plannedWorkout!.sport),
                    color: _getSportColor(widget.plannedWorkout!.sport),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.plannedWorkout!.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_formatDuration(widget.plannedWorkout!.plannedDurationSec)}'
                        '${widget.plannedWorkout!.plannedLoad != null ? " · ${widget.plannedWorkout!.plannedLoad!.round()} TSS" : ""}',
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: widget.onWorkoutTap,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.volt,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Details'),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_forward_ios, size: 12),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRingLegendRow({
    required String label,
    required String value,
    required Color color,
    required String subtext,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 3),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 1),
              Text(
                subtext,
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getSportColor(String sport) {
    switch (sport.toUpperCase()) {
      case 'BIKE':
      case 'CYCLING':
        return AppColors.amber;
      case 'RUN':
      case 'RUNNING':
        return AppColors.cyan;
      case 'SWIM':
      case 'SWIMMING':
        return const Color(0xFF38BDF8);
      default:
        return AppColors.volt;
    }
  }

  IconData _getSportIcon(String sport) {
    switch (sport.toUpperCase()) {
      case 'BIKE':
      case 'CYCLING':
        return Icons.directions_bike;
      case 'RUN':
      case 'RUNNING':
        return Icons.directions_run;
      case 'SWIM':
      case 'SWIMMING':
        return Icons.pool;
      default:
        return Icons.fitness_center;
    }
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

/// CustomPainter für die 3 konzentrischen Ringe mit Zielkorridor-Markierung.
class _ThreeRingsPainter extends CustomPainter {
  final double recoveryRatio;
  final Color recoveryColor;
  final double strainRatio;
  final double strainTargetMinRatio;
  final double strainTargetMaxRatio;
  final double sleepRatio;

  _ThreeRingsPainter({
    required this.recoveryRatio,
    required this.recoveryColor,
    required this.strainRatio,
    required this.strainTargetMinRatio,
    required this.strainTargetMaxRatio,
    required this.sleepRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 9.0;
    const spacing = 4.0;
    const startAngle = -math.pi / 2; // Oben (12 Uhr)

    // Radien:
    // Äußerer Ring: Erholung
    final rRecovery = (size.width / 2) - (strokeWidth / 2);
    // Mittlerer Ring: Tagesbelastung
    final rStrain = rRecovery - strokeWidth - spacing;
    // Innerer Ring: Schlaf
    final rSleep = rStrain - strokeWidth - spacing;

    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // 1. Äußerer Ring: Erholung
    bgPaint.color = recoveryColor.withValues(alpha: 0.18);
    canvas.drawCircle(center, rRecovery, bgPaint);

    final recoveryPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = recoveryColor;
    final sweepRecovery = 2 * math.pi * recoveryRatio.clamp(0.001, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: rRecovery),
      startAngle,
      sweepRecovery,
      false,
      recoveryPaint,
    );

    // 2. Mittlerer Ring: Tagesbelastung & Zielkorridor
    bgPaint.color = AppColors.amber.withValues(alpha: 0.18);
    canvas.drawCircle(center, rStrain, bgPaint);

    // Zielkorridor-Markierung auf dem Hintergrund-Ring
    final targetStartAngle =
        startAngle + (2 * math.pi * strainTargetMinRatio.clamp(0.0, 1.0));
    final targetSweep = 2 *
        math.pi *
        (strainTargetMaxRatio - strainTargetMinRatio).clamp(0.0, 1.0);
    final targetPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 2
      ..strokeCap = StrokeCap.butt
      ..color = AppColors.amber.withValues(alpha: 0.40);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: rStrain),
      targetStartAngle,
      targetSweep,
      false,
      targetPaint,
    );

    // Aktueller Belastungs-Bogen
    final strainPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = AppColors.amber;
    final sweepStrain = 2 * math.pi * strainRatio.clamp(0.001, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: rStrain),
      startAngle,
      sweepStrain,
      false,
      strainPaint,
    );

    // 3. Innerer Ring: Schlaf-Score
    bgPaint.color = AppColors.cyan.withValues(alpha: 0.18);
    canvas.drawCircle(center, rSleep, bgPaint);

    final sleepPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = AppColors.cyan;
    final sweepSleep = 2 * math.pi * sleepRatio.clamp(0.001, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: rSleep),
      startAngle,
      sweepSleep,
      false,
      sleepPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ThreeRingsPainter oldDelegate) {
    return oldDelegate.recoveryRatio != recoveryRatio ||
        oldDelegate.recoveryColor != recoveryColor ||
        oldDelegate.strainRatio != strainRatio ||
        oldDelegate.sleepRatio != sleepRatio;
  }
}
