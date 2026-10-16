import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';

/// Power- / Pace-Profil-Kurve (MMP) für den Analyse-Tab.
///
/// Features:
/// - Logarithmische Dauer-Achse (1s bis 60m: 1s, 5s, 15s, 30s, 1m, 3m, 5m, 12m, 20m, 60m)
/// - Vergleich „Letzte 42 Tage vs. Saison-Bestwerte"
/// - Ausgewiesene Modell-Parameter: Critical Power (CP in Watt) und W' (kJ)
class PerformanceProfileCard extends StatelessWidget {
  final Map<int, double> recentMmp; // z. B. letzte 42 Tage
  final Map<int, double> seasonMmp; // Saison-Bestwerte
  final double cpWatts;
  final double wPrimeKj;
  final double pMaxWatts;

  const PerformanceProfileCard({
    super.key,
    required this.recentMmp,
    required this.seasonMmp,
    this.cpWatts = 280.0,
    this.wPrimeKj = 20.4,
    this.pMaxWatts = 980.0,
  });

  @override
  Widget build(BuildContext context) {
    // Standard-Dauerstützpunkte
    final durationKeys = [1, 5, 15, 30, 60, 180, 300, 720, 1200, 3600];

    final effectiveRecent = recentMmp.isNotEmpty
        ? recentMmp
        : {
            1: 920.0,
            5: 780.0,
            15: 640.0,
            30: 510.0,
            60: 410.0,
            180: 345.0,
            300: 315.0,
            720: 288.0,
            1200: 275.0,
            3600: 252.0,
          };

    final effectiveSeason = seasonMmp.isNotEmpty
        ? seasonMmp
        : {
            1: 980.0,
            5: 840.0,
            15: 690.0,
            30: 550.0,
            60: 440.0,
            180: 360.0,
            300: 330.0,
            720: 300.0,
            1200: 285.0,
            3600: 260.0,
          };

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.bolt, color: Color(0xFFF59E0B), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Leistungsprofil & Critical Power (MMP)',
                    style: AppTypography.title.copyWith(color: AppColors.navy),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Modell-Karten (CP, W', Pmax)
          Row(
            children: [
              Expanded(
                child: _buildModelCard(
                  label: 'Critical Power (CP)',
                  value: '${cpWatts.round()} W',
                  subtitle: 'Aerobe Dauerleistung',
                  color: const Color(0xFF00D2FF),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildModelCard(
                  label: "W' (Reserve)",
                  value: '${wPrimeKj.toStringAsFixed(1)} kJ',
                  subtitle: 'Anaerobe Arbeitskapazität',
                  color: const Color(0xFFF43F5E),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildModelCard(
                  label: 'Pmax (Peak)',
                  value: '${pMaxWatts.round()} W',
                  subtitle: 'Sprint-Maximalleistung',
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Legende
          Row(
            children: [
              _buildLegend(const Color(0xFF00D2FF), 'Letzte 42 Tage'),
              const SizedBox(width: 16),
              _buildLegend(const Color(0xFFF59E0B), 'Saison-Bestwerte'),
            ],
          ),
          const SizedBox(height: 12),

          // Logarithmischer MMP-Graph
          SizedBox(
            height: 150,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return CustomPaint(
                  size: Size(constraints.maxWidth, 150),
                  painter: _MmpCurvePainter(
                    durations: durationKeys,
                    recentMmp: effectiveRecent,
                    seasonMmp: effectiveSeason,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),

          // Dauer-Achsenbeschriftung
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('1s', style: TextStyle(color: Colors.grey, fontSize: 10)),
              Text('15s', style: TextStyle(color: Colors.grey, fontSize: 10)),
              Text('1m', style: TextStyle(color: Colors.grey, fontSize: 10)),
              Text('5m', style: TextStyle(color: Colors.grey, fontSize: 10)),
              Text('20m', style: TextStyle(color: Colors.grey, fontSize: 10)),
              Text('60m', style: TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModelCard({
    required String label,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.navy.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTypography.label.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.navy,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _MmpCurvePainter extends CustomPainter {
  final List<int> durations;
  final Map<int, double> recentMmp;
  final Map<int, double> seasonMmp;

  _MmpCurvePainter({
    required this.durations,
    required this.recentMmp,
    required this.seasonMmp,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (durations.isEmpty) return;

    final w = size.width;
    final h = size.height;

    // Logarithmische x-Achsen-Skalierung: log(1) = 0 bis log(3600)
    final minLog = log(durations.first.toDouble());
    final maxLog = log(durations.last.toDouble());
    final logRange = maxLog - minLog;

    // Max Watt Skalierung
    final maxWatt = [
      ...recentMmp.values,
      ...seasonMmp.values,
    ].fold(0.0, max);
    final scaleWatt = maxWatt > 0 ? maxWatt * 1.1 : 1000.0;

    // Horizontale Hilfslinien
    final gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, h * 0.25), Offset(w, h * 0.25), gridPaint);
    canvas.drawLine(Offset(0, h * 0.50), Offset(w, h * 0.50), gridPaint);
    canvas.drawLine(Offset(0, h * 0.75), Offset(w, h * 0.75), gridPaint);

    double mapX(int d) {
      final logD = log(max(1.0, d.toDouble()));
      return ((logD - minLog) / logRange) * w;
    }

    double mapY(double watt) {
      return h - (watt / scaleWatt) * (h - 10);
    }

    // 1. Saison-Bestwerte (Gold)
    _drawCurve(
      canvas: canvas,
      durations: durations,
      mmpMap: seasonMmp,
      mapX: mapX,
      mapY: mapY,
      color: const Color(0xFFF59E0B),
      strokeWidth: 2.2,
    );

    // 2. Letzte 42 Tage (Cyan)
    _drawCurve(
      canvas: canvas,
      durations: durations,
      mmpMap: recentMmp,
      mapX: mapX,
      mapY: mapY,
      color: const Color(0xFF00D2FF),
      strokeWidth: 2.5,
    );
  }

  void _drawCurve({
    required Canvas canvas,
    required List<int> durations,
    required Map<int, double> mmpMap,
    required double Function(int) mapX,
    required double Function(double) mapY,
    required Color color,
    required double strokeWidth,
  }) {
    final path = Path();
    bool started = false;

    for (final d in durations) {
      final watt = mmpMap[d];
      if (watt != null && watt > 0) {
        final x = mapX(d);
        final y = mapY(watt);
        if (!started) {
          path.moveTo(x, y);
          started = true;
        } else {
          path.lineTo(x, y);
        }
      }
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MmpCurvePainter oldDelegate) {
    return oldDelegate.durations != durations ||
        oldDelegate.recentMmp != recentMmp ||
        oldDelegate.seasonMmp != seasonMmp;
  }
}
