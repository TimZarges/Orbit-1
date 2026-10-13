import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/user_provider.dart';
import '../../coach_link/screens/athlete_coach_tab_screen.dart';
import '../../coach_link/screens/trainer_athletes_tab_screen.dart';
import '../../activities/screens/today_tab_screen.dart';
import '../../calendar/screens/calendar_screen.dart';
import '../../analysis/screens/analysis_tab_screen.dart';
import '../../workout_builder/screens/workout_template_library_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
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
        : ['Heute', 'Plan', 'Analyse', 'Coach'];

    return Scaffold(
      appBar: _currentIndex == 1
          ? null
          : AppBar(
              title: Text(_currentIndex == 0 ? 'Orbit' : titles[_currentIndex]),
              actions: [
                IconButton(
                  icon: const CircleAvatar(
                    radius: 16,
                    child: Icon(Icons.person, size: 16),
                  ),
                  onPressed: () {
                    showMenu(
                      context: context,
                      position: const RelativeRect.fromLTRB(100, kToolbarHeight, 0, 0),
                      items: [
                        PopupMenuItem(
                          value: 'profile',
                          child: const Text('Profil'),
                          onTap: () => context.go('/profile'),
                        ),
                        PopupMenuItem(
                          value: 'templates',
                          child: const Text('Workout-Vorlagen'),
                          onTap: () => context.go('/templates'),
                        ),
                        PopupMenuItem(
                          value: 'builder',
                          child: const Text('Workout Builder'),
                          onTap: () => context.go('/workout-builder'),
                        ),
                        PopupMenuItem(
                          value: 'diagnostics',
                          child: const Text('Leistungsdiagnostik'),
                          onTap: () => context.go('/diagnostics'),
                        ),
                        PopupMenuItem(
                          value: 'settings',
                          child: const Text('Einstellungen'),
                          onTap: () => context.go('/settings'),
                        ),
                      ],
                    );
                  },
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
                  label: 'Plan',
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
