import 'package:flutter/material.dart';
import 'package:orbit/l10n/app_localizations.dart';
import 'package:orbit/core/widgets/info_term.dart';
import 'package:orbit/core/metrics/training_zones_model.dart';
import 'package:orbit/core/design/app_colors.dart';

class ThresholdsScreen extends StatelessWidget {
  const ThresholdsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schwellenwerte'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildThresholdCard(
            context: context,
            title: 'Radfahren (FTP)',
            currentValue: '280 W',
            infoTitle: l10n.infoTerm_ftp,
            infoDesc: l10n.infoTerm_ftp_desc,
            zones: powerZones,
          ),
          const SizedBox(height: 16),
          _buildThresholdCard(
            context: context,
            title: 'Schwimmen (CSS)',
            currentValue: '1:30 min/100m',
            infoTitle: l10n.infoTerm_css,
            infoDesc: l10n.infoTerm_css_desc,
            zones: swimPaceZones,
          ),
          const SizedBox(height: 16),
          _buildThresholdCard(
            context: context,
            title: 'Laufen (Schwellen-Pace)',
            currentValue: '4:30 min/km',
            infoTitle: 'Schwellen-Pace',
            infoDesc: 'Die Geschwindigkeit, ab der sich Laktat schneller im Blut ansammelt als es abgebaut werden kann.',
            zones: runPaceZones,
          ),
          const SizedBox(height: 16),
          _buildThresholdCard(
            context: context,
            title: 'Maximalpuls',
            currentValue: '190 bpm',
            infoTitle: l10n.infoTerm_maxHr,
            infoDesc: l10n.infoTerm_maxHr_desc,
            zones: heartRateZones,
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdCard({
    required BuildContext context,
    required String title,
    required String currentValue,
    required String infoTitle,
    required String infoDesc,
    required List<TrainingZone> zones,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(width: 8),
                    InfoTerm(title: infoTitle, description: infoDesc),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Neuen Wert erfassen
                  },
                  child: const Text('Ändern'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(currentValue, style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 16),
            const Text('Zonen-Vorschau', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: Row(
                children: zones.map((z) {
                  return Expanded(
                    child: Container(
                      color: z.color,
                      child: Center(
                        child: Text(
                          z.shortName,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {},
              child: const Text('Wert schätzen lassen'),
            )
          ],
        ),
      ),
    );
  }
}
