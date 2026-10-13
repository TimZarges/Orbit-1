/// Rollen von Blöcken und Schritten in einer strukturierten Trainingseinheit.
enum WorkoutRole {
  /// Aufwärmen
  warmup,

  /// Hauptbelastung / Intervall
  work,

  /// Pause / Erholung
  rest,

  /// Abkühlen / Ausfahren / Auslaufen
  cooldown,

  /// Durchgehende Hauptphase (z. B. Grundlagenteil)
  main;

  /// Konvertiert die Rolle in den Schema-String (z. B. 'WARMUP').
  String toSchemaString() {
    switch (this) {
      case WorkoutRole.warmup:
        return 'WARMUP';
      case WorkoutRole.work:
        return 'WORK';
      case WorkoutRole.rest:
        return 'REST';
      case WorkoutRole.cooldown:
        return 'COOLDOWN';
      case WorkoutRole.main:
        return 'MAIN';
    }
  }

  /// Erstellt eine Rolle aus dem Schema-String.
  static WorkoutRole fromSchemaString(String raw) {
    switch (raw.toUpperCase()) {
      case 'WARMUP':
      case 'WU':
        return WorkoutRole.warmup;
      case 'WORK':
        return WorkoutRole.work;
      case 'REST':
      case 'PAUSE':
        return WorkoutRole.rest;
      case 'COOLDOWN':
      case 'CD':
        return WorkoutRole.cooldown;
      case 'MAIN':
        return WorkoutRole.main;
      default:
        throw ArgumentError('Unbekannte WorkoutRole: $raw');
    }
  }

  /// Lokalisierter Standardname (Deutsch).
  String get displayNameDe {
    switch (this) {
      case WorkoutRole.warmup:
        return 'Aufwärmen';
      case WorkoutRole.work:
        return 'Belastung';
      case WorkoutRole.rest:
        return 'Erholung';
      case WorkoutRole.cooldown:
        return 'Abkühlen';
      case WorkoutRole.main:
        return 'Hauptteil';
    }
  }
}
