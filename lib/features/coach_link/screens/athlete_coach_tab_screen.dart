import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/user_provider.dart';

class AthleteCoachTabScreen extends ConsumerWidget {
  const AthleteCoachTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              const Icon(Icons.group_add, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Noch kein Trainer verknüpft',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Gib hier den Einladungscode deines Trainers ein oder scanne seinen QR-Code.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // TODO: Code-Eingabe-Dialog
                },
                child: const Text('Code eingeben'),
              ),
            ],
          ),
        ),
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
              subtitle: Text('ID: $coachId'), // Später: Name auflösen
              trailing: IconButton(
                icon: const Icon(Icons.link_off),
                tooltip: 'Verknüpfung lösen',
                onPressed: () {
                  // TODO: Dialog zur Bestätigung, dann revokeLink Function aufrufen
                },
              ),
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
            value: true, // TODO: Aus coachLinks lesen
            onChanged: (val) {
              // TODO: updatePermissions Function aufrufen
            },
          ),
          SwitchListTile(
            title: const Text('Kalender'),
            subtitle: const Text('Deine Planung und Verfügbarkeit'),
            value: true,
            onChanged: (val) {},
          ),
          SwitchListTile(
            title: const Text('Gesundheitsdaten'),
            subtitle: const Text('Schlaf, HRV, Ruhepuls (sofern vorhanden)'),
            value: false,
            onChanged: (val) {},
          ),
        ],
      ),
    );
  }
}
