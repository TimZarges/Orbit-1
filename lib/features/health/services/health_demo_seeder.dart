import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/daily_metrics.dart';

/// Hilfsklasse zum Erzeugen und Seeden realistischer Demo-Gesundheitsdaten über 30 Tage.
class HealthDemoSeeder {
  /// Generiert eine Liste von 30 konsistenten [DailyMetrics] mit realistischen physiologischen Phasen
  /// (Erholung, Trainingsblock mit leichter Ermüdung, Ausreißer und Regeneration).
  static List<DailyMetrics> generateDemoHistory({DateTime? referenceDate}) {
    final now = referenceDate ?? DateTime.now();
    final List<DailyMetrics> list = [];

    // 30 Tage rückwärts generieren
    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

      int rhr;
      int hrv;
      int sleepSec;
      int sleepScore;
      int stress;
      int steps;

      if (i >= 22) {
        // Phase 1: Ruhiger Grundlagenblock (ausgeruht)
        rhr = 48 + (i % 3);
        hrv = 72 - (i % 4);
        sleepSec = 27000 + (i % 3) * 600; // ~7.5h - 8h
        sleepScore = 84 + (i % 5);
        stress = 20 + (i % 6);
        steps = 8000 + (i % 4) * 800;
      } else if (i >= 14) {
        // Phase 2: Intensiver Trainingsblock (Akkumulierte Belastung & leichte Ermüdung)
        rhr = 53 + (i % 3); // Erhöhter Puls (+4-5 bpm)
        hrv = 57 - (i % 5); // Reduzierte HRV
        sleepSec = 24600 + (i % 4) * 500; // ~6.8h - 7.2h
        sleepScore = 71 + (i % 6);
        stress = 34 + (i % 8);
        steps = 11500 + (i % 5) * 1000;
      } else if (i >= 9) {
        // Phase 3: Entlastungswoche / Regeneration
        rhr = 47 + (i % 2);
        hrv = 76 + (i % 3);
        sleepSec = 28800 + (i % 2) * 600; // 8h+
        sleepScore = 89 + (i % 4);
        stress = 17 + (i % 4);
        steps = 6500 + (i % 3) * 500;
      } else if (i == 3) {
        // Phase 4 Ausreißer (z. B. schlechter Schlaf / harte Einheit)
        rhr = 55;
        hrv = 51;
        sleepSec = 21600; // 6h
        sleepScore = 62;
        stress = 42;
        steps = 14000;
      } else {
        // Aktuelle Tage (Stabil im Normalbereich)
        rhr = 49 + (i % 2);
        hrv = 70 + (i % 4);
        sleepSec = 27600 + (i % 3) * 400; // ~7.7h
        sleepScore = 83 + (i % 4);
        stress = 22 + (i % 5);
        steps = 9200 + (i % 4) * 700;
      }

      list.add(DailyMetrics(
        localDate: dateStr,
        restingHrBpm: rhr,
        hrvMs: hrv,
        sleepSeconds: sleepSec,
        sleepScore: sleepScore,
        stress: stress,
        steps: steps,
        bodyBattery: 75 + (i % 15),
        source: 'DEMO',
        updatedAt: date,
      ));
    }

    return list;
  }

  /// Schreibt die generierten Demo-Tageswerte für den Athleten in Firestore unter `users/{uid}/dailyMetrics/`.
  static Future<void> seedDemoMetricsForAthlete(String athleteId) async {
    final db = FirebaseFirestore.instance;
    final metrics = generateDemoHistory();
    final batch = db.batch();

    for (final m in metrics) {
      final docRef = db.collection('users').doc(athleteId).collection('dailyMetrics').doc(m.localDate);
      batch.set(docRef, m.toMap(), SetOptions(merge: true));
    }

    await batch.commit();
  }
}
