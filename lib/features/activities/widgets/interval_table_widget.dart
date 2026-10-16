import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../models/activity.dart';

/// Intervall-Tabelle für das Aktivitäts-Cockpit.
///
/// Unterstützt:
/// - Umschaltung zwischen manuellen Runden ([laps]) und automatisch erkannten Intervallen ([autoIntervals])
/// - Spalten: Intervall #, Dauer, Distanz, Ø Watt / Pace, NP/NGP, Ø HF, Efficiency Factor (EF)
class IntervalTableWidget extends StatefulWidget {
  final List<ActivityLapData> laps;
  final List<ActivityLapData> autoIntervals;
  final String sport;

  const IntervalTableWidget({
    super.key,
    required this.laps,
    required this.autoIntervals,
    this.sport = 'BIKE',
  });

  @override
  State<IntervalTableWidget> createState() => _IntervalTableWidgetState();
}

class _IntervalTableWidgetState extends State<IntervalTableWidget> {
  bool _showAutoIntervals = false;

  @override
  Widget build(BuildContext context) {
    final hasLaps = widget.laps.isNotEmpty;
    final hasAuto = widget.autoIntervals.isNotEmpty;

    // Wenn keine manuellen Runden vorliegen, aber Auto-Intervalle vorhanden sind, schalte standardmäßig auf Auto
    final currentList = (_showAutoIntervals || !hasLaps)
        ? (hasAuto ? widget.autoIntervals : widget.laps)
        : widget.laps;

    if (currentList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF001F47),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: const Center(
          child: Text(
            'Keine Intervall- oder Runden-Daten verfügbar.',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ),
      );
    }

    final isRun = widget.sport.toUpperCase() == 'RUN';

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
          // Header mit Umschalter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.timer_outlined,
                      color: AppColors.accentVolt, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Intervalle & Runden',
                    style: AppTypography.title.copyWith(color: Colors.white),
                  ),
                ],
              ),
              // Umschalter (Laps vs Auto-Intervalle)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToggleButton(
                      label: 'Manuell (${widget.laps.length})',
                      isSelected: !_showAutoIntervals,
                      onTap: () => setState(() => _showAutoIntervals = false),
                    ),
                    _buildToggleButton(
                      label: 'Auto (${widget.autoIntervals.length})',
                      isSelected: _showAutoIntervals,
                      onTap: () => setState(() => _showAutoIntervals = true),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Intervall-Tabelle
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 18,
              horizontalMargin: 8,
              headingRowHeight: 36,
              dataRowMinHeight: 38,
              dataRowMaxHeight: 42,
              headingTextStyle: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              columns: [
                const DataColumn(label: Text('#')),
                const DataColumn(label: Text('Dauer')),
                const DataColumn(label: Text('Distanz')),
                DataColumn(label: Text(isRun ? 'Ø Pace' : 'Ø Watt')),
                DataColumn(label: Text(isRun ? 'NGP' : 'NP')),
                const DataColumn(label: Text('Ø HF')),
                const DataColumn(label: Text('EF')),
              ],
              rows: currentList.map((lap) {
                final durationStr = _formatDuration(lap.durationSec);
                final distKm = lap.distanceM > 0
                    ? '${(lap.distanceM / 1000).toStringAsFixed(2)} km'
                    : '–';

                final avgValStr = isRun
                    ? (lap.avgPaceSecPerKm != null
                        ? _formatPace(lap.avgPaceSecPerKm!)
                        : '–')
                    : (lap.avgWatts != null
                        ? '${lap.avgWatts!.round()} W'
                        : '–');

                final npValStr = isRun
                    ? (lap.avgPaceSecPerKm != null
                        ? _formatPace(lap.avgPaceSecPerKm! * 0.98)
                        : '–')
                    : (lap.npWatts != null ? '${lap.npWatts!.round()} W' : '–');

                final hrStr =
                    lap.avgHr != null ? '${lap.avgHr!.round()} bpm' : '–';
                final efStr = lap.efficiencyFactor != null
                    ? lap.efficiencyFactor!.toStringAsFixed(2)
                    : '–';

                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        '${lap.lapIndex}',
                        style: const TextStyle(
                          color: AppColors.accentVolt,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataCell(Text(durationStr,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12))),
                    DataCell(Text(distKm,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12))),
                    DataCell(Text(avgValStr,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12))),
                    DataCell(Text(npValStr,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12))),
                    DataCell(Text(hrStr,
                        style: const TextStyle(
                            color: Color(0xFFFF6B6B), fontSize: 12))),
                    DataCell(Text(efStr,
                        style: const TextStyle(
                            color: Color(0xFF22D3EE), fontSize: 12))),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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

  String _formatDuration(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')} min';
  }

  String _formatPace(double secPerKm) {
    final m = secPerKm ~/ 60;
    final s = (secPerKm % 60).round();
    return '$m:${s.toString().padLeft(2, '0')}/km';
  }
}
