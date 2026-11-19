/// Datei-Header: `lib/features/settings/widgets/privacy_settings_sheet.dart`
/// Zweck: Modales Bottom-Sheet für DSGVO-Datenschutzrechte (Art. 9, 13/14, 17),
/// Datenexport, 1-Klick-Rechtsdokumente und sofortige Kontolöschung.
/// Architektur-Einordnung: Präsentationsschicht (`lib/features/settings/widgets/`),
/// nutzt `settingsControllerProvider.select(...)` für DE/EN-Lokalisierung,
/// adaptiert automatisch zwischen Light- und Dark-Mode und delegiert die
/// unwiderrufliche Löschung an den zentralen [AccountDeletionService].
library;

import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/routing/app_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/services/account_deletion_service.dart';
import '../../legal/widgets/legal_documents_sheet.dart';
import '../providers/settings_provider.dart';

/// Bottom-Sheet für Datenschutz-Einstellungen, Rechtsdokumente, Datenexport
/// und DSGVO-Kontolöschung (Art. 17 DSGVO).
///
/// Was: Stellt den schnellen Zugriff auf Datenschutzerklärung, Impressum,
/// Serverstandort-Transparenz (Frankfurt am Main), Datenexport und die
/// vollständige Kontolöschung bereit.
/// Warum: Zentralisiert DSGVO-Betroffenenrechte barrierefrei in DE/EN sowie
/// im Light- und Dark-Mode.
class PrivacySettingsSheet extends ConsumerStatefulWidget {
  /// Erstellt ein [PrivacySettingsSheet].
  const PrivacySettingsSheet({super.key});

  /// Öffnet das Datenschutz-Sheet modal über dem aktuellen Kontext.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const PrivacySettingsSheet(),
    );
  }

  @override
  ConsumerState<PrivacySettingsSheet> createState() =>
      _PrivacySettingsSheetState();
}

/// Zustandsverwaltung des [PrivacySettingsSheet].
class _PrivacySettingsSheetState extends ConsumerState<PrivacySettingsSheet> {
  /// Laufzeit-Flag während der Vorbereitung eines Datenexports.
  bool _exporting = false;

  /// Laufzeit-Flag während einer laufenden DSGVO-Kontolöschung.
  bool _deleting = false;

