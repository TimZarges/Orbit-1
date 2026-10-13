import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';

/// Platzhalter-Karte für Schwellenwerte und Diagnostik (wird in Phase 12 ausgebaut).
class ThresholdProgressCard extends StatelessWidget {
  final double? ftpW;
  final double? thresholdHrBpm;
  final double? cssSecPer100m;

  const ThresholdProgressCard({
    super.key,
    this.ftpW,
    this.thresholdHrBpm,
    this.cssSecPer100m,
  });

  @override
  Widget build(BuildContext context) {
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
          // Kopfzeile
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.tune_outlined, size: 20, color: AppColors.navy),
                  const SizedBox(width: 8),
                  Text(
                    'Aktuelle Schwellenwerte',
                    style: AppTypography.title.copyWith(color: AppColors.navy),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.techGrey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Phase 12',
                  style: AppTypography.label.copyWith(
                    color: Colors.grey.shade600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Schwellen-Grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ThresholdItem(
                label: 'Rad FTP',
                value: ftpW != null && ftpW! > 0 ? '${ftpW!.round()} W' : '250 W',
                icon: Icons.directions_bike,
                color: AppColors.sportBike,
              ),
              _ThresholdItem(
                label: 'Schwellen-HF',
                value: thresholdHrBpm != null && thresholdHrBpm! > 0
                    ? '${thresholdHrBpm!.round()} bpm'
                    : '168 bpm',
                icon: Icons.favorite_border,
                color: const Color(0xFFFF6B6B),
              ),
              _ThresholdItem(
                label: 'Schwimm-CSS',
                value: cssSecPer100m != null && cssSecPer100m! > 0
                    ? _formatCss(cssSecPer100m!)
                    : '1:45 /100m',
                icon: Icons.pool,
                color: AppColors.sportSwim,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Hinweis auf Phase 12
          Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Automatische Erkennung neuer Schwellenwerte und Diagnostik folgen in Phase 12.',
                  style: AppTypography.label.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCss(double sec) {
    final m = sec ~/ 60;
    final s = (sec % 60).round();
    return '$m:${s.toString().padLeft(2, '0')} /100m';
  }
}

class _ThresholdItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _ThresholdItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: AppTypography.label.copyWith(color: Colors.grey.shade600)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.title.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.navy,
          ),
        ),
      ],
    );
  }
}
