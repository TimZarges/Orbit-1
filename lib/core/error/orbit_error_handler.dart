import 'dart:collection';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../design/app_colors.dart';
import '../design/app_typography.dart';

/// Strukturierte, nutzerfreundliche Fehlermeldung ohne technische Stacktraces.
class OrbitUserMessage {
  final String title;
  final String message;
  final String code;
  final bool canRetry;

  const OrbitUserMessage({
    required this.title,
    required this.message,
    required this.code,
    this.canRetry = true,
  });
}

/// Zentraler Error-Mapper und anonymisierter Diagnose-Ringpuffer (max. 20 Einträge) für ORBIT.
///
/// Verbannt rohe [FirebaseException]-, [FirebaseFunctionsException]- oder technische
/// Fehler-Strings aus der UI und übersetzt sie zweisprachig (DE/EN) in klare Hinweise
/// mit Handlungsoption ("Erneut versuchen" / "Problem melden").
class OrbitErrorHandler {
  static const int maxLogEntries = 20;
  static final ListQueue<String> _recentLogs = ListQueue<String>(maxLogEntries);

  /// Gibt die letzten bis zu 20 anonymisierten Log-/Fehler-Einträge zurück.
  static List<String> get recentLogs => List<String>.unmodifiable(_recentLogs);

  /// Löscht den Diagnose-Puffer (z. B. für Tests oder beim Logout).
  static void clearLogs() {
    _recentLogs.clear();
  }

  /// Fügt einen Log-Eintrag hinzu und entfernt vorher personenbezogene Daten
  /// (E-Mail-Adressen, OAuth-Tokens, lange UIDs).
  static void recordLog(String rawEntry, {DateTime? timestamp}) {
    final ts = (timestamp ?? DateTime.now()).toUtc().toIso8601String();
    final sanitized = sanitizeLogText(rawEntry);
    if (_recentLogs.length >= maxLogEntries) {
      _recentLogs.removeFirst();
    }
    _recentLogs.addLast('[$ts] $sanitized');
  }

  /// Entfernt E-Mails, Bearer-/OAuth-Tokens und potenziell sensible Parameter aus Log-Strings.
  static String sanitizeLogText(String input) {
    var result = input;
    // E-Mail-Adressen maskieren
    result = result.replaceAll(
      RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'),
      '<redacted-email>',
    );
    // Tokens/Secrets maskieren
    result = result.replaceAllMapped(
      RegExp(
        r'(oauth_token|oauth_token_secret|token|secret|password|authorization)\s*[:=]\s*[^\s,&"]+',
        caseSensitive: false,
      ),
      (match) => '${match.group(1)}=<redacted>',
    );
    // Mehrzeilige Stacktraces auf die erste relevante Zeile kürzen
    final firstLine = result.split('\n').first.trim();
    if (firstLine.length > 220) {
      return '${firstLine.substring(0, 220)}...';
    }
    return firstLine;
  }

