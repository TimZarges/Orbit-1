import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/athlete_context_provider.dart';

/// Wrapper-Widget, das einem Trainer erlaubt, temporär in die Ansicht
/// eines verknüpften Athleten zu schlüpfen (Athleten-Kontext).
///
/// Überschreibt [viewedAthleteIdProvider] via [ProviderScope] und zeigt
/// eine Kopfleiste mit Schließen-Button und Athletenname.
class AthleteContextWrapper extends ConsumerWidget {
  /// Die ID des betrachteten Athleten.
  final String athleteId;

  /// Der Anzeigename des betrachteten Athleten.
  final String athleteName;

  /// Das eingebettete Inhalts-Widget (z. B. Dashboard, Kalender oder Analyse).
  final Widget child;

  /// Erstellt einen [AthleteContextWrapper].
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
