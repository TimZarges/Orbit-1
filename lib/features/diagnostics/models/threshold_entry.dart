import 'package:cloud_firestore/cloud_firestore.dart';

/// Ein historischer Schwellenwert-Eintrag (`users/{uid}/thresholdHistory/{id}`).
class ThresholdEntry {
  final String id;
  final String effectiveFrom; // Format: YYYY-MM-DD
  final double? ftpW;
  final double? thresholdHrBpm;
  final double? maxHrBpm;
  final double? restingHrBpm;
  final double? runThresholdPaceSecPerKm;
  final double? swimCssSecPer100m;
  final String source; // "MANUAL" | "ESTIMATED" | "IMPORTED"
  final DateTime createdAt;

  const ThresholdEntry({
    required this.id,
    required this.effectiveFrom,
    this.ftpW,
    this.thresholdHrBpm,
    this.maxHrBpm,
    this.restingHrBpm,
    this.runThresholdPaceSecPerKm,
    this.swimCssSecPer100m,
    this.source = 'MANUAL',
    required this.createdAt,
  });

  factory ThresholdEntry.fromDocument(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return ThresholdEntry(
      id: doc.id,
      effectiveFrom: data['effectiveFrom'] as String? ?? '',
      ftpW: (data['ftpW'] as num?)?.toDouble(),
      thresholdHrBpm: (data['thresholdHrBpm'] as num?)?.toDouble(),
      maxHrBpm: (data['maxHrBpm'] as num?)?.toDouble(),
      restingHrBpm: (data['restingHrBpm'] as num?)?.toDouble(),
      runThresholdPaceSecPerKm: (data['runThresholdPaceSecPerKm'] as num?)?.toDouble(),
      swimCssSecPer100m: (data['swimCssSecPer100m'] as num?)?.toDouble(),
      source: data['source'] as String? ?? 'MANUAL',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'effectiveFrom': effectiveFrom,
      if (ftpW != null) 'ftpW': ftpW,
      if (thresholdHrBpm != null) 'thresholdHrBpm': thresholdHrBpm,
      if (maxHrBpm != null) 'maxHrBpm': maxHrBpm,
      if (restingHrBpm != null) 'restingHrBpm': restingHrBpm,
      if (runThresholdPaceSecPerKm != null) 'runThresholdPaceSecPerKm': runThresholdPaceSecPerKm,
      if (swimCssSecPer100m != null) 'swimCssSecPer100m': swimCssSecPer100m,
      'source': source,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ThresholdEntry copyWith({
    String? id,
    String? effectiveFrom,
    double? ftpW,
    double? thresholdHrBpm,
    double? maxHrBpm,
    double? restingHrBpm,
    double? runThresholdPaceSecPerKm,
    double? swimCssSecPer100m,
    String? source,
    DateTime? createdAt,
  }) {
    return ThresholdEntry(
      id: id ?? this.id,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      ftpW: ftpW ?? this.ftpW,
      thresholdHrBpm: thresholdHrBpm ?? this.thresholdHrBpm,
      maxHrBpm: maxHrBpm ?? this.maxHrBpm,
      restingHrBpm: restingHrBpm ?? this.restingHrBpm,
      runThresholdPaceSecPerKm: runThresholdPaceSecPerKm ?? this.runThresholdPaceSecPerKm,
      swimCssSecPer100m: swimCssSecPer100m ?? this.swimCssSecPer100m,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
