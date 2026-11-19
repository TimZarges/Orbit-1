/// @file garmin_oauth_flow_v103_test.dart
/// @description Umfassende Tests für den reparierten Garmin-Connect-OAuth-Flow (v1.0.3):
/// Deep-Link/Web-Callback-Parsing, Abbruch-/Timeout-Verhalten gegen Hängenbleiben bei
/// „Warte auf Bestätigung...“, AppLifecycleState.resumed und `COLOR_SYSTEM_V1`-Konformität.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/core/design/app_colors.dart';
import 'package:orbit/features/activities/models/activity.dart';
import 'package:orbit/features/activities/providers/activities_provider.dart';
import 'package:orbit/features/integrations/models/garmin_status.dart';
import 'package:orbit/features/integrations/providers/garmin_provider.dart';
import 'package:orbit/features/integrations/screens/garmin_connection_screen.dart';

/// Mock-Service ohne Firebase-Abhängigkeit zur deterministischen Prüfung aller Zustandsübergänge.
class _FakeGarminService extends GarminService {
  int startCalls = 0;
  int cancelCalls = 0;
  int completeCalls = 0;
  int syncCalls = 0;
  String? lastCancelledReason;
  String? lastCompletedVerifier;
  bool shouldThrowOnSync = false;

  @override
  Future<GarminAuthStartResult?> startGarminAuthSession() async {
    startCalls++;
    return const GarminAuthStartResult(
      authUrl: 'https://connect.garmin.com/oauthConfirm?oauth_token=req_tok_1',
      oauthToken: 'req_tok_1',
    );
  }

  @override
  Future<void> launchAuthUrl(String authUrl) async {
    // Im Widget-Test kein echtes Browser-Launch nötig.
  }

  @override
  Future<void> cancelGarminAuth({String reason = 'cancelled'}) async {
    cancelCalls++;
    lastCancelledReason = reason;
  }

  @override
  Future<void> completeGarminAuth({
    required String oauthVerifier,
    String? oauthToken,
  }) async {
    completeCalls++;
    lastCompletedVerifier = oauthVerifier;
  }

  @override
  Future<Map<String, dynamic>> syncActivitiesNow({int days = 90}) async {
    syncCalls++;
    if (shouldThrowOnSync) {
      throw Exception('Rate Limit 429');
    }
    return {
      'success': true,
      'count': 3,
      'message': '3 Aktivitäten synchronisiert',
    };
  }
}

