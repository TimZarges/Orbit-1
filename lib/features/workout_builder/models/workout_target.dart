/// Zielvorgabe für einen Trainingsschritt: Entweder Dauer in Sekunden oder Distanz in Metern.
class WorkoutTarget {
  /// Dauer in Sekunden (SI-Einheit).
  final int? durationSec;

  /// Distanz in Metern (SI-Einheit).
  final int? distanceM;

  const WorkoutTarget._({this.durationSec, this.distanceM});

  /// Erstellt ein Ziel basierend auf Dauer in Sekunden.
  const factory WorkoutTarget.duration(int durationSec) = _WorkoutTargetDuration;

  /// Erstellt ein Ziel basierend auf Distanz in Metern.
  const factory WorkoutTarget.distance(int distanceM) = _WorkoutTargetDistance;

  /// Gibt an, ob das Ziel zeitbasiert ist.
  bool get isDuration => durationSec != null;

  /// Gibt an, ob das Ziel distanzbasiert ist.
  bool get isDistance => distanceM != null;

  /// Konvertiert in das Schema-JSON.
  Map<String, dynamic> toJson() {
    if (durationSec != null) {
      return {'durationSec': durationSec};
    } else if (distanceM != null) {
      return {'distanceM': distanceM};
    }
    throw StateError('WorkoutTarget besitzt weder Dauer noch Distanz.');
  }

  /// Erstellt ein [WorkoutTarget] aus dem Schema-JSON.
  factory WorkoutTarget.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('durationSec')) {
      final val = json['durationSec'];
      if (val is num) {
        return WorkoutTarget.duration(val.toInt());
      }
    }
    if (json.containsKey('distanceM')) {
      final val = json['distanceM'];
      if (val is num) {
        return WorkoutTarget.distance(val.toInt());
      }
    }
    throw FormatException(
      'Ungültiges WorkoutTarget: weder durationSec noch distanceM vorhanden ($json)',
    );
  }

  /// Formatierte Anzeige des Ziels (z. B. "10:00 min" oder "400 m").
  String get formattedDisplay {
    if (durationSec != null) {
      final sec = durationSec!;
      if (sec < 60) {
        return '$sec"';
      } else if (sec % 60 == 0) {
        final min = sec ~/ 60;
        if (min >= 60) {
          final h = min ~/ 60;
          final m = min % 60;
          return m == 0 ? '${h}h' : '${h}h ${m}min';
        }
        return '$min min';
      } else {
        final min = sec ~/ 60;
        final remainderSec = sec % 60;
        return '$min:${remainderSec.toString().padLeft(2, '0')} min';
      }
    } else if (distanceM != null) {
      final m = distanceM!;
      if (m >= 1000 && m % 100 == 0) {
        final km = m / 1000.0;
        return km % 1 == 0 ? '${km.toInt()} km' : '${km.toStringAsFixed(1)} km';
      }
      return '$m m';
    }
    return '--';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutTarget &&
          runtimeType == other.runtimeType &&
          durationSec == other.durationSec &&
          distanceM == other.distanceM;

  @override
  int get hashCode => durationSec.hashCode ^ distanceM.hashCode;

  @override
  String toString() =>
      isDuration ? 'WorkoutTarget.duration($durationSec s)' : 'WorkoutTarget.distance($distanceM m)';
}

class _WorkoutTargetDuration extends WorkoutTarget {
  const _WorkoutTargetDuration(int durationSec)
      : assert(durationSec > 0, 'Dauer muss größer als 0 sein'),
        super._(durationSec: durationSec);
}

class _WorkoutTargetDistance extends WorkoutTarget {
  const _WorkoutTargetDistance(int distanceM)
      : assert(distanceM > 0, 'Distanz muss größer als 0 sein'),
        super._(distanceM: distanceM);
}
