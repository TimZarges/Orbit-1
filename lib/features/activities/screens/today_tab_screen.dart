import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:orbit/core/design/app_colors.dart';
import 'package:orbit/core/design/app_typography.dart';
import '../providers/activities_provider.dart';
import 'activity_detail_screen.dart';
import '../providers/activity_upload_provider.dart';
import '../models/activity.dart';

class TodayTabScreen extends ConsumerWidget {
  const TodayTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(activitiesProvider);
    final uploadState = ref.watch(activityUploadProvider);

    return Scaffold(
      body: activitiesAsync.when(
        data: (activities) {
          if (activities.isEmpty) {
            return _buildEmptyState(context, ref, uploadState);
          }
          return _buildActivitiesList(context, activities, uploadState, ref);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Fehler: $err')),
      ),
      floatingActionButton: activitiesAsync.valueOrNull?.isNotEmpty == true
          ? FloatingActionButton(
              onPressed: uploadState.isUploading
                  ? null
                  : () =>
                      ref.read(activityUploadProvider.notifier).pickAndUpload(),
              child: uploadState.isUploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildEmptyState(
      BuildContext context, WidgetRef ref, ActivityUploadState uploadState) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.directions_run,
                size: 64, color: AppColors.navyLight),
            const SizedBox(height: 16),
            const Text(
              'Noch keine Aktivitäten',
              style: AppTypography.headline,
            ),
            const SizedBox(height: 8),
            const Text(
              'Verbinde dein Konto oder lade eine FIT-Datei hoch, um zu starten.',
              style: AppTypography.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: null, // Disabled für Phase 06
              icon: const Icon(Icons.sync),
              label: const Text('Garmin verbinden (folgt)'),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: uploadState.isUploading
                  ? null
                  : () =>
                      ref.read(activityUploadProvider.notifier).pickAndUpload(),
              icon: uploadState.isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.upload_file),
              label: const Text('FIT-Datei importieren'),
            ),
            if (uploadState.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(uploadState.error!,
                    style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitiesList(BuildContext context, List<Activity> activities,
      ActivityUploadState uploadState, WidgetRef ref) {
    return ListView.builder(
      itemCount: activities.length + (uploadState.isUploading ? 1 : 0),
      itemBuilder: (context, index) {
        if (uploadState.isUploading && index == 0) {
          return const ListTile(
            leading: CircularProgressIndicator(),
            title: Text('Datei wird hochgeladen und verarbeitet...'),
          );
        }

        final activity = activities[index - (uploadState.isUploading ? 1 : 0)];
        return _ActivityCard(activity: activity);
      },
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Activity activity;
  const _ActivityCard({required this.activity});

  IconData _getIcon() {
    switch (activity.sport) {
      case 'RUN':
        return Icons.directions_run;
      case 'BIKE':
        return Icons.directions_bike;
      case 'SWIM':
        return Icons.pool;
      default:
        return Icons.fitness_center;
    }
  }

  Color _getColor() {
    switch (activity.sport) {
      case 'RUN':
        return AppColors.sportRun;
      case 'BIKE':
        return AppColors.sportBike;
      case 'SWIM':
        return AppColors.sportSwim;
      default:
        return AppColors.navyLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('dd.MM.yyyy HH:mm');
    final duration = Duration(seconds: activity.durationSec.toInt());
    final distanceKm = activity.distanceM / 1000;

    return GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => ActivityDetailScreen(activity: activity)),
          );
        },
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getColor().withValues(alpha: 0.2),
              child: Icon(_getIcon(), color: _getColor()),
            ),
            title: Text(activity.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(format.format(activity.startTimeUtc)),
                if (activity.processing?.state == 'PROCESSING')
                  const Text('Wird verarbeitet...',
                      style: TextStyle(color: Colors.orange)),
                if (activity.processing?.state == 'FAILED')
                  Text('Fehler: ${activity.processing?.errorCode}',
                      style: const TextStyle(color: Colors.red)),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${distanceKm.toStringAsFixed(2)} km'),
                Text('${duration.inMinutes} Min'),
              ],
            ),
          ),
        ));
  }
}
