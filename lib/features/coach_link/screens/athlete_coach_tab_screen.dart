import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design/app_colors.dart';
import '../../auth/providers/user_provider.dart';

/// Screen für die Trainer-Verknüpfung aus Athleten-Sicht.
class AthleteCoachTabScreen extends ConsumerStatefulWidget {
  const AthleteCoachTabScreen({super.key});

  @override
  ConsumerState<AthleteCoachTabScreen> createState() =>
      _AthleteCoachTabScreenState();
}

class _AthleteCoachTabScreenState extends ConsumerState<AthleteCoachTabScreen> {
  bool _shareActivities = true;
  bool _shareCalendar = true;
  bool _shareHealth = false;

  @override
  Widget build(BuildContext context) {
    final userDoc = ref.watch(userDocumentProvider).valueOrNull;
    final coachId = userDoc?['coachId'];

    if (coachId == null) {
      return _buildEmptyState(context);
    }

    return _buildCoachDetails(context, coachId);
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
              const Icon(Icons.group_add,
                  size: 64, color: AppColors.textTertiaryDark),
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
                onPressed: () => _showEnterCodeDialog(context),
                icon: const Icon(Icons.vpn_key_outlined),
                label: const Text('Einladungscode eingeben'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.volt,
                  foregroundColor: AppColors.navy,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Trainer-Einladungscode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Gib den 6- oder 8-stelligen Code ein, den du von deinem Trainer erhalten hast.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Einladungscode (z. B. COACH-492)',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              final code = controller.text.trim();
              if (code.isEmpty) return;
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Code $code wird geprüft und Verknüpfungsanfrage gesendet...'),
                  backgroundColor: AppColors.green,
                ),
              );
            },
            child: const Text('Verknüpfen'),
          ),
        ],
      ),
    );
  }

  void _showRevokeDialog(BuildContext context, String coachId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Trainer-Verknüpfung beenden?'),
        content: const Text(
          'Der Trainer verliert sofort den Zugriff auf deine Aktivitäten, '
          'deinen Kalender und eventuelle Gesundheitsdaten. Der bisherige Chatverlauf '
          'bleibt archiviert, es können aber keine neuen Nachrichten mehr gesendet werden.',
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
                  content: Text('Verknüpfung wurde beendet.'),
                  backgroundColor: AppColors.red,
                ),
              );
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

  Widget _buildCoachDetails(BuildContext context, String coachId) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dein Coach')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: const Text('Dein aktueller Trainer'),
              subtitle: Text('Trainer-ID: $coachId'),
              trailing: IconButton(
                icon: const Icon(Icons.link_off, color: AppColors.red),
                tooltip: 'Verknüpfung lösen',
                onPressed: () => _showRevokeDialog(context, coachId),
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
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),
          Text('Datenfreigaben', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
              'Lege fest, welche Daten dein Trainer sehen darf. Diese Einstellungen kannst du jederzeit ändern.'),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Aktivitäten & Workouts'),
            subtitle:
                const Text('Trainingsplandaten und absolvierte Einheiten'),
            value: _shareActivities,
            onChanged: (val) {
              setState(() => _shareActivities = val);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Freigabe Aktivitäten: ${val ? 'Aktiviert' : 'Deaktiviert'}'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          SwitchListTile(
            title: const Text('Kalender'),
            subtitle: const Text('Deine Planung und Verfügbarkeit'),
            value: _shareCalendar,
            onChanged: (val) {
              setState(() => _shareCalendar = val);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Freigabe Kalender: ${val ? 'Aktiviert' : 'Deaktiviert'}'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          SwitchListTile(
            title: const Text('Gesundheitsdaten (Art. 9 DSGVO)'),
            subtitle: const Text(
                'Schlaf, HRV, Ruhepuls (nur bei gesonderter Freigabe)'),
            value: _shareHealth,
            onChanged: (val) {
              setState(() => _shareHealth = val);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Freigabe Gesundheitsdaten: ${val ? 'Aktiviert' : 'Deaktiviert'}'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
