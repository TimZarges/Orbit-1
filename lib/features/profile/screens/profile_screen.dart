import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Center(
            child: Stack(
              children: [
                const CircleAvatar(
                  radius: 50,
                  child: Icon(Icons.person, size: 50),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt,
                          size: 18, color: Colors.white),
                      onPressed: () {
                        // TODO: Implement image upload
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            initialValue: 'Max Mustermann',
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: '1990',
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Geburtsjahr',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: '75.0',
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Gewicht (kg)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  initialValue: '180',
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Größe (cm)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Sportarten',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            children: [
              FilterChip(
                  label: const Text('Laufen'),
                  selected: true,
                  onSelected: (_) {}),
              FilterChip(
                  label: const Text('Radfahren'),
                  selected: true,
                  onSelected: (_) {}),
              FilterChip(
                  label: const Text('Schwimmen'),
                  selected: false,
                  onSelected: (_) {}),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profil gespeichert')),
              );
            },
            child: const Text('Speichern'),
          ),
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                Text(
                  'ORBIT ${AppInfo.fullVersionString}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Server-Region: ${AppInfo.region}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
