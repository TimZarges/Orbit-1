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
  Future<void> _showInviteByEmailDialog(String lang) async {
    final isEn = lang == 'en';
    final controller = TextEditingController();
    bool isSending = false;
    String? errorMsg;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
            isEn ? 'Invite Athlete by Email' : 'Athlet per E-Mail einladen',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEn
                    ? 'The athlete will see your request in their Profile and must confirm GDPR sharing.'
                    : 'Der Athlet sieht deine Anfrage in seinem Profil und muss der DSGVO-Freigabe zustimmen.',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('coach_invite_email_input'),
                controller: controller,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: isEn ? 'Athlete Email' : 'Athleten-E-Mail',
                  hintText: 'athlet@verein.de',
                ),
              ),
              if (errorMsg != null) ...[
                const SizedBox(height: 8),
                Text(
                  errorMsg!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSending ? null : () => Navigator.of(ctx).pop(),
              child: Text(isEn ? 'Cancel' : 'Abbrechen'),
            ),
            FilledButton(
              key: const Key('coach_send_email_invite_btn'),
              onPressed: isSending
                  ? null
                  : () async {
                      final email = controller.text.trim();
                      if (email.isEmpty || !email.contains('@')) {
                        setDialogState(() {
                          errorMsg = isEn
                              ? 'Please enter a valid email address.'
                              : 'Bitte gültige E-Mail-Adresse eingeben.';
                        });
                        return;
                      }
                      setDialogState(() {
                        isSending = true;
                        errorMsg = null;
                      });
                      try {
                        await ref
                            .read(v1CoachConnectionServiceProvider)
                            .requestAthleteByEmail(email);
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isEn
                                    ? 'Connection request sent to $email.'
                                    : 'Verbindungsanfrage an $email gesendet.',
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() {
                          isSending = false;
                          errorMsg = e.toString();
                        });
                      }
                    },
              child: isSending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEn ? 'Send Request' : 'Anfrage senden'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
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
    final activeAthletes = allLinks.where((l) => l.isActive).toList();
    final pendingRequests = allLinks.where((l) => l.isPending).toList();

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
                                  : const Icon(Icons.vpn_key_outlined, size: 18),
                              label: Text(
                                _inviteCode == null
                                    ? (isEn
                                        ? 'Generate Code'
                                        : 'Code erzeugen')
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

          // 2. Offene Verbindungsanfragen (PENDING)
          if (pendingRequests.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Text(
                  isEn
                      ? 'Pending Requests (${pendingRequests.length})'
                      : 'Offene Anfragen (${pendingRequests.length})',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
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
                        icon: const Icon(Icons.close, color: Colors.redAccent),
                        tooltip: isEn ? 'Cancel request' : 'Anfrage zurückziehen',
                        onPressed: () => ref
                            .read(v1CoachConnectionServiceProvider)
                            .revokeLink(req.linkId),
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
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
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
    final label = isTri ? 'Triathlon' : AppStrings.sportLabel(normalized, lang: lang);

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
