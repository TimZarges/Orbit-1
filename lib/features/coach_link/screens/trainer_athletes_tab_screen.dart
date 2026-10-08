import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'athlete_context_wrapper.dart';
import '../../dashboard/screens/dashboard_screen.dart'; // Platzhalter für Athleten-Ansicht

class TrainerAthletesTabScreen extends ConsumerStatefulWidget {
  const TrainerAthletesTabScreen({super.key});

  @override
  ConsumerState<TrainerAthletesTabScreen> createState() =>
      _TrainerAthletesTabScreenState();
}

class _TrainerAthletesTabScreenState
    extends ConsumerState<TrainerAthletesTabScreen> {
  String? _inviteCode;
  bool _isLoading = false;

  Future<void> _generateInvite() async {
    setState(() => _isLoading = true);
    try {
      final result =
          await FirebaseFunctions.instance.httpsCallable('createInvite').call();
      setState(() {
        _inviteCode = result.data['code'];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Fehler: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openAthleteContext(String athleteId, String name) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AthleteContextWrapper(
          athleteId: athleteId,
          athleteName: name,
          // Als Platzhalter öffnen wir das Dashboard im Kontext des Athleten
          child: const Center(
              child: Text(
                  'Hier kommen später Kalender und Analyse des Athleten hin.')),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meine Athleten')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (_inviteCode != null) ...[
                      const Text('Dein Einladungscode:'),
                      Text(_inviteCode!,
                          style: Theme.of(context).textTheme.headlineLarge),
                      const SizedBox(height: 16),
                    ],
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else
                      ElevatedButton(
                        onPressed: _generateInvite,
                        child: const Text('Neue Einladung erstellen'),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  leading: const CircleAvatar(child: Text('M')),
                  title: const Text('Max Mustermann'),
                  subtitle: const Text('Ironman Frankfurt (Erfahren)'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      _openAthleteContext('athlete_123', 'Max Mustermann'),
                ),
                ListTile(
                  leading: const CircleAvatar(child: Text('A')),
                  title: const Text('Anna Athletin'),
                  subtitle: const Text('Olympische Distanz (Fortgeschritten)'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      _openAthleteContext('athlete_456', 'Anna Athletin'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
