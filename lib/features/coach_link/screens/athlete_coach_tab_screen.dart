import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design/app_colors.dart';
import '../../auth/providers/user_provider.dart';
import '../providers/coach_link_provider.dart';

/// Screen für die Trainer-Verknüpfung aus Athleten-Sicht.
/// Bietet echtes Einlösen von Einladungscodes, Live-Streaming der Art. 9 DSGVO-Berechtigungen
/// und sofortigen Zugriffs-Widerruf.
class AthleteCoachTabScreen extends ConsumerStatefulWidget {
  const AthleteCoachTabScreen({super.key});

  @override
  ConsumerState<AthleteCoachTabScreen> createState() =>
      _AthleteCoachTabScreenState();
}

class _AthleteCoachTabScreenState extends ConsumerState<AthleteCoachTabScreen> {
  bool _isActionInProgress = false;

  @override
  Widget build(BuildContext context) {
    final userDoc = ref.watch(userDocumentProvider).valueOrNull;
    final coachId = userDoc?['coachId'] as String?;

    if (coachId == null || coachId.isEmpty) {
      return _buildEmptyState(context);
    }

    final athleteId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final linkId = '${athleteId}_$coachId';
    final linkAsync = ref.watch(coachLinkStreamProvider(linkId));

    return linkAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Dein Coach')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Dein Coach')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Fehler beim Laden der Verknüpfung: $err',
              style: const TextStyle(color: AppColors.red),
            ),
          ),
        ),
      ),
      data: (linkData) =>
          _buildCoachDetails(context, coachId, linkId, linkData),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dein Coach')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.group_add,
                size: 64,
                color: AppColors.textTertiaryDark,
              ),
              const SizedBox(height: 16),
              Text(
                'Noch kein Trainer verknüpft',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Gib hier den Einladungscode deines Trainers ein oder lasse dir einen Einladungslink senden.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isActionInProgress
                    ? null
                    : () => _showEnterCodeDialog(context),
                icon: const Icon(Icons.vpn_key_outlined),
                label: const Text('Einladungscode eingeben'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.volt,
                  foregroundColor: AppColors.navy,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEnterCodeDialog(BuildContext context) {
    final controller = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: !isSubmitting,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: const Text('Trainer-Einladungscode'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Gib den Einladungscode ein, den du von deinem Trainer erhalten hast.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: '6-stelliger Einladungscode (z. B. 4A8F2C)',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
                autofocus: true,
                enabled: !isSubmitting,
              ),
              if (isSubmitting) ...[
                const SizedBox(height: 16),
                const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final code = controller.text.trim().toUpperCase();
                      if (code.isEmpty) return;

                      setDialogState(() => isSubmitting = true);
                      setState(() => _isActionInProgress = true);

                      try {
                        await ref
                            .read(coachLinkServiceProvider)
                            .redeemInvite(code);
                        ref.invalidate(userDocumentProvider);

                        if (dialogCtx.mounted) {
                          Navigator.of(dialogCtx).pop();
                        }

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Erfolgreich mit deinem Trainer verknüpft!',
                              ),
                              backgroundColor: AppColors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('Fehler beim Einlösen des Codes: $e'),
                              backgroundColor: AppColors.red,
                            ),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() => _isActionInProgress = false);
                        }
                      }
                    },
              child: const Text('Verknüpfen'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRevokeDialog(BuildContext context, String linkId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Trainer-Verknüpfung beenden?'),
        content: const Text(
          'Der Trainer verliert sofort den Zugriff auf deine Aktivitäten, '
          'deinen Kalender und eventuelle Gesundheitsdaten (Art. 9 DSGVO). Der bisherige Chatverlauf '
          'bleibt archiviert, es können aber keine neuen Nachrichten mehr gesendet werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              setState(() => _isActionInProgress = true);

              try {
                await ref.read(coachLinkServiceProvider).revokeLink(linkId);
                ref.invalidate(userDocumentProvider);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Verknüpfung wurde erfolgreich beendet. Trainerzugriff entzogen.',
                      ),
                      backgroundColor: AppColors.red,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Fehler beim Trennen: $e'),
                      backgroundColor: AppColors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isActionInProgress = false);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Verknüpfung lösen'),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachDetails(
    BuildContext context,
    String coachId,
    String linkId,
    CoachLinkData? linkData,
  ) {
    final shareActivities = linkData?.shareActivities ?? true;
    final shareCalendar = linkData?.shareCalendar ?? true;
    final shareHealth = linkData?.shareHealth ?? false;
    final shareBodyWeightAndNotes = linkData?.shareBodyWeightAndNotes ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Dein Coach')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: const Text('Dein aktueller Trainer'),
              subtitle: Text(
                'Trainer-ID: $coachId\nStatus: ${linkData?.status ?? "AKTIV"}',
              ),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.link_off, color: AppColors.red),
                tooltip: 'Verknüpfung lösen',
                onPressed: _isActionInProgress
                    ? null
                    : () => _showRevokeDialog(context, linkId),
              ),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () {
              final athleteId = FirebaseAuth.instance.currentUser?.uid ?? '';
              final chatId = '${athleteId}_$coachId';
              context.push('/chat/$chatId?athleteId=$athleteId&name=Trainer');
            },
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Chat mit Trainer öffnen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.volt,
              foregroundColor: AppColors.navy,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Datenfreigaben (Art. 9 DSGVO)',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Lege fest, welche Daten dein Trainer einsehen darf. Jede Änderung schreibt einen Audit-Log-Eintrag und aktualisiert die Berechtigung in Echtzeit.',
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Trainingsaktivitäten & Leistungsdaten'),
            subtitle:
                const Text('Absolvierte Einheiten, Watt-, Pace- und Pulsdaten'),
            value: shareActivities,
            onChanged: _isActionInProgress
                ? null
                : (val) async {
                    try {
                      await ref
                          .read(coachLinkServiceProvider)
                          .updatePermissions(
                            coachId: coachId,
                            shareActivities: val,
                            shareCalendar: shareCalendar,
                            shareHealth: shareHealth,
                            shareBodyWeightAndNotes: shareBodyWeightAndNotes,
                          );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Freigabe Aktivitäten: ${val ? "Aktiviert" : "Deaktiviert"}',
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Fehler beim Aktualisieren: $e'),
                            backgroundColor: AppColors.red,
                          ),
                        );
                      }
                    }
                  },
          ),
          SwitchListTile(
            title: const Text('Kalender & Trainingsplanung'),
            subtitle: const Text('Geplante Workouts und Verfügbarkeit'),
            value: shareCalendar,
            onChanged: _isActionInProgress
                ? null
                : (val) async {
                    try {
                      await ref
                          .read(coachLinkServiceProvider)
                          .updatePermissions(
                            coachId: coachId,
                            shareActivities: shareActivities,
                            shareCalendar: val,
                            shareHealth: shareHealth,
                            shareBodyWeightAndNotes: shareBodyWeightAndNotes,
                          );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Freigabe Kalender: ${val ? "Aktiviert" : "Deaktiviert"}',
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Fehler beim Aktualisieren: $e'),
                            backgroundColor: AppColors.red,
                          ),
                        );
                      }
                    }
                  },
          ),
          SwitchListTile(
            title:
                const Text('Gesundheits-, Schlaf- & HRV-Daten (Art. 9 DSGVO)'),
            subtitle:
                const Text('Schlaf, HRV, Ruhepuls (strikte Zweckbindung)'),
            value: shareHealth,
            onChanged: _isActionInProgress
                ? null
                : (val) async {
                    try {
                      await ref
                          .read(coachLinkServiceProvider)
                          .updatePermissions(
                            coachId: coachId,
                            shareActivities: shareActivities,
                            shareCalendar: shareCalendar,
                            shareHealth: val,
                            shareBodyWeightAndNotes: shareBodyWeightAndNotes,
                          );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Freigabe Gesundheitsdaten: ${val ? "Aktiviert" : "Deaktiviert"}',
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Fehler beim Aktualisieren: $e'),
                            backgroundColor: AppColors.red,
                          ),
                        );
                      }
                    }
                  },
          ),
          SwitchListTile(
            title: const Text('Körpergewicht & Notizen (Art. 9 DSGVO)'),
            subtitle: const Text(
              'Gewichtsverlauf, Körperfettanteil und persönliche Notizen',
            ),
            value: shareBodyWeightAndNotes,
            onChanged: _isActionInProgress
                ? null
                : (val) async {
                    try {
                      await ref
                          .read(coachLinkServiceProvider)
                          .updatePermissions(
                            coachId: coachId,
                            shareActivities: shareActivities,
                            shareCalendar: shareCalendar,
                            shareHealth: shareHealth,
                            shareBodyWeightAndNotes: val,
                          );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Freigabe Körpergewicht/Notizen: ${val ? "Aktiviert" : "Deaktiviert"}',
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Fehler beim Aktualisieren: $e'),
                            backgroundColor: AppColors.red,
                          ),
                        );
                      }
                    }
                  },
          ),
        ],
      ),
    );
  }
}
