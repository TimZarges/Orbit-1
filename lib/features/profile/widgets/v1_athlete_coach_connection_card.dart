/// Datei-Header: `lib/features/profile/widgets/v1_athlete_coach_connection_card.dart`
/// Zweck: Modulares Widget für die Sektion „Mein Coach / Verbindung mit Coach“
/// im „Profil Einfach“ des Athleten (Phase 44): Einladungscode einlösen,
/// eingehende Coach-Anfragen mit DSGVO-Freigabe bestätigen oder ablehnen sowie
/// aktive Coach-Verbindung mit 1 Klick widerrufen.
/// Architektur-Einordnung: Präsentationsschicht (`lib/features/profile/widgets/`),
/// nutzt `v1CoachConnectionServiceProvider` und `v1AthleteCoachLinksStreamProvider`
/// (`AGENTS.md` Regel 10).
library;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design/app_colors.dart';
import '../../coach_link/models/v1_coach_athlete_link.dart';
import '../../coach_link/providers/v1_coach_connection_provider.dart';

/// Sektion „Mein Coach / Verbindung mit Coach“ im „Profil Einfach“ des Athleten.
///
/// Was:
/// - Zeigt eine aktive Coach-Verbindung (Name, E-Mail, DSGVO-Hinweis) inkl.
///   1-Klick-Trennen-Button (`revokeLink`).
/// - Zeigt eingehende Verbindungsanfragen (`PENDING`) mit verpflichtender,
///   nicht vorangekreuzter DSGVO-Datenfreigabe-Checkbox.
/// - Bietet ohne aktive Verbindung ein Einladungscode-Eingabefeld inkl.
///   verpflichtender DSGVO-Checkbox zum Verbinden (`redeemInvite`).
/// Warum: Trennt die Coach-Verbindungslogik sauber von `V1SimpleProfileView`
/// und bleibt durch `linksOverride` vollständig widget-testbar.
class V1AthleteCoachConnectionCard extends ConsumerStatefulWidget {
  /// Aktive Sprache (`'de'` oder `'en'`).
  final String lang;

  /// Optionaler Test-Override für die Verbindungs-Liste (ohne Firestore).
  final List<V1CoachAthleteLink>? linksOverride;

  /// Erstellt die [V1AthleteCoachConnectionCard].
  const V1AthleteCoachConnectionCard({
    super.key,
    required this.lang,
    this.linksOverride,
  });

  @override
  ConsumerState<V1AthleteCoachConnectionCard> createState() =>
      _V1AthleteCoachConnectionCardState();
}

