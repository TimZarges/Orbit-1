/// Kategorien für den In-App Beta-Bug- & Feedback-Reporter.
enum BetaFeedbackCategory {
  bugCrash('BUG_CRASH'),
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
        return isEn ? 'Bug / Crash' : 'Bug / Absturz';
      case BetaFeedbackCategory.wrongCalculation:
        return isEn ? 'Wrong Calculation' : 'Falsche Berechnung';
      case BetaFeedbackCategory.garminUpload:
        return isEn ? 'Garmin / Upload Issue' : 'Garmin / Upload-Problem';
      case BetaFeedbackCategory.designSuggestion:
        return isEn ? 'Design / Suggestion' : 'Design / Vorschlag';
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
  final DateTime createdAt;

  const BetaFeedbackReport({
    required this.id,
    required this.userId,
    required this.category,
    required this.description,
    required this.includeDiagnostics,
    this.diagnostics,
    this.screenshotPath,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'category': category.wireValue,
      'description': description,
      'includeDiagnostics': includeDiagnostics,
      if (includeDiagnostics && diagnostics != null)
        'diagnostics': diagnostics!.toJson(),
      if (screenshotPath != null) 'screenshotPath': screenshotPath,
      'createdAt': createdAt.toUtc().toIso8601String(),
    };
  }
}
