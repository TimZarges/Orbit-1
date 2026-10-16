import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../models/activity.dart';

/// Kompakte Karte für Aerobe Effizienz (NP, IF, VI, EF),
/// Aerobic Decoupling (%) mit Ampel-Farbe und Brick-Analyse-Badge.
class AerobicEfficiencyBadge extends StatelessWidget {
  final Activity activity;

  const AerobicEfficiencyBadge({
    super.key,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    final m = activity.metrics;
    final summary = activity.summary;

    final np = m?.np ?? summary?.avgPowerW;
    final iff = m?.iff;
    final vi = m?.vi;
    final ef = m?.ef;
    final decoupling = m?.aerobicDecouplingPercent;
    final brickPaceDrop = m?.brickPaceDropSecPerKm;

    // Decoupling Ampelfarbe & Status
    final Color decouplingColor;
    final String decouplingLabel;
    if (decoupling != null) {
      if (decoupling < 5.0) {
        decouplingColor = const Color(0xFF10B981); // Emerald / Grün
        decouplingLabel = 'Gekoppelt (< 5%)';
      } else if (decoupling <= 8.0) {
        decouplingColor = const Color(0xFFF59E0B); // Amber / Gelb
        decouplingLabel = 'Moderat (5–8%)';
      } else {
        decouplingColor = const Color(0xFFEF4444); // Rot
        decouplingLabel = 'Entkoppelt (> 8%)';
      }
    } else {
      decouplingColor = Colors.grey.shade400;
      decouplingLabel = 'Nicht ermittelt';
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF001F47), // Dark Navy Look
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (Wrap für perfekte Responsivität bei schmalen Screens und Textskalierung)
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.speed,
                      color: AppColors.accentVolt, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Aerobe Effizienz & Belastung',
                    style: AppTypography.title.copyWith(color: Colors.white),
                  ),
                ],
              ),
              if (decoupling != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: decouplingColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: decouplingColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: decouplingColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${decoupling >= 0 ? "+" : ""}${decoupling.toStringAsFixed(1)} % $decouplingLabel',
                        style: TextStyle(
                          color: decouplingColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Metriken-Grid (NP, IF, VI, EF)
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: activity.sport.toUpperCase() == 'RUN' ? 'NGP' : 'NP',
                  value: np != null ? '${np.round()} W' : '–',
                  subtitle: 'Normalized Power',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'IF',
                  value: iff != null ? iff.toStringAsFixed(2) : '–',
                  subtitle: 'Intensity Factor',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'VI',
                  value: vi != null ? vi.toStringAsFixed(2) : '1.00',
                  subtitle: 'Variability Index',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'EF',
                  value: ef != null ? ef.toStringAsFixed(2) : '–',
                  subtitle: 'Efficiency Factor',
                ),
              ),
            ],
          ),

          // Brick-Koppeltrainings-Badge
          if (brickPaceDrop != null ||
              activity.sport.toUpperCase() == 'TRIATHLON' ||
              activity.sport.toUpperCase() == 'DUATHLON') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.directions_run,
                      color: Color(0xFF22D3EE), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Brick-Analyse (Koppellauf):',
                    style: TextStyle(
                      color: Colors.grey.shade300,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      brickPaceDrop != null
                          ? '${brickPaceDrop >= 0 ? "+" : ""}${brickPaceDrop.round()} s/km (Pace-Abfall auf 0–2 km)'
                          : 'Pace stabil',
                      style: const TextStyle(
                        color: Color(0xFF22D3EE),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.accentVolt,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}
