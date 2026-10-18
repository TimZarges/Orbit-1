/// Mathematische Hilfsklasse zur schnellen Vorschau-Berechnung von Trainingsbelastungen.
///
/// Basiert auf der sportwissenschaftlichen Standardformel für Trainingsbelastung:
/// $$TSS = \frac{t \cdot NP \cdot IF}{FTP \cdot 3600} \cdot 100$$
class LoadPreview {
  /// Berechnet die Trainingsbelastung (ORBIT Load / TSS) anhand von Dauer, Normalized Power und FTP.
  ///
  /// - [durationSeconds]: Dauer der Einheit in Sekunden.
  /// - [normalizedPower]: Berechnete oder geschätzte Normalized Power in Watt.
  /// - [ftp]: Aktuelle funktionelle Schwellenleistung (FTP) des Athleten in Watt.
  ///
  /// Liefert 0.0 zurück, falls FTP oder Dauer kleiner oder gleich 0 sind.
  static double calculateTss({
    required double durationSeconds,
    required double normalizedPower,
    required double ftp,
  }) {
    if (ftp <= 0 || durationSeconds <= 0) return 0.0;
    final iff = normalizedPower / ftp;
    return (durationSeconds * normalizedPower * iff) / (ftp * 3600) * 100;
  }
}
