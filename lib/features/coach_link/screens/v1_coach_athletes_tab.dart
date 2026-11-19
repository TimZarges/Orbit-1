/// Datei-Header: `lib/features/coach_link/screens/v1_coach_athletes_tab.dart`
/// Zweck: Aufgeräumte V1.0.0 Coach-Athleten-Übersicht (Tab 1 der 3-Tab-Coach-Navigation,
/// Phase 44) im Clean Professional Design (Hell & Dunkel) mit Einladungscode-Karte,
/// E-Mail-Verbindungsanfrage, Sportarten-Badges inkl. Triathlon, Datum der letzten
/// Aktivität (`dd.mm.yy • 24h`) und direktem Sprung in den Athleten-Kalender.
/// Architektur-Einordnung: Präsentationsschicht (`lib/features/coach_link/screens/`),
/// nutzt `ListView.builder`, `const`-Konstruktoren und granulare Riverpod-Selektoren
/// (`AGENTS.md` Regel 10).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/utils/country_date_time_formatter.dart';
import '../../onboarding/widgets/triathlon_combined_icon.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/v1_coach_athlete_link.dart';
import '../providers/athlete_context_provider.dart';
import '../providers/v1_coach_connection_provider.dart';

/// V1.0.0 Coach-Tab 1: „Athleten“ (ohne V2/V3-Analyse- oder Planungs-Elemente).
///
/// Was:
/// - Zeigt den eigenen Coach-Einladungscode (inkl. Generieren & Kopieren) sowie
///   einen Dialog für Verbindungsanfragen per Athleten-E-Mail.
/// - Listet offene Verbindungsanfragen (`PENDING`) und alle verbundenen Athleten
///   (`ACTIVE`) mit Hauptsportarten (inkl. Triathlon-Icon) und letzter Aktivität.
/// - Klick auf einen verbundenen Athleten wählt diesen in
///   `v1SelectedCoachAthleteIdProvider` aus und wechselt in Tab 2 (`Kalender`).
/// Warum: Fokussierter Coach-Workflow für Closed Beta V1.0.0 (`docs/ROADMAP_V1_TO_V4.md`).
class V1CoachAthletesTab extends ConsumerStatefulWidget {
  /// Optionaler Test-Override für die Athletenliste (ohne Firestore).
  final List<V1CoachAthleteLink>? athletesOverride;

  /// Optionaler Test-Override für einen bereits generierten Einladungscode.
  final String? initialInviteCodeOverride;

  /// Erstellt den [V1CoachAthletesTab].
  const V1CoachAthletesTab({
    super.key,
    this.athletesOverride,
    this.initialInviteCodeOverride,
  });

  @override
  ConsumerState<V1CoachAthletesTab> createState() => _V1CoachAthletesTabState();
}

