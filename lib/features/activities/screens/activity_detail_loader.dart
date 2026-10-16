import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../models/activity.dart';
import 'activity_detail_screen.dart';

/// Lädt eine Aktivität anhand ihrer ID für Deep-Links (z. B. aus Push-Benachrichtigungen `/activities/:id`).
class ActivityDetailLoader extends StatelessWidget {
  final String activityId;

  const ActivityDetailLoader({super.key, required this.activityId});

  @override
  Widget build(BuildContext context) {
    if (activityId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Aktivität')),
        body: const Center(child: Text('Ungültige Aktivitäts-ID')),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('activities')
          .doc(activityId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.backgroundLight,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.navy),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(title: const Text('Aktivität')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('Aktivität nicht gefunden oder gelöscht.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Zurück'),
                  ),
                ],
              ),
            ),
          );
        }

        final activity = Activity.fromDocument(snapshot.data!);
        return ActivityDetailScreen(activity: activity);
      },
    );
  }
}