void main() {
  group('Garmin OAuth Flow v1.0.3 — URI-Parsing & Statusmodell', () {
    test(
        'parseGarminCallbackUri extrahiert gültige Parameter und blockt null/denied',
        () {
      final validUri = Uri.parse(
        'orbit://oauth/garmin?oauth_token=tok_123&oauth_verifier=ver_456',
      );
      final valid = parseGarminCallbackUri(validUri);
      expect(valid.hasValidVerifier, isTrue);
      expect(valid.verifier, equals('ver_456'));
      expect(valid.token, equals('tok_123'));
      expect(valid.isCancelledOrError, isFalse);

      final nullVerifierUri = Uri.parse(
        'https://orbit-app-mvp.web.app/callback/garmin?oauth_token=tok_123&oauth_verifier=null',
      );
      final cancelledNull = parseGarminCallbackUri(nullVerifierUri);
      expect(cancelledNull.hasValidVerifier, isFalse);
      expect(cancelledNull.verifier, isNull);
      expect(cancelledNull.isCancelledOrError, isTrue);
      expect(cancelledNull.error, equals('cancelled'));

      final deniedUri =
          Uri.parse('orbit://oauth/garmin?denied=tok_123&error=access_denied');
      final denied = parseGarminCallbackUri(deniedUri);
      expect(denied.hasValidVerifier, isFalse);
      expect(denied.isCancelledOrError, isTrue);
      expect(denied.error, equals('access_denied'));
    });

    test(
        'GarminStatus.fromMap parst CONNECTING, ERROR, authStartedAt und errorMessage',
        () {
      final startedAt = DateTime.now().toUtc().toIso8601String();
      final connectingStatus = GarminStatus.fromMap({
        'state': 'CONNECTING',
        'authStartedAt': startedAt,
      });
      expect(connectingStatus.state, GarminConnectionState.connecting);
      expect(connectingStatus.authStartedAt, isNotNull);

      final errorStatus = GarminStatus.fromMap({
        'state': 'ERROR',
        'errorMessage': 'Sitzung abgelaufen',
      });
      expect(errorStatus.state, GarminConnectionState.error);
      expect(errorStatus.errorMessage, equals('Sitzung abgelaufen'));
    });
  });

  group('GarminConnectionScreen v1.0.3 — Zustandsmaschine & Recovery', () {
    testWidgets(
        'verlässt „Warte auf Bestätigung...“ sauber beim Klick auf Abbrechen / Zurücksetzen',
        (WidgetTester tester) async {
      final fakeService = _FakeGarminService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            garminServiceProvider.overrideWithValue(fakeService),
            garminStatusStreamProvider.overrideWith(
              (ref) => Stream.value(const GarminStatus()),
            ),
          ],
          child: const MaterialApp(
            home: GarminConnectionScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Startzustand: Nicht verbunden
      expect(find.text('Nicht verbunden'), findsOneWidget);
      expect(find.byKey(const Key('garmin_connect_button')), findsOneWidget);

      // Verbindung starten -> Zustand wechselt auf Warte auf Bestätigung + Aktionskarte
      await tester.tap(find.byKey(const Key('garmin_connect_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(fakeService.startCalls, equals(1));
      expect(find.text('Warte auf Bestätigung...'), findsOneWidget);
      expect(find.byKey(const Key('garmin_waiting_card')), findsOneWidget);
      expect(
        find.byKey(const Key('garmin_cancel_pending_button')),
        findsOneWidget,
      );

      // Abbrechen klicken -> Warte-Zustand wird sofort verlassen
      await tester.tap(find.byKey(const Key('garmin_cancel_pending_button')));
      await tester.pumpAndSettle();

      expect(fakeService.cancelCalls, equals(1));
      expect(fakeService.lastCancelledReason, equals('cancelled'));
      expect(find.text('Warte auf Bestätigung...'), findsNothing);
      expect(find.byKey(const Key('garmin_waiting_card')), findsNothing);
      expect(find.byKey(const Key('garmin_error_banner')), findsOneWidget);
    });

    testWidgets(
        'setzt hängenden Zustand nach 3-Minuten-Timeout automatisch zurück',
        (WidgetTester tester) async {
      final fakeService = _FakeGarminService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            garminServiceProvider.overrideWithValue(fakeService),
            garminStatusStreamProvider.overrideWith(
              (ref) => Stream.value(const GarminStatus()),
            ),
          ],
          child: const MaterialApp(
            home: GarminConnectionScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('garmin_connect_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Warte auf Bestätigung...'), findsOneWidget);

      // 3 Minuten + Puffer vorspulen -> Watchdog bricht sauber mit Timeout-Hinweis ab
      await tester.pump(const Duration(minutes: 3, seconds: 1));
      await tester.pumpAndSettle();

      expect(fakeService.lastCancelledReason, equals('timeout'));
      expect(find.text('Warte auf Bestätigung...'), findsNothing);
      expect(find.byKey(const Key('garmin_waiting_card')), findsNothing);
      expect(find.byKey(const Key('garmin_error_banner')), findsOneWidget);
      expect(find.textContaining('Zeitüberschreitung'), findsOneWidget);
    });

    testWidgets(
        'erkennt Rückkehr über AppLifecycleState.resumed ohne Bestätigung und bietet Auswege',
        (WidgetTester tester) async {
      final fakeService = _FakeGarminService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            garminServiceProvider.overrideWithValue(fakeService),
            garminStatusStreamProvider.overrideWith(
              (ref) => Stream.value(const GarminStatus()),
            ),
          ],
          child: const MaterialApp(
            home: GarminConnectionScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('garmin_connect_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Rückkehr aus Browser simulieren + 2s Grace-Period abwarten
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(seconds: 3));

      expect(
        find.text('Rückkehr ohne automatische Bestätigung erkannt'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('garmin_reopen_browser_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('garmin_paste_clipboard_button')),
        findsOneWidget,
      );
    });

    testWidgets(
        'veralteter serverseitiger CONNECTING-Status (> 5 Min) hängt nicht in „Warte auf Bestätigung...“ fest',
        (WidgetTester tester) async {
      final staleStatus = GarminStatus(
        state: GarminConnectionState.connecting,
        authStartedAt: DateTime.now().subtract(const Duration(minutes: 10)),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            garminStatusStreamProvider.overrideWith(
              (ref) => Stream.value(staleStatus),
            ),
          ],
          child: const MaterialApp(
            home: GarminConnectionScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Warte auf Bestätigung...'), findsNothing);
      expect(find.byKey(const Key('garmin_waiting_card')), findsNothing);
      expect(find.byKey(const Key('garmin_error_banner')), findsOneWidget);
    });

    testWidgets(
        'schließt Kopplung mit initialVerifier automatisch ab, selbst wenn Sync ein Rate-Limit trifft',
        (WidgetTester tester) async {
      final fakeService = _FakeGarminService()..shouldThrowOnSync = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            garminServiceProvider.overrideWithValue(fakeService),
            garminStatusStreamProvider.overrideWith(
              (ref) => Stream.value(const GarminStatus()),
            ),
            activitiesProvider.overrideWith(
              (ref) => Stream.value(<Activity>[]),
            ),
          ],
          child: const MaterialApp(
            home: GarminConnectionScreen(
              initialToken: 'tok_auto',
              initialVerifier: 'ver_auto_777',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(fakeService.completeCalls, equals(1));
      expect(fakeService.lastCompletedVerifier, equals('ver_auto_777'));
      expect(fakeService.syncCalls, equals(1));
      expect(find.text('Warte auf Bestätigung...'), findsNothing);
      expect(
        find.textContaining('Erfolgreich mit Garmin verbunden!'),
        findsOneWidget,
      );
    });

    testWidgets(
        'respektiert COLOR_SYSTEM_V1 (Light: Navy ohne Volt; Dark: Volt auf Tiefdunkel)',
        (WidgetTester tester) async {
      const disconnectedStatus = GarminStatus();

      // Light Mode prüfen: Verbinden-Button muss Logo-Navy (#001F47) tragen
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            garminStatusStreamProvider.overrideWith(
              (ref) => Stream.value(disconnectedStatus),
            ),
          ],
          child: MaterialApp(
            theme: ThemeData.light(),
            home: const GarminConnectionScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final lightBtn = tester.widget<ElevatedButton>(
        find.byKey(const Key('garmin_connect_button')),
      );
      expect(
        lightBtn.style?.backgroundColor?.resolve(<WidgetState>{}),
        equals(AppColors.navy),
      );

      // Dark Mode prüfen: Verbinden-Button nutzt Logo-Volt (#CDFB17)
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            garminStatusStreamProvider.overrideWith(
              (ref) => Stream.value(disconnectedStatus),
            ),
          ],
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: const GarminConnectionScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final darkBtn = tester.widget<ElevatedButton>(
        find.byKey(const Key('garmin_connect_button')),
      );
      expect(
        darkBtn.style?.backgroundColor?.resolve(<WidgetState>{}),
        equals(AppColors.volt),
      );
    });
  });
}
