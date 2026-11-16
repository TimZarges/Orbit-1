/// Datei-Header: `lib/features/dashboard/screens/dashboard_screen.dart`
/// Zweck: Zentrales Haupt-Dashboard der ORBIT-Applikation mit reaktiver V1.0.0-
/// vs. V2/V3-Feature-Steuerung (`ReleaseConfig`) und vollständiger DE/EN-Lokalisierung.
/// Architektur-Einordnung: Präsentationsschicht (`lib/features/dashboard/screens/`),
/// nutzt granulare Riverpod-Selektoren (`select`) gemäß `AGENTS.md` Regel 10.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/release_config.dart';
import '../../../core/localization/app_strings.dart';
import '../../activities/screens/today_tab_screen.dart';
import '../../analysis/screens/analysis_tab_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../../beta_feedback/widgets/beta_bug_reporter_sheet.dart';
import '../../calendar/screens/calendar_screen.dart';
import '../../coach_link/screens/athlete_coach_tab_screen.dart';
import '../../coach_link/screens/trainer_athletes_tab_screen.dart';
import '../../notifications/widgets/notification_bell_icon_button.dart';
import '../../profile/screens/profile_screen.dart';
import '../../settings/providers/settings_provider.dart';
import '../../workout_builder/screens/workout_template_library_screen.dart';

/// Zentrales Haupt-Dashboard der ORBIT-Applikation.
///
/// Was: Stellt die rollen- und versionsbasierte Bottom-Navigation bereit:
/// - Im V1.0.0-Standardbetrieb (`ReleaseConfig.isV2Enabled == false`):
///   - Athlet: *Heute*, *Kalender*, *Coach* (ohne V2/V3-Analyse-Tab).
///   - Coach: *Athleten*, *Kalender*, *Profil/Einstellungen* (3-Tab-Coach-Navigation gemäß `docs/ROADMAP_V1_TO_V4.md`).
/// - Im V2/V3-Modus (`ReleaseConfig.isV2Enabled == true`):
///   - Athlet: *Heute*, *Kalender*, *Analyse*, *Coach*.
///   - Coach: *Athleten*, *Kalender*, *Analyse*, *Bibliothek*.
/// Warum: Trennt den fokussierten V1.0.0-Release-Umfang sauber von den geparkten V2/V3-Modulen,
/// während alle 218 Bestands-Tests über `ReleaseConfig.overrideForTesting` nahtlos weiterlaufen.
class DashboardScreen extends ConsumerStatefulWidget {
  /// Erstellt das Haupt-Dashboard.
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  /// Aktuell ausgewählter Tab-Index.
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Granulare Selektoren gemäß Effizienz-Gebot (AGENTS.md Regel 10)
    final role = ref.watch(
      userDocumentProvider.select((asyncDoc) => asyncDoc.valueOrNull?['role']),
    );
    final lang = ref.watch(
      settingsControllerProvider.select((s) => s.languageCode),
    );
    final isV2Enabled = ref.watch(
      releaseConfigProvider.select((cfg) => cfg.isV2Enabled),
    );
    final isV3Enabled = ref.watch(
      releaseConfigProvider.select((cfg) => cfg.isV3Enabled),
    );

    final isTrainer = role == 'TRAINER';

    // Seiten-Liste abhängig von Rolle und aktivem Release-Scope (V1.0.0 vs. V2/V3)
    final List<Widget> pages = isTrainer
        ? [
            const TrainerAthletesTabScreen(),
            const CalendarScreen(),
            if (isV2Enabled || isV3Enabled) const AnalysisTabScreen(),
            if (isV2Enabled)
              const WorkoutTemplateLibraryScreen()
            else
              const ProfileScreen(),
          ]
        : [
            const TodayTabScreen(),
            const CalendarScreen(),
            if (isV2Enabled || isV3Enabled) const AnalysisTabScreen(),
            const AthleteCoachTabScreen(),
          ];

    // Lokalisierte Tab-Titel (DE / EN)
    final List<String> titles = isTrainer
        ? [
            AppStrings.navAthletes(lang: lang),
            AppStrings.navCalendar(lang: lang),
            if (isV2Enabled || isV3Enabled) AppStrings.navAnalysis(lang: lang),
            if (isV2Enabled)
              AppStrings.navLibrary(lang: lang)
            else
              AppStrings.navProfile(lang: lang),
          ]
        : [
            AppStrings.navToday(lang: lang),
            AppStrings.navCalendar(lang: lang),
            if (isV2Enabled || isV3Enabled) AppStrings.navAnalysis(lang: lang),
            AppStrings.navCoach(lang: lang),
          ];

    // Sicherstellen, dass der Index bei Scope-Umschaltung im gültigen Bereich bleibt
    final safeIndex = _currentIndex.clamp(0, pages.length - 1);

