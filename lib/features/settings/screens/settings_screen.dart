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
}
