import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/features/beta_feedback/models/beta_feedback_report.dart';
import 'package:orbit/features/beta_feedback/screens/admin_feedback_screen.dart';
import 'package:orbit/features/beta_feedback/widgets/beta_feedback_ticket_card.dart';

void main() {
  group('Nutzer Beta-Feedback Inbox (Phase 38.4)', () {
    testWidgets('AdminFeedbackScreen rendert Titel Meine gemeldeten Tickets für Tester', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AdminFeedbackScreen(
                isAdminOverride: false,
                streamOverride: const Stream.empty(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Meine gemeldeten Tickets'), findsOneWidget);
    });

    testWidgets('BetaFeedbackTicketCard visualisiert Ticket-ID, OrbitDateFormatter und Status-Badges', (tester) async {
      final reportOpen = BetaFeedbackReport(
        id: 'rep_1',
        ticketId: '#ORB-101',
        category: BetaFeedbackCategory.bugCrash,
        description: 'GPS-Strecke springt nach Tunnel',
        status: 'OPEN',
        includeDiagnostics: false,
      userId: 'test_user',
        createdAt: DateTime(2026, 10, 18, 14, 30),
      );

      final reportInProgress = BetaFeedbackReport(
        id: 'rep_2',
        ticketId: '#ORB-102',
        category: BetaFeedbackCategory.designSuggestion,
        description: 'Schriftgröße im Zonen-Diagramm',
        status: 'IN_PROGRESS',
        includeDiagnostics: false,
      userId: 'test_user',
        createdAt: DateTime(2026, 10, 17, 9, 15),
      );

      final reportResolved = BetaFeedbackReport(
        id: 'rep_3',
        ticketId: '#ORB-103',
        category: BetaFeedbackCategory.wrongCalculation,
        description: 'FTP-Schwellenwert um 5W abweichend',
        status: 'RESOLVED',
        includeDiagnostics: false,
      userId: 'test_user',
        createdAt: DateTime(2026, 10, 16, 18, 45),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  BetaFeedbackTicketCard(report: reportOpen, isAdmin: false),
                  BetaFeedbackTicketCard(report: reportInProgress, isAdmin: false),
                  BetaFeedbackTicketCard(report: reportResolved, isAdmin: false),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Ticket-IDs
      expect(find.text('#ORB-101'), findsOneWidget);
      expect(find.text('#ORB-102'), findsOneWidget);
      expect(find.text('#ORB-103'), findsOneWidget);

      // Status-Badges
      expect(find.text('🟢 Offen'), findsOneWidget);
      expect(find.text('🟡 In Arbeit'), findsOneWidget);
      expect(find.text('✅ Gelöst'), findsOneWidget);

      // Datumsanzeigen via OrbitDateFormatter
      expect(find.text('18.10.2026 • 14:30 Uhr'), findsOneWidget);
      expect(find.text('17.10.2026 • 09:15 Uhr'), findsOneWidget);
      expect(find.text('16.10.2026 • 18:45 Uhr'), findsOneWidget);
    });
  });
}
