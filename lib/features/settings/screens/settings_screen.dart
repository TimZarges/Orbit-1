/// Datei-Header: `lib/features/settings/screens/settings_screen.dart`
/// Zweck: Einstellungs- und Präferenz-Bildschirm der ORBIT-Applikation (Phase 41).
/// Architektur-Einordnung: Präsentationsschicht (`lib/features/settings/screens/`),
/// nutzt granulare Riverpod-Selektoren (`ref.watch(settingsControllerProvider.select(...))`)
/// gemäß `AGENTS.md` Regel 10, unterstützt Echtzeit-Wechsel zwischen Deutsch (`de`)
/// und Englisch (`en`), Hell/Dunkel/System-Modus sowie Wohnland-Auswahl (`dd.mm.yy` & `24h`).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/release_config.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/metrics/term_resolver.dart';
import '../../../core/utils/country_date_time_formatter.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/widgets/two_step_account_deletion_dialog.dart';
import '../../beta_feedback/widgets/beta_bug_reporter_sheet.dart';
import '../../legal/widgets/legal_documents_sheet.dart';
import '../models/app_settings.dart';
import '../providers/settings_provider.dart';
import '../widgets/privacy_settings_sheet.dart';

/// Einstellungs- und Präferenz-Bildschirm der ORBIT-Applikation.
///
/// Was: Bietet Konfigurationsmöglichkeiten für Sprache (DE/EN), Wohnland (`dd.mm.yy` & `24h`),
/// Maßeinheiten (Metrisch/Imperial), Darstellung (Hell/Dunkel/System), Erfahrungsstufe
/// (in V2/V3), Datenschutz- und DSGVO-Exporte sowie Account-Aktionen (Passwort ändern, Logout).
/// Warum: Nutzt granulare Riverpod-Selektoren (`select`), um unnötige Widget-Rebuilds
/// zu vermeiden (`AGENTS.md` Regel 10).
class SettingsScreen extends ConsumerWidget {
  /// Erstellt den Einstellungs-Bildschirm.
  const SettingsScreen({super.key});

