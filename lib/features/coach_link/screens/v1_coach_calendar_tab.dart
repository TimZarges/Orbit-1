/// Datei-Header: `lib/features/coach_link/screens/v1_coach_calendar_tab.dart`
/// Zweck: V1.0.0 Coach-Kalender-Ansicht (Tab 2 der 3-Tab-Coach-Navigation, Phase 44)
/// mit kompakter Athleten-Auswahlleiste oben und dem vollständigen V1.0.0-Kalender
/// (Woche, Monat, Liste) inklusive `TrainingPreviewCard` und aktivem `.FIT`-Download
/// für den ausgewählten Athleten.
/// Architektur-Einordnung: Präsentationsschicht (`lib/features/coach_link/screens/`),
/// nutzt `ProviderScope`-Override auf [viewedAthleteIdProvider], sodass alle
/// Aktivitäts-Streams und [FitDownloadService] automatisch auf `athleteId` laufen
/// (`AGENTS.md` Regel 10).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design/app_colors.dart';
import '../../beta_feedback/widgets/beta_bug_reporter_sheet.dart';
import '../../calendar/screens/calendar_screen.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/v1_coach_athlete_link.dart';
import '../providers/athlete_context_provider.dart';
import '../providers/v1_coach_connection_provider.dart';

/// V1.0.0 Coach-Tab 2: „Kalender“ mit Athleten-Schnellwechsel.
///
/// Was:
/// - Zeigt oben eine horizontale Athleten-Auswahlleiste (`ChoiceChip`s) für alle
///   aktiv verbundenen Athleten.
/// - Rendert darunter den vollständigen [CalendarScreen] (Woche, Monat, Liste)
///   im Kontext des ausgewählten Athleten (`athleteId`), sodass `TrainingPreviewCard`
///   inkl. `.FIT`-Download-Button direkt für dessen Einheiten funktioniert.
/// - Zeigt bei fehlenden Athleten einen klaren Leerzustand mit Sprung zu Tab 1.
/// Warum: Ermöglicht dem Coach blitzschnelles Umschalten zwischen seinen
/// Athleten ohne verschachtelte Navigationsebenen.
class V1CoachCalendarTab extends ConsumerWidget {
  /// Optionaler Test-Override für die verbundenen Athleten (ohne Firestore).
  final List<V1CoachAthleteLink>? athletesOverride;

  /// Erstellt den [V1CoachCalendarTab].
  const V1CoachCalendarTab({super.key, this.athletesOverride});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(
      settingsControllerProvider.select((s) => s.languageCode),
    );
    final selectedId = ref.watch(v1SelectedCoachAthleteIdProvider);
    final isEn = lang == 'en';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<V1CoachAthleteLink> allLinks = athletesOverride ??
        (ref.watch(v1CoachAthletesStreamProvider).valueOrNull ?? const []);
    final activeAthletes = allLinks.where((l) => l.isActive).toList();

    if (activeAthletes.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isEn ? 'Calendar' : 'Kalender'),
          actions: const [
            BetaBugReportIconButton(),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 56,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isEn
                        ? 'No connected athletes yet'
                        : 'Noch keine verbundenen Athleten',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isEn
                        ? 'Connect with an athlete in the Athletes tab to view their workouts and download .FIT files.'
                        : 'Verbinde dich im Tab „Athleten“ mit einem Athleten, um seine Einheiten und .FIT-Dateien zu sehen.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    key: const Key('coach_calendar_go_athletes_btn'),
                    onPressed: () {
                      ref.read(v1CoachTabIndexProvider.notifier).state = 0;
                    },
                    icon: const Icon(Icons.group_outlined),
                    label: Text(isEn ? 'Go to Athletes' : 'Zu den Athleten'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Aktiven Athleten bestimmen (Fallback auf den ersten verbundenen Athleten)
    final V1CoachAthleteLink selectedAthlete = activeAthletes.firstWhere(
      (a) => a.athleteId == selectedId,
      orElse: () => activeAthletes.first,
    );

    // Sicherstellen, dass v1SelectedCoachAthleteIdProvider und viewedAthleteIdProvider
    // auch beim direkten Tab-Wechsel sofort auf den aktiven Athleten zeigen
    if (selectedId != selectedAthlete.athleteId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          ref.read(v1SelectedCoachAthleteIdProvider.notifier).state =
              selectedAthlete.athleteId;
          ref.read(viewedAthleteIdProvider.notifier).state =
              selectedAthlete.athleteId;
        }
      });
    }

    return Column(
      children: [
        // Kompakte Athleten-Auswahlleiste oben (mit SafeArea wegen appBar: null im Dashboard)
        Container(
          key: const Key('coach_calendar_athlete_selector'),
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? AppColors.anthraciteCard : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE2E8F0),
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 54,
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                scrollDirection: Axis.horizontal,
                itemCount: activeAthletes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, idx) {
                  final athlete = activeAthletes[idx];
                  final isSelected =
                      athlete.athleteId == selectedAthlete.athleteId;
                  final displayName = athlete.athleteName.isNotEmpty
                      ? athlete.athleteName
                      : athlete.athleteEmail;

                  return ChoiceChip(
                    key: Key('coach_calendar_chip_${athlete.athleteId}'),
                    selected: isSelected,
                    label: Text(displayName),
                    avatar: CircleAvatar(
                      radius: 11,
                      backgroundColor:
                          isSelected ? AppColors.navy : AppColors.volt,
                      child: Text(
                        (displayName.isNotEmpty ? displayName[0] : 'A')
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppColors.volt : AppColors.navy,
                        ),
                      ),
                    ),
                    onSelected: (_) {
                      ref
                          .read(v1SelectedCoachAthleteIdProvider.notifier)
                          .state = athlete.athleteId;
                      ref.read(viewedAthleteIdProvider.notifier).state =
                          athlete.athleteId;
                    },
                  );
                },
              ),
            ),
          ),
        ),

        // V1.0.0-Kalender im Kontext des ausgewählten Athleten
        Expanded(
          child: ProviderScope(
            key: ValueKey('coach_calendar_scope_${selectedAthlete.athleteId}'),
            overrides: [
              viewedAthleteIdProvider
                  .overrideWith((ref) => selectedAthlete.athleteId),
            ],
            child: CalendarScreen(
              athleteId: selectedAthlete.athleteId,
              hideSafeAreaTop: true,
            ),
          ),
        ),
      ],
    );
  }
}
