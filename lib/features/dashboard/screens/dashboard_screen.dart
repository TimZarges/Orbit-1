import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../../coach_link/screens/athlete_coach_tab_screen.dart';
import '../../coach_link/screens/trainer_athletes_tab_screen.dart';
import '../../activities/screens/today_tab_screen.dart';
import '../../calendar/screens/calendar_screen.dart';
import '../../analysis/screens/analysis_tab_screen.dart';
import '../../beta_feedback/widgets/beta_bug_reporter_sheet.dart';
import '../../workout_builder/screens/workout_template_library_screen.dart';
import '../../notifications/widgets/notification_bell_icon_button.dart';

/// Zentrales Haupt-Dashboard der ORBIT-Applikation.
///
/// Stellt die rollenbasierte Bottom-Navigation bereit:
/// - Für Athleten: Heute, Kalender, Analyse, Coach
/// - Für Trainer: Athleten, Kalender, Analyse, Bibliothek
/// Verwaltet zudem die globale AppBar mit Bug-Reporter, Benachrichtigungen/Chat und Profilzugang.
class DashboardScreen extends ConsumerStatefulWidget {
  /// Erstellt das Haupt-Dashboard.
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userDoc = ref.watch(userDocumentProvider).valueOrNull;
    final role = userDoc?['role'];
    final isTrainer = role == 'TRAINER';

    final List<Widget> pages = isTrainer
        ? [
            const TrainerAthletesTabScreen(),
            const CalendarScreen(),
            const AnalysisTabScreen(),
            const WorkoutTemplateLibraryScreen(),
          ]
        : [
            const TodayTabScreen(),
            const CalendarScreen(),
            const AnalysisTabScreen(),
            const AthleteCoachTabScreen(),
          ];

    final titles = isTrainer
        ? ['Athleten', 'Kalender', 'Analyse', 'Bibliothek']
        : ['Heute', 'Kalender', 'Analyse', 'Coach'];

    return Scaffold(
      appBar: _currentIndex == 1
          ? null
          : AppBar(
              title: Text(titles[_currentIndex]),
              actions: [
                const BetaBugReportIconButton(),
                const NotificationBellIconButton(),
                Builder(
                  builder: (btnContext) => IconButton(
                    icon: const CircleAvatar(
                      radius: 16,
                      child: Icon(Icons.person, size: 16),
                    ),
                    onPressed: () async {
                      final RenderBox button =
                          btnContext.findRenderObject() as RenderBox;
                      final RenderBox overlay = Overlay.of(btnContext)
                          .context
                          .findRenderObject() as RenderBox;
                      final RelativeRect position = RelativeRect.fromRect(
                        Rect.fromPoints(
                          button.localToGlobal(Offset.zero, ancestor: overlay),
                          button.localToGlobal(
                              button.size.bottomRight(Offset.zero),
                              ancestor: overlay),
                        ),
                        Offset.zero & overlay.size,
                      );

                      final selected = await showMenu<String>(
                        context: btnContext,
                        position: position,
                        items: const [
                          PopupMenuItem(
                            value: '/profile',
                            child: Text('Profil'),
                          ),
                          PopupMenuItem(
                            value: '/templates',
                            child: Text('Workout-Vorlagen'),
                          ),
                          PopupMenuItem(
                            value: '/workout-builder',
                            child: Text('Workout Builder'),
                          ),
                          PopupMenuItem(
                            value: '/health',
                            child: Text('Gesundheit & Baselines'),
                          ),
                          PopupMenuItem(
                            value: '/diagnostics',
                            child: Text('Leistungsdiagnostik'),
                          ),
                          PopupMenuItem(
                            value: '/admin/feedback',
                            child: Text('Beta-Feedback Inbox'),
                          ),
                          PopupMenuItem(
                            value: '/gallery',
                            child: Text('Design-Galerie & Karten'),
                          ),
                          PopupMenuItem(
                            value: '/settings',
                            child: Text('Einstellungen'),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'logout',
                            child: Row(
                              children: [
                                Icon(Icons.logout,
                                    size: 18, color: Colors.redAccent),
                                SizedBox(width: 8),
                                Text(
                                  'Abmelden',
                                  style: TextStyle(
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
                          btnContext.push(selected);
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: isTrainer
            ? const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.group_outlined),
                  activeIcon: Icon(Icons.group),
                  label: 'Athleten',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_month_outlined),
                  activeIcon: Icon(Icons.calendar_month),
                  label: 'Kalender',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.query_stats_outlined),
                  activeIcon: Icon(Icons.query_stats),
                  label: 'Analyse',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.collections_bookmark_outlined),
                  activeIcon: Icon(Icons.collections_bookmark),
                  label: 'Bibliothek',
                ),
              ]
            : const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Heute',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_month_outlined),
                  activeIcon: Icon(Icons.calendar_month),
                  label: 'Kalender',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.query_stats_outlined),
                  activeIcon: Icon(Icons.query_stats),
                  label: 'Analyse',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people_outline),
                  activeIcon: Icon(Icons.people),
                  label: 'Coach',
                ),
              ],
      ),
    );
  }
}
