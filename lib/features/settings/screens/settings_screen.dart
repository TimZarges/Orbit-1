import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit/features/settings/providers/settings_provider.dart';
import 'package:orbit/features/settings/models/app_settings.dart';
import 'package:orbit/core/metrics/term_resolver.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
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
                settings.measurementSystem == MeasurementSystem.metric
                    ? 'Metrisch (km, kg)'
                    : 'Imperial (mi, lbs)'),
            trailing: DropdownButton<MeasurementSystem>(
              value: settings.measurementSystem,
              items: const [
                DropdownMenuItem(
                    value: MeasurementSystem.metric, child: Text('Metrisch')),
                DropdownMenuItem(
                    value: MeasurementSystem.imperial, child: Text('Imperial')),
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
            subtitle: Text(settings.themeMode.name),
            trailing: DropdownButton<ThemeMode>(
              value: settings.themeMode,
              items: const [
                DropdownMenuItem(
                    value: ThemeMode.system, child: Text('Automatisch')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Hell')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dunkel')),
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
            subtitle: Text(settings.experienceLevel.name),
            trailing: DropdownButton<ExperienceLevel>(
              value: settings.experienceLevel,
              items: const [
                DropdownMenuItem(
                    value: ExperienceLevel.beginner, child: Text('Einfach')),
                DropdownMenuItem(
                    value: ExperienceLevel.advanced,
                    child: Text('Fortgeschritten')),
                DropdownMenuItem(
                    value: ExperienceLevel.expert, child: Text('Experte')),
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

          // Datenschutz
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Datenschutz'),
            subtitle: const Text('Gesundheitsdaten widerrufen, Datenexport'),
            onTap: () {
              // TODO: Zu Datenschutz-Details navigieren
            },
          ),
        ],
      ),
    );
  }
}
