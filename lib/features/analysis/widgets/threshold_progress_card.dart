import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../../diagnostics/providers/diagnostics_providers.dart';

/// Karte für Schwellenwerte und Diagnostik im Analyse-Tab.
class ThresholdProgressCard extends ConsumerWidget {
  final String? athleteId;
  final double? ftpW;
  final double? thresholdHrBpm;
  final double? cssSecPer100m;

  const ThresholdProgressCard({
    super.key,
    this.athleteId,
    this.ftpW,
    this.thresholdHrBpm,
    this.cssSecPer100m,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveAthleteId = athleteId ?? 'demo';
    final proposalsAsync = ref.watch(pendingProposalsProvider(effectiveAthleteId));
    final historyAsync = ref.watch(thresholdHistoryProvider(effectiveAthleteId));

    final pendingCount = proposalsAsync.asData?.value.length ?? 0;
    final latestHistory = historyAsync.asData?.value.isNotEmpty == true
        ? historyAsync.asData!.value.last
        : null;

    final currentFtp = latestHistory?.ftpW ?? ftpW ?? 260.0;
    final currentHr = latestHistory?.thresholdHrBpm ?? thresholdHrBpm ?? 168.0;
    final currentCss = latestHistory?.swimCssSecPer100m ?? cssSecPer100m ?? 105.0;

    return InkWell(
      onTap: () {
        context.push('/diagnostics?athleteId=$effectiveAthleteId');
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
                      'Schwellenwerte & Diagnostik',
                      style: AppTypography.title.copyWith(color: AppColors.navy),
                    ),
                  ],
                ),
                Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
              ],
            ),
            const SizedBox(height: 14),

            // Schwellen-Grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ThresholdItem(
                  label: 'Rad FTP',
                  value: '${currentFtp.round()} W',
                  icon: Icons.directions_bike,
                  color: AppColors.sportBike,
                ),
                _ThresholdItem(
                  label: 'Schwellen-HF',
                  value: '${currentHr.round()} bpm',
                  icon: Icons.favorite_border,
                  color: const Color(0xFFFF6B6B),
                ),
                _ThresholdItem(
                  label: 'Schwimm-CSS',
                  value: _formatCss(currentCss),
                  icon: Icons.pool,
                  color: AppColors.sportSwim,
                ),
              ],
            ),

            if (pendingCount > 0) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.volt.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.volt),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 16, color: AppColors.navy),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$pendingCount neuer Schwellenwert-Vorschlag verfügbar',
                        style: AppTypography.label.copyWith(
                          color: AppColors.navy,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      'Prüfen',
                      style: AppTypography.label.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.insights, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Tippen für Details, Vorschläge und geführte Feldtests.',
                      style: AppTypography.label.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
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
