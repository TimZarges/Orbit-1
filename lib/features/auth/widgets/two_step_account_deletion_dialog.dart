/// Datei-Header: `lib/features/auth/widgets/two_step_account_deletion_dialog.dart`
/// Zweck: Zweistufiger Sicherheits-Dialog (DE & EN, Light & Dark Mode) für die
/// unwiderrufliche Löschung aller Daten und des ORBIT-Kontos nach Art. 17 DSGVO.
/// Architektur-Einordnung: Präsentationsschicht (`lib/features/auth/widgets/`),
/// nutzt [accountDeletionServiceProvider] zur Ausführung der Löschung (`AGENTS.md` Regel 10).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design/app_colors.dart';
import '../../settings/providers/settings_provider.dart';
import '../services/account_deletion_service.dart';

/// Zweistufiger Bestätigungs-Dialog für „Daten & Konto unwiderruflich löschen“.
///
/// Was:
/// - **Schritt 1:** Listet verständlich auf, welche Datenkategorien vollständig
///   entfernt werden (Profil, Aktivitäten, `.fit`-Dateien, Garmin-Tokens,
///   Coach-Verbindungen, Login-Konto).
/// - **Schritt 2:** Fordert eine aktive Bestätigungs-Checkbox vor der Freigabe
///   des finalen Lösch-Buttons.
/// Warum: Schützt vor versehentlichem Datenverlust und erfüllt DSGVO Art. 17.
class TwoStepAccountDeletionDialog extends ConsumerStatefulWidget {
  /// Optionaler Test-Callback anstelle des Cloud-Function-Aufrufs.
  final Future<void> Function()? onDeleteOverride;

  /// Erstellt den [TwoStepAccountDeletionDialog].
  const TwoStepAccountDeletionDialog({super.key, this.onDeleteOverride});

  /// Öffnet den zweistufigen Lösch-Dialog modal.
  static Future<bool?> show(
    BuildContext context, {
    Future<void> Function()? onDeleteOverride,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => TwoStepAccountDeletionDialog(
        onDeleteOverride: onDeleteOverride,
      ),
    );
  }

  @override
  ConsumerState<TwoStepAccountDeletionDialog> createState() =>
      _TwoStepAccountDeletionDialogState();
}

class _TwoStepAccountDeletionDialogState
    extends ConsumerState<TwoStepAccountDeletionDialog> {
  int _step = 0;
  bool _confirmed = false;
  bool _isDeleting = false;
  String? _errorText;

  /// Führt nach Abschluss von Schritt 2 die echte Kontolöschung aus.
  Future<void> _executeDeletion(bool isEn) async {
    if (!_confirmed || _isDeleting) return;
    setState(() {
      _isDeleting = true;
      _errorText = null;
    });

    try {
      if (widget.onDeleteOverride != null) {
        await widget.onDeleteOverride!();
      } else {
        await ref
            .read(accountDeletionServiceProvider)
            .deleteAccountAndSignOut();
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);

      // Benutzer zur Anmeldeseite weiterleiten und Vollzug melden
      try {
        GoRouter.of(context).go('/login');
      } catch (_) {}

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEn
                ? 'Your account and all data have been permanently deleted (GDPR Art. 17).'
                : 'Dein Konto und alle Daten wurden vollständig gelöscht (Art. 17 DSGVO).',
          ),
          backgroundColor: AppColors.coral,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
        _errorText =
            isEn ? 'Deletion failed: $e' : 'Löschung fehlgeschlagen: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(
      settingsControllerProvider.select((s) => s.languageCode),
    );
    final isEn = lang == 'en';
    final theme = Theme.of(context);

    const itemsDe = <String>[
      '• Dein ORBIT-Profil, Stammdaten und Login-Zugang (Firebase Auth)',
      '• Alle absolvierten Trainingseinheiten, Metriken und Verläufe',
      '• Alle hochgeladenen & synchronisierten .FIT-/.TCX-/.GPX-Dateien in Cloud Storage',
      '• Alle aktiven & offenen Coach-Athleten-Verbindungen und Einladungscodes',
      '• Alle Garmin Connect Verknüpfungen & Tokens',
    ];
    const itemsEn = <String>[
      '• Your ORBIT profile, personal details, and authentication credentials',
      '• All completed workouts, training metrics, and history',
      '• All .FIT/.TCX/.GPX files stored in Cloud Storage',
      '• All active & pending coach-athlete links and invite codes',
      '• All Garmin Connect tokens and integrations',
    ];

    return AlertDialog(
      key: const Key('two_step_delete_account_dialog'),
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _step == 0
                  ? (isEn
                      ? 'Delete Data & Account? (1/2)'
                      : 'Daten & Konto löschen? (1/2)')
                  : (isEn
                      ? 'Final Confirmation (2/2)'
                      : 'Endgültige Bestätigung (2/2)'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: _step == 0
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEn
                        ? 'Pursuant to GDPR Art. 17, the following data will be permanently and irreversibly erased:'
                        : 'Gemäß Art. 17 DSGVO werden folgende Daten vollständig und unwiderruflich gelöscht:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final line in (isEn ? itemsEn : itemsDe)) ...[
                    Text(line, style: theme.textTheme.bodySmall),
                    const SizedBox(height: 6),
                  ],
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEn
                        ? 'This action cannot be undone. Confirm below to permanently delete your account.'
                        : 'Dieser Vorgang kann nicht rückgängig gemacht werden. Bitte bestätige die endgültige Löschung:',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    key: const Key('delete_step2_confirm_checkbox'),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _confirmed,
                    onChanged: _isDeleting
                        ? null
                        : (val) => setState(() => _confirmed = val ?? false),
                    title: Text(
                      isEn
                          ? 'I understand that my account and all training data will be permanently erased.'
                          : 'Ich verstehe, dass mein Konto und alle Daten unwiderruflich gelöscht werden.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  if (_errorText != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _errorText!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
      ),
      actions: [
        TextButton(
          key: const Key('delete_dialog_cancel_btn'),
          onPressed:
              _isDeleting ? null : () => Navigator.of(context).pop(false),
          child: Text(isEn ? 'Cancel' : 'Abbrechen'),
        ),
        if (_step == 0)
          FilledButton(
            key: const Key('delete_step1_continue_btn'),
            onPressed: () => setState(() => _step = 1),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text(isEn ? 'Continue' : 'Weiter'),
          )
        else ...[
          TextButton(
            onPressed: _isDeleting
                ? null
                : () => setState(() {
                      _step = 0;
                      _confirmed = false;
                    }),
            child: Text(isEn ? 'Back' : 'Zurück'),
          ),
          FilledButton(
            key: const Key('delete_step2_confirm_btn'),
            onPressed: !_confirmed || _isDeleting
                ? null
                : () => _executeDeletion(isEn),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: _isDeleting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    isEn ? 'Delete Permanently' : 'Endgültig löschen',
                  ),
          ),
        ],
      ],
    );
  }
}
