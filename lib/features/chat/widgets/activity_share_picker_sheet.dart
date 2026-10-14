import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../models/chat_message.dart';

/// Modal-Sheet zur Auswahl einer absolvierten Trainingseinheit zum Teilen im Chat.
class ActivitySharePickerSheet extends StatelessWidget {
  final String athleteId;
  final ValueChanged<ActivityShareSnapshot> onSelect;

  const ActivitySharePickerSheet({
    super.key,
    required this.athleteId,
    required this.onSelect,
  });

  static Future<ActivityShareSnapshot?> show(
      BuildContext context, String athleteId) {
    return showModalBottomSheet<ActivityShareSnapshot>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ActivitySharePickerSheet(
        athleteId: athleteId,
        onSelect: (snap) => Navigator.of(ctx).pop(snap),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Aktivität teilen',
              style: AppTypography.title
                  .copyWith(fontSize: 18, color: AppColors.navy),
            ),
            const SizedBox(height: 4),
            Text(
              'Wähle eine absolvierte Einheit, um eine Momentaufnahme im Chat zu teilen.',
              style: AppTypography.label.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('activities')
                    .where('athleteId', isEqualTo: athleteId)
                    .orderBy('startTimeUtc', descending: true)
                    .limit(20)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Center(
                      child: Text(
                        'Keine Aktivitäten vorhanden.',
                        style: AppTypography.body
                            .copyWith(color: Colors.grey.shade500),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;

                      final title = data['title'] as String? ?? 'Training';
                      final sport = data['sport'] as String? ?? 'OTHER';
                      final date = data['localDate'] as String? ?? '';
                      final durationSec =
                          (data['durationSec'] as num?)?.toInt() ?? 0;
                      final distanceM =
                          (data['distanceM'] as num?)?.toDouble() ?? 0.0;
                      final summary =
                          data['summary'] as Map<String, dynamic>? ?? {};

                      final snapshotObj = ActivityShareSnapshot(
                        activityId: doc.id,
                        title: title,
                        sport: sport,
                        date: date,
                        durationSec: durationSec,
                        distanceM: distanceM,
                        avgPowerW: (summary['avgPowerW'] as num?)?.toDouble(),
                        avgHr: (summary['avgHr'] as num?)?.toDouble(),
                      );

                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.techGrey,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(_getSportIcon(sport),
                              color: AppColors.navy, size: 20),
                        ),
                        title: Text(
                          title,
                          style: AppTypography.body.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.navy),
                        ),
                        subtitle: Text(
                          '$date · ${snapshotObj.formattedDuration}${distanceM > 0 ? " · ${snapshotObj.formattedDistance}" : ""}',
                          style: AppTypography.label
                              .copyWith(color: Colors.grey.shade600),
                        ),
                        trailing: const Icon(Icons.send,
                            size: 18, color: AppColors.navy),
                        onTap: () => onSelect(snapshotObj),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getSportIcon(String sport) {
    switch (sport.toUpperCase()) {
      case 'BIKE':
        return Icons.directions_bike;
      case 'RUN':
        return Icons.directions_run;
      case 'SWIM':
        return Icons.pool;
      default:
        return Icons.fitness_center;
    }
  }
}
