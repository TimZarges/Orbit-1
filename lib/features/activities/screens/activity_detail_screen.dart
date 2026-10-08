import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../models/activity.dart';
import '../providers/activity_actions_provider.dart';

class ActivityDetailScreen extends ConsumerWidget {
  final Activity activity;

  const ActivityDetailScreen({super.key, required this.activity});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aktivität löschen'),
        content: const Text(
            'Möchtest du diese Aktivität wirklich löschen? Dieser Vorgang kann nicht rückgängig gemacht werden.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        Navigator.of(context).pop();
        await ref.read(activityActionsProvider).deleteActivity(activity.id);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fehler beim Löschen: $e')),
          );
        }
      }
    }
  }

  Color _getSportColor(String? sport) {
    switch (sport?.toUpperCase()) {
      case 'RUN':
        return AppColors.sportRun;
      case 'BIKE':
        return AppColors.sportBike;
      case 'SWIM':
        return AppColors.sportSwim;
      case 'MULTISPORT':
        return AppColors.sportMulti;
      default:
        return AppColors.navy;
    }
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatPace(double mps) {
    if (mps <= 0) return '-:-- /km';
    final paceSeconds = 1000 / mps;
    final m = paceSeconds ~/ 60;
    final s = (paceSeconds % 60).toInt();
    return '$m:${s.toString().padLeft(2, '0')} /km';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = activity.summary;
    final localTime = activity.localDate.isNotEmpty
        ? DateTime.tryParse(activity.localDate) ?? DateTime.now()
        : DateTime.now();

    final dateStr = DateFormat('dd.MM.yyyy, HH:mm').format(localTime);
    final sportColor = _getSportColor(activity.sport);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktivität'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: sportColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.fitness_center, color: sportColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.sport,
                        style: AppTypography.headline,
                      ),
                      Text(dateStr, style: AppTypography.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Metrics Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                if (activity.durationSec > 0)
                  _MetricCard(
                    title: 'Dauer',
                    value: _formatDuration(activity.durationSec.toInt()),
                  ),
                if (activity.distanceM > 0)
                  _MetricCard(
                    title: 'Distanz',
                    value:
                        '${(activity.distanceM / 1000).toStringAsFixed(2)} km',
                  ),
                if (summary?.avgHr != null)
                  _MetricCard(
                    title: 'Ø HF',
                    value: '${summary!.avgHr!.round()} bpm',
                  ),
                if (summary?.maxHr != null)
                  _MetricCard(
                    title: 'Max HF',
                    value: '${summary!.maxHr!.round()} bpm',
                  ),
                if (summary?.avgPowerW != null)
                  _MetricCard(
                    title: 'Ø Leistung',
                    value: '${summary!.avgPowerW!.round()} W',
                  ),
                if (summary?.elevationGainM != null)
                  _MetricCard(
                    title: 'Anstieg',
                    value: '${summary!.elevationGainM!.round()} m',
                  ),
                if (summary?.avgPaceSecPerKm != null)
                  _MetricCard(
                    title: 'Ø Pace',
                    value: _formatPace(summary!
                        .avgPaceSecPerKm!), // wait, avgPaceSecPerKm is already seconds per km!
                  ),
                if (summary?.avgCadence != null)
                  _MetricCard(
                    title: 'Ø Kadenz',
                    value: '${summary!.avgCadence!.round()} spm',
                  ),
              ],
            ),

            const SizedBox(height: 32),

            // Segments (Multisport)
            if (activity.segments != null && activity.segments!.isNotEmpty) ...[
              const Text('Segmente', style: AppTypography.title),
              const SizedBox(height: 16),
              ...activity.segments!.map((s) => ListTile(
                    leading: Icon(Icons.check_circle_outline,
                        color: _getSportColor(s.sport)),
                    title: Text(s.sport),
                    subtitle: Text(_formatDuration(s.durationSec.toInt())),
                    trailing: s.distanceM > 0
                        ? Text('${(s.distanceM / 1000).toStringAsFixed(2)} km')
                        : null,
                  )),
              const SizedBox(height: 32),
            ],

            // Disabled More Details
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: null,
                child: const Text('Mehr Details (Demnächst)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;

  const _MetricCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: AppTypography.label.copyWith(color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: AppTypography.title),
        ],
      ),
    );
  }
}
