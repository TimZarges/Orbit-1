import 'package:flutter/material.dart';

/// Basis-Klasse für eine Trainingszone
class TrainingZone {
  final int id;
  final String name;
  final String shortName;
  final double minPercent;
  final double? maxPercent;
  final Color color;

  const TrainingZone({
    required this.id,
    required this.name,
    required this.shortName,
    required this.minPercent,
    this.maxPercent,
    required this.color,
  });

  bool contains(double percent) {
    if (maxPercent == null) return percent >= minPercent;
    return percent >= minPercent && percent < maxPercent!;
  }
}

/// 7-Zonen-Modell für Leistung (Power) basierend auf FTP (Coggan).
/// Quelle: Coggan Power Zones.
const List<TrainingZone> powerZones = [
  TrainingZone(id: 1, name: 'Active Recovery', shortName: 'Z1', minPercent: 0, maxPercent: 0.55, color: Colors.grey),
  TrainingZone(id: 2, name: 'Endurance', shortName: 'Z2', minPercent: 0.55, maxPercent: 0.75, color: Colors.blue),
  TrainingZone(id: 3, name: 'Tempo', shortName: 'Z3', minPercent: 0.75, maxPercent: 0.90, color: Colors.green),
  TrainingZone(id: 4, name: 'Lactate Threshold', shortName: 'Z4', minPercent: 0.90, maxPercent: 1.05, color: Colors.yellow),
  TrainingZone(id: 5, name: 'VO2 Max', shortName: 'Z5', minPercent: 1.05, maxPercent: 1.20, color: Colors.orange),
  TrainingZone(id: 6, name: 'Anaerobic Capacity', shortName: 'Z6', minPercent: 1.20, maxPercent: 1.50, color: Colors.red),
  TrainingZone(id: 7, name: 'Neuromuscular Power', shortName: 'Z7', minPercent: 1.50, maxPercent: null, color: Colors.deepPurple),
];

/// 5-Zonen-Modell für Herzfrequenz basierend auf Schwellen-HF (LTHR).
/// Quelle: Friel Heart Rate Zones.
const List<TrainingZone> heartRateZones = [
  TrainingZone(id: 1, name: 'Recovery', shortName: 'Z1', minPercent: 0, maxPercent: 0.81, color: Colors.grey),
  TrainingZone(id: 2, name: 'Aerobic', shortName: 'Z2', minPercent: 0.81, maxPercent: 0.89, color: Colors.blue),
  TrainingZone(id: 3, name: 'Tempo', shortName: 'Z3', minPercent: 0.89, maxPercent: 0.93, color: Colors.green),
  TrainingZone(id: 4, name: 'SubThreshold', shortName: 'Z4', minPercent: 0.93, maxPercent: 0.99, color: Colors.yellow),
  TrainingZone(id: 5, name: 'SuperThreshold', shortName: 'Z5', minPercent: 0.99, maxPercent: null, color: Colors.red),
];

/// Pace-Zonen für Laufen basierend auf Schwellen-Pace (Threshold Pace in m/s).
/// Quelle: Joe Friel Run Zones. (Pace verhält sich invers zur Geschwindigkeit, aber wir rechnen in Geschwindigkeit m/s für %-Vergleiche).
const List<TrainingZone> runPaceZones = [
  TrainingZone(id: 1, name: 'Recovery', shortName: 'Z1', minPercent: 0, maxPercent: 0.85, color: Colors.grey),
  TrainingZone(id: 2, name: 'Aerobic', shortName: 'Z2', minPercent: 0.85, maxPercent: 0.90, color: Colors.blue),
  TrainingZone(id: 3, name: 'Tempo', shortName: 'Z3', minPercent: 0.90, maxPercent: 0.95, color: Colors.green),
  TrainingZone(id: 4, name: 'Threshold', shortName: 'Z4', minPercent: 0.95, maxPercent: 1.05, color: Colors.yellow),
  TrainingZone(id: 5, name: 'Anaerobic', shortName: 'Z5', minPercent: 1.05, maxPercent: null, color: Colors.red),
];

/// Schwimm-Zonen basierend auf Critical Swim Speed (CSS in m/s).
const List<TrainingZone> swimPaceZones = [
  TrainingZone(id: 1, name: 'Recovery', shortName: 'Z1', minPercent: 0, maxPercent: 0.80, color: Colors.grey),
  TrainingZone(id: 2, name: 'Endurance', shortName: 'Z2', minPercent: 0.80, maxPercent: 0.95, color: Colors.blue),
  TrainingZone(id: 3, name: 'CSS/Threshold', shortName: 'Z3', minPercent: 0.95, maxPercent: 1.05, color: Colors.green),
  TrainingZone(id: 4, name: 'Anaerobic', shortName: 'Z4', minPercent: 1.05, maxPercent: null, color: Colors.red),
];