  /// Unterstützte Wohnländer im Dropdown.
  static const List<String> _selectableCountries = [
    'DE',
    'AT',
    'CH',
    'LU',
    'NL',
    'BE',
    'FR',
    'IT',
    'ES',
    'GB',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Granulare Selektoren gemäß Effizienz-Gebot (AGENTS.md Regel 10)
    final lang = ref.watch(
      settingsControllerProvider.select((s) => s.languageCode),
    );
    final countryCode = ref.watch(
      settingsControllerProvider.select((s) => s.countryCode),
    );
    final measurementSystem = ref.watch(
      settingsControllerProvider.select((s) => s.measurementSystem),
    );
    final themeMode = ref.watch(
      settingsControllerProvider.select((s) => s.themeMode),
    );
    final experienceLevel = ref.watch(
      settingsControllerProvider.select((s) => s.experienceLevel),
    );
    final isV2Enabled = ref.watch(
      releaseConfigProvider.select((cfg) => cfg.isV2Enabled),
    );

    final isEn = lang == 'en';

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.navSettings(lang: lang)),
        actions: const [
          BetaBugReportIconButton(),
        ],
      ),
      body: ListView(
        children: [
          // 1. Sprache (DE & EN)
          ListTile(
            key: const Key('settings_language_tile'),
            leading: const Icon(Icons.language),
            title: Text(AppStrings.settingsLanguageTitle(lang: lang)),
            subtitle: Text(isEn ? 'English' : 'Deutsch'),
            trailing: DropdownButton<String>(
              key: const Key('settings_language_dropdown'),
              value: lang,
              items: const [
                DropdownMenuItem(value: 'de', child: Text('DE')),
                DropdownMenuItem(value: 'en', child: Text('EN')),
              ],
              onChanged: (val) {
                if (val != null) {
                  ref
                      .read(settingsControllerProvider.notifier)
                      .setLanguage(val);
                }
              },
            ),
          ),

          // 2. Wohnland (steuert dd.mm.yy & 24h-Uhrzeitformat)
          ListTile(
            key: const Key('settings_country_tile'),
            leading: const Icon(Icons.public),
            title: Text(AppStrings.settingsCountryTitle(lang: lang)),
            subtitle: Text(
              '${CountryDateTimeFormatter.countryLabel(countryCode, lang: lang)} • '
              '${CountryDateTimeFormatter.formatDateTime(DateTime(2026, 10, 21, 19, 54), countryCode: countryCode)}',
            ),
            trailing: DropdownButton<String>(
              key: const Key('settings_country_dropdown'),
              value: _selectableCountries.contains(countryCode)
                  ? countryCode
                  : 'DE',
              items: _selectableCountries
                  .map(
                    (code) => DropdownMenuItem<String>(
                      value: code,
                      child: Text(code),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  ref
                      .read(settingsControllerProvider.notifier)
                      .setCountryCode(val);
                }
              },
            ),
          ),

          // 3. Einheiten (Metrisch / Imperial)
          ListTile(
            key: const Key('settings_units_tile'),
            leading: const Icon(Icons.straighten),
            title: Text(AppStrings.settingsUnitsTitle(lang: lang)),
            subtitle: Text(
              AppStrings.measurementSystemLabel(measurementSystem, lang: lang),
            ),
            trailing: DropdownButton<MeasurementSystem>(
              key: const Key('settings_units_dropdown'),
              value: measurementSystem,
              items: [
                DropdownMenuItem(
                  value: MeasurementSystem.metric,
                  child: Text(
                    AppStrings.measurementSystemLabel(
                      MeasurementSystem.metric,
                      lang: lang,
                    ),
                  ),
                ),
                DropdownMenuItem(
                  value: MeasurementSystem.imperial,
                  child: Text(
                    AppStrings.measurementSystemLabel(
                      MeasurementSystem.imperial,
                      lang: lang,
                    ),
                  ),
                ),
              ],
              onChanged: (val) {
                if (val != null) {
                  ref
                      .read(settingsControllerProvider.notifier)
                      .setMeasurementSystem(val);
                }
              },
            ),
          ),

          // 4. Darstellung (Hell / Dunkel / System)
          ListTile(
            key: const Key('settings_theme_tile'),
            leading: const Icon(Icons.brightness_6),
            title: Text(AppStrings.settingsThemeTitle(lang: lang)),
            subtitle: Text(AppStrings.themeModeLabel(themeMode, lang: lang)),
            trailing: DropdownButton<ThemeMode>(
              key: const Key('settings_theme_dropdown'),
              value: themeMode,
              items: [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text(
                    AppStrings.themeModeLabel(ThemeMode.system, lang: lang),
                  ),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text(
                    AppStrings.themeModeLabel(ThemeMode.light, lang: lang),
                  ),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text(
                    AppStrings.themeModeLabel(ThemeMode.dark, lang: lang),
                  ),
                ),
              ],
              onChanged: (val) {
                if (val != null) {
                  ref
                      .read(settingsControllerProvider.notifier)
                      .setThemeMode(val);
                }
              },
            ),
          ),

          // 5. Erfahrungsstufe (In V1.0.0 fest auf "Einfach", Auswahl ab V2.0.0 aktiv)
          if (isV2Enabled)
            ListTile(
              key: const Key('settings_experience_tile'),
              leading: const Icon(Icons.school),
              title: Text(AppStrings.settingsExperienceTitle(lang: lang)),
              subtitle: Text(
                AppStrings.experienceLevelLabel(experienceLevel, lang: lang),
              ),
              trailing: DropdownButton<ExperienceLevel>(
                value: experienceLevel,
                items: [
                  DropdownMenuItem(
                    value: ExperienceLevel.beginner,
                    child: Text(
                      AppStrings.experienceLevelLabel(
                        ExperienceLevel.beginner,
                        lang: lang,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: ExperienceLevel.advanced,
                    child: Text(
                      AppStrings.experienceLevelLabel(
                        ExperienceLevel.advanced,
                        lang: lang,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: ExperienceLevel.expert,
                    child: Text(
                      AppStrings.experienceLevelLabel(
                        ExperienceLevel.expert,
                        lang: lang,
                      ),
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    ref
                        .read(settingsControllerProvider.notifier)
                        .setExperienceLevel(val);
                  }
                },
              ),
            ),

          const Divider(),

          // 6. Externe Verbindungen (Garmin)
          ListTile(
            leading: const Icon(Icons.sync_alt),
            title: Text(AppStrings.settingsGarminTitle(lang: lang)),
            subtitle: Text(AppStrings.settingsGarminSubtitle(lang: lang)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.go('/settings/garmin');
            },
          ),

          const Divider(),

          // 7. Datenschutz (DSGVO Art. 9, 13/14, 17)
          ListTile(
            key: const Key('settings_privacy_tile'),
            leading: const Icon(Icons.privacy_tip),
            title: Text(AppStrings.settingsPrivacyTitle(lang: lang)),
            subtitle: Text(AppStrings.settingsPrivacySubtitle(lang: lang)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              PrivacySettingsSheet.show(context);
            },
          ),

          // 7b. Impressum & Rechtliche Hinweise (1-Klick-Zugang DE/EN)
          ListTile(
            key: const Key('settings_legal_imprint_tile'),
            leading: const Icon(Icons.gavel_outlined),
            title: Text(
              isEn
                  ? 'Legal Notice & Privacy Policy'
                  : 'Impressum & Datenschutzerklärung',
            ),
            subtitle: Text(
              isEn
                  ? 'Operator info (§ 5 DDG) & full GDPR transparency'
                  : 'Anbieterkennzeichnung (§ 5 DDG) & DSGVO-Hinweise',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              LegalDocumentsSheet.show(
                context,
                initialTab: LegalDocumentTab.imprint,
              );
            },
          ),

          const Divider(),

          // 8. Fehler melden & Verbesserung vorschlagen
          ListTile(
            leading:
                const Icon(Icons.bug_report_outlined, color: AppColors.volt),
            title: Text(AppStrings.settingsBugReportTitle(lang: lang)),
            subtitle: Text(AppStrings.settingsBugReportSubtitle(lang: lang)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showBetaBugReporterSheet(context);
            },
          ),

          const Divider(),

          // 9. Meine gemeldeten Tickets
          ListTile(
            key: const Key('settings_my_feedback_tile'),
            leading: const Icon(Icons.inbox_outlined, color: AppColors.volt),
            title: Text(AppStrings.navMyFeedback(lang: lang)),
            subtitle: Text(AppStrings.settingsMyFeedbackSubtitle(lang: lang)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push('/my-feedback');
            },
          ),

          const Divider(),

          // 10. Passwort ändern & Passwort zurücksetzen
          ListTile(
            key: const Key('settings_change_password_tile'),
            leading: const Icon(Icons.lock_reset, color: AppColors.volt),
            title: Text(AppStrings.settingsChangePasswordTitle(lang: lang)),
            subtitle:
                Text(AppStrings.settingsChangePasswordSubtitle(lang: lang)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showChangePasswordDialog(context, ref, lang: lang);
            },
          ),
          ListTile(
            key: const Key('settings_reset_password_email_tile'),
            leading: const Icon(
              Icons.mark_email_read_outlined,
              color: AppColors.volt,
            ),
            title: Text(
              isEn
                  ? 'Reset Password (Email Link)'
                  : 'Passwort zurücksetzen (E-Mail-Link)',
            ),
            subtitle: Text(
              isEn
                  ? 'Send a reset link to your email address'
                  : 'Sicherer Link zum Zurücksetzen an deine E-Mail senden',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                _showResetPasswordEmailDialog(context, ref, isEn: isEn),
          ),

          const Divider(),

          // 11. Abmelden
          ListTile(
            key: const Key('settings_logout_tile'),
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: Text(
              AppStrings.navLogout(lang: lang),
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(AppStrings.settingsLogoutSubtitle(lang: lang)),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(isEn ? 'Sign Out?' : 'Abmelden?'),
                  content: Text(
                    isEn
                        ? 'Do you really want to sign out of ORBIT?'
                        : 'Möchtest du dich wirklich von ORBIT abmelden?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text(isEn ? 'Cancel' : 'Abbrechen'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                      ),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text(
                        AppStrings.navLogout(lang: lang),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await ref.read(authServiceProvider).signOut();
              }
            },
          ),

          const Divider(),

          // 12. Konto & alle Daten unwiderruflich löschen (2-Stufen Art. 17 DSGVO)
          ListTile(
            key: const Key('settings_delete_account_tile'),
            leading: const Icon(
              Icons.delete_forever_outlined,
              color: Colors.redAccent,
            ),
            title: Text(
              isEn ? 'Delete Data & Account' : 'Daten & Konto löschen',
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              isEn
                  ? 'Permanently delete profile, workouts and health data (Art. 17 GDPR)'
                  : 'Profil, Trainings & Gesundheitsdaten unwiderruflich löschen (Art. 17 DSGVO)',
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.redAccent),
            onTap: () {
              TwoStepAccountDeletionDialog.show(context);
            },
          ),
        ],
      ),
    );
  }

  /// Öffnet den Dialog zum Senden einer Passwort-Zurücksetzen-E-Mail direkt aus den Einstellungen.
  Future<void> _showResetPasswordEmailDialog(
    BuildContext context,
    WidgetRef ref, {
    required bool isEn,
  }) async {
    final emailCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSending = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: Text(
            isEn ? 'Reset Password' : 'Passwort zurücksetzen',
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              key: const Key('settings_reset_password_email_field'),
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: isEn ? 'Email Address' : 'E-Mail-Adresse',
              ),
              validator: (val) =>
                  (val == null || val.trim().isEmpty || !val.contains('@'))
                      ? (isEn
                          ? 'Please enter a valid email address'
                          : 'Bitte gib eine gültige E-Mail-Adresse ein')
                      : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSending ? null : () => Navigator.of(ctx).pop(),
              child: Text(isEn ? 'Cancel' : 'Abbrechen'),
            ),
            ElevatedButton(
              key: const Key('settings_reset_password_submit_button'),
              onPressed: isSending
                  ? null
                  : () async {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      final target = emailCtrl.text.trim();
                      setDialogState(() => isSending = true);
                      try {
                        await ref
                            .read(authServiceProvider)
                            .resetPassword(target);
                        if (!context.mounted) return;
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isEn
                                  ? 'Reset link sent to $target.'
                                  : 'Link zum Zurücksetzen an $target gesendet.',
                            ),
                            backgroundColor: AppColors.emerald,
                          ),
                        );
                      } catch (e) {
                        if (ctx.mounted) {
                          setDialogState(() => isSending = false);
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isEn
                                    ? 'Could not send email: $e'
                                    : 'E-Mail konnte nicht gesendet werden: $e',
                              ),
                              backgroundColor: AppColors.coral,
                            ),
                          );
                        }
                      }
                    },
              child: isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEn ? 'Send Link' : 'Link senden'),
            ),
          ],
        ),
      ),
    );
  }

  /// Öffnet den Dialog zur Änderung des Passworts mit Live-Validierungs-Checkliste.
  ///
  /// [context]: Aktueller BuildContext.
  /// [ref]: Riverpod WidgetRef.
  /// [lang]: Aktiver Sprachcode (`'de'` oder `'en'`).
  Future<void> _showChangePasswordDialog(
    BuildContext context,
    WidgetRef ref, {
    String lang = 'de',
  }) async {
    // Initialisiert Controller und Form-Key für den Passwort-Dialog
    final isEn = lang == 'en';
    final oldPwController = TextEditingController();
    final newPwController = TextEditingController();
    final confirmPwController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final newPw = newPwController.text;
          final confirmPw = confirmPwController.text;
          final hasMinLength = newPw.length >= 8;
          final hasUpper = newPw.contains(RegExp(r'[A-Z]'));
          final hasLower = newPw.contains(RegExp(r'[a-z]'));
          final hasDigitOrSpecial =
              newPw.contains(RegExp(r'[0-9!@#\$%^&*(),.?":{}|<>]'));
          final matchesConfirm = confirmPw.isNotEmpty && confirmPw == newPw;
          final allValid = hasMinLength &&
              hasUpper &&
              hasLower &&
              hasDigitOrSpecial &&
              matchesConfirm;

          return AlertDialog(
            backgroundColor: AppColors.anthraciteCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.darkSubtleBorder),
            ),
            title: Text(
              AppStrings.settingsChangePasswordTitle(lang: lang),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      key: const Key('change_password_old_field'),
                      controller: oldPwController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText:
                            isEn ? 'Current password' : 'Aktuelles Passwort',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: AppColors.carbonDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (val) => (val == null || val.isEmpty)
                          ? (isEn
                              ? 'Please enter your current password'
                              : 'Bitte aktuelles Passwort eingeben')
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('change_password_new_field'),
                      controller: newPwController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(
                        labelText: isEn ? 'New password' : 'Neues Passwort',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: AppColors.carbonDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('change_password_confirm_field'),
                      controller: confirmPwController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(
                        labelText: isEn
                            ? 'Confirm new password'
                            : 'Neues Passwort bestätigen',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: AppColors.carbonDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildCriterion(
                      hasMinLength,
                      isEn ? 'At least 8 characters' : 'Mindestens 8 Zeichen',
                    ),
                    _buildCriterion(
                      hasUpper,
                      isEn
                          ? 'At least 1 uppercase letter (A-Z)'
                          : 'Mindestens 1 Großbuchstabe (A-Z)',
                    ),
                    _buildCriterion(
                      hasLower,
                      isEn
                          ? 'At least 1 lowercase letter (a-z)'
                          : 'Mindestens 1 Kleinbuchstabe (a-z)',
                    ),
                    _buildCriterion(
                      hasDigitOrSpecial,
                      isEn
                          ? 'At least 1 digit or special character'
                          : 'Mindestens 1 Zahl oder Sonderzeichen',
                    ),
                    _buildCriterion(
                      matchesConfirm,
                      isEn ? 'Passwords match' : 'Passwörter stimmen überein',
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  isEn ? 'Cancel' : 'Abbrechen',
                  style: const TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                key: const Key('change_password_save_button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      allValid ? AppColors.volt : Colors.grey.shade700,
                  foregroundColor: AppColors.navy,
                ),
                onPressed: allValid
                    ? () async {
                        if (formKey.currentState?.validate() ?? false) {
                          try {
                            await ref.read(authServiceProvider).changePassword(
                                  oldPwController.text,
                                  newPwController.text,
                                );
                            if (context.mounted) {
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isEn
                                        ? 'Password updated successfully.'
                                        : 'Passwort erfolgreich aktualisiert.',
                                  ),
                                  backgroundColor: AppColors.emerald,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isEn
                                        ? 'Failed to change password: $e'
                                        : 'Fehler beim Ändern des Passworts: $e',
                                  ),
                                  backgroundColor: AppColors.coral,
                                ),
                              );
                            }
                          }
                        }
                      }
                    : null,
                child: Text(
                  isEn ? 'Save' : 'Speichern',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Rendert eine einzelne Kriterien-Zeile innerhalb des Passwort-Dialogs.
  Widget _buildCriterion(bool satisfied, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(
            satisfied
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 14,
            color: satisfied ? AppColors.emerald : Colors.white38,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: satisfied ? Colors.white : Colors.white60,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
