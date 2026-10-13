/// Basisklasse für Intensitätsvorgaben eines Schritts.
sealed class WorkoutIntensity {
  const WorkoutIntensity();

  /// Bezeichner des Intensitätstyps im JSON-Schema.
  String get kind;

  /// Formatierte Kurzdarstellung (z. B. "Z2", "90-95% FTP", "@4:30/km").
  String get formattedDisplay;

  /// Prüft, ob diese Intensität für die gegebene Sportart zulässig ist.
  bool isAllowedForSport(String sport) {
    final s = sport.toUpperCase();
    switch (this) {
      case ZoneIntensity():
        return true; // Alle Sportarten unterstützen Zonen
      case FreeIntensity():
        return true; // Freie Intensität ist immer erlaubt
      case PctFtpIntensity():
        return s == 'BIKE';
      case PctLthrIntensity():
        return s == 'BIKE' || s == 'RUN';
      case PaceIntensity():
        return s == 'RUN';
      case SwimPaceIntensity():
      case CssOffsetIntensity():
        return s == 'SWIM';
    }
  }

  /// Konvertiert in das Schema-JSON.
  Map<String, dynamic> toJson();

  /// Erstellt eine [WorkoutIntensity] aus dem Schema-JSON.
  factory WorkoutIntensity.fromJson(Map<String, dynamic> json) {
    final kind = json['kind'] as String?;
    switch (kind) {
      case 'ZONE':
        return ZoneIntensity(
          low: (json['low'] as num).toInt(),
          high: (json['high'] as num).toInt(),
        );
      case 'PCT_FTP':
        return PctFtpIntensity(
          low: (json['low'] as num).toInt(),
          high: (json['high'] as num).toInt(),
        );
      case 'PCT_LTHR':
        return PctLthrIntensity(
          low: (json['low'] as num).toInt(),
          high: (json['high'] as num).toInt(),
        );
      case 'PACE':
        return PaceIntensity(
          secPerKm: (json['secPerKm'] as num).toInt(),
        );
      case 'SWIM_PACE':
        return SwimPaceIntensity(
          secPer100m: (json['secPer100m'] as num).toInt(),
        );
      case 'CSS_OFFSET':
        return CssOffsetIntensity(
          offsetSecPer100m: (json['offsetSecPer100m'] as num).toInt(),
        );
      case 'FREE':
        return const FreeIntensity();
      default:
        throw FormatException('Unbekannter Intensitätstyp (kind): $kind ($json)');
    }
  }
}

/// Zonen-Intensität (z. B. Z1 bis Z7).
class ZoneIntensity extends WorkoutIntensity {
  final int low;
  final int high;

  const ZoneIntensity({
    required this.low,
    required this.high,
  }) : assert(low >= 1 && low <= 7, 'low Zone muss zwischen 1 und 7 liegen'),
       assert(high >= 1 && high <= 7, 'high Zone muss zwischen 1 und 7 liegen'),
       assert(low <= high, 'low Zone muss <= high Zone sein');

  /// Convenience-Konstruktor für Ein-Zonen-Vorgabe (z. B. nur Z2).
  const ZoneIntensity.single(int zone) : this(low: zone, high: zone);

  @override
  String get kind => 'ZONE';

  @override
  String get formattedDisplay => low == high ? 'Z$low' : 'Z$low-Z$high';

  @override
  Map<String, dynamic> toJson() => {
    'kind': kind,
    'low': low,
    'high': high,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ZoneIntensity &&
          runtimeType == other.runtimeType &&
          low == other.low &&
          high == other.high;

  @override
  int get hashCode => low.hashCode ^ high.hashCode;

  @override
  String toString() => 'ZoneIntensity($formattedDisplay)';
}

/// Prozentuale FTP-Intensität (für Radtraining).
class PctFtpIntensity extends WorkoutIntensity {
  final int low;
  final int high;

  const PctFtpIntensity({
    required this.low,
    required this.high,
  }) : assert(low > 0, 'low %FTP muss > 0 sein'),
       assert(high >= low, 'high %FTP muss >= low sein');

  const PctFtpIntensity.single(int pct) : this(low: pct, high: pct);

  @override
  String get kind => 'PCT_FTP';

  @override
  String get formattedDisplay => low == high ? '$low% FTP' : '$low-$high% FTP';

  @override
  Map<String, dynamic> toJson() => {
    'kind': kind,
    'low': low,
    'high': high,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PctFtpIntensity &&
          runtimeType == other.runtimeType &&
          low == other.low &&
          high == other.high;

  @override
  int get hashCode => low.hashCode ^ high.hashCode;

  @override
  String toString() => 'PctFtpIntensity($formattedDisplay)';
}

/// Prozentuale LTHR-Intensität (Schwellen-Herzfrequenz für Rad oder Lauf).
class PctLthrIntensity extends WorkoutIntensity {
  final int low;
  final int high;

