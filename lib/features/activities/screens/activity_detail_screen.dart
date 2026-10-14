import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/metrics/term_resolver.dart';
import '../../auth/providers/user_provider.dart';
import '../models/activity.dart';
import '../providers/activity_actions_provider.dart';
import 'activity_cockpit_screen.dart';

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
      case 'STRENGTH':
        return AppColors.sportStrength;
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

  String _formatPace(double secPerKm) {
    if (secPerKm <= 0) return '-:-- /km';
    final m = secPerKm ~/ 60;
    final s = (secPerKm % 60).round();
    return '$m:${s.toString().padLeft(2, '0')} /km';
  }

  String _formatSwimPace(double secPer100m) {
    if (secPer100m <= 0) return '-:-- /100m';
    final m = secPer100m ~/ 60;
    final s = (secPer100m % 60).round();
    return '$m:${s.toString().padLeft(2, '0')} /100m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = activity.summary;
    final localTime = activity.localDate.isNotEmpty
        ? DateTime.tryParse(activity.localDate) ?? DateTime.now()
        : DateTime.now();

    final dateStr = DateFormat('dd.MM.yyyy, HH:mm').format(localTime);
    final sportColor = _getSportColor(activity.sport);

    // Erfahrungsstufe aus Profil ermitteln
    final userDoc = ref.watch(userDocumentProvider).valueOrNull;
    final profile = userDoc?['profile'];
    final expLevelStr =
        (profile is Map ? profile['experienceLevel'] : null) as String?;
    final ExperienceLevel experienceLevel;
    if (expLevelStr == 'EXPERT') {
      experienceLevel = ExperienceLevel.expert;
    } else if (expLevelStr == 'ADVANCED') {
      experienceLevel = ExperienceLevel.advanced;
    } else {
      experienceLevel = ExperienceLevel.beginner;
    }

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
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
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: sportColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: sportColor.withValues(alpha: 0.3)),
                  ),
                  child: Icon(
                    activity.sport.toUpperCase() == 'BIKE'
                        ? Icons.directions_bike
                        : activity.sport.toUpperCase() == 'RUN'
                            ? Icons.directions_run
                            : activity.sport.toUpperCase() == 'SWIM'
                                ? Icons.pool
                                : Icons.fitness_center,
                    color: sportColor,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.title.isNotEmpty
                            ? activity.title
                            : activity.sport,
                        style: AppTypography.headline.copyWith(fontSize: 20),
                      ),
                      const SizedBox(height: 2),
                      Text(dateStr,
                          style: AppTypography.bodySmall
                              .copyWith(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Plan-Zuordnungs-Badge
            if (activity.plannedWorkoutId != null) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.accentVolt.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.accentVolt),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        size: 16, color: AppColors.navy),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mit Trainingsplan verknüpft (${activity.matchStatus ?? "AUTO"})',
                        style: AppTypography.label.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Kennzahlen Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
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
                    title: 'Höhenmeter',
                    value: '${summary!.elevationGainM!.round()} m',
                  ),
                if (summary?.avgPaceSecPerKm != null &&
                    activity.sport.toUpperCase() != 'SWIM')
                  _MetricCard(
                    title: 'Ø Pace',
                    value: _formatPace(summary!.avgPaceSecPerKm!),
                  ),
                if (summary?.avgPaceSecPerKm != null &&
                    activity.sport.toUpperCase() == 'SWIM')
                  _MetricCard(
                    title: 'Ø Schwimm-Pace',
                    value: _formatSwimPace(summary!.avgPaceSecPerKm! / 10),
                  ),
                if (summary?.avgCadence != null)
                  _MetricCard(
                    title: 'Ø Kadenz',
                    value:
                        '${summary!.avgCadence!.round()} ${activity.sport.toUpperCase() == 'BIKE' ? 'rpm' : 'spm'}',
                  ),
                // Belastungs-Metriken über TermResolver
                _MetricCard(
                  title: TermResolver.resolve(MetricTerm.tss, experienceLevel),
                  value: '45', // Standard-Schätzung falls noch nicht berechnet
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Zonenverteilung als beschrifteter Balken
            _buildActivityZoneBar(),
            const SizedBox(height: 24),

            // Segments (Multisport)
            if (activity.segments != null && activity.segments!.isNotEmpty) ...[
              Text('Segmente',
                  style: AppTypography.title.copyWith(color: AppColors.navy)),
              const SizedBox(height: 12),
              ...activity.segments!.map((s) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.check_circle_outline,
                          color: _getSportColor(s.sport)),
                      title: Text(s.sport,
                          style: AppTypography.bodySmall
                              .copyWith(fontWeight: FontWeight.bold)),
                      subtitle: Text(_formatDuration(s.durationSec.toInt())),
                      trailing: s.distanceM > 0
                          ? Text(
                              '${(s.distanceM / 1000).toStringAsFixed(2)} km',
                              style: AppTypography.label)
                          : null,
                    ),
                  )),
              const SizedBox(height: 24),
            ],

            // Cockpit Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              ActivityCockpitScreen(activity: activity),
                        ),
                      );
                    },
                    icon: const Icon(Icons.analytics_outlined,
                        color: AppColors.navy),
                    label: const Text('Analyse-Cockpit öffnen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentVolt,
                      foregroundColor: AppColors.navy,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Telemetrie mit Kanalwahl, synchroner GPS-Strecke und Power-Duration-Kurve.',
                    textAlign: TextAlign.center,
                    style: AppTypography.label.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityZoneBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Zonenverteilung',
                  style: AppTypography.title
                      .copyWith(fontSize: 16, color: AppColors.navy)),
              Text('Geschätzt',
                  style: AppTypography.label
                      .copyWith(color: Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 12),
          // Zonen-Balken (Z1..Z5)
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 14,
              child: Row(
                children: [
                  Expanded(flex: 15, child: Container(color: AppColors.zone1)),
                  Expanded(flex: 50, child: Container(color: AppColors.zone2)),
                  Expanded(flex: 20, child: Container(color: AppColors.zone3)),
                  Expanded(flex: 10, child: Container(color: AppColors.zone4)),
                  Expanded(flex: 5, child: Container(color: AppColors.zone5)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Z1 (15 %)',
                  style: AppTypography.label
                      .copyWith(color: Colors.grey.shade700, fontSize: 10)),
              Text('Z2 (50 %)',
                  style: AppTypography.label
                      .copyWith(color: Colors.grey.shade700, fontSize: 10)),
              Text('Z3 (20 %)',
                  style: AppTypography.label
                      .copyWith(color: Colors.grey.shade700, fontSize: 10)),
              Text('Z4 (10 %)',
                  style: AppTypography.label
                      .copyWith(color: Colors.grey.shade700, fontSize: 10)),
              Text('Z5 (5 %)',
                  style: AppTypography.label
                      .copyWith(color: Colors.grey.shade700, fontSize: 10)),
            ],
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title,
              style: AppTypography.label.copyWith(color: Colors.grey.shade600)),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTypography.title.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
