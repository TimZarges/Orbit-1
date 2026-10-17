import 'package:cloud_firestore/cloud_firestore.dart';

/// Kategorien für den In-App Beta-Bug- & Feedback-Reporter (Phase 28.2).
enum BetaFeedbackCategory {
  bugCrash('BUG_CRASH'),
  featureIdea('FEATURE_IDEA'),
  supportQuestion('SUPPORT_QUESTION'),
  wrongCalculation('WRONG_CALCULATION'),
  garminUpload('GARMIN_UPLOAD'),
  designSuggestion('DESIGN_SUGGESTION');

  final String wireValue;
  const BetaFeedbackCategory(this.wireValue);

  /// Zweisprachiges Label für die UI.
  String label({String languageCode = 'de'}) {
    final isEn = languageCode.toLowerCase().startsWith('en');
    switch (this) {
      case BetaFeedbackCategory.bugCrash:
        return isEn ? 'Bug / Crash' : 'Fehler / Bug';
      case BetaFeedbackCategory.featureIdea:
        return isEn ? 'Feature / Idea' : 'Verbesserung / Idee';
      case BetaFeedbackCategory.supportQuestion:
        return isEn ? 'Question / Support' : 'Frage / Support';
      case BetaFeedbackCategory.wrongCalculation:
        return isEn ? 'Calculation' : 'Falsche Berechnung';
      case BetaFeedbackCategory.garminUpload:
        return isEn ? 'Garmin / Upload' : 'Garmin / Upload';
      case BetaFeedbackCategory.designSuggestion:
        return isEn ? 'Design / UI' : 'Design / Layout';
    }
  }

  static BetaFeedbackCategory fromWire(String? raw) {
    for (final cat in BetaFeedbackCategory.values) {
      if (cat.wireValue == raw) return cat;
    }
    return BetaFeedbackCategory.bugCrash;
  }
}

/// Optionale Diagnose-Metadaten, die nur mit explizitem Opt-in des Nutzers angehängt werden.
class BetaDiagnosticsPayload {
  final String route;
  final String appVersion;
  final String deviceInfo;
  final List<String> recentLogs;

  const BetaDiagnosticsPayload({
    required this.route,
    required this.appVersion,
    required this.deviceInfo,
    required this.recentLogs,
  });

  Map<String, dynamic> toJson() {
    return {
      'route': route,
      'appVersion': appVersion,
      'deviceInfo': deviceInfo,
      'recentLogs': recentLogs,
    };
  }
}

/// Datenmodell für einen Beta-Feedback-Bericht in Firestore (`betaFeedback/{reportId}`).
class BetaFeedbackReport {
  final String id;
  final String userId;
  final BetaFeedbackCategory category;
  final String description;
  final bool includeDiagnostics;
  final BetaDiagnosticsPayload? diagnostics;
  final String? screenshotPath;
  final String? ticketId;
  final String status;
  final DateTime createdAt;

  const BetaFeedbackReport({
    required this.id,
    required this.userId,
    required this.category,
    required this.description,
    required this.includeDiagnostics,
    this.diagnostics,
    this.screenshotPath,
    this.ticketId,
    this.status = 'OPEN',
    required this.createdAt,
  });

  factory BetaFeedbackReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final diagData = data['diagnostics'] as Map<String, dynamic>?;
    return BetaFeedbackReport(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      category: BetaFeedbackCategory.fromWire(data['category'] as String?),
      description: data['description'] as String? ?? '',
      includeDiagnostics: data['includeDiagnostics'] as bool? ?? false,
      ticketId: data['ticketId'] as String?,
      status: data['status'] as String? ?? 'OPEN',
      screenshotPath: data['screenshotPath'] as String?,
      diagnostics: diagData != null
          ? BetaDiagnosticsPayload(
              route: diagData['route'] as String? ?? '',
              appVersion: diagData['appVersion'] as String? ?? '',
              deviceInfo: diagData['deviceInfo'] as String? ?? '',
              recentLogs: (diagData['recentLogs'] as List<dynamic>?)
                      ?.map((e) => e.toString())
                      .toList() ??
                  [],
            )
          : null,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['createdAt']?.toString() ?? '') ??
              DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'category': category.wireValue,
      'description': description,
      'includeDiagnostics': includeDiagnostics,
      if (includeDiagnostics && diagnostics != null)
        'diagnostics': diagnostics!.toJson(),
      if (screenshotPath != null) 'screenshotPath': screenshotPath,
      if (ticketId != null) 'ticketId': ticketId,
      'status': status,
      'createdAt': createdAt.toUtc().toIso8601String(),
    };
  }
}
