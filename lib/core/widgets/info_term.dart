import 'package:flutter/material.dart';
import 'package:orbit/l10n/app_localizations.dart';

/// Ein wiederverwendbarer Info-Icon-Baustein, der bei Klick einen Bottom Sheet
/// mit Erklärtexten (z.B. für FTP, CTL) öffnet.
class InfoTerm extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback? onLearnMore;

  const InfoTerm({
    super.key,
    required this.title,
    required this.description,
    this.onLearnMore,
  });

  void _showInfoSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                if (onLearnMore != null)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onLearnMore!();
                      },
                      child: const Text('Mehr erfahren'),
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Verstanden'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.info_outline, size: 20),
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      onPressed: () => _showInfoSheet(context),
      tooltip: title,
    );
  }
}
