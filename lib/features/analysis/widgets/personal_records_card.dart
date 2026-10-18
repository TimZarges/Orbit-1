import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../models/personal_record.dart';

/// Interaktive PR-Datenbank mit Power- & Pace-Duration-Kurven im ORBIT Dark Cockpit (Phase 31.4).
///
/// Features:
/// - Sportarten-Tabs: Rad, Lauf, Schwimmen
/// - Zeiträume: Allzeit, 2026, Letzte 90 Tage
/// - Rad: Watt & W/kg über 5s, 15s, 30s, 1m, 3m, 5m, 10m, 20m, 60m, 90m, 180m
/// - Lauf: 400m, 1km, 3km, 5km, 10km, Halbmarathon, Marathon
/// - Schwimmen: 100m, 200m, 400m, 800m, 1500m
/// - Visuelle Power-Duration-Kurve mit logarithmischer Dauer-Achse
class PersonalRecordsCard extends StatefulWidget {
  final PersonalRecordsSummary? summary;

  const PersonalRecordsCard({
    super.key,
    this.summary,
  });

  @override
  State<PersonalRecordsCard> createState() => _PersonalRecordsCardState();
}

class _PersonalRecordsCardState extends State<PersonalRecordsCard> {
  PRSport _selectedSport = PRSport.bike;
  PRTimeframe _selectedTimeframe = PRTimeframe.allTime;
  late final PersonalRecordsSummary _summary;

  @override
  void initState() {
    super.initState();
    _summary = widget.summary ?? PersonalRecordsSummary.demo();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('personal_records_card'),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF003875)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header mit Titel und Trophäen-Icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.volt.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.volt.withValues(alpha: 0.4),
                  ),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: AppColors.volt,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PR-Datenbank',
                      style: AppTypography.title.copyWith(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Bestleistungen',
                      style: AppTypography.label.copyWith(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // Zeitfilter-Chips
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF003875)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: PRTimeframe.values.map((tf) {
                    final isSelected = _selectedTimeframe == tf;
                    final displayLabel =
                        tf == PRTimeframe.last90Days ? '90 Tage' : tf.label;
                    return InkWell(
                      key: Key('pr_timeframe_${tf.name}'),
                      onTap: () => setState(() => _selectedTimeframe = tf),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected ? AppColors.volt : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          displayLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? AppColors.navy : Colors.white70,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Sportarten-Umschalter
          Row(
            children: PRSport.values.map((sport) {
              final isSelected = _selectedSport == sport;
              final icon = sport == PRSport.bike
                  ? Icons.directions_bike
                  : sport == PRSport.run
                      ? Icons.directions_run
                      : Icons.pool;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: InkWell(
                    key: Key('pr_sport_${sport.name}'),
                    onTap: () => setState(() => _selectedSport = sport),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.volt.withValues(alpha: 0.15)
                            : AppColors.navy,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.volt
                              : const Color(0xFF003875),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icon,
                            size: 16,
                            color: isSelected ? AppColors.volt : Colors.white70,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            sport.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color:
                                  isSelected ? AppColors.volt : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Inhalt je nach Sportart
          if (_selectedSport == PRSport.bike) ...[
            _buildBikeSection(),
          ] else if (_selectedSport == PRSport.run) ...[
            _buildRunSection(),
          ] else ...[
            _buildSwimSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildBikeSection() {
    final prs = _summary.getBike(_selectedTimeframe);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Power-Duration Kurven-Preview
        Container(
          height: 130,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF003875)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Power-Duration-Kurve (${_selectedTimeframe.label})',
                    style: AppTypography.label.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '5s..180m',
                    style: AppTypography.label.copyWith(
                      color: AppColors.volt,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(
                child: CustomPaint(
                  painter: _BikeCurvePainter(prs: prs),
                  child: Container(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Grid aller Stützpunkte
        GridView.builder(
          key: const Key('pr_bike_grid'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: prs.length,
          itemBuilder: (context, index) {
            final pr = prs[index];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF003875)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.volt.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          pr.durationLabel,
                          style: const TextStyle(
                            color: AppColors.volt,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        pr.formattedDate,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${pr.watts.round()} W',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${pr.wattsPerKg.toStringAsFixed(1)} W/kg',
                        style: const TextStyle(
                          color: AppColors.volt,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRunSection() {
    final prs = _summary.getRun(_selectedTimeframe);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          key: const Key('pr_run_grid'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: prs.length,
          itemBuilder: (context, index) {
            final pr = prs[index];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF003875)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.sportRun.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          pr.distanceLabel,
                          style: const TextStyle(
                            color: AppColors.sportRun,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        pr.formattedDate,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        pr.formattedTime,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        pr.formattedPace,
                        style: const TextStyle(
                          color: AppColors.volt,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSwimSection() {
    final prs = _summary.getSwim(_selectedTimeframe);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          key: const Key('pr_swim_grid'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: prs.length,
          itemBuilder: (context, index) {
            final pr = prs[index];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF003875)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.sportSwim.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          pr.distanceLabel,
                          style: const TextStyle(
                            color: AppColors.sportSwim,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        pr.formattedDate,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        pr.formattedTime,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        pr.formattedPace,
                        style: const TextStyle(
                          color: AppColors.volt,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

/// CustomPainter für eine saubere logarithmische Power-Duration Kurve.
class _BikeCurvePainter extends CustomPainter {
  final List<BikePR> prs;

  _BikeCurvePainter({required this.prs});

  @override
  void paint(Canvas canvas, Size size) {
    if (prs.length < 2) return;

    final maxW = prs.map((p) => p.watts).reduce(max);
    final minW = prs.map((p) => p.watts).reduce(min);

    // Logarithmische X-Skala (5s bis 10800s)
    final logMin = log(5.0);
    final logMax = log(10800.0);
    final logRange = logMax - logMin;

    final gridPaint = Paint()
      ..color = const Color(0xFF003875).withValues(alpha: 0.5)
      ..strokeWidth = 1.0;

    // Horizontale Hilfslinien
    for (int i = 1; i <= 3; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < prs.length; i++) {
      final pr = prs[i];
      final logVal = log(pr.durationSec.toDouble());
      final x = ((logVal - logMin) / logRange) * size.width;
      final y = size.height -
          ((pr.watts - minW * 0.8) / (maxW * 1.05 - minW * 0.8)) * size.height;
      final offset =
          Offset(x.clamp(0.0, size.width), y.clamp(0.0, size.height));
      points.add(offset);

      if (i == 0) {
        path.moveTo(offset.dx, offset.dy);
      } else {
        path.lineTo(offset.dx, offset.dy);
      }
    }

    // Volt-Pfad zeichnen
    final curvePaint = Paint()
      ..color = AppColors.volt
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, curvePaint);

    // Punkte auf der Kurve
    final dotPaint = Paint()
      ..color = AppColors.volt
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = AppColors.navy
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final pt in points) {
      canvas.drawCircle(pt, 3.5, dotPaint);
      canvas.drawCircle(pt, 3.5, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BikeCurvePainter oldDelegate) =>
      oldDelegate.prs != prs;
}