  const PctLthrIntensity({
    required this.low,
    required this.high,
  }) : assert(low > 0, 'low %LTHR muss > 0 sein'),
       assert(high >= low, 'high %LTHR muss >= low sein');

  const PctLthrIntensity.single(int pct) : this(low: pct, high: pct);

  @override
  String get kind => 'PCT_LTHR';

  @override
  String get formattedDisplay => low == high ? '$low% LTHR' : '$low-$high% LTHR';

  @override
  Map<String, dynamic> toJson() => {
    'kind': kind,
    'low': low,
    'high': high,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PctLthrIntensity &&
          runtimeType == other.runtimeType &&
          low == other.low &&
          high == other.high;

  @override
  int get hashCode => low.hashCode ^ high.hashCode;

  @override
  String toString() => 'PctLthrIntensity($formattedDisplay)';
}

/// Pace-Intensität beim Laufen (Sekunden pro Kilometer).
class PaceIntensity extends WorkoutIntensity {
  final int secPerKm;

  const PaceIntensity({
    required this.secPerKm,
  }) : assert(secPerKm > 0, 'secPerKm muss > 0 sein');

  @override
  String get kind => 'PACE';

  @override
  String get formattedDisplay {
    final min = secPerKm ~/ 60;
    final sec = secPerKm % 60;
    return '@$min:${sec.toString().padLeft(2, '0')}/km';
  }

  @override
  Map<String, dynamic> toJson() => {
    'kind': kind,
    'secPerKm': secPerKm,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaceIntensity &&
          runtimeType == other.runtimeType &&
          secPerKm == other.secPerKm;

  @override
  int get hashCode => secPerKm.hashCode;

  @override
  String toString() => 'PaceIntensity($formattedDisplay)';
}

/// Absolute Schwimm-Pace (Sekunden pro 100 Meter).
class SwimPaceIntensity extends WorkoutIntensity {
  final int secPer100m;

  const SwimPaceIntensity({
    required this.secPer100m,
  }) : assert(secPer100m > 0, 'secPer100m muss > 0 sein');

  @override
  String get kind => 'SWIM_PACE';

  @override
  String get formattedDisplay {
    final min = secPer100m ~/ 60;
    final sec = secPer100m % 60;
    return '@$min:${sec.toString().padLeft(2, '0')}/100m';
  }

  @override
  Map<String, dynamic> toJson() => {
    'kind': kind,
    'secPer100m': secPer100m,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SwimPaceIntensity &&
          runtimeType == other.runtimeType &&
          secPer100m == other.secPer100m;

  @override
  int get hashCode => secPer100m.hashCode;

  @override
  String toString() => 'SwimPaceIntensity($formattedDisplay)';
}

/// Schwimm-Pace relativ zur CSS (Critical Swim Speed in Sekunden/100m).
class CssOffsetIntensity extends WorkoutIntensity {
  /// Offset in Sekunden pro 100m (0 = genau CSS, z. B. +5" = 5s langsamer als CSS, -3" = 3s schneller).
  final int offsetSecPer100m;

  const CssOffsetIntensity({
    required this.offsetSecPer100m,
  });

  @override
  String get kind => 'CSS_OFFSET';

  @override
  String get formattedDisplay {
    if (offsetSecPer100m == 0) return 'CSS';
    if (offsetSecPer100m > 0) return 'CSS+$offsetSecPer100m"';
    return 'CSS$offsetSecPer100m"';
  }

  @override
  Map<String, dynamic> toJson() => {
    'kind': kind,
    'offsetSecPer100m': offsetSecPer100m,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CssOffsetIntensity &&
          runtimeType == other.runtimeType &&
          offsetSecPer100m == other.offsetSecPer100m;

  @override
  int get hashCode => offsetSecPer100m.hashCode;

  @override
  String toString() => 'CssOffsetIntensity($formattedDisplay)';
}

/// Freie Intensität / keine Vorgabe (z. B. lockere Pause oder Krafttraining).
class FreeIntensity extends WorkoutIntensity {
  const FreeIntensity();

  @override
  String get kind => 'FREE';

  @override
  String get formattedDisplay => 'Frei';

  @override
  Map<String, dynamic> toJson() => {
    'kind': kind,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FreeIntensity && runtimeType == other.runtimeType;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'FreeIntensity()';
}
