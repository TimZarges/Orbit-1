/// @file garmin_connection_screen.dart
/// @description Einstellungs- und Status-Screen für die Garmin-Connect-Integration.
///
/// Steuert den vollständigen OAuth-1.0a-Verbindungsprozess über App (Android Deep-Link &
/// Lifecycle-Resumption) und Web (BroadcastChannel / postMessage / Storage-Bridge),
/// verhindert ein Hängenbleiben im Zustand „Warte auf Bestätigung...“ durch Timeouts,
/// explizite Abbruch-Aktionen und bereinigte Status-Übergänge gemäß `COLOR_SYSTEM_V1`.
library;

import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_colors.dart';
import '../../activities/providers/activities_provider.dart';
import '../../home/providers/home_dashboard_provider.dart';
import '../models/garmin_status.dart';
import '../providers/garmin_provider.dart';
import '../services/garmin_web_callback_bridge.dart';

/// Standard-Wartezeit bis eine ausbleibende Browser-Bestätigung sauber zurückgesetzt wird.
const Duration _kAuthWatchdogTimeout = Duration(minutes: 3);

/// Maximales Alter eines serverseitigen `CONNECTING`-Zustands, bevor er als abgelaufen gilt.
const Duration _kStaleConnectingThreshold = Duration(minutes: 5);

/// Screen zur Verwaltung der Garmin-Connect-Kopplung, manueller Sync-Läufe und Backfills.
class GarminConnectionScreen extends ConsumerStatefulWidget {
  /// Optionaler `oauth_verifier` aus Deep-Link oder Web-Callback.
  final String? initialVerifier;

  /// Optionales zugehöriges `oauth_token` aus dem Callback.
  final String? initialToken;

  /// Optionaler Abbruch-/Fehlergrund aus dem Callback (z. B. `'cancelled'`).
  final String? initialError;

  /// Erstellt den Garmin-Verbindungsscreen.
  const GarminConnectionScreen({
    super.key,
    this.initialVerifier,
    this.initialToken,
    this.initialError,
  });

  @override
  ConsumerState<GarminConnectionScreen> createState() =>
      _GarminConnectionScreenState();
}

