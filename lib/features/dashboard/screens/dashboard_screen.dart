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
import '../../../core/design/app_colors.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/widgets/responsive_content_frame.dart';
import '../../activities/screens/today_tab_screen.dart';
import '../../analysis/screens/analysis_tab_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../../auth/widgets/email_verification_banner.dart';
import '../../beta_feedback/widgets/beta_bug_reporter_sheet.dart';
import '../../calendar/screens/calendar_screen.dart';
import '../../coach_link/providers/v1_coach_connection_provider.dart';
import '../../coach_link/screens/athlete_coach_tab_screen.dart';
import '../../coach_link/screens/trainer_athletes_tab_screen.dart';
import '../../coach_link/screens/v1_coach_calendar_tab.dart';
import '../../notifications/widgets/notification_bell_icon_button.dart';
import '../../profile/screens/profile_screen.dart';
import '../../profile/widgets/user_avatar_circle.dart';
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

    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool isWideScreen =
        screenWidth >= ResponsiveContentFrame.desktopBreakpoint;
    final bool isExtendedRail =
        screenWidth >= ResponsiveContentFrame.extendedRailBreakpoint;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Offene Coach-E-Mail-Einladungen bei Athleten automatisch übernehmen
    if (!isTrainer) {
      ref.watch(v1AutoClaimCoachInvitesProvider);
    }

    // Seiten-Liste abhängig von Rolle, aktivem Release-Scope und Responsive-Modus
    final List<Widget> pages = isTrainer
        ? [
            const TrainerAthletesTabScreen(),
            if (isV2Enabled)
              const CalendarScreen()
            else
              const V1CoachCalendarTab(),
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
            // Im breiten Web-/Desktop-Layout direkter Profil-Tab in der NavigationRail
            if (isWideScreen && !isV2Enabled) const ProfileScreen(),
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
            if (isWideScreen && !isV2Enabled) AppStrings.navProfile(lang: lang),
          ];

    // Sicherstellen, dass der Index bei Scope- oder Breakpoint-Wechsel gültig bleibt
    final int activeCoachTab = (isTrainer && !isV2Enabled)
        ? ref.watch(v1CoachTabIndexProvider)
        : _currentIndex;
    final safeIndex = activeCoachTab.clamp(0, pages.length - 1);

    // BottomNavigationBar-Items (auf Mobilgeräten < 900px)
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

    // NavigationRail-Ziele für Web / Desktop ab >= 900px Breite
    final List<NavigationRailDestination> railDestinations = isTrainer
        ? [
            NavigationRailDestination(
              icon: const Icon(Icons.group_outlined),
              selectedIcon: const Icon(Icons.group),
              label: Text(AppStrings.navAthletes(lang: lang)),
            ),
            NavigationRailDestination(
              icon: const Icon(Icons.calendar_month_outlined),
              selectedIcon: const Icon(Icons.calendar_month),
              label: Text(AppStrings.navCalendar(lang: lang)),
            ),
            if (isV2Enabled || isV3Enabled)
              NavigationRailDestination(
                icon: const Icon(Icons.query_stats_outlined),
                selectedIcon: const Icon(Icons.query_stats),
                label: Text(AppStrings.navAnalysis(lang: lang)),
              ),
            if (isV2Enabled)
              NavigationRailDestination(
                icon: const Icon(Icons.collections_bookmark_outlined),
                selectedIcon: const Icon(Icons.collections_bookmark),
                label: Text(AppStrings.navLibrary(lang: lang)),
              )
            else
              NavigationRailDestination(
                icon: const Icon(Icons.person_outline),
                selectedIcon: const Icon(Icons.person),
                label: Text(AppStrings.navProfile(lang: lang)),
              ),
          ]
        : [
            NavigationRailDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: Text(AppStrings.navToday(lang: lang)),
            ),
            NavigationRailDestination(
              icon: const Icon(Icons.calendar_month_outlined),
              selectedIcon: const Icon(Icons.calendar_month),
              label: Text(AppStrings.navCalendar(lang: lang)),
            ),
            if (isV2Enabled || isV3Enabled)
              NavigationRailDestination(
                icon: const Icon(Icons.query_stats_outlined),
                selectedIcon: const Icon(Icons.query_stats),
                label: Text(AppStrings.navAnalysis(lang: lang)),
              ),
            NavigationRailDestination(
              icon: const Icon(Icons.people_outline),
              selectedIcon: const Icon(Icons.people),
              label: Text(AppStrings.navCoach(lang: lang)),
            ),
            if (!isV2Enabled)
              NavigationRailDestination(
                icon: const Icon(Icons.person_outline),
                selectedIcon: const Icon(Icons.person),
                label: Text(AppStrings.navProfile(lang: lang)),
              ),
          ];

    // Gemeinsame Tab-Umschaltlogik für Rail & BottomNavigationBar
    void onTabSelected(int index) {
      if (isTrainer && !isV2Enabled) {
        ref.read(v1CoachTabIndexProvider.notifier).state = index;
      } else {
        setState(() => _currentIndex = index);
      }
    }

    // Aktiver Inhaltsbereich mit zentrierter Maximalbreite für Web/Desktop
    final Widget contentArea = ResponsiveContentFrame(
      maxWidth: 1080.0,
      child: Column(
        children: [
          const EmailVerificationBanner(),
          Expanded(child: pages[safeIndex]),
        ],
      ),
    );

    final bool hideAppBar = safeIndex == 1 ||
        (isTrainer && !isV2Enabled && safeIndex == 2) ||
        (!isTrainer && isWideScreen && !isV2Enabled && safeIndex == 3);

    return Scaffold(
      appBar: hideAppBar
          ? null
          : AppBar(
              title: Text(titles[safeIndex]),
              actions: [
                const BetaBugReportIconButton(),
                if (isV2Enabled) const NotificationBellIconButton(),
                Builder(
                  builder: (btnContext) => IconButton(
                    key: const Key('dashboard_avatar_menu_button'),
                    icon: const UserAvatarCircle(radius: 16),
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
      body: isWideScreen
          ? Row(
              children: [
                NavigationRail(
                  key: const Key('dashboard_web_navigation_rail'),
                  extended: isExtendedRail,
                  minExtendedWidth: 210,
                  backgroundColor: AppColors.cardBg(isDark: isDark),
                  selectedIndex: safeIndex,
                  onDestinationSelected: onTabSelected,
                  indicatorColor: AppColors.primaryAccent(isDark: isDark)
                      .withValues(alpha: isDark ? 0.20 : 0.12),
                  selectedIconTheme: IconThemeData(
                    color: AppColors.primaryAccent(isDark: isDark),
                  ),
                  selectedLabelTextStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryAccent(isDark: isDark),
                  ),
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.navy,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.bolt,
                        color: AppColors.volt,
                        size: 20,
                      ),
                    ),
                  ),
                  trailing: Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 16),
                    child: IconButton(
                      key: const Key('rail_settings_button'),
                      icon: const Icon(Icons.settings_outlined),
                      tooltip: lang == 'en' ? 'Settings' : 'Einstellungen',
                      onPressed: () => context.push('/settings'),
                    ),
                  ),
                  destinations: railDestinations,
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: AppColors.cardBorderFor(isDark: isDark),
                ),
                Expanded(child: contentArea),
              ],
            )
          : contentArea,
      bottomNavigationBar: isWideScreen
          ? null
          : BottomNavigationBar(
              key: const Key('dashboard_mobile_bottom_nav'),
              type: BottomNavigationBarType.fixed,
              currentIndex: safeIndex,
              onTap: onTabSelected,
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
            child:
                Text(lang == 'en' ? 'Workout Templates' : 'Workout-Vorlagen'),
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
