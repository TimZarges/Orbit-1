import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/features/integrations/models/garmin_status.dart';
import 'package:orbit/features/integrations/providers/garmin_provider.dart';
import 'package:orbit/features/integrations/screens/garmin_connection_screen.dart';

void main() {
  group('Phase 35.1 - Garmin REST-Pull Synchronisation & Status', () {
    test('GarminStatus parst aktive REST-Pull Felder sauber', () {
      final map = {
        'state': 'CONNECTED',
        'garminUserId': 'garmin_user_test_123',
        'lastSyncAt': '2026-10-18T22:30:00.000Z',
        'lastSyncCount': 5,
        'lastSyncMessage': '5 Aktivitäten erfolgreich synchronisiert',
      };

      final status = GarminStatus.fromMap(map);
      expect(status.state, GarminConnectionState.connected);
      expect(status.garminUserId, 'garmin_user_test_123');
      expect(status.lastSyncCount, 5);
      expect(status.lastSyncMessage, '5 Aktivitäten erfolgreich synchronisiert');
      expect(status.lastSyncAt, isNotNull);
    });

    testWidgets('GarminConnectionScreen zeigt Button "Jetzt synchronisieren (REST-Pull)" im verbundenen Zustand',
        (WidgetTester tester) async {
      final mockStatus = GarminStatus(
        state: GarminConnectionState.connected,
        garminUserId: 'user_456',
        lastSyncAt: DateTime(2026, 10, 18, 22, 0),
        lastSyncCount: 2,
        lastSyncMessage: '2 Aktivitäten synchronisiert',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            garminStatusStreamProvider.overrideWith((ref) => Stream.value(mockStatus)),
          ],
          child: const MaterialApp(
            home: GarminConnectionScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('garmin_sync_now_button')), findsOneWidget);
      expect(find.text('Jetzt synchronisieren (REST-Pull)'), findsOneWidget);
      expect(find.text('Historische Daten anfordern (Garmin Queue)'), findsOneWidget);
    });
  });
}
