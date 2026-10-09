class LoadPreview {
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