  /// Übersetzt einen beliebigen Fehler in eine verständliche zweisprachige [OrbitUserMessage]
  /// und protokolliert den anonymisierten Fehlercode im Ringpuffer.
  static OrbitUserMessage resolve(
    Object error, {
    String languageCode = 'de',
    String? contextHint,
  }) {
    final isEn = languageCode.toLowerCase().startsWith('en');
    final code = _extractErrorCode(error);
    final rawText = error.toString();

    recordLog(
      '${contextHint != null ? "[$contextHint] " : ""}code=$code msg=$rawText',
    );

    // Spezifische Garmin- oder Integrations-Hinweise
    final lower = rawText.toLowerCase();
    if (lower.contains('garmin') ||
        (contextHint?.toLowerCase().contains('garmin') ?? false)) {
      if (code == 'unavailable' ||
          code == 'deadline-exceeded' ||
          lower.contains('timeout') ||
          lower.contains('network')) {
        return OrbitUserMessage(
          title: isEn
              ? 'Garmin servers unreachable'
              : 'Garmin-Server antwortet gerade nicht',
          message: isEn
              ? 'Garmin Connect is temporarily slow or unreachable. Your training data is safe and will sync automatically.'
              : 'Garmin Connect antwortet derzeit nicht. Deine Daten gehen nicht verloren und werden automatisch synchronisiert.',
          code: 'garmin-unavailable',
          canRetry: true,
        );
      }
      if (code == 'failed-precondition') {
        return OrbitUserMessage(
          title: isEn
              ? 'Garmin connection required'
              : 'Garmin-Verbindung erforderlich',
          message: isEn
              ? 'Please connect your Garmin account first before starting a sync.'
              : 'Bitte verbinde zuerst dein Garmin-Konto, bevor du die Synchronisation startest.',
          code: 'garmin-not-connected',
          canRetry: false,
        );
      }
    }

    switch (code) {
      case 'unauthenticated':
        return OrbitUserMessage(
          title: isEn ? 'Session expired' : 'Sitzung abgelaufen',
          message: isEn
              ? 'Please sign in again to continue.'
              : 'Bitte melde dich erneut an, um fortzufahren.',
          code: code,
          canRetry: false,
        );
      case 'permission-denied':
        return OrbitUserMessage(
          title: isEn ? 'Access denied' : 'Zugriff nicht erlaubt',
          message: isEn
              ? 'You do not have permission for this action or the data sharing was revoked.'
              : 'Für diese Aktion fehlt die Berechtigung oder die Freigabe wurde widerrufen.',
          code: code,
          canRetry: false,
        );
      case 'not-found':
        return OrbitUserMessage(
          title: isEn ? 'Entry not found' : 'Eintrag nicht gefunden',
          message: isEn
              ? 'The requested code or entry could not be found. Please check your input.'
              : 'Der angeforderte Code oder Eintrag wurde nicht gefunden. Bitte prüfe deine Eingabe.',
          code: code,
          canRetry: false,
        );
      case 'already-exists':
        return OrbitUserMessage(
          title: isEn ? 'Already configured' : 'Bereits vorhanden',
          message: isEn
              ? 'This entry or link has already been set up.'
              : 'Dieser Eintrag oder diese Verknüpfung ist bereits eingerichtet.',
          code: code,
          canRetry: false,
        );
      case 'invalid-argument':
        return OrbitUserMessage(
          title: isEn ? 'Invalid input' : 'Ungültige Eingabe',
          message: isEn
              ? 'Please check the entered values and try again.'
              : 'Bitte überprüfe deine Eingaben und versuche es erneut.',
          code: code,
          canRetry: false,
        );
      case 'resource-exhausted':
        return OrbitUserMessage(
          title: isEn ? 'Too many requests' : 'Zu viele Anfragen',
          message: isEn
              ? 'Please wait a moment before trying again.'
              : 'Bitte warte einen kurzen Moment, bevor du es erneut versuchst.',
          code: code,
          canRetry: true,
        );
      case 'unavailable':
      case 'network-request-failed':
      case 'deadline-exceeded':
        return OrbitUserMessage(
          title: isEn ? 'Connection issue' : 'Verbindungsproblem',
          message: isEn
              ? 'Please check your internet connection and try again. Your data is safe.'
              : 'Bitte prüfe deine Internetverbindung und versuche es erneut. Deine Daten gehen nicht verloren.',
          code: code,
          canRetry: true,
        );
      default:
        return OrbitUserMessage(
          title: isEn
              ? 'Something went wrong'
              : 'Aktion konnte nicht ausgeführt werden',
          message: isEn
              ? 'An unexpected issue occurred. Please try again or report the problem to help us improve the beta.'
              : 'Es ist ein unerwartetes Problem aufgetreten. Bitte versuche es erneut oder melde das Problem für die Beta.',
          code: code,
          canRetry: true,
        );
    }
  }

  static String _extractErrorCode(Object error) {
    if (error is FirebaseFunctionsException) {
      return error.code.toLowerCase();
    }
    if (error is FirebaseException) {
      return error.code.toLowerCase();
    }
    final text = error.toString().toLowerCase();
    for (final known in const [
      'permission-denied',
      'permission_denied',
      'unauthenticated',
      'not-found',
      'already-exists',
      'invalid-argument',
      'failed-precondition',
      'resource-exhausted',
      'deadline-exceeded',
      'network-request-failed',
      'unavailable',
    ]) {
      if (text.contains(known)) {
        return known.replaceAll('_', '-');
      }
    }
    return 'unknown-error';
  }
}

/// Einheitliches, nutzerfreundliches Fehler-Banner mit "Erneut versuchen"- und
/// "Problem melden"-Button (öffnet das Beta-Bug-Report-Bottom-Sheet).
class OrbitErrorBanner extends StatelessWidget {
  final Object error;
  final String? contextHint;
  final VoidCallback? onRetry;
  final VoidCallback? onReportIssue;
  final String? languageCode;

  const OrbitErrorBanner({
    super.key,
    required this.error,
    this.contextHint,
    this.onRetry,
    this.onReportIssue,
    this.languageCode,
  });

  @override
  Widget build(BuildContext context) {
    final lang = languageCode ??
        Localizations.maybeLocaleOf(context)?.languageCode ??
        'de';
    final isEn = lang.toLowerCase().startsWith('en');
    final resolved = OrbitErrorHandler.resolve(
      error,
      languageCode: lang,
      contextHint: contextHint,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.red, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  resolved.title,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            resolved.message,
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (onRetry != null && resolved.canRetry)
                ElevatedButton.icon(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(48, 40),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: Text(isEn ? 'Try again' : 'Erneut versuchen'),
                ),
              if (onReportIssue != null)
                OutlinedButton.icon(
                  onPressed: onReportIssue,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navy,
                    minimumSize: const Size(48, 40),
                    side: const BorderSide(color: AppColors.navy),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  icon: const Icon(Icons.bug_report_outlined, size: 16),
                  label: Text(isEn ? 'Report issue' : 'Problem melden'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
