/// Repräsentiert einen Syntax- oder Validierungsfehler beim Parsen eines Workouts.
class WorkoutParseError {
  /// Startindex im Quelltext (0-basiert).
  final int startIndex;

  /// Endindex im Quelltext (exklusiv).
  final int endIndex;

  /// Maschinenlesbarer Fehlercode (z. B. 'INVALID_ZONE', 'UNCLOSED_PAREN').
  final String code;

  /// Lokalisierte Fehlermeldung auf Deutsch.
  final String messageDe;

  /// Lokalisierte Fehlermeldung auf Englisch.
  final String messageEn;

  const WorkoutParseError({
    required this.startIndex,
    required this.endIndex,
    required this.code,
    required this.messageDe,
    required this.messageEn,
  });

  /// Gibt die passende Nachricht für den Sprachcode zurück.
  String message([String languageCode = 'de']) =>
      languageCode == 'de' ? messageDe : messageEn;

  @override
  String toString() =>
      'WorkoutParseError($code [$startIndex..$endIndex]: $messageDe)';
}
