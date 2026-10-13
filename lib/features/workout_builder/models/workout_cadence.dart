/// Trittfrequenz- bzw. Schrittfrequenz-Vorgabe (`low` bis `high` rpm / spm).
class WorkoutCadence {
  /// Untere Frequenzgrenze.
  final int low;

  /// Obere Frequenzgrenze.
  final int high;

  const WorkoutCadence({
    required this.low,
    required this.high,
  }) : assert(low > 0, 'low muss > 0 sein'),
       assert(high >= low, 'high muss >= low sein');

  /// Konvertiert in das Schema-JSON.
  Map<String, dynamic> toJson() => {
    'low': low,
    'high': high,
  };

  /// Erstellt eine Frequenz aus Schema-JSON.
  factory WorkoutCadence.fromJson(Map<String, dynamic> json) {
    return WorkoutCadence(
      low: (json['low'] as num).toInt(),
      high: (json['high'] as num).toInt(),
    );
  }

  /// Formatierte Anzeige (z. B. "90-95 rpm" oder "90 rpm").
  String formattedDisplay({String unit = 'rpm'}) {
    if (low == high) return '$low $unit';
    return '$low-$high $unit';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutCadence &&
          runtimeType == other.runtimeType &&
          low == other.low &&
          high == other.high;

  @override
  int get hashCode => low.hashCode ^ high.hashCode;

  @override
  String toString() => 'WorkoutCadence($low-$high)';
}
