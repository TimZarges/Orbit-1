import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:orbit/features/settings/providers/settings_provider.dart';
import 'package:orbit/features/settings/models/app_settings.dart';
import 'package:orbit/features/settings/widgets/privacy_settings_sheet.dart';
import 'package:orbit/features/auth/providers/auth_provider.dart';
import 'package:orbit/features/beta_feedback/widgets/beta_bug_reporter_sheet.dart';
import 'package:orbit/core/metrics/term_resolver.dart';
import 'package:orbit/core/design/app_colors.dart';
import 'package:orbit/core/localization/app_strings.dart';

/// Einstellungs- und Präferenz-Bildschirm der ORBIT-Applikation.
///
/// Bietet Konfigurationsmöglichkeiten für Sprache (DE/EN), Maßeinheiten (Metrisch/Imperial),
/// Erfahrungsstufe (Einsteiger/Fortgeschritten/Pro), Datenschutz- und DSGVO-Exporte,
/// Account-Aktionen (Logout, Profil löschen) sowie Entwickler-Werkzeuge.
class SettingsScreen extends ConsumerWidget {
  /// Erstellt den Einstellungs-Bildschirm.
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
        actions: const [
          BetaBugReportIconButton(),
        ],
      ),
      body: ListView(
        children: [
          // Sprache
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Sprache'),
            subtitle:
                Text(settings.languageCode == 'de' ? 'Deutsch' : 'English'),
            trailing: DropdownButton<String>(
              value: settings.languageCode,
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

          // Einheiten
          ListTile(
            leading: const Icon(Icons.straighten),
            title: const Text('Einheiten'),
            subtitle: Text(
                AppStrings.measurementSystemLabel(settings.measurementSystem)),
            trailing: DropdownButton<MeasurementSystem>(
              value: settings.measurementSystem,
              items: [
                DropdownMenuItem(
                    value: MeasurementSystem.metric,
                    child: Text(AppStrings.measurementSystemLabel(
                        MeasurementSystem.metric))),
                DropdownMenuItem(
                    value: MeasurementSystem.imperial,
                    child: Text(AppStrings.measurementSystemLabel(
                        MeasurementSystem.imperial))),
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

          // Theme
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Darstellung'),
            subtitle: Text(AppStrings.themeModeLabel(settings.themeMode)),
            trailing: DropdownButton<ThemeMode>(
              value: settings.themeMode,
              items: [
                DropdownMenuItem(
                    value: ThemeMode.system,
                    child: Text(AppStrings.themeModeLabel(ThemeMode.system))),
                DropdownMenuItem(
                    value: ThemeMode.light,
                    child: Text(AppStrings.themeModeLabel(ThemeMode.light))),
                DropdownMenuItem(
                    value: ThemeMode.dark,
                    child: Text(AppStrings.themeModeLabel(ThemeMode.dark))),
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

          // Erfahrungsstufe
          ListTile(
            leading: const Icon(Icons.school),
            title: const Text('Erfahrungsstufe'),
            subtitle:
                Text(AppStrings.experienceLevelLabel(settings.experienceLevel)),
            trailing: DropdownButton<ExperienceLevel>(
              value: settings.experienceLevel,
              items: [
                DropdownMenuItem(
                    value: ExperienceLevel.beginner,
                    child: Text(AppStrings.experienceLevelLabel(
                        ExperienceLevel.beginner))),
                DropdownMenuItem(
                    value: ExperienceLevel.advanced,
                    child: Text(AppStrings.experienceLevelLabel(
                        ExperienceLevel.advanced))),
                DropdownMenuItem(
                    value: ExperienceLevel.expert,
                    child: Text(AppStrings.experienceLevelLabel(
                        ExperienceLevel.expert))),
              ],
              onChanged: (val) {
                if (val != null) {
                  ref
                      .read(settingsControllerProvider.notifier)
                      .setExperienceLevel(val);
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  if (uid != null) {
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .set({
                      'settings': {'experienceLevel': val.name},
                      'profile': {'experienceLevel': val.name.toUpperCase()},
                    }, SetOptions(merge: true)).catchError((_) {});
                  }
                }
              },
            ),
          ),

          const Divider(),

          // Externe Verbindungen
          ListTile(
            leading: const Icon(Icons.sync_alt),
            title: const Text('Verbindungen (Garmin)'),
            subtitle: const Text('Garmin Connect verknüpfen oder verwalten'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.go('/settings/garmin');
            },
          ),

          const Divider(),

          // Datenschutz
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Datenschutz'),
            subtitle:
                const Text('Gesundheitsdaten widerrufen, Datenexport, DSGVO'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              PrivacySettingsSheet.show(context);
            },
          ),

          const Divider(),

          // Feedback & Bug melden
          ListTile(
            leading:
                const Icon(Icons.bug_report_outlined, color: AppColors.volt),
            title: const Text('Fehler melden & Verbesserung vorschlagen'),
            subtitle:
                const Text('Direktes Feedback an das ORBIT-Entwicklerteam'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showBetaBugReporterSheet(context);
            },
          ),

          const Divider(),

          // Meine gemeldeten Tickets (Phase 38.4)
          ListTile(
            key: const Key('settings_my_feedback_tile'),
            leading: const Icon(Icons.inbox_outlined, color: AppColors.volt),
            title: const Text('Meine gemeldeten Tickets'),
            subtitle: const Text('Status deiner Bug-Reports und Feedback-Vorschläge'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push('/my-feedback');
            },
          ),

          const Divider(),

          // Passwort ändern (Phase 36.1)
          ListTile(
            key: const Key('settings_change_password_tile'),
            leading: const Icon(Icons.lock_reset, color: AppColors.volt),
            title: const Text('Passwort ändern'),
            subtitle:
                const Text('Sichere Aktualisierung deines Login-Passworts'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showChangePasswordDialog(context, ref);
            },
          ),

          const Divider(),

          // Abmelden
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              'Abmelden',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: const Text('Aus diesem Konto abmelden'),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Abmelden?'),
                  content: const Text(
                      'Möchtest du dich wirklich von ORBIT abmelden?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Abbrechen'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                      ),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text(
                        'Abmelden',
                        style: TextStyle(color: Colors.white),
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
        ],
      ),
    );
  }

  /// Öffnet den Dialog zur Änderung des Passworts mit Live-Validierungs-Checkliste.
  Future<void> _showChangePasswordDialog(
      BuildContext context, WidgetRef ref) async {
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
          final matchesConfirm =
              confirmPw.isNotEmpty && confirmPw == newPw;
          final allValid = hasMinLength &&
              hasUpper &&
              hasLower &&
              hasDigitOrSpecial &&
              matchesConfirm;

          return AlertDialog(
            backgroundColor: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFF1E293B)),
            ),
            title: const Text(
              'Passwort ändern',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                        labelText: 'Aktuelles Passwort',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: const Color(0xFF001F47),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (val) => (val == null || val.isEmpty)
                          ? 'Bitte aktuelles Passwort eingeben'
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
                        labelText: 'Neues Passwort',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: const Color(0xFF001F47),
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
                        labelText: 'Neues Passwort bestätigen',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: const Color(0xFF001F47),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildCriterion(hasMinLength, 'Mindestens 8 Zeichen'),
                    _buildCriterion(
                        hasUpper, 'Mindestens 1 Großbuchstabe (A-Z)'),
                    _buildCriterion(
                        hasLower, 'Mindestens 1 Kleinbuchstabe (a-z)'),
                    _buildCriterion(
                        hasDigitOrSpecial, 'Mindestens 1 Zahl oder Sonderzeichen'),
                    _buildCriterion(
                        matchesConfirm, 'Passwörter stimmen überein'),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Abbrechen',
                    style: TextStyle(color: Colors.white54)),
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
                                const SnackBar(
                                  content:
                                      Text('Passwort erfolgreich aktualisiert.'),
                                  backgroundColor: AppColors.emerald,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Fehler beim Ändern des Passworts: $e'),
                                  backgroundColor: AppColors.coral,
                                ),
                              );
                            }
                          }
                        }
                      }
                    : null,
                child: const Text('Speichern',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

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
