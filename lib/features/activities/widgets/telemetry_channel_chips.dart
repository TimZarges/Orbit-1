import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';

/// Die auswählbaren Telemetrie-Kanäle im Analyse-Cockpit.
enum TelemetryChannel {
  power,
  heartRate,
  speed,
  cadence,
  altitude,
  temperature,
}

extension TelemetryChannelX on TelemetryChannel {
  String get label {
    switch (this) {
      case TelemetryChannel.power:
        return 'Leistung';
      case TelemetryChannel.heartRate:
        return 'HF';
      case TelemetryChannel.speed:
        return 'Pace / Tempo';
      case TelemetryChannel.cadence:
        return 'Kadenz';
      case TelemetryChannel.altitude:
        return 'Höhe';
      case TelemetryChannel.temperature:
        return 'Temperatur';
    }
  }

  String get unit {
    switch (this) {
      case TelemetryChannel.power:
        return 'W';
      case TelemetryChannel.heartRate:
        return 'bpm';
      case TelemetryChannel.speed:
        return 'km/h';
      case TelemetryChannel.cadence:
        return 'rpm';
      case TelemetryChannel.altitude:
        return 'm';
      case TelemetryChannel.temperature:
        return '°C';
    }
  }

  /// Exakte Telemetrie-Kanalfarben gemäß docs/DESIGN.md §3.2 (auf #0F172A kontrastreich).
  Color get color {
    switch (this) {
      case TelemetryChannel.power:
        return const Color(0xFFF6C453); // Leistung (Gelb/Gold)
      case TelemetryChannel.heartRate:
        return const Color(0xFFFF6B6B); // Herzfrequenz (Helles Korallenrot)
      case TelemetryChannel.speed:
        return const Color(0xFF22D3EE); // Pace / Speed (Cyan)
      case TelemetryChannel.cadence:
        return const Color(0xFF4ADE80); // Kadenz (Hellgrün)
      case TelemetryChannel.altitude:
        return const Color(0xFF94A3B8); // Höhe (Backdrop Slate)
      case TelemetryChannel.temperature:
        return const Color(0xFFFB923C); // Temperatur (Orange)
    }
  }

  IconData get icon {
    switch (this) {
      case TelemetryChannel.power:
        return Icons.bolt;
      case TelemetryChannel.heartRate:
        return Icons.favorite;
      case TelemetryChannel.speed:
        return Icons.speed;
      case TelemetryChannel.cadence:
        return Icons.sync;
      case TelemetryChannel.altitude:
        return Icons.landscape;
      case TelemetryChannel.temperature:
        return Icons.thermostat;
    }
  }
}

/// Horizontale Leiste mit Kanal-Chips zum Ein- und Ausblenden einzelner Telemetrielinien.
class TelemetryChannelChips extends StatelessWidget {
  final Set<TelemetryChannel> activeChannels;
  final Set<TelemetryChannel> availableChannels;
  final ValueChanged<TelemetryChannel> onToggle;

  const TelemetryChannelChips({
    super.key,
    required this.activeChannels,
    required this.availableChannels,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: TelemetryChannel.values.where(availableChannels.contains).map((channel) {
          final isActive = activeChannels.contains(channel);
          final color = channel.color;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Semantics(
              button: true,
              selected: isActive,
              label: 'Kanal ${channel.label} ${isActive ? "ausblenden" : "einblenden"}',
              child: InkWell(
                onTap: () => onToggle(channel),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? color.withValues(alpha: 0.2) : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive ? color : const Color(0xFF334155),
                      width: isActive ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        channel.icon,
                        size: 14,
                        color: isActive ? color : Colors.grey.shade400,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        channel.label,
                        style: AppTypography.label.copyWith(
                          color: isActive ? Colors.white : Colors.grey.shade400,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
