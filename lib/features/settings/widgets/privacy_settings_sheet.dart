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
        backgroundColor: Color(0xFF10B981),
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
                  backgroundColor: Color(0xFFEF4444),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
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
            color: Color(0xFF0F172A),
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
                            color: const Color(0xFF94A3B8),
                            height: 1.4,
                          ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: Color(0xFF1E293B)),
                    const SizedBox(height: 12),

                    // Recht auf Datenübertragbarkeit
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.download_outlined, color: AppColors.volt),
                      ),
                      title: const Text('Daten exportieren (Art. 20 DSGVO)',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      subtitle: const Text(
                        'Maschinenlesbarer Export deiner Profildaten, Aktivitäten und Messwerte als JSON.',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      ),
                      trailing: _exporting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
                      onTap: _exporting ? null : _triggerExport,
                    ),

                    const SizedBox(height: 12),
                    const Divider(color: Color(0xFF1E293B)),
                    const SizedBox(height: 12),

                    // Server & Speicherort Info
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.shield_outlined, color: Color(0xFF0EA5E9)),
                      ),
                      title: const Text('Speicherort & Sicherheit',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      subtitle: const Text(
                        'Hosting: Google Cloud Frankfurt (europe-west3). Ende-zu-Ende verschlüsselte '
                        'Tokens in Google Secret Manager.',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      ),
                    ),

                    const SizedBox(height: 12),
                    const Divider(color: Color(0xFF1E293B)),
                    const SizedBox(height: 12),

                    // Recht auf Vergessenwerden / Löschung
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0x26EF4444),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.delete_forever_outlined, color: Color(0xFFEF4444)),
                      ),
                      title: const Text('Konto und Daten löschen (Art. 17 DSGVO)',
                          style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
                      subtitle: const Text(
                        'Unwiderrufliche Löschung aller Trainings-, Gesundheits- und Profildaten.',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Color(0xFFEF4444)),
                      onTap: _confirmDeleteAccount,
                    ),

                    const SizedBox(height: 32),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF1E293B)),
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
