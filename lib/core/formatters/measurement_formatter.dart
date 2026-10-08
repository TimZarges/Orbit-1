import 'package:orbit/features/settings/models/app_settings.dart';

/// Zentrale Schicht zur Formatierung von Einheiten basierend auf dem
/// Messsystem (Metrisch vs. Imperial).
class MeasurementFormatter {
  final MeasurementSystem system;

  const MeasurementFormatter(this.system);

  /// Distanz (Meter zu km oder Meilen)
  String formatDistance(double meters, {int decimals = 1}) {
    if (system == MeasurementSystem.imperial) {
      final miles = meters / 1609.34;
      return '${miles.toStringAsFixed(decimals)} mi';
    } else {
      final km = meters / 1000;
      return '${km.toStringAsFixed(decimals)} km';
    }
  }

  /// Geschwindigkeit/Pace (m/s zu min/km oder min/mi)
  String formatPace(double speedMetersPerSecond) {
    if (speedMetersPerSecond <= 0) return '-:--';

    double distanceMultiplier =
        system == MeasurementSystem.imperial ? 1609.34 : 1000.0;

    // Sekunden pro km/mi
    double secondsPerUnit = distanceMultiplier / speedMetersPerSecond;

    int minutes = (secondsPerUnit / 60).floor();
    int seconds = (secondsPerUnit % 60).round();

    if (seconds == 60) {
      minutes++;
      seconds = 0;
    }

    final unit = system == MeasurementSystem.imperial ? 'mi' : 'km';
    return '$minutes:${seconds.toString().padLeft(2, '0')} min/$unit';
  }

  /// Schwimm-Pace (m/s zu min/100m oder min/100yd)
  String formatSwimPace(double speedMetersPerSecond) {
    if (speedMetersPerSecond <= 0) return '-:--';

    // Für imperial (yd) -> 100yd = 91.44m
    double distance = system == MeasurementSystem.imperial ? 91.44 : 100.0;

    double secondsPerUnit = distance / speedMetersPerSecond;

    int minutes = (secondsPerUnit / 60).floor();
    int seconds = (secondsPerUnit % 60).round();

    if (seconds == 60) {
      minutes++;
      seconds = 0;
    }

    final unit = system == MeasurementSystem.imperial ? '100yd' : '100m';
    return '$minutes:${seconds.toString().padLeft(2, '0')} /$unit';
  }

  /// Gewicht (kg zu lbs)
  String formatWeight(double kg, {int decimals = 1}) {
    if (system == MeasurementSystem.imperial) {
      final lbs = kg * 2.20462;
      return '${lbs.toStringAsFixed(decimals)} lbs';
    } else {
      return '${kg.toStringAsFixed(decimals)} kg';
    }
  }

  /// Höhe (Meter zu feet)
  String formatElevation(double meters, {int decimals = 0}) {
    if (system == MeasurementSystem.imperial) {
      final feet = meters * 3.28084;
      return '${feet.toStringAsFixed(decimals)} ft';
    } else {
      return '${meters.toStringAsFixed(decimals)} m';
    }
  }
}
