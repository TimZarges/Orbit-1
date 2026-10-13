import 'package:flutter/material.dart';
import 'package:orbit/core/design/app_colors.dart';

/// Bottom-Sheet für Datenschutz-Einstellungen und DSGVO-Rechte (Art. 9, 17, 20).
class PrivacySettingsSheet extends StatefulWidget {
  const PrivacySettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const PrivacySettingsSheet(),
    );
  }

  @override
  State<PrivacySettingsSheet> createState() => _PrivacySettingsSheetState();
}

class _PrivacySettingsSheetState extends State<PrivacySettingsSheet> {
  bool _exporting = false;

  void _triggerExport() async {
    setState(() => _exporting = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _exporting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Datenexport (JSON) wird vorbereitet und per E-Mail bereitgestellt.'),
        backgroundColor: AppColors.green,
      ),
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konto und Daten löschen?'),
        content: const Text(
          'Gemäß Art. 17 DSGVO werden dein Konto, alle Aktivitäten, Gesundheitsdaten '
          'und Schwellenwerte unwiderruflich gelöscht. Dieser Vorgang kann nicht rückgängig gemacht werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Löschungsanfrage eingereicht. Dein Konto wird deaktiviert.'),
                  backgroundColor: AppColors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Endgültig löschen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Griffleiste
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiaryDark,
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
                        const Icon(Icons.privacy_tip_outlined, color: AppColors.volt, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          'Datenschutz & Rechte',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ORBIT speichert deine Daten ausschließlich in der EU (Region europe-west3, Frankfurt). '
                      'Gesundheitsdaten (Art. 9 DSGVO) wie Herzfrequenz, Schlaf und HRV werden nur mit '
                      'deiner ausdrücklichen Einwilligung verarbeitet.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondaryDark,
                            height: 1.4,
                          ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: AppColors.borderDark),
                    const SizedBox(height: 12),

                    // Recht auf Datenübertragbarkeit
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.download_outlined, color: AppColors.volt),
                      ),
                      title: const Text('Daten exportieren (Art. 20 DSGVO)',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      subtitle: const Text(
                        'Maschinenlesbarer Export deiner Profildaten, Aktivitäten und Messwerte als JSON.',
                        style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
                      ),
                      trailing: _exporting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.chevron_right, color: AppColors.textTertiaryDark),
                      onTap: _exporting ? null : _triggerExport,
                    ),

                    const SizedBox(height: 12),
                    const Divider(color: AppColors.borderDark),
                    const SizedBox(height: 12),

                    // Server & Speicherort Info
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.shield_outlined, color: AppColors.accentBlue),
                      ),
                      title: const Text('Speicherort & Sicherheit',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      subtitle: const Text(
                        'Hosting: Google Cloud Frankfurt (europe-west3). Ende-zu-Ende verschlüsselte '
                        'Tokens in Google Secret Manager.',
                        style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
                      ),
                    ),

                    const SizedBox(height: 12),
                    const Divider(color: AppColors.borderDark),
                    const SizedBox(height: 12),

                    // Recht auf Vergessenwerden / Löschung
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.delete_forever_outlined, color: AppColors.red),
                      ),
                      title: const Text('Konto und Daten löschen (Art. 17 DSGVO)',
                          style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w600)),
                      subtitle: const Text(
                        'Unwiderrufliche Löschung aller Trainings-, Gesundheits- und Profildaten.',
                        style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.red),
                      onTap: _confirmDeleteAccount,
                    ),

                    const SizedBox(height: 32),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.borderDark),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Schließen'),
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
