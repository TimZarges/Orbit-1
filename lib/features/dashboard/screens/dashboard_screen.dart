import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/user_provider.dart';
import '../../coach_link/screens/athlete_coach_tab_screen.dart';
import '../../coach_link/screens/trainer_athletes_tab_screen.dart';

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
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Dashboard Placeholder'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go('/gallery'),
              child: const Text('Zur Widget-Galerie'),
            ),
          ],
        ),
      ),
      if (role == 'TRAINER')
        const TrainerAthletesTabScreen()
      else
        const AthleteCoachTabScreen(),
    ];

    return Scaffold(
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
