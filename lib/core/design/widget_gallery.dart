import 'package:flutter/material.dart';

class WidgetGalleryScreen extends StatelessWidget {
  const WidgetGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Widget Galerie')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Typography', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 16),
          Text('Display', style: Theme.of(context).textTheme.displayLarge),
          Text('Title', style: Theme.of(context).textTheme.titleLarge),
          Text('Body', style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 32),
          Text('Colors', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ColorBox(color: Theme.of(context).primaryColor, name: 'Navy'),
              _ColorBox(
                  color: Theme.of(context).colorScheme.secondary, name: 'Volt'),
            ],
          ),
          const SizedBox(height: 32),
          Text('Tagesform (Readiness Card)', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 16),
          const Text('Die Tagesform-Karte passt sich der Erfahrungsstufe an und visualisiert Schlaf, Ruhepuls und HRV im Verhältnis zur 28-Tage-Basislinie.'),
          const SizedBox(height: 12),
          // Preview Card
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Color(0xFF10B981)),
                      SizedBox(width: 8),
                      Text('Unauffällig (Normalbereich)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('Ruhepuls und HRV liegen im gewohnten persönlichen Bereich.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );

  }
}

class _ColorBox extends StatelessWidget {
  final Color color;
  final String name;

  const _ColorBox({required this.color, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      color: color,
      alignment: Alignment.center,
      child: Text(
        name,
        style: const TextStyle(
            color: Colors.white, shadows: [Shadow(blurRadius: 2)]),
      ),
    );
  }
}
