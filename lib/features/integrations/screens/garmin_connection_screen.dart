import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/garmin_status.dart';
import '../providers/garmin_provider.dart';
import '../../../core/design/app_colors.dart';

class GarminConnectionScreen extends ConsumerStatefulWidget {
  final String? initialVerifier;
  final String? initialToken;

  const GarminConnectionScreen({
    super.key,
    this.initialVerifier,
    this.initialToken,
  });

  @override
  ConsumerState<GarminConnectionScreen> createState() =>
      _GarminConnectionScreenState();
}

class _GarminConnectionScreenState
    extends ConsumerState<GarminConnectionScreen> {
  bool _isLoading = false;
  String? _pendingOauthToken;
  final TextEditingController _verifierController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialVerifier != null && widget.initialVerifier!.isNotEmpty) {
      _verifierController.text = widget.initialVerifier!;
      _pendingOauthToken = widget.initialToken;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _submitVerifier();
      });
    }
  }

  @override
  void didUpdateWidget(GarminConnectionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialVerifier != null &&
        widget.initialVerifier!.isNotEmpty &&
        widget.initialVerifier != oldWidget.initialVerifier) {
      _verifierController.text = widget.initialVerifier!;
      _pendingOauthToken = widget.initialToken;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _submitVerifier();
      });
    }
  }

  @override
  void dispose() {
    _verifierController.dispose();
    super.dispose();
  }

  Future<void> _connectGarmin() async {
    setState(() => _isLoading = true);
    try {
      final oauthToken =
          await ref.read(garminServiceProvider).startGarminAuth();
      if (mounted) {
        setState(() {
          _pendingOauthToken = oauthToken;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Starten der Verbindung: $e')),
        );
      }
    }
  }

  Future<void> _submitVerifier() async {
    final verifier = _verifierController.text.trim();
    if (verifier.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(garminServiceProvider).completeGarminAuth(
            oauthVerifier: verifier,
            oauthToken: _pendingOauthToken,
          );
      if (mounted) {
        setState(() {
          _pendingOauthToken = null;
          _verifierController.clear();
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF10B981),
            content: Text(
              'Erfolgreich mit Garmin verbunden! Daten werden jetzt synchronisiert.',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text(
              'Verifizierung fehlgeschlagen: $e',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    }
  }

  Future<void> _disconnectGarmin() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Garmin-Verbindung trennen?'),
        content: const Text(
          'Möchtest du dein Garmin-Konto wirklich trennen? '
          'Die automatische Synchronisation wird gestoppt. Bereits importierte Trainings bleiben erhalten.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Trennen', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await ref.read(garminServiceProvider).disconnectGarmin();
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Garmin-Verbindung wurde erfolgreich getrennt.'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fehler beim Trennen: $e')),
          );
        }
      }
    }
  }

  Future<void> _triggerBackfill() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(garminServiceProvider).triggerBackfill(days: 90);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF0EA5E9),
            content: Text(
              'Historischer Import (90 Tage) wurde bei Garmin angefordert!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Anfordern: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(garminStatusStreamProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Garmin Connect'),
      ),
      body: statusAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Fehler beim Laden des Status: $err',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ),
        data: (status) {
          final isConnected = status.state == GarminConnectionState.connected;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              // Status Card
              Card(
                elevation: 0,
                color: theme.cardTheme.color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color:
                        isDark ? const Color(0xFF334155) : AppColors.cardBorder,
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.navy,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.watch,
                          color: AppColors.volt,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Garmin Connect',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isConnected
                                        ? const Color(0xFF10B981)
                                        : (_pendingOauthToken != null
                                            ? const Color(0xFFF59E0B)
                                            : const Color(0xFF94A3B8)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isConnected
                                      ? 'Verbunden'
                                      : (_pendingOauthToken != null
                                          ? 'Warte auf Bestätigung...'
                                          : 'Nicht verbunden'),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isConnected
                                        ? const Color(0xFF10B981)
                                        : (_pendingOauthToken != null
                                            ? const Color(0xFFF59E0B)
                                            : theme
                                                .colorScheme.onSurfaceVariant),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              if (isConnected) ...[
                // Verbundener Zustand
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : AppColors.cardBorder,
                    ),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading:
                            const Icon(Icons.sync, color: Color(0xFF10B981)),
                        title: Text(
                          'Automatische Synchronisation aktiv',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          status.garminUserId != null
                              ? 'Garmin ID: ${status.garminUserId}'
                              : 'Neue Aktivitäten werden automatisch importiert',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (status.isBackfillInProgress) ...[
                        const Divider(height: 1),
                        ListTile(
                          leading: const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                          title: Text(
                            'Import historischer Daten läuft...',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            'Synchronisiere Historie (${status.targetDays} Tage)... ${status.receivedActivities} Einheiten empfangen',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Backfill Button
                OutlinedButton.icon(
                  onPressed: _isLoading || status.isBackfillInProgress
                      ? null
                      : _triggerBackfill,
                  icon: const Icon(Icons.history),
                  label: const Text('Historische Daten laden (letzte 90 Tage)'),
                ),

                const SizedBox(height: 16),

                // Disconnect Button
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade600,
                  ),
                  onPressed: _isLoading ? null : _disconnectGarmin,
                  icon: const Icon(Icons.link_off),
                  label: const Text('Garmin-Verbindung trennen'),
                ),
              ] else ...[
                // Nicht verbundener Zustand
                Text(
                  'Verbinde dein Garmin-Konto, um alle aufgezeichneten Trainings (Schwimmen, Radfahren, Laufen) '
                  'automatisch und nahtlos in ORBIT zu analysieren.',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _connectGarmin,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.link),
                  label: Text(
                    _isLoading ? 'Wird geöffnet...' : 'Mit Garmin verbinden',
                  ),
                ),

                // Bestätigungscode Eingabebereich
                const SizedBox(height: 28),
                Card(
                  elevation: 0,
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDark
                          ? const Color(0xFF334155)
                          : AppColors.cardBorder,
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.vpn_key_outlined,
                              size: 22,
                              color: Color(0xFF0EA5E9),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Bestätigungscode eingeben',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Nach dem Login bei Garmin wirst du auf die Bestätigungsseite weitergeleitet. '
                          'Kopiere dort den angezeigten Code und füge ihn hier ein:',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _verifierController,
                          decoration: const InputDecoration(
                            labelText: 'oauth_verifier Code',
                            hintText: 'z. B. 1a2b3c4d...',
                            prefixIcon: Icon(Icons.check),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _submitVerifier,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Verbindung abschließen'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
