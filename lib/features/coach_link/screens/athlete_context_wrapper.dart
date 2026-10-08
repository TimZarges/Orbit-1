import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/athlete_context_provider.dart';

class AthleteContextWrapper extends ConsumerWidget {
  final String athleteId;
  final String athleteName;
  final Widget child;

  const AthleteContextWrapper({
    super.key,
    required this.athleteId,
    required this.athleteName,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Wenn dieser Wrapper gebaut wird, überschreiben wir den Provider-Wert für den Baum darunter
    return ProviderScope(
      overrides: [
        viewedAthleteIdProvider.overrideWith((ref) => athleteId),
      ],
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Du siehst: $athleteName',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: child,
      ),
    );
  }
}
