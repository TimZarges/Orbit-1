/// Datei-Header: `lib/features/profile/widgets/v1_athlete_coach_connection_card.dart`
/// Zweck: Modulares Widget für die Sektion „Mein Coach / Verbindung mit Coach“
/// im „Profil Einfach“ des Athleten (Phase 44): Einladungscode einlösen,
/// eingehende Coach-Anfragen mit DSGVO-Freigabe bestätigen oder ablehnen sowie
/// aktive Coach-Verbindung mit 1 Klick widerrufen.
/// Architektur-Einordnung: Präsentationsschicht (`lib/features/profile/widgets/`),
/// nutzt `v1CoachConnectionServiceProvider` und `v1AthleteCoachLinksStreamProvider`
/// (`AGENTS.md` Regel 10).
library;

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : AppColors.volt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEn = widget.lang == 'en';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Entweder Test-Override oder echter Firestore-Stream (defensiv gegen fehlendes Firebase)
    final List<V1CoachAthleteLink> links;
    if (widget.linksOverride != null) {
      links = widget.linksOverride!;
    } else {
      links =
          ref.watch(v1AthleteCoachLinksStreamProvider).valueOrNull ?? const [];
    }

    final activeLinks = links.where((l) => l.isActive).toList();
    final pendingLinks = links.where((l) => l.isPending).toList();

    final gdprConsentLabel = isEn
        ? 'I allow this coach to view my completed workouts in the calendar and download the associated .fit files.'
        : 'Ich erlaube diesem Coach, meine absolvierten Trainings im Kalender einzusehen und die zugehörigen .fit-Dateien herunterzuladen.';

    return Card(
      key: const Key('athlete_coach_connection_card'),
      elevation: 0,
      color: isDark ? AppColors.anthraciteCard : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
        ),
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
                  color: isDark ? AppColors.volt : AppColors.navy,
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

            // 1. Aktive Coach-Verbindung anzeigen
            for (final active in activeLinks) ...[
              Container(
                key: Key('active_coach_tile_${active.coachId}'),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.volt.withValues(alpha: 0.45),
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
                            color: AppColors.volt.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isEn ? 'Connected' : 'Verbunden',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.volt : AppColors.navy,
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
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
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
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEn
                          ? 'Incoming Coach Request'
                          : 'Eingehende Coach-Anfrage',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
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
            ],
          ],
        ),
      ),
    );
  }
}
