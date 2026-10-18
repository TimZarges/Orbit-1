import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/core/config/contact_config.dart';
import 'package:orbit/features/beta_feedback/models/beta_feedback_report.dart';
import 'package:orbit/features/beta_feedback/screens/admin_feedback_screen.dart';

void main() {
  group('Phase 28.3 — Zentrale Kontakt- und Support-Konfiguration', () {
    test('ContactConfig enthält alle offiziellen E-Mail-Adressen und URLs', () {
      expect(ContactConfig.supportEmail, 'support@orbit-training.app');
      expect(ContactConfig.bugsEmail, 'bugs@orbit-training.app');
      expect(ContactConfig.feedbackEmail, 'feedback@orbit-training.app');
      expect(ContactConfig.generalEmail, 'hello@orbit-training.app');
      expect(ContactConfig.privacyEmail, 'privacy@orbit-training.app');

      expect(ContactConfig.helpUrl, contains('help.html'));
      expect(ContactConfig.privacyUrl, contains('privacy.html'));
      expect(ContactConfig.imprintUrl, contains('imprint.html'));
      expect(ContactConfig.deleteAccountUrl, contains('delete-account.html'));
    });
  });

  group('Phase 28.2 — Beta-Feedback & Ticket-Workflow', () {
    test('BetaFeedbackCategory unterstützt alle 6 Kategorien inkl. Phase 28',
        () {
      expect(BetaFeedbackCategory.bugCrash.wireValue, 'BUG_CRASH');
      expect(BetaFeedbackCategory.featureIdea.wireValue, 'FEATURE_IDEA');
      expect(
          BetaFeedbackCategory.supportQuestion.wireValue, 'SUPPORT_QUESTION');
      expect(
          BetaFeedbackCategory.wrongCalculation.wireValue, 'WRONG_CALCULATION');
      expect(BetaFeedbackCategory.garminUpload.wireValue, 'GARMIN_UPLOAD');
      expect(
          BetaFeedbackCategory.designSuggestion.wireValue, 'DESIGN_SUGGESTION');

      // Labels DE/EN
      expect(BetaFeedbackCategory.featureIdea.label(languageCode: 'de'),
          'Verbesserung / Idee');
      expect(BetaFeedbackCategory.featureIdea.label(languageCode: 'en'),
          'Feature / Idea');
      expect(BetaFeedbackCategory.supportQuestion.label(languageCode: 'de'),
          'Frage / Support');

      // fromWire Fallback
      expect(BetaFeedbackCategory.fromWire('FEATURE_IDEA'),
          BetaFeedbackCategory.featureIdea);
      expect(BetaFeedbackCategory.fromWire('UNKNOWN'),
          BetaFeedbackCategory.bugCrash);
    });

    test(
        'BetaFeedbackReport serialisiert und deserialisiert Ticket-ID und Status',
        () {
      final now = DateTime.utc(2026, 10, 17, 12, 0, 0);
      final report = BetaFeedbackReport(
        id: 'report_001',
        userId: 'user_tim',
        category: BetaFeedbackCategory.featureIdea,
        description: 'Bitte Dunkelmodus für den Kalender hinzufügen!',
        includeDiagnostics: true,
        ticketId: '#ORB-042',
        status: 'OPEN',
        createdAt: now,
        diagnostics: const BetaDiagnosticsPayload(
          route: '/calendar',
          appVersion: '1.0.0+1',
          deviceInfo: 'Pixel 10 Pro (Android 16)',
          recentLogs: ['[LOG] Calendar rendered'],
        ),
      );

      final json = report.toJson();
      expect(json['userId'], 'user_tim');
      expect(json['category'], 'FEATURE_IDEA');
      expect(json['ticketId'], '#ORB-042');
      expect(json['status'], 'OPEN');
      expect(json['includeDiagnostics'], true);
      expect(json['diagnostics']['route'], '/calendar');
      expect(json['diagnostics']['deviceInfo'], contains('Pixel 10 Pro'));
    });

    testWidgets('AdminFeedbackScreen rendert Header und Filter-Chips für Admin',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: AdminFeedbackScreen(
              streamOverride: Stream.empty(),
              isAdminOverride: true,
            ),
          ),
        ),
      );

      // AppBar Titel für Admin
      expect(find.text('Beta Feedback-Inbox'), findsOneWidget);

      // Status-Filter Chips
      expect(find.text('Alle Status'), findsOneWidget);
      expect(find.text('🔴 Offen'), findsOneWidget);
      expect(find.text('🟡 In Arbeit'), findsOneWidget);
      expect(find.text('🟢 Behoben'), findsOneWidget);

      // Kategorie-Filter Chips
      expect(find.text('Alle Kategorien'), findsOneWidget);
      expect(find.text('🐛 Bugs'), findsOneWidget);
      expect(find.text('💡 Ideen'), findsOneWidget);
      expect(find.text('❓ Support'), findsOneWidget);
    });

    testWidgets(
        'AdminFeedbackScreen rendert Titel Meine Feedback-Tickets für normale Tester',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: AdminFeedbackScreen(
              streamOverride: Stream.empty(),
              isAdminOverride: false,
            ),
          ),
        ),
      );

      // AppBar Titel für normale Nutzer
      expect(find.text('Meine gemeldeten Tickets'), findsOneWidget);
    });
  });
}
