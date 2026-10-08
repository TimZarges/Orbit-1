import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Heute')),
      body: Center(
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
    );
  }
}