/// Verwaltet lokale Übergangszustände, Timer, Browser-Bridge und App-Lifecycle-Events.
class _GarminConnectionScreenState extends ConsumerState<GarminConnectionScreen>
    with WidgetsBindingObserver {
  bool _isLoading = false;
  bool _isSubmittingVerifier = false;
  bool _returnedWithoutConfirmation = false;
  String? _pendingOauthToken;
  String? _pendingAuthUrl;
  String? _localErrorMessage;
  String? _lastHandledErrorKey;

  final TextEditingController _verifierController = TextEditingController();
  Timer? _authTimeoutTimer;
  Timer? _resumeCheckTimer;
  void Function()? _disposeWebCallbackBridge;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _disposeWebCallbackBridge =
        GarminWebCallbackBridge.listen(_handleWebCallbackEvent);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _processRouteParameters(
        verifier: widget.initialVerifier,
        token: widget.initialToken,
        error: widget.initialError,
      );
    });
  }

  @override
  void didUpdateWidget(GarminConnectionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialVerifier != oldWidget.initialVerifier ||
        widget.initialToken != oldWidget.initialToken ||
        widget.initialError != oldWidget.initialError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _processRouteParameters(
          verifier: widget.initialVerifier,
          token: widget.initialToken,
          error: widget.initialError,
        );
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;

    // Im Web beim Fokus-Wechsel unmittelbar auf abgelegte Callback-Daten prüfen.
    final pendingWebEvent = GarminWebCallbackBridge.consumePendingWebCallback();
    if (pendingWebEvent != null) {
      _handleWebCallbackEvent(pendingWebEvent);
      return;
    }

    // Auf Android kann ein Deep-Link 1-2 Frames nach `resumed` eintreffen; kurz abwarten
    // und danach einen klaren Rückkehr-Hinweis samt Abbruch-/Zwischenablage-Option anbieten.
    if (_pendingOauthToken != null && !_isSubmittingVerifier) {
      _resumeCheckTimer?.cancel();
      _resumeCheckTimer = Timer(const Duration(seconds: 2), () {
        if (!mounted) return;
        final currentStatus = ref.read(garminStatusStreamProvider).valueOrNull;
        if (currentStatus?.state == GarminConnectionState.connected ||
            _isSubmittingVerifier ||
            _pendingOauthToken == null) {
          return;
        }
        setState(() {
          _returnedWithoutConfirmation = true;
        });
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authTimeoutTimer?.cancel();
    _resumeCheckTimer?.cancel();
    _disposeWebCallbackBridge?.call();
    _verifierController.dispose();
    super.dispose();
  }

  /// Prüft, ob ein übergebener Verifier gültig ist (schließt `'null'`/`'denied'` aus).
  bool _isValidVerifierString(String? raw) {
    if (raw == null) return false;
    final trimmed = raw.trim().toLowerCase();
    return trimmed.isNotEmpty &&
        trimmed != 'null' &&
        trimmed != 'undefined' &&
        trimmed != 'denied';
  }

  /// Verarbeitet eingehende Router-Parameter (`oauth_verifier`, `error`) bzw. Web-Storage-Reste.
  Future<void> _processRouteParameters({
    String? verifier,
    String? token,
    String? error,
  }) async {
    if (error != null && error.trim().isNotEmpty) {
      final errorKey = '$error|${token ?? ""}';
      if (_lastHandledErrorKey == errorKey) return;
      _lastHandledErrorKey = errorKey;
      await _handleCancelledFlow(
        message: 'Garmin-Autorisierung wurde im Browser abgebrochen.',
      );
      return;
    }

    if (_isValidVerifierString(verifier)) {
      _verifierController.text = verifier!.trim();
      _pendingOauthToken = token;
      await _submitVerifier();
      return;
    }

    if (kIsWeb) {
      final pendingEvent = GarminWebCallbackBridge.consumePendingWebCallback();
      if (pendingEvent != null) {
        _handleWebCallbackEvent(pendingEvent);
      }
    }
  }

  /// Verarbeitet Events aus der Web-Bridge (`BroadcastChannel`, `postMessage`, `localStorage`).
  void _handleWebCallbackEvent(GarminWebCallbackEvent event) {
    if (!mounted) return;
    if (event.isCancelled) {
      unawaited(
        _handleCancelledFlow(
          message: 'Garmin-Autorisierung wurde im Browser abgebrochen.',
        ),
      );
      return;
    }
    final verifier = event.oauthVerifier?.trim();
    if (_isValidVerifierString(verifier)) {
      _resumeCheckTimer?.cancel();
      _verifierController.text = verifier!;
      if (event.oauthToken != null && event.oauthToken!.isNotEmpty) {
        _pendingOauthToken = event.oauthToken;
      }
      unawaited(_submitVerifier());
    }
  }

  /// Startet einen Timeout-Watchdog, damit „Warte auf Bestätigung...“ niemals endlos hängt.
  void _startAuthWatchdog() {
    _authTimeoutTimer?.cancel();
    _authTimeoutTimer = Timer(_kAuthWatchdogTimeout, () {
      if (!mounted) return;
      final currentStatus = ref.read(garminStatusStreamProvider).valueOrNull;
      if (currentStatus?.state == GarminConnectionState.connected ||
          _isSubmittingVerifier) {
        return;
      }
      unawaited(_handleTimeoutExpired());
    });
  }

  /// Bricht nach Ablauf des Watchdogs den hängenden Zustand sauber lokal und im Backend ab.
  Future<void> _handleTimeoutExpired() async {
    _cancelLocalTimers();
    if (mounted) {
      setState(() {
        _pendingOauthToken = null;
        _pendingAuthUrl = null;
        _returnedWithoutConfirmation = false;
        _isLoading = false;
        _localErrorMessage =
            'Zeitüberschreitung beim Warten auf die Garmin-Bestätigung. '
            'Bitte starte den Verbindungsaufbau erneut.';
      });
    }
    try {
      await ref.read(garminServiceProvider).cancelGarminAuth(reason: 'timeout');
    } catch (_) {
      // Lokaler Zustand ist bereits sauber zurückgesetzt; stiller Fallback verhindert UI-Blockade.
    }
  }

  /// Bricht den laufenden OAuth-Versuch auf Nutzerwunsch oder nach Browser-Abbruch sauber ab.
  Future<void> _handleCancelledFlow({
    required String message,
    bool showSnackBar = true,
  }) async {
    _cancelLocalTimers();
    if (mounted) {
      setState(() {
        _pendingOauthToken = null;
        _pendingAuthUrl = null;
        _returnedWithoutConfirmation = false;
        _isLoading = false;
        _localErrorMessage = message;
      });
    }
    try {
      await ref
          .read(garminServiceProvider)
          .cancelGarminAuth(reason: 'cancelled');
    } catch (_) {
      // Wenn Backend-Call offline scheitert, bleibt der Nutzer trotzdem handlungsfähig im UI.
    }
    if (mounted && showSnackBar) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor:
              isDark ? AppColors.warningDark : AppColors.warningLight,
          content: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  /// Beendet alle aktiven Warte-Timer kontrolliert.
  void _cancelLocalTimers() {
    _authTimeoutTimer?.cancel();
    _authTimeoutTimer = null;
    _resumeCheckTimer?.cancel();
    _resumeCheckTimer = null;
  }

  /// Startet den Garmin-OAuth-1.0a-Flow über Cloud Function und öffnet die Login-Seite im Browser.
  Future<void> _connectGarmin() async {
    setState(() {
      _isLoading = true;
      _localErrorMessage = null;
      _returnedWithoutConfirmation = false;
      _lastHandledErrorKey = null;
    });

    try {
      final session =
          await ref.read(garminServiceProvider).startGarminAuthSession();
      if (!mounted) return;

      if (session == null) {
        setState(() {
          _isLoading = false;
          _localErrorMessage =
              'Garmin-Anmelde-URL konnte nicht erzeugt werden. Bitte erneut versuchen.';
        });
        return;
      }

      setState(() {
        _pendingOauthToken = session.oauthToken ?? 'pending';
        _pendingAuthUrl = session.authUrl;
        _isLoading = false;
      });
      _startAuthWatchdog();
    } catch (e) {
      if (!mounted) return;
      final errorMsg = GarminService.resolveErrorMessage(e);
      setState(() {
        _isLoading = false;
        _pendingOauthToken = null;
        _pendingAuthUrl = null;
        _localErrorMessage = errorMsg;
      });
      final isDark = Theme.of(context).brightness == Brightness.dark;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: isDark ? AppColors.errorDark : AppColors.errorLight,
          content: Text(
            'Fehler beim Starten der Verbindung: $errorMsg',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  /// Öffnet das Garmin-Autorisierungsfenster für die bereits begonnene Sitzung erneut.
  Future<void> _reopenAuthBrowser() async {
    final authUrl = _pendingAuthUrl;
    if (authUrl == null || authUrl.isEmpty) {
      await _connectGarmin();
      return;
    }
    try {
      setState(() {
        _returnedWithoutConfirmation = false;
        _localErrorMessage = null;
      });
      await ref.read(garminServiceProvider).launchAuthUrl(authUrl);
      _startAuthWatchdog();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _localErrorMessage = GarminService.resolveErrorMessage(e);
      });
    }
  }

  /// Übernimmt einen zuvor kopierten `oauth_verifier` aus der Zwischenablage und schließt ab.
  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final raw = data?.text?.trim() ?? '';
    if (!_isValidVerifierString(raw)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kein gültiger Garmin-Bestätigungscode in der Zwischenablage gefunden.',
          ),
        ),
      );
      return;
    }
    _verifierController.text = raw;
    await _submitVerifier();
  }

  /// Sendet den `oauth_verifier` genau einmal an `garminAuthCallback` und startet danach den Sync.
  Future<void> _submitVerifier() async {
    final verifier = _verifierController.text.trim();
    if (!_isValidVerifierString(verifier)) {
      setState(() {
        _localErrorMessage =
            'Bitte gib einen gültigen Garmin-Bestätigungscode ein.';
      });
      return;
    }
    if (_isSubmittingVerifier) return;

    _isSubmittingVerifier = true;
    _cancelLocalTimers();
    setState(() {
      _isLoading = true;
      _localErrorMessage = null;
      _returnedWithoutConfirmation = false;
    });

    try {
      await ref.read(garminServiceProvider).completeGarminAuth(
            oauthVerifier: verifier,
            oauthToken: _pendingOauthToken,
          );

      // Verbindung steht in Firestore -> sofort offenen Wartestatus aufräumen.
      if (mounted) {
        setState(() {
          _pendingOauthToken = null;
          _pendingAuthUrl = null;
          _verifierController.clear();
        });
      }

      // Initialen REST-Pull best-effort anstoßen, ohne bei Sync-Rate-Limits den Erfolg zu widerrufen.
      int syncedCount = 0;
      String? syncWarning;
      try {
        final syncResult =
            await ref.read(garminServiceProvider).syncActivitiesNow(days: 90);
        syncedCount = (syncResult['count'] as num?)?.toInt() ?? 0;
      } catch (syncErr) {
        syncWarning = GarminService.resolveErrorMessage(syncErr);
      }

      ref.invalidate(activitiesProvider);
      ref.invalidate(homeDashboardProvider);

      if (!mounted) return;
      setState(() => _isLoading = false);

      final isDark = Theme.of(context).brightness == Brightness.dark;
      final successColor =
          isDark ? AppColors.successDark : AppColors.successLight;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: successColor,
          content: Text(
            syncWarning != null
                ? 'Erfolgreich mit Garmin verbunden! Erster Abruf folgt im Hintergrund ($syncWarning).'
                : 'Erfolgreich mit Garmin verbunden! $syncedCount Aktivitäten wurden synchronisiert.',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final currentStatus = ref.read(garminStatusStreamProvider).valueOrNull;
      if (currentStatus?.state == GarminConnectionState.connected) {
        // Paralleler Tab oder Deep-Link hat den Vorgang bereits abgeschlossen.
        setState(() {
          _pendingOauthToken = null;
          _pendingAuthUrl = null;
          _verifierController.clear();
          _isLoading = false;
        });
        return;
      }

      final errorMsg = GarminService.resolveErrorMessage(e);
      setState(() {
        _isLoading = false;
        _pendingOauthToken = null;
        _pendingAuthUrl = null;
        _localErrorMessage = errorMsg;
      });
      final isDark = Theme.of(context).brightness == Brightness.dark;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: isDark ? AppColors.errorDark : AppColors.errorLight,
          content: Text(
            'Verifizierung fehlgeschlagen: $errorMsg',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    } finally {
      _isSubmittingVerifier = false;
    }
  }

  /// Startet eine sofortige aktive REST-Pull-Synchronisation über Garmin.
  Future<void> _syncGarminNow() async {
    setState(() => _isLoading = true);
    try {
      final syncResult =
          await ref.read(garminServiceProvider).syncActivitiesNow(days: 90);
      ref.invalidate(activitiesProvider);
      ref.invalidate(homeDashboardProvider);
      if (!mounted) return;

      setState(() => _isLoading = false);
      final success = syncResult['success'] == true;
      final count = (syncResult['count'] as num?)?.toInt() ?? 0;
      final message = (syncResult['message'] as String?) ?? '';
      final isDark = Theme.of(context).brightness == Brightness.dark;

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor:
                isDark ? AppColors.errorDark : AppColors.errorLight,
            content: Text(
              message.isNotEmpty
                  ? message
                  : 'Fehler bei der Garmin-Synchronisation.',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      } else if (count > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor:
                isDark ? AppColors.successDark : AppColors.successLight,
            content: Text(
              'Garmin-Synchronisation erfolgreich! $count Aktivitäten aktualisiert.',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: isDark
                ? AppColors.sportTriathlonDark
                : AppColors.sportTriathlonLight,
            content: Text(
              message.isNotEmpty
                  ? message
                  : 'Garmin ist synchron. Keine neuen Aktivitäten gefunden.',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final isDark = Theme.of(context).brightness == Brightness.dark;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: isDark ? AppColors.errorDark : AppColors.errorLight,
          content: Text(
            'Fehler bei der Synchronisation: ${GarminService.resolveErrorMessage(e)}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  /// Trennt die aktive Garmin-Verbindung nach ausdrücklicher Bestätigung.
  Future<void> _disconnectGarmin() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final errorColor = isDark ? AppColors.errorDark : AppColors.errorLight;

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
            style: ElevatedButton.styleFrom(
              backgroundColor: errorColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Trennen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await ref.read(garminServiceProvider).disconnectGarmin();
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _pendingOauthToken = null;
          _pendingAuthUrl = null;
          _localErrorMessage = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Garmin-Verbindung wurde erfolgreich getrennt.'),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Fehler beim Trennen: ${GarminService.resolveErrorMessage(e)}',
            ),
          ),
        );
      }
    }
  }

  /// Fordert bei Garmin einen historischen 90-Tage-Backfill über die Queue an.
  Future<void> _triggerBackfill() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(garminServiceProvider).triggerBackfill(days: 90);
      if (!mounted) return;
      setState(() => _isLoading = false);
      final isDark = Theme.of(context).brightness == Brightness.dark;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: isDark
              ? AppColors.sportTriathlonDark
              : AppColors.sportTriathlonLight,
          content: const Text(
            'Historischer Import (90 Tage) wurde bei Garmin angefordert!',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Fehler beim Anfordern: ${GarminService.resolveErrorMessage(e)}',
          ),
        ),
      );
    }
  }

  /// Ermittelt, ob ein serverseitiger `CONNECTING`-Status noch frisch (< 5 Min.) oder veraltet ist.
  bool _isServerConnectingFresh(GarminStatus status) {
    if (status.state != GarminConnectionState.connecting) return false;
    final startedAt = status.authStartedAt;
    if (startedAt == null) return true;
    return DateTime.now().difference(startedAt) <= _kStaleConnectingThreshold;
  }

  @override
  Widget build(BuildContext context) {
    // Reagiert unmittelbar auf den Firestore-Statuswechsel nach `CONNECTED`, sodass Warte-Banner verschwinden.
    ref.listen<AsyncValue<GarminStatus>>(
      garminStatusStreamProvider,
      (_, next) {
        final nextStatus = next.valueOrNull;
        if (nextStatus == null) return;
        if (nextStatus.state == GarminConnectionState.connected &&
            (_pendingOauthToken != null || _localErrorMessage != null)) {
          _cancelLocalTimers();
          GarminWebCallbackBridge.clearPendingWebCallback();
          if (mounted) {
            setState(() {
              _pendingOauthToken = null;
              _pendingAuthUrl = null;
              _returnedWithoutConfirmation = false;
              _localErrorMessage = null;
            });
          }
        }
      },
    );

    final statusAsync = ref.watch(garminStatusStreamProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Farbtokens streng gemäß COLOR_SYSTEM_V1 (Light: Navy, kein Volt; Dark: Volt auf Tiefdunkel)
    final cardBg =
        isDark ? AppColors.darkCardSurface : AppColors.lightCardSurface;
    final elevatedBg = isDark
        ? AppColors.darkElevatedSurface
        : AppColors.lightSecondarySurface;
    final borderColor =
        isDark ? AppColors.darkSubtleBorder : AppColors.lightBorder;
    final accentColor = isDark ? AppColors.volt : AppColors.navy;
    final accentForeground = isDark ? AppColors.navy : Colors.white;
    final successColor =
        isDark ? AppColors.successDark : AppColors.successLight;
    final warningColor =
        isDark ? AppColors.warningDark : AppColors.warningLight;
    final errorColor = isDark ? AppColors.errorDark : AppColors.errorLight;
    final infoIconColor =
        isDark ? AppColors.sportTriathlonDark : AppColors.navy;

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
              style: TextStyle(color: errorColor),
            ),
          ),
        ),
        data: (status) {
          final isConnected = status.state == GarminConnectionState.connected;
          final isWaiting = !isConnected &&
              (_pendingOauthToken != null || _isServerConnectingFresh(status));
          final isStaleServerConnecting = !isConnected &&
              _pendingOauthToken == null &&
              status.state == GarminConnectionState.connecting &&
              !_isServerConnectingFresh(status);
          final effectiveError = _localErrorMessage ??
              (isStaleServerConnecting
                  ? 'Der letzte Garmin-Verbindungsversuch ist abgelaufen. Bitte starte die Kopplung erneut.'
                  : (!isConnected &&
                          !isWaiting &&
                          status.state == GarminConnectionState.error
                      ? (status.errorMessage ??
                          'Fehler beim letzten Garmin-Verbindungsversuch.')
                      : null));

          final statusDotColor = isConnected
              ? successColor
              : (isWaiting
                  ? warningColor
                  : (effectiveError != null
                      ? errorColor
                      : theme.colorScheme.onSurfaceVariant));
          final statusLabel = isConnected
              ? 'Verbunden'
              : (isWaiting
                  ? 'Warte auf Bestätigung...'
                  : (effectiveError != null
                      ? 'Verbindung fehlgeschlagen'
                      : 'Nicht verbunden'));

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              // Haupt-Status-Karte
              Card(
                elevation: 0,
                color: cardBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: borderColor, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isDark ? elevatedBg : AppColors.navy,
                          borderRadius: BorderRadius.circular(14),
                          border:
                              isDark ? Border.all(color: borderColor) : null,
                        ),
                        child: Icon(
                          Icons.watch,
                          color: isDark ? AppColors.volt : Colors.white,
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
                                    color: statusDotColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    statusLabel,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: statusDotColor,
                                    ),
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

              const SizedBox(height: 20),

              if (effectiveError != null) ...[
                Container(
                  key: const Key('garmin_error_banner'),
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: errorColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: errorColor.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.error_outline, color: errorColor, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          effectiveError,
                          style: TextStyle(
                            color: errorColor,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (isConnected) ...[
                // Verbundener Zustand
                Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.sync, color: successColor),
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

                // Aktiver REST-Pull Synchronisations-Button (Theme-konform: Navy im Light Mode, Volt im Dark Mode)
                ElevatedButton.icon(
                  key: const Key('garmin_sync_now_button'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: accentForeground,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _isLoading ? null : _syncGarminNow,
                  icon: _isLoading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: accentForeground,
                          ),
                        )
                      : const Icon(Icons.sync),
                  label: const Text(
                    'Jetzt synchronisieren (REST-Pull)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 12),

                // Backfill Button
                OutlinedButton.icon(
                  onPressed: _isLoading || status.isBackfillInProgress
                      ? null
                      : _triggerBackfill,
                  icon: const Icon(Icons.history),
                  label:
                      const Text('Historische Daten anfordern (Garmin Queue)'),
                ),

                const SizedBox(height: 16),

                // Disconnect Button
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: errorColor,
                  ),
                  onPressed: _isLoading ? null : _disconnectGarmin,
                  icon: const Icon(Icons.link_off),
                  label: const Text('Garmin-Verbindung trennen'),
                ),
              ] else ...[
                if (isWaiting) ...[
                  // Aktive Wartehilfe mit konkreten Auswegen gegen jedes Hängenbleiben
                  Card(
                    key: const Key('garmin_waiting_card'),
                    elevation: 0,
                    color: warningColor.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: warningColor.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: warningColor,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _returnedWithoutConfirmation
                                      ? 'Rückkehr ohne automatische Bestätigung erkannt'
                                      : 'Anmeldung im Browser läuft',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _returnedWithoutConfirmation
                                ? 'Du bist zu ORBIT zurückgekehrt, aber Garmin hat noch keinen '
                                    'Bestätigungscode übermittelt. Du kannst den Code unten einfügen, '
                                    'aus der Zwischenablage übernehmen oder den Vorgang abbrechen.'
                                : 'Bitte bestätige die Freigabe im geöffneten Garmin-Fenster. '
                                    'Sobald du zustimmst, wird dein Konto automatisch verknüpft.',
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.45,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                key: const Key('garmin_reopen_browser_button'),
                                onPressed:
                                    _isLoading ? null : _reopenAuthBrowser,
                                icon: const Icon(Icons.open_in_new, size: 18),
                                label: const Text('Browser erneut öffnen'),
                              ),
                              OutlinedButton.icon(
                                key: const Key('garmin_paste_clipboard_button'),
                                onPressed:
                                    _isLoading ? null : _pasteFromClipboard,
                                icon: const Icon(Icons.content_paste, size: 18),
                                label: const Text('Code einfügen'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            key: const Key('garmin_cancel_pending_button'),
                            style: TextButton.styleFrom(
                              foregroundColor: errorColor,
                              alignment: Alignment.centerLeft,
                            ),
                            onPressed: _isLoading
                                ? null
                                : () => _handleCancelledFlow(
                                      message:
                                          'Verbindungsvorgang wurde zurückgesetzt.',
                                      showSnackBar: false,
                                    ),
                            icon: const Icon(Icons.close, size: 18),
                            label:
                                const Text('Vorgang abbrechen / Zurücksetzen'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Nicht verbundener Zustand
                Text(
                  'Verbinde dein Garmin Connect™ Konto per OAuth 1.0a, um aufgezeichnete Ausdauertrainings '
                  '(Schwimmen, Radfahren, Laufen) in ORBIT zu synchronisieren, im Kalender einzusehen und '
                  'optional für deinen Coach freizugeben. Dein Garmin-Passwort wird dabei niemals gespeichert.',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                ElevatedButton.icon(
                  key: const Key('garmin_connect_button'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: accentForeground,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _isLoading ? null : _connectGarmin,
                  icon: _isLoading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: accentForeground,
                          ),
                        )
                      : const Icon(Icons.link),
                  label: Text(
                    _isLoading
                        ? 'Wird verarbeitet...'
                        : (isWaiting
                            ? 'Verbindung neu starten'
                            : 'Mit Garmin verbinden'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

                // Bestätigungscode Eingabebereich (manueller Fallback für alle Browser)
                const SizedBox(height: 28),
                Card(
                  elevation: 0,
                  color: cardBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: borderColor, width: 1.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.vpn_key_outlined,
                              size: 22,
                              color: infoIconColor,
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
                          'Falls dein Browser dich nach dem Garmin-Login nicht automatisch '
                          'zurückleitet, kopiere den angezeigten Code auf der Bestätigungsseite '
                          'und füge ihn hier ein:',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          key: const Key('garmin_verifier_textfield'),
                          controller: _verifierController,
                          decoration: const InputDecoration(
                            labelText: 'Bestätigungscode (oauth_verifier)',
                            hintText: 'z. B. 1a2b3c4d...',
                            prefixIcon: Icon(Icons.check),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          key: const Key('garmin_submit_verifier_button'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: accentForeground,
                          ),
                          onPressed: _isLoading ? null : _submitVerifier,
                          child: _isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: accentForeground,
                                  ),
                                )
                              : const Text('Verbindung abschließen'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                'Hinweis nach Marken- & Schnittstellenrichtlinien: Garmin Connect™ ist eine Marke der Garmin Ltd. oder ihrer Tochtergesellschaften. ORBIT ist eine eigenständige Plattform ohne offizielle Partnerschaft oder Zertifizierung durch Garmin Ltd.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
