import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../../analysis/models/zone_distribution.dart';

/// Detaillierte Zeit-in-Zonen-Histogramme für das Analyse-Cockpit.
///
/// Unterstützt:
/// - Umschaltung zwischen Watt (Z1–Z7 Coggan), Herzfrequenz (Z1–Z5) und Pace
/// - Gestapelten Gesamtbalken & Einzellisten mit Prozent- und Zeitangaben
class ZoneDetailWidget extends StatefulWidget {
  final String title;
  final ZoneDistributionSummary summary;
  final ZoneDistributionSummary? powerSummary;
  final ZoneDistributionSummary? hrSummary;
  final ZoneDistributionSummary? paceSummary;

  const ZoneDetailWidget({
    super.key,
    required this.title,
    required this.summary,
    this.powerSummary,
    this.hrSummary,
    this.paceSummary,
  });

  @override
  State<ZoneDetailWidget> createState() => _ZoneDetailWidgetState();
}

class _ZoneDetailWidgetState extends State<ZoneDetailWidget> {
  int _selectedTab = 0; // 0: Auto/Default, 1: Power, 2: HR, 3: Pace

  @override
  Widget build(BuildContext context) {
    final hasMulti = widget.powerSummary != null ||
        widget.hrSummary != null ||
        widget.paceSummary != null;

    ZoneDistributionSummary activeSummary = widget.summary;
    if (hasMulti) {
      if (_selectedTab == 1 && widget.powerSummary != null) {
        activeSummary = widget.powerSummary!;
      } else if (_selectedTab == 2 && widget.hrSummary != null) {
        activeSummary = widget.hrSummary!;
      } else if (_selectedTab == 3 && widget.paceSummary != null) {
        activeSummary = widget.paceSummary!;
      } else if (widget.powerSummary != null) {
        activeSummary = widget.powerSummary!;
      }
    }

    if (activeSummary.zones.isEmpty || activeSummary.totalDurationSec <= 0) {
      return const SizedBox.shrink();
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: AppTypography.title
                    .copyWith(color: Colors.white, fontSize: 16),
              ),
              Text(
                'Gesamt ${_formatTotal(activeSummary.totalDurationSec)}',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ],
          ),
          if (hasMulti) ...[
            const SizedBox(height: 10),
            // Umschalt-Tabs
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.powerSummary != null) _buildTab(1, 'Watt (Z1–Z7)'),
                  if (widget.hrSummary != null) _buildTab(2, 'HF (Z1–Z5)'),
                  if (widget.paceSummary != null) _buildTab(3, 'Pace'),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Gestapelter Balken
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 10,
              child: Row(
                children: activeSummary.zones.map((z) {
                  if (z.percent <= 0) return const SizedBox.shrink();
                  return Flexible(
                    flex: (z.percent * 10).round().clamp(1, 1000),
                    child: Container(color: z.color),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Zeilen je Zone
          Column(
            children: activeSummary.zones.map((zone) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: zone.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        zone.zoneLabel,
                        style: TextStyle(
                            color: zone.color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        zone.nameDe,
                        style: TextStyle(
                            color: Colors.grey.shade300, fontSize: 12),
                      ),
                    ),
                    Text(
                      '${zone.formattedDuration} (${zone.percent.round()}%)',
                      style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label) {
    final isSelected =
        _selectedTab == index || (_selectedTab == 0 && index == 1);
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentVolt : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.navy : Colors.white70,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  String _formatTotal(double seconds) {
    final sec = seconds.round();
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    if (h > 0) return '$h h $m min';
    return '$m min';
  }
}