class _V1AthleteCoachConnectionCardState
    extends ConsumerState<V1AthleteCoachConnectionCard> {
  final TextEditingController _codeController = TextEditingController();
  bool _gdprAcceptedForCode = false;
  final Map<String, bool> _gdprAcceptedForRequest = {};
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    // Übernimmt etwaige vor Registrierung gesendete Coach-E-Mail-Einladungen als PENDING-Anfrage
    if (widget.linksOverride == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _claimPendingEmailInvitesIfReady();
      });
    }
  }

  /// Prüft aktiv auf offene Coach-E-Mail-Einladungen (`coachInvites`) und lädt bei
  /// Bedarf den Verbindungs-Stream neu.
  Future<void> _claimPendingEmailInvitesIfReady({
    bool showFeedbackOnEmpty = false,
  }) async {
    final isEn = widget.lang == 'en';
    try {
      if (Firebase.apps.isEmpty) return;
      final claimed = await ref
          .read(v1CoachConnectionServiceProvider)
          .claimPendingInvites();
      ref.invalidate(v1AthleteCoachLinksStreamProvider);
      if (mounted && showFeedbackOnEmpty) {
        _showFeedback(
          claimed > 0
              ? (isEn
                  ? '$claimed coach request(s) loaded.'
                  : '$claimed Coach-Anfrage(n) übernommen.')
              : (isEn
                  ? 'Checked: no new open email invitations.'
                  : 'Geprüft: keine weiteren offenen E-Mail-Einladungen gefunden.'),
        );
      }
    } catch (e) {
      if (mounted && showFeedbackOnEmpty) {
        _showFeedback(
          isEn
              ? 'Could not check invites: $e'
              : 'Einladungsprüfung fehlgeschlagen: $e',
          isError: true,
        );
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  /// Löst den eingegebenen Einladungscode nach DSGVO-Bestätigung ein.
  Future<void> _submitInviteCode() async {
    final isEn = widget.lang == 'en';
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      _showFeedback(
        isEn
            ? 'Please enter an invite code.'
            : 'Bitte gib einen Einladungscode ein.',
        isError: true,
      );
      return;
    }
    if (!_gdprAcceptedForCode) {
      _showFeedback(
        isEn
            ? 'Please confirm GDPR data sharing first.'
            : 'Bitte bestätige zuerst die DSGVO-Datenfreigabe.',
        isError: true,
      );
      return;
    }

    setState(() => _isBusy = true);
    try {
      await ref.read(v1CoachConnectionServiceProvider).redeemInviteWithConsent(
            code: code,
            gdprConsent: true,
          );
      if (mounted) {
        _codeController.clear();
        setState(() => _gdprAcceptedForCode = false);
        _showFeedback(
          isEn
              ? 'Successfully connected with your coach.'
              : 'Erfolgreich mit deinem Coach verbunden.',
        );
      }
    } catch (e) {
      if (mounted) {
        _showFeedback(
          isEn ? 'Connection failed: $e' : 'Verbindung fehlgeschlagen: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  /// Beantwortet eine eingehende Coach-Anfrage (Annehmen nur mit DSGVO-Haken).
  Future<void> _respondToRequest(
    V1CoachAthleteLink link, {
    required bool accept,
  }) async {
    final isEn = widget.lang == 'en';
    final consented = _gdprAcceptedForRequest[link.linkId] ?? false;
    if (accept && !consented) {
      _showFeedback(
        isEn
            ? 'Please confirm GDPR data sharing first.'
            : 'Bitte bestätige zuerst die DSGVO-Datenfreigabe.',
        isError: true,
      );
      return;
    }

    setState(() => _isBusy = true);
    try {
      await ref.read(v1CoachConnectionServiceProvider).respondToPendingRequest(
            linkId: link.linkId,
            accept: accept,
            gdprConsent: consented,
          );
      if (mounted) {
        _showFeedback(
          accept
              ? (isEn
                  ? 'Coach connection confirmed.'
                  : 'Coach-Verbindung bestätigt.')
              : (isEn ? 'Request declined.' : 'Anfrage abgelehnt.'),
        );
      }
    } catch (e) {
      if (mounted) {
        _showFeedback(
          isEn ? 'Action failed: $e' : 'Aktion fehlgeschlagen: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  /// Widerruft eine bestehende Coach-Verbindung mit sofortiger Wirkung.
  Future<void> _disconnectCoach(V1CoachAthleteLink link) async {
    final isEn = widget.lang == 'en';
    setState(() => _isBusy = true);
    try {
      await ref.read(v1CoachConnectionServiceProvider).revokeLink(link.linkId);
      if (mounted) {
        _showFeedback(
          isEn
              ? 'Coach connection disconnected. Data access revoked.'
              : 'Coach-Verbindung getrennt. Datenzugriff sofort entzogen.',
        );
      }
    } catch (e) {
      if (mounted) {
        _showFeedback(
          isEn ? 'Disconnect failed: $e' : 'Trennen fehlgeschlagen: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  /// Zeigt eine lokalisierte Rückmeldung über eine SnackBar an.
  void _showFeedback(String message, {bool isError = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? AppColors.statusError(isDark: isDark)
            : AppColors.statusSuccess(isDark: isDark),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEn = widget.lang == 'en';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Hintergrund-Übernahme offener E-Mail-Einladungen beim Öffnen triggern
    AsyncValue<List<V1CoachAthleteLink>>? linksAsync;
    final List<V1CoachAthleteLink> links;
    if (widget.linksOverride != null) {
      links = widget.linksOverride!;
    } else {
      ref.watch(v1AutoClaimCoachInvitesProvider);
      linksAsync = ref.watch(v1AthleteCoachLinksStreamProvider);
      links = linksAsync?.valueOrNull ?? const [];
    }

    final activeLinks = links.where((l) => l.isActive).toList();
    final pendingLinks = links.where((l) => l.isPending).toList();
    final streamError = linksAsync?.error;

    final gdprConsentLabel = isEn
        ? 'I allow this coach to view my completed workouts in the calendar and download the associated .fit files.'
        : 'Ich erlaube diesem Coach, meine absolvierten Trainings im Kalender einzusehen und die zugehörigen .fit-Dateien herunterzuladen.';

    final primaryAccent = AppColors.primaryAccent(isDark: isDark);
    final cardBg = AppColors.cardBg(isDark: isDark);
    final borderColor = AppColors.cardBorderFor(isDark: isDark);
    final subtleBg = AppColors.subtleSurface(isDark: isDark);
    final successColor = AppColors.statusSuccess(isDark: isDark);
    final warningColor = AppColors.statusWarning(isDark: isDark);
    final errorColor = AppColors.statusError(isDark: isDark);

    return Card(
      key: const Key('athlete_coach_connection_card'),
      elevation: 0,
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.supervisor_account_outlined,
                  size: 20,
                  color: primaryAccent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isEn
                        ? 'My Coach / Coach Connection'
                        : 'Mein Coach / Verbindung mit Coach',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (streamError != null) ...[
              Container(
                key: const Key('athlete_coach_links_error'),
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: errorColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: errorColor.withValues(alpha: 0.45)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEn
                          ? 'Could not load coach requests: $streamError'
                          : 'Coach-Anfragen konnten nicht geladen werden: $streamError',
                      style: TextStyle(fontSize: 12, color: errorColor),
                    ),
                    const SizedBox(height: 6),
                    TextButton.icon(
                      onPressed: () =>
                          _claimPendingEmailInvitesIfReady(showFeedbackOnEmpty: true),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: Text(isEn ? 'Retry' : 'Erneut laden'),
                    ),
                  ],
                ),
              ),
            ],

            // 1. Aktive Coach-Verbindung anzeigen
            for (final active in activeLinks) ...[
              Container(
                key: Key('active_coach_tile_${active.coachId}'),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: subtleBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: successColor.withValues(alpha: 0.50),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.navy,
                          child: Icon(
                            Icons.sports,
                            color: AppColors.volt,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                active.coachName.isNotEmpty
                                    ? active.coachName
                                    : 'ORBIT Coach',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              if (active.coachEmail.isNotEmpty)
                                Text(
                                  active.coachEmail,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: successColor.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isEn ? 'Connected' : 'Verbunden',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: successColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isEn
                          ? 'GDPR sharing active: Calendar & .fit download allowed.'
                          : 'DSGVO-Freigabe aktiv: Kalender-Einsicht & .fit-Download erlaubt.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        key: Key('disconnect_coach_btn_${active.linkId}'),
                        onPressed:
                            _isBusy ? null : () => _disconnectCoach(active),
                        icon: const Icon(Icons.link_off, size: 18),
                        label: Text(
                          isEn ? 'Disconnect Coach' : 'Verbindung trennen',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: errorColor,
                          side: BorderSide(color: errorColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // 2. Eingehende Coach-Anfragen (PENDING) mit DSGVO-Bestätigung
            for (final pending in pendingLinks) ...[
              Container(
                key: Key('pending_coach_request_${pending.linkId}'),
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: subtleBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: warningColor.withValues(alpha: 0.55),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEn
                          ? 'Incoming Coach Request'
                          : 'Eingehende Coach-Anfrage',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: warningColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pending.coachName.isNotEmpty
                          ? '${pending.coachName} (${pending.coachEmail})'
                          : pending.coachEmail,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    CheckboxListTile(
                      key: Key('pending_gdpr_checkbox_${pending.linkId}'),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _gdprAcceptedForRequest[pending.linkId] ?? false,
                      onChanged: _isBusy
                          ? null
                          : (val) => setState(
                                () => _gdprAcceptedForRequest[pending.linkId] =
                                    val ?? false,
                              ),
                      title: Text(
                        gdprConsentLabel,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            key: Key('decline_coach_btn_${pending.linkId}'),
                            onPressed: _isBusy
                                ? null
                                : () =>
                                    _respondToRequest(pending, accept: false),
                            child: Text(isEn ? 'Decline' : 'Ablehnen'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            key: Key('accept_coach_btn_${pending.linkId}'),
                            onPressed: _isBusy ||
                                    !(_gdprAcceptedForRequest[pending.linkId] ??
                                        false)
                                ? null
                                : () =>
                                    _respondToRequest(pending, accept: true),
                            child: Text(
                              isEn ? 'Confirm' : 'Verbindung bestätigen',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            // 3. Einladungscode eingeben, sofern noch kein aktiver Coach verbunden ist
            if (activeLinks.isEmpty) ...[
              TextField(
                key: const Key('athlete_invite_code_input'),
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText:
                      isEn ? 'Coach Invite Code' : 'Coach-Einladungscode',
                  hintText: 'A1B2C3',
                  prefixIcon: const Icon(Icons.vpn_key_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                key: const Key('athlete_code_gdpr_checkbox'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _gdprAcceptedForCode,
                onChanged: _isBusy
                    ? null
                    : (val) =>
                        setState(() => _gdprAcceptedForCode = val ?? false),
                title: Text(
                  gdprConsentLabel,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                key: const Key('athlete_connect_code_btn'),
                onPressed:
                    _isBusy || !_gdprAcceptedForCode ? null : _submitInviteCode,
                icon: _isBusy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.link),
                label: Text(
                  isEn ? 'Connect with Coach' : 'Mit Coach verbinden',
                ),
              ),
              if (widget.linksOverride == null) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  key: const Key('athlete_check_email_invites_btn'),
                  onPressed: _isBusy
                      ? null
                      : () => _claimPendingEmailInvitesIfReady(
                            showFeedbackOnEmpty: true,
                          ),
                  icon: const Icon(Icons.mark_email_read_outlined, size: 16),
                  label: Text(
                    isEn
                        ? 'Check for email invitations'
                        : 'Auf E-Mail-Einladungen prüfen',
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
