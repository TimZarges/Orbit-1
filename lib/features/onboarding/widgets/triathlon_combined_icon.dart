import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';

/// Kombiniertes Triathlon-Piktogramm (Phase 36.4).
///
/// Zeigt die drei Teildisziplinen Schwimmen, Radfahren und Laufen
/// in einem harmonischen, modernen Multi-Sport-Icon für maximalen Wiedererkennungswert.
class TriathlonCombinedIcon extends StatelessWidget {
  /// Größe der einzelnen Icons.
  final double size;

  /// Optionale Akzentfarbe für die Piktogramme.
  final Color color;

  const TriathlonCombinedIcon({
    super.key,
    this.size = 14,
    this.color = AppColors.volt,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.pool, size: size, color: color),
          const SizedBox(width: 2),
          Icon(Icons.directions_bike, size: size, color: color),
          const SizedBox(width: 2),
          Icon(Icons.directions_run, size: size, color: color),
        ],
      ),
    );
  }
}
