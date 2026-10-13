import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';

/// Modal mit einer Übersicht aller Tastaturkürzel im Coach-Desktop.
class KeyboardShortcutsDialog extends StatelessWidget {
  const KeyboardShortcutsDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const KeyboardShortcutsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.white,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.techGrey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.keyboard_outlined, size: 20, color: AppColors.navy),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Tastaturkürzel (Coach)',
                      style: AppTypography.title.copyWith(fontSize: 18, color: AppColors.navy),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Schließen',
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),
            _buildShortcutRow('?', 'Diese Übersicht öffnen'),
            _buildShortcutRow('Cmd + K  /  Strg + K', 'Athleten-Suche fokussieren'),
            _buildShortcutRow('/', 'Schnellsuche im Raster'),
            _buildShortcutRow('Alt + Ziehen', 'Einheit duplizieren / kopieren'),
            _buildShortcutRow('Pfeiltasten ↑ ↓', 'In der Athletenliste navigieren'),
            _buildShortcutRow('Enter', 'Ausgewählten Athleten öffnen'),
            _buildShortcutRow('Esc', 'Suche / Dialoge schließen'),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Verstanden'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcutRow(String keys, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.techGrey,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              keys,
              style: AppTypography.label.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Text(
            description,
            style: AppTypography.body.copyWith(fontSize: 13, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}
