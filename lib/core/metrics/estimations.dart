/// Schätzhilfen für Schwellenwerte.
/// ACHTUNG: Dies sind nur grobe Schätzungen und sollten vom Nutzer nur als Vorschlag genutzt werden.
/// Eine automatische Übernahme findet nie statt.
class Estimations {
  
  /// Grobe Schätzung der maximalen Herzfrequenz.
  /// Formel: 208 - (0.7 * Alter) (Tanaka et al. 2001)
  /// Quelle: https://pubmed.ncbi.nlm.nih.gov/11153730/
  static int estimateMaxHr(int age) {
    if (age <= 0 || age > 120) return 190; // Fallback
    return (208 - (0.7 * age)).round();
  }

  /// Grobe Schätzung der FTP aus einem 20-Minuten-Test.
  /// Formel: 95% der durchschnittlichen Leistung über 20 Minuten.
  /// Quelle: Coggan & Allen, Training and Racing with a Power Meter.
  static int estimateFtpFrom20MinTest(double avgPower20Min) {
    if (avgPower20Min <= 0) return 0;
    return (avgPower20Min * 0.95).round();
  }

  /// Schätzung der Lauf-Schwellenpace aus einem 30-Minuten-All-Out-Test.
  /// Formel: 100% der Durchschnittspace (bzw. Geschwindigkeit) über 30 Minuten.
  /// Geschwindigkeit in m/s.
  /// Quelle: Joe Friel, The Triathlete's Training Bible.
  static double estimateRunThresholdPaceFrom30MinTest(double avgSpeed30Min) {
    return avgSpeed30Min;
  }

  /// Schätzung der Critical Swim Speed (CSS) aus einem 400m und 200m Test.
  /// Formel: CSS = (400 - 200) / (Time_400 - Time_200) in m/s
  /// time400m und time200m in Sekunden.
  /// Quelle: Ginn (1993), basierend auf Wakayoshi et al. (1992).
  static double estimateCssFrom400And200Test(double time400m, double time200m) {
    if (time400m <= time200m) return 0; // Ungültig
    return 200.0 / (time400m - time200m);
  }
}