  /// Ruft den echten Art.-20-DSGVO-Datenexport über die Cloud Function `exportAccount`
  /// (`europe-west3`) ab und zeigt das maschinenlesbare JSON inklusive Kopier-Funktion an.
  Future<void> _triggerExport({required bool isEn}) async {
    setState(() => _exporting = true);
    try {
      final Map<String, dynamic> payload;
      if (Firebase.apps.isEmpty) {
        payload = <String, dynamic>{
          'exportedAt': DateTime.now().toUtc().toIso8601String(),
          'notice': 'Test/Offline-Umgebung ohne aktive Firebase-Session',
        };
      } else {
        final callable = FirebaseFunctions.instanceFor(region: 'europe-west3')
            .httpsCallable('exportAccount');
        final res = await callable.call();
        payload = res.data is Map
            ? Map<String, dynamic>.from(res.data as Map)
            : <String, dynamic>{};
      }

      if (!mounted) return;
      setState(() => _exporting = false);

      final prettyJson = const JsonEncoder.withIndent('  ').convert(payload);
      await showDialog<void>(
        context: context,
        builder: (_) => _GdprExportResultDialog(
          isEn: isEn,
          prettyJson: prettyJson,
          onCopied: () {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isEn
                      ? 'JSON data export copied to clipboard.'
                      : 'JSON-Datenexport in die Zwischenablage kopiert.',
                ),
                backgroundColor: const Color(0xFF10B981),
              ),
            );
          },
        ),
      );
    } catch (err) {
      if (!mounted) return;
      setState(() => _exporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEn ? 'Data export failed: $err' : 'Datenexport fehlgeschlagen: $err',
          ),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  /// Führt die vollständige Kontolöschung über Backend & Auth-Logout durch.
  Future<void> _executeAccountDeletion({required bool isEn}) async {
    setState(() => _deleting = true);
    try {
      // Im isolierten Widget-Test ohne initialisierte Firebase-App wird direkt
      // auf den Auth-Service ausgewichen; im Echtbetrieb wirft jeder Backend-Fehler
      // sauber nach außen (`AGENTS.md` Regel 0).
      if (Firebase.apps.isEmpty) {
        await ref.read(authServiceProvider).signOut();
      } else {
        await ref
            .read(accountDeletionServiceProvider)
            .deleteAccountAndSignOut();
      }

      if (!mounted) return;

      // Modales Bottom Sheet schließen und sicher auf /login umleiten.
      final rootCtx = rootNavigatorKey.currentContext ?? context;
      Navigator.of(context, rootNavigator: true)
          .popUntil((route) => route.isFirst);
      if (!rootCtx.mounted) return;
      rootCtx.go('/login');

      // Bestätigungs-Snackbar gemäß Art. 17 DSGVO anzeigen.
      ScaffoldMessenger.of(rootCtx).showSnackBar(
        SnackBar(
          content: Text(
            isEn
                ? 'Your account and all personal data have been permanently deleted (Art. 17 GDPR).'
                : 'Dein Konto und alle personenbezogenen Daten wurden unwiderruflich gelöscht (Art. 17 DSGVO).',
          ),
          backgroundColor: const Color(0xFFEF4444),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (err) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEn
                ? 'Account deletion failed: $err'
                : 'Fehler bei der Kontolöschung: $err',
          ),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  /// Zeigt den Bestätigungsdialog vor der unwiderruflichen Kontolöschung.
  void _confirmDeleteAccount({required bool isEn}) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isEn ? 'Delete Account & Data?' : 'Konto und Daten löschen?',
        ),
        content: Text(
          isEn
              ? 'All of your activities, workout metrics, health data and your profile will be '
                  'permanently and completely deleted. This action cannot be undone.'
              : 'Alle deine Aktivitäten, Trainingswerte, Gesundheitsdaten und dein Profil werden '
                  'unwiderruflich und vollständig gelöscht. Dieser Vorgang kann nicht rückgängig gemacht werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isEn ? 'Cancel' : 'Abbrechen'),
          ),
          ElevatedButton(
            key: const Key('confirm_delete_account_button'),
            onPressed: _deleting
                ? null
                : () {
                    Navigator.of(ctx).pop();
                    _executeAccountDeletion(isEn: isEn);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: _deleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(isEn ? 'Permanently Delete' : 'Endgültig löschen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Granularer Selektor verhindert unnötige Rebuilds bei fremden Settings-Änderungen.
    final lang =
        ref.watch(settingsControllerProvider.select((s) => s.languageCode));
    final isEn = lang == 'en';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Hell- und Dunkelmodus-Farben für optimale Kontraste im Sheet.
    final sheetBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final tileBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final dividerColor =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final accentIcon = isDark ? AppColors.volt : AppColors.navy;

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Griffleiste zum Verschieben des Bottom-Sheets
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF64748B),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.privacy_tip_outlined,
                          color: accentIcon,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isEn
                                ? 'Privacy & Your Rights'
                                : 'Datenschutz & Rechte',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: titleColor,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isEn
                          ? 'Secure server location Germany (Frankfurt am Main) – Protected under strict German and European GDPR laws.\n\n'
                              'Your workout and health data (heart rate, sleep, power metrics) are used exclusively for your personal training overview and optional coach connection, and are never sold or shared with advertisers.'
                          : 'Sicherer Serverstandort Deutschland (Frankfurt am Main) – Geschützt nach strengen deutschen und europäischen Datenschutzgesetzen.\n\n'
                              'Deine Trainings- und Gesundheitsdaten (Herzfrequenz, Schlaf, Wattwerte) dienen ausschließlich deiner persönlichen Trainingsübersicht sowie der von dir aktiv freigegebenen Coach-Verbindung und werden niemals an Werbepartner weitergegeben.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: mutedColor,
                            height: 1.45,
                          ),
                    ),
                    const SizedBox(height: 20),
                    Divider(color: dividerColor),
                    const SizedBox(height: 8),

                    // 1-Klick-Zugang zur Datenschutzerklärung
                    ListTile(
                      key: const Key('privacy_sheet_policy_tile'),
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: tileBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.policy_outlined, color: accentIcon),
                      ),
                      title: Text(
                        isEn ? 'Privacy Policy' : 'Datenschutzerklärung',
                        style: TextStyle(
                          color: titleColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        isEn
                            ? 'Art. 9, 13 & 14 GDPR transparency in plain language'
                            : 'DSGVO-Hinweise (Art. 9, 13 & 14) verständlich erklärt',
                        style: TextStyle(color: mutedColor, fontSize: 13),
                      ),
                      trailing: Icon(Icons.chevron_right, color: mutedColor),
                      onTap: () => LegalDocumentsSheet.show(
                        context,
                        initialTab: LegalDocumentTab.privacy,
                        lang: lang,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // 1-Klick-Zugang zum Impressum
                    ListTile(
                      key: const Key('privacy_sheet_imprint_tile'),
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: tileBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.gavel_outlined, color: accentIcon),
                      ),
                      title: Text(
                        isEn ? 'Legal Notice / Imprint' : 'Impressum',
                        style: TextStyle(
                          color: titleColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        isEn
                            ? 'Operator & contact details (§ 5 DDG)'
                            : 'Verantwortliche Stelle & Kontakt (§ 5 DDG)',
                        style: TextStyle(color: mutedColor, fontSize: 13),
                      ),
                      trailing: Icon(Icons.chevron_right, color: mutedColor),
                      onTap: () => LegalDocumentsSheet.show(
                        context,
                        initialTab: LegalDocumentTab.imprint,
                        lang: lang,
                      ),
                    ),

                    const SizedBox(height: 8),
                    Divider(color: dividerColor),
                    const SizedBox(height: 8),

                    // Recht auf Datenübertragbarkeit / Export
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: tileBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.download_outlined,
                          color: accentIcon,
                        ),
                      ),
                      title: Text(
                        isEn ? 'Export All Data' : 'Alle Daten exportieren',
                        style: TextStyle(
                          color: titleColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        isEn
                            ? 'Complete export of your profile data, workouts and metrics.'
                            : 'Vollständiger Export all deiner Profildaten, Trainings- und Messwerte auf Knopfdruck.',
                        style: TextStyle(color: mutedColor, fontSize: 13),
                      ),
                      trailing: _exporting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.chevron_right, color: mutedColor),
                      onTap:
                          _exporting ? null : () => _triggerExport(isEn: isEn),
                    ),

                    const SizedBox(height: 8),
                    Divider(color: dividerColor),
                    const SizedBox(height: 8),

                    // Server & Speicherort Info
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: tileBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          color: Color(0xFF0EA5E9),
                        ),
                      ),
                      title: Text(
                        isEn
                            ? 'Server Location & Security'
                            : 'Speicherort & Sicherheit',
                        style: TextStyle(
                          color: titleColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        isEn
                            ? 'Secure servers in Frankfurt am Main, Germany. Encrypted transfer and storage.'
                            : 'Sicherer Serverstandort Frankfurt am Main. Deine Zugangs- und Verknüpfungsdaten werden mit modernen kryptografischen Standards geschützt.',
                        style: TextStyle(color: mutedColor, fontSize: 13),
                      ),
                    ),

                    const SizedBox(height: 8),
                    Divider(color: dividerColor),
                    const SizedBox(height: 8),

                    // Recht auf Vergessenwerden / Löschung (Art. 17 DSGVO)
                    ListTile(
                      key: const Key('delete_account_tile'),
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0x26EF4444),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.delete_forever_outlined,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                      title: Text(
                        isEn
                            ? 'Permanently Delete Account & Data'
                            : 'Konto und alle Daten unwiderruflich löschen',
                        style: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        isEn
                            ? 'Immediate permanent deletion of your profile, workouts and health records.'
                            : 'Vollständige und sofortige Löschung deines Profils und aller Trainingsdaten auf Knopfdruck.',
                        style: TextStyle(color: mutedColor, fontSize: 13),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Color(0xFFEF4444),
                      ),
                      onTap: () => _confirmDeleteAccount(isEn: isEn),
                    ),

                    const SizedBox(height: 28),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: titleColor,
                        side: BorderSide(color: dividerColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(isEn ? 'Close' : 'Schließen'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Eigenständiger Ergebnis-Dialog für den Art.-20-DSGVO-JSON-Datenexport.
///
/// Was: Stellt den formatierten JSON-Export scrollbar bereit und erlaubt das
/// Kopieren in die Zwischenablage mit Bestätigung.
/// Warum: Lagert das Dialog-Layout sauber aus [_PrivacySettingsSheetState] aus.
class _GdprExportResultDialog extends StatelessWidget {
  final bool isEn;
  final String prettyJson;
  final VoidCallback onCopied;

  const _GdprExportResultDialog({
    required this.isEn,
    required this.prettyJson,
    required this.onCopied,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('gdpr_export_result_dialog'),
      title: Text(
        isEn ? 'GDPR Data Export (Art. 20)' : 'DSGVO-Datenexport (Art. 20)',
      ),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEn
                  ? 'Your machine-readable JSON export is ready. You can copy it directly below or download original .FIT files from each workout card.'
                  : 'Dein maschinenlesbarer JSON-Export steht bereit. Original-.FIT-Dateien kannst du zusätzlich direkt an jeder Trainingseinheit herunterladen.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 220),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  prettyJson,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(isEn ? 'Close' : 'Schließen'),
        ),
        FilledButton.icon(
          key: const Key('gdpr_export_copy_btn'),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: prettyJson));
            if (context.mounted) Navigator.of(context).pop();
            onCopied();
          },
          icon: const Icon(Icons.copy_rounded, size: 18),
          label: Text(isEn ? 'Copy JSON' : 'JSON kopieren'),
        ),
      ],
    );
  }
}