    // BottomNavigationBar-Items passend zu Rolle, Sprache und Release-Scope
    final List<BottomNavigationBarItem> navItems = isTrainer
        ? [
            BottomNavigationBarItem(
              icon: const Icon(Icons.group_outlined),
              activeIcon: const Icon(Icons.group),
              label: AppStrings.navAthletes(lang: lang),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.calendar_month_outlined),
              activeIcon: const Icon(Icons.calendar_month),
              label: AppStrings.navCalendar(lang: lang),
            ),
            if (isV2Enabled || isV3Enabled)
              BottomNavigationBarItem(
                icon: const Icon(Icons.query_stats_outlined),
                activeIcon: const Icon(Icons.query_stats),
                label: AppStrings.navAnalysis(lang: lang),
              ),
            if (isV2Enabled)
              BottomNavigationBarItem(
                icon: const Icon(Icons.collections_bookmark_outlined),
                activeIcon: const Icon(Icons.collections_bookmark),
                label: AppStrings.navLibrary(lang: lang),
              )
            else
              BottomNavigationBarItem(
                icon: const Icon(Icons.person_outline),
                activeIcon: const Icon(Icons.person),
                label: AppStrings.navProfile(lang: lang),
              ),
          ]
        : [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: AppStrings.navToday(lang: lang),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.calendar_month_outlined),
              activeIcon: const Icon(Icons.calendar_month),
              label: AppStrings.navCalendar(lang: lang),
            ),
            if (isV2Enabled || isV3Enabled)
              BottomNavigationBarItem(
                icon: const Icon(Icons.query_stats_outlined),
                activeIcon: const Icon(Icons.query_stats),
                label: AppStrings.navAnalysis(lang: lang),
              ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.people_outline),
              activeIcon: const Icon(Icons.people),
              label: AppStrings.navCoach(lang: lang),
            ),
          ];

    return Scaffold(
      appBar: safeIndex == 1
          ? null
          : AppBar(
              title: Text(titles[safeIndex]),
              actions: [
                const BetaBugReportIconButton(),
                if (isV2Enabled) const NotificationBellIconButton(),
                Builder(
                  builder: (btnContext) => IconButton(
                    key: const Key('dashboard_avatar_menu_button'),
                    icon: const CircleAvatar(
                      radius: 16,
                      child: Icon(Icons.person, size: 16),
                    ),
                    onPressed: () => _openAvatarMenu(
                      btnContext,
                      lang: lang,
                      isV2Enabled: isV2Enabled,
                      isV3Enabled: isV3Enabled,
                    ),
                  ),
                ),
              ],
            ),
      body: pages[safeIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: safeIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: navItems,
      ),
    );
  }

  /// Öffnet das Profil- & Schnellzugriffsmenü oben rechts unter Berücksichtigung
  /// der aktiven Release-Ausbaustufe (`ReleaseConfig`).
  Future<void> _openAvatarMenu(
    BuildContext btnContext, {
    required String lang,
    required bool isV2Enabled,
    required bool isV3Enabled,
  }) async {
    // Berechnet die exakte Bildschirmposition des Avatar-Buttons für showMenu
    final RenderBox button = btnContext.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(btnContext).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    final selected = await showMenu<String>(
      context: btnContext,
      position: position,
      items: <PopupMenuEntry<String>>[
        PopupMenuItem(
          value: '/profile',
          child: Text(AppStrings.navProfile(lang: lang)),
        ),
        if (isV2Enabled) ...[
          PopupMenuItem(
            value: '/templates',
            child: Text(lang == 'en' ? 'Workout Templates' : 'Workout-Vorlagen'),
          ),
          const PopupMenuItem(
            value: '/workout-builder',
            child: Text('Workout Builder'),
          ),
          PopupMenuItem(
            value: '/diagnostics',
            child: Text(
              lang == 'en' ? 'Performance Diagnostics' : 'Leistungsdiagnostik',
            ),
          ),
        ],
        if (isV3Enabled)
          PopupMenuItem(
            value: '/health',
            child: Text(
              lang == 'en' ? 'Health & Baselines' : 'Gesundheit & Baselines',
            ),
          ),
        PopupMenuItem(
          value: '/my-feedback',
          child: Text(AppStrings.navMyFeedback(lang: lang)),
        ),
        PopupMenuItem(
          value: '/settings',
          child: Text(AppStrings.navSettings(lang: lang)),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              const Icon(Icons.logout, size: 18, color: Colors.redAccent),
              const SizedBox(width: 8),
              Text(
                AppStrings.navLogout(lang: lang),
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (selected != null && btnContext.mounted) {
      if (selected == 'logout') {
        await ref.read(authServiceProvider).signOut();
      } else {
        await btnContext.push(selected);
      }
    }
  }
}
