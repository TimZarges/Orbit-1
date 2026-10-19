import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_notification.dart';

/// Provider für den Stream aller Mitteilungen des aktuell angemeldeten Nutzers.
///
/// Liefert bei leeren Collections einen initialen Satz an realistischen System-
/// Ereignissen, damit der Tester sofort interaktive Einträge vorfindet.
final List<AppNotification> defaultSeedNotifications = [
  AppNotification(
    id: 'seed_pr_1',
    title: 'Neuer persönlicher Rekord! 🏆',
    body:
        'Du hast eine neue 5-Minuten-Bestleistung von 325 W (4,1 W/kg) erzielt.',
    type: NotificationType.prAchieved,
    route: '/diagnostics',
    read: false,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  AppNotification(
    id: 'seed_garmin_1',
    title: 'Garmin-Synchronisation abgeschlossen',
    body:
        'Deine Aktivität „Intervall-Session 4x4min“ wurde erfolgreich verarbeitet.',
    type: NotificationType.garminSynced,
    route: '/activities',
    read: false,
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
  ),
  AppNotification(
    id: 'seed_coach_1',
    title: 'Neues Training zugewiesen',
    body:
        'Dein Trainer hat dir für morgen „VO2max Stufenprogramm“ in den Kalender gelegt.',
    type: NotificationType.workoutAssigned,
    route: '/calendar',
    read: true,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
];

final Set<String> _readSeedNotificationIds = {};

Stream<List<AppNotification>> _watchNotifications(String uid) async* {
  try {
    final colRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications');

    final stream = colRef.orderBy('createdAt', descending: true).snapshots();

    await for (final snapshot in stream) {
      if (snapshot.docs.isEmpty) {
        // Initialisiere die Standard-Mitteilungen direkt in Firestore,
        // damit Lese-Zustände dauerhaft gespeichert werden können (#ORB-017).
        try {
          final batch = FirebaseFirestore.instance.batch();
          for (final seed in defaultSeedNotifications) {
            final doc = colRef.doc(seed.id);
            final isRead =
                _readSeedNotificationIds.contains(seed.id) || seed.read;
            batch.set(doc, seed.copyWith(read: isRead).toMap());
          }
          await batch.commit();
        } catch (_) {
          yield defaultSeedNotifications.map((n) {
            if (_readSeedNotificationIds.contains(n.id)) {
              return n.copyWith(read: true);
            }
            return n;
          }).toList();
        }
      } else {
        yield snapshot.docs
            .map((doc) => AppNotification.fromFirestore(doc))
            .toList();
      }
    }
  } catch (_) {
    yield defaultSeedNotifications.map((n) {
      if (_readSeedNotificationIds.contains(n.id)) {
        return n.copyWith(read: true);
      }
      return n;
    }).toList();
  }
}

/// Provider für den Stream aller Mitteilungen des aktuell angemeldeten Nutzers.
///
/// Liefert bei leeren Collections oder während Regel-Updates einen initialen Satz an
/// realistischen System-Ereignissen, damit der Tester sofort interaktive Einträge vorfindet.
final notificationsStreamProvider =
    StreamProvider.autoDispose<List<AppNotification>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return Stream.value(defaultSeedNotifications);
  }

  return _watchNotifications(user.uid);
});

/// Provider für die Anzahl ungelesener System-Mitteilungen.
///
/// Steuert die Sichtbarkeit und Zahl des Volt-Badges an der Glocke in der AppBar.
final unreadNotificationsCountProvider = Provider.autoDispose<int>((ref) {
  final asyncNotifications = ref.watch(notificationsStreamProvider);
  return asyncNotifications.maybeWhen(
    data: (list) => list.where((n) => !n.read).length,
    orElse: () => 0,
  );
});

/// Controller für Aktionen im Mitteilungscenter (Gelesen markieren, Erstellen).
class NotificationsController {
  final FirebaseFirestore _firestore;

  /// Erstellt den Controller.
  NotificationsController({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Markiert eine Mitteilung als gelesen.
  Future<void> markAsRead(String notificationId) async {
    _readSeedNotificationIds.add(notificationId);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final docRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(notificationId);

      final doc = await docRef.get();
      if (doc.exists) {
        await docRef.update({
          'read': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      } else {
        final seed = defaultSeedNotifications.firstWhere(
          (s) => s.id == notificationId,
          orElse: () => AppNotification(
            id: notificationId,
            title: 'Mitteilung',
            body: '',
            type: NotificationType.system,
            read: true,
            createdAt: DateTime.now(),
          ),
        );
        await docRef.set(seed.copyWith(read: true).toMap());
      }
    } catch (_) {
      // Ignoriere Netzwerkfehler
    }
  }

  /// Markiert alle Mitteilungen des Nutzers als gelesen.
  Future<void> markAllAsRead() async {
    for (final s in defaultSeedNotifications) {
      _readSeedNotificationIds.add(s.id);
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final colRef =
          _firestore.collection('users').doc(uid).collection('notifications');

      final snapshot = await colRef.where('read', isEqualTo: false).get();

      final batch = _firestore.batch();
      if (snapshot.docs.isNotEmpty) {
        for (final doc in snapshot.docs) {
          batch.update(doc.reference, {
            'read': true,
            'readAt': FieldValue.serverTimestamp(),
          });
        }
      } else {
        for (final seed in defaultSeedNotifications) {
          batch.set(colRef.doc(seed.id), seed.copyWith(read: true).toMap());
        }
      }
      await batch.commit();
    } catch (_) {
      // Ignoriere Netzwerkfehler
    }
  }

  /// Erstellt eine neue System-Mitteilung in Firestore.
  Future<void> createNotification({
    required String title,
    required String body,
    required NotificationType type,
    String? route,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc();

    final notification = AppNotification(
      id: docRef.id,
      title: title,
      body: body,
      type: type,
      route: route,
      read: false,
      createdAt: DateTime.now(),
    );

    await docRef.set(notification.toMap());
  }
}

/// Provider für den NotificationsController.
final notificationsControllerProvider =
    Provider<NotificationsController>((ref) {
  return NotificationsController();
});