class _V1CoachAthletesTabState extends ConsumerState<V1CoachAthletesTab> {
  String? _inviteCode;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _inviteCode = widget.initialInviteCodeOverride;
  }

  /// Erzeugt über die Cloud Function `createInvite` einen neuen 6-stelligen Code.
  Future<void> _generateInviteCode(String lang) async {
    final isEn = lang == 'en';
    setState(() => _isGenerating = true);
    try {
      final code =
          await ref.read(v1CoachConnectionServiceProvider).createInviteCode();
      if (mounted) {
        setState(() => _inviteCode = code);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEn
                  ? 'Could not generate invite code: $e'
                  : 'Code konnte nicht erzeugt werden: $e',
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  /// Kopiert den Einladungscode in die Zwischenablage.
  Future<void> _copyInviteCode(String lang) async {
    final code = _inviteCode;
    if (code == null || code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang == 'en'
                ? 'Invite code copied: $code'
                : 'Einladungscode kopiert: $code',
          ),
        ),
      );
    }
  }

  /// Öffnet den Dialog zum Versenden einer E-Mail-Verbindungsanfrage an einen Athleten.
  ///
  /// Warum [_InviteByEmailDialog]: Kapselt den [TextEditingController] im eigenen
  /// `ConsumerStatefulWidget`, sodass `dispose()` sicher erst nach der Dialog-Schließanimation
  /// greift und Rückmeldungen sowohl für bestehende als auch neue Athleten-Konten sauber
  /// inklusive 6-stelligem Einladungscode angezeigt werden.
  Future<void> _showInviteByEmailDialog(String lang) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _InviteByEmailDialog(isEn: lang == 'en'),
    );
    if (!mounted || result == null) return;

    final isEn = lang == 'en';
    final returnedCode =
        (result['inviteCode'] as String? ?? '').trim().toUpperCase();
    if (returnedCode.isNotEmpty) {
      setState(() => _inviteCode = returnedCode);
    }

    final email = (result['athleteEmail'] as String? ?? '').trim();
    final accountExists = result['accountExists'] == true;
    final mailProviderConfigured = result['mailProviderConfigured'] == true;

    if (accountExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEn
                ? 'Connection request sent to $email (Coach code: $returnedCode). Athlete confirms GDPR sharing in Profile.'
                : 'Verbindungsanfrage für $email hinterlegt (Coach-Code: $returnedCode). Athlet bestätigt im Profil.',
          ),
        ),
      );
      return;
    }

    // Für noch nicht registrierte E-Mails: Klare Anleitung + 1-Klick-Teilen des Coach-Codes
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('coach_email_invite_result_dialog'),
        title: Text(
          isEn
              ? 'Invitation Saved (No Account Yet)'
              : 'Einladung vorgemerkt (noch kein Konto)',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEn
                  ? 'No ORBIT account exists for $email yet. Your invitation is saved and will appear automatically in their Profile as soon as they sign up with $email.'
                  : 'Für $email existiert noch kein ORBIT-Konto. Die Einladung ist gespeichert und erscheint automatisch im Profil, sobald sich $email registriert.',
            ),
            const SizedBox(height: 10),
            if (!mailProviderConfigured)
              Text(
                isEn
                    ? 'Note: Automatic email dispatch is not active yet. Please share your 6-character Coach Code directly:'
                    : 'Hinweis: Automatischer E-Mail-Versand ist aktuell nicht aktiv. Bitte teile deinem Athleten direkt deinen 6-stelligen Coach-Code mit:',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
            if (returnedCode.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  returnedCode,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (returnedCode.isNotEmpty)
            TextButton.icon(
              key: const Key('coach_copy_invite_share_btn'),
              onPressed: () async {
                final shareText = isEn
                    ? 'Join me on ORBIT (https://orbit-app-mvp.web.app/app/#/register) with Coach Code: $returnedCode'
                    : 'Verbinde dich mit mir auf ORBIT (https://orbit-app-mvp.web.app/app/#/register) mit meinem Coach-Code: $returnedCode';
                await Clipboard.setData(ClipboardData(text: shareText));
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isEn
                            ? 'Invite text & code copied!'
                            : 'Einladungstext & Code kopiert!',
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: Text(
                isEn ? 'Copy Code & Link' : 'Code & Link kopieren',
              ),
            ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isEn ? 'OK' : 'Verstanden'),
          ),
        ],
      ),
    );
  }

  /// Wählt den Athleten für Tab 2 (`Kalender`) aus, synchronisiert den globalen
  /// Athleten-Kontext ([viewedAthleteIdProvider]) und wechselt direkt dorthin.
  void _openAthleteCalendar(V1CoachAthleteLink link) {
    ref.read(v1SelectedCoachAthleteIdProvider.notifier).state = link.athleteId;
    ref.read(viewedAthleteIdProvider.notifier).state = link.athleteId;
    ref.read(v1CoachTabIndexProvider.notifier).state = 1;
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(
      settingsControllerProvider.select((s) => s.languageCode),
    );
    final countryCode = ref.watch(
      settingsControllerProvider.select((s) => s.countryCode),
    );
    final isEn = lang == 'en';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<V1CoachAthleteLink> allLinks = widget.athletesOverride ??
        (ref.watch(v1CoachAthletesStreamProvider).valueOrNull ?? const []);
    final List<V1PendingCoachEmailInvite> pendingEmailInvites =
        widget.athletesOverride != null
            ? const []
            : (ref
                    .watch(v1CoachPendingEmailInvitesStreamProvider)
                    .valueOrNull ??
                const []);
    final activeAthletes = allLinks.where((l) => l.isActive).toList();
    final pendingRequests = allLinks.where((l) => l.isPending).toList();
    final totalPendingCount =
        pendingRequests.length + pendingEmailInvites.length;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 1. Einladungscode- & E-Mail-Anfrage-Karte
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Card(
                key: const Key('coach_invite_card'),
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
                      Text(
                        isEn ? 'Connect Athlete' : 'Athleten verbinden',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isEn
                            ? 'Share your invite code or send an email connection request.'
                            : 'Teile deinen Einladungscode oder sende eine Anfrage per E-Mail.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_inviteCode != null && _inviteCode!.isNotEmpty) ...[
                        Container(
                          key: const Key('coach_invite_code_box'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.volt.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _inviteCode!,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 4,
                                  ),
                                ),
                              ),
                              IconButton(
                                key: const Key('coach_copy_invite_btn'),
                                onPressed: () => _copyInviteCode(lang),
                                icon: const Icon(Icons.copy_rounded),
                                tooltip: isEn ? 'Copy Code' : 'Code kopieren',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              key: const Key('coach_generate_invite_btn'),
                              onPressed: _isGenerating
                                  ? null
                                  : () => _generateInviteCode(lang),
                              icon: _isGenerating
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.vpn_key_outlined,
                                      size: 18,
                                    ),
                              label: Text(
                                _inviteCode == null
                                    ? (isEn ? 'Generate Code' : 'Code erzeugen')
                                    : (isEn ? 'New Code' : 'Neuer Code'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              key: const Key('coach_open_email_invite_btn'),
                              onPressed: () => _showInviteByEmailDialog(lang),
                              icon: const Icon(Icons.mail_outline, size: 18),
                              label: Text(
                                isEn ? 'By Email' : 'Per E-Mail',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. Offene Verbindungsanfragen (PENDING coachLinks & noch nicht registrierte coachInvites)
          if (totalPendingCount > 0) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Text(
                  isEn
                      ? 'Pending Requests ($totalPendingCount)'
                      : 'Offene Anfragen ($totalPendingCount)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (pendingRequests.isNotEmpty)
              SliverList.builder(
                itemCount: pendingRequests.length,
                itemBuilder: (ctx, idx) {
                  final req = pendingRequests[idx];
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Card(
                      key: Key('coach_pending_athlete_${req.athleteId}'),
                      elevation: 0,
                      color: isDark ? AppColors.anthraciteCard : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: Colors.amber.withValues(alpha: 0.4),
                        ),
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.hourglass_top_rounded, size: 18),
                        ),
                        title: Text(
                          req.athleteName.isNotEmpty
                              ? req.athleteName
                              : req.athleteEmail,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          isEn
                              ? 'Waiting for athlete GDPR confirmation'
                              : 'Wartet auf DSGVO-Bestätigung des Athleten',
                        ),
                        trailing: IconButton(
                          icon:
                              const Icon(Icons.close, color: Colors.redAccent),
                          tooltip:
                              isEn ? 'Cancel request' : 'Anfrage zurückziehen',
                          onPressed: () => ref
                              .read(v1CoachConnectionServiceProvider)
                              .revokeLink(req.linkId),
                        ),
                      ),
                    ),
                  );
                },
              ),
            if (pendingEmailInvites.isNotEmpty)
              SliverList.builder(
                itemCount: pendingEmailInvites.length,
                itemBuilder: (ctx, idx) {
                  final inv = pendingEmailInvites[idx];
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Card(
                      key: Key('coach_pending_email_invite_${inv.inviteId}'),
                      elevation: 0,
                      color: isDark ? AppColors.anthraciteCard : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: Colors.amber.withValues(alpha: 0.4),
                        ),
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.mail_outline_rounded, size: 18),
                        ),
                        title: Text(
                          inv.athleteEmail,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          isEn
                              ? 'Pending sign-up • Share code: ${inv.inviteCode}'
                              : 'Wartet auf Registrierung • Coach-Code: ${inv.inviteCode}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (inv.inviteCode.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.copy_rounded, size: 18),
                                tooltip: isEn ? 'Copy Code' : 'Code kopieren',
                                onPressed: () async {
                                  await Clipboard.setData(
                                    ClipboardData(text: inv.inviteCode),
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isEn
                                              ? 'Invite code copied: ${inv.inviteCode}'
                                              : 'Einladungscode kopiert: ${inv.inviteCode}',
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.redAccent,
                              ),
                              tooltip: isEn
                                  ? 'Revoke invite'
                                  : 'Einladung zurückziehen',
                              onPressed: () => ref
                                  .read(v1CoachConnectionServiceProvider)
                                  .revokePendingInvite(inv.inviteId),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],

          // 3. Überschrift Verbundene Athleten
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Text(
                isEn
                    ? 'Connected Athletes (${activeAthletes.length})'
                    : 'Verbundene Athleten (${activeAthletes.length})',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // 4. Liste der verbundenen Athleten oder Leerzustand
          if (activeAthletes.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.group_outlined,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isEn
                          ? 'No athletes connected yet.'
                          : 'Noch keine Athleten verbunden.',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEn
                          ? 'Generate an invite code above and share it with your athlete.'
                          : 'Erzeuge oben einen Einladungscode und teile ihn mit deinem Athleten.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList.builder(
              itemCount: activeAthletes.length,
              itemBuilder: (ctx, index) {
                final athlete = activeAthletes[index];
                final lastActStr = athlete.lastActivityAt != null
                    ? CountryDateTimeFormatter.formatDateTime(
                        athlete.lastActivityAt!,
                        countryCode: countryCode,
                      )
                    : (isEn ? 'No activity yet' : 'Noch keine Aktivität');

                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  child: Card(
                    key: Key('coach_athlete_card_${athlete.athleteId}'),
                    elevation: 0,
                    color: isDark ? AppColors.anthraciteCard : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _openAthleteCalendar(athlete),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColors.navy,
                              child: Text(
                                (athlete.athleteName.isNotEmpty
                                        ? athlete.athleteName[0]
                                        : 'A')
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.volt,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    athlete.athleteName.isNotEmpty
                                        ? athlete.athleteName
                                        : athlete.athleteEmail,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (athlete.athleteSports.isNotEmpty)
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: athlete.athleteSports
                                          .take(3)
                                          .map(
                                            (sport) => _SportBadge(
                                              sport: sport,
                                              lang: lang,
                                              isDark: isDark,
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.schedule,
                                        size: 14,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isEn
                                            ? 'Last training: $lastActStr'
                                            : 'Letztes Training: $lastActStr',
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.calendar_month_outlined),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

/// Kompaktes Sportarten-Badge (mit [TriathlonCombinedIcon] für Triathlon).
class _SportBadge extends StatelessWidget {
  final String sport;
  final String lang;
  final bool isDark;

  const _SportBadge({
    required this.sport,
    required this.lang,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = sport.toUpperCase();
    final isTri = normalized == 'TRIATHLON';
    final label =
        isTri ? 'Triathlon' : AppStrings.sportLabel(normalized, lang: lang);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isTri)
            TriathlonCombinedIcon(
              size: 13,
              color: isDark ? AppColors.volt : AppColors.navy,
            )
          else
            Icon(
              _iconForSport(normalized),
              size: 13,
              color: isDark ? AppColors.volt : AppColors.navy,
            ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  /// Ordnet dem Sport-Code ein klares Material-Icon zu.
  IconData _iconForSport(String code) {
    switch (code) {
      case 'BIKE':
      case 'CYCLING':
        return Icons.directions_bike;
      case 'RUN':
      case 'RUNNING':
        return Icons.directions_run;
      case 'SWIM':
      case 'SWIMMING':
        return Icons.pool;
      case 'STRENGTH':
        return Icons.fitness_center;
      default:
        return Icons.sports;
    }
  }
}

/// Eigenständiges Dialog-Widget für die E-Mail-Einladung durch den Coach.
///
/// Was: Rendert das E-Mail-Eingabefeld und ruft `requestAthleteByEmail` auf.
/// Warum: Durch die Kapselung als `ConsumerStatefulWidget` wird der interne
/// `TextEditingController` erst nach Abschluss der Dialog-Schließanimation
/// in `State.dispose()` freigegeben (`AGENTS.md` Regel 10).
class _InviteByEmailDialog extends ConsumerStatefulWidget {
  final bool isEn;

  const _InviteByEmailDialog({required this.isEn});

  @override
  ConsumerState<_InviteByEmailDialog> createState() =>
      _InviteByEmailDialogState();
}

class _InviteByEmailDialogState extends ConsumerState<_InviteByEmailDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isSending = false;
  String? _errorMsg;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEn = widget.isEn;
    return AlertDialog(
      title: Text(
        isEn ? 'Invite Athlete by Email' : 'Athlet per E-Mail einladen',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isEn
                ? 'The athlete will see your request in their Profile (immediately or after registration) and must confirm GDPR sharing.'
                : 'Der Athlet sieht deine Anfrage in seinem Profil (sofort oder nach Registrierung) und muss der DSGVO-Freigabe zustimmen.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('coach_invite_email_input'),
            controller: _controller,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: isEn ? 'Athlete Email' : 'Athleten-E-Mail',
              hintText: 'athlet@verein.de',
            ),
          ),
          if (_errorMsg != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMsg!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSending ? null : () => Navigator.of(context).pop(),
          child: Text(isEn ? 'Cancel' : 'Abbrechen'),
        ),
        FilledButton(
          key: const Key('coach_send_email_invite_btn'),
          onPressed: _isSending
              ? null
              : () async {
                  final email = _controller.text.trim();
                  if (email.isEmpty || !email.contains('@')) {
                    setState(() {
                      _errorMsg = isEn
                          ? 'Please enter a valid email address.'
                          : 'Bitte gültige E-Mail-Adresse eingeben.';
                    });
                    return;
                  }
                  setState(() {
                    _isSending = true;
                    _errorMsg = null;
                  });
                  try {
                    final response = await ref
                        .read(v1CoachConnectionServiceProvider)
                        .requestAthleteByEmail(email);
                    if (context.mounted) {
                      Navigator.of(context).pop(<String, dynamic>{
                        ...response,
                        'athleteEmail':
                            response['athleteEmail'] ?? email.toLowerCase(),
                      });
                    }
                  } catch (e) {
                    if (mounted) {
                      setState(() {
                        _isSending = false;
                        _errorMsg = e.toString();
                      });
                    }
                  }
                },
          child: _isSending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEn ? 'Send Request' : 'Anfrage senden'),
        ),
      ],
    );
  }
}
