import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/user_provider.dart';
import '../../coach_link/screens/athlete_coach_tab_screen.dart';
import '../../coach_link/screens/trainer_athletes_tab_screen.dart';
import '../../activities/screens/today_tab_screen.dart';

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

    final List<Widget> pages = [
      const TodayTabScreen(),
      if (role == 'TRAINER')
        const TrainerAthletesTabScreen()
      else
        const AthleteCoachTabScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orbit'),
        actions: [
          IconButton(
            icon: const CircleAvatar(
              radius: 16,
              child: Icon(Icons.person, size: 16),
            ),
            onPressed: () {
              // Menü öffnen oder direkt zum Profil
              showMenu(
                context: context,
                position:
                    const RelativeRect.fromLTRB(100, kToolbarHeight, 0, 0),
                items: [
                  PopupMenuItem(
                    value: 'profile',
                    child: const Text('Profil'),
                    onTap: () => context.go('/profile'),
                  ),
                  PopupMenuItem(
                    value: 'thresholds',
                    child: const Text('Schwellenwerte'),
                    onTap: () => context.go('/thresholds'),
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
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Heute'),
          BottomNavigationBarItem(
            icon: const Icon(Icons.group),
            label: role == 'TRAINER' ? 'Athleten' : 'Coach',
          ),
        ],
      ),
    );
  }
}
