import '../domain/workout_parser.dart';
import '../models/workout_builder_models.dart';
import '../models/workout_template.dart';

/// Statische Startbibliothek mit 20 triathlon-spezifischen Original-Vorlagen.
/// Alle Inhalte sind eigenständig für ORBIT verfasst und frei von Dritt-Rechten.
class TemplateSeedData {
  const TemplateSeedData._();

  static List<WorkoutTemplate> getInitialTemplates(
      {required String currentUserId}) {
    final rawList = <_RawSeed>[
      // 1-5: SCHWIMMEN
      const _RawSeed(
        id: 'seed_swim_01',
        sport: 'SWIM',
        title: 'CSS-Test (400m / 200m)',
        description:
            'Standard-Testprotokoll zur Ermittlung der Critical Swim Speed (CSS).',
        syntax:
            '400m Z1, 400m Z5 [All-Out Zeit stoppen], 200m Z1, 200m Z5 [All-Out Zeit stoppen], 200m Z1',
        tags: ['Test', 'CSS', 'Benchmark'],
      ),
      const _RawSeed(
        id: 'seed_swim_02',
        sport: 'SWIM',
        title: 'CSS-Schwellenserie 8x100m',
        description:
            'Effektives Schwellentraining zur Verbesserung der Renngeschwindigkeit.',
        syntax: '400m Z1, 8x(100m CSS / 20"), 200m Z1',
        tags: ['Schwelle', 'CSS', 'Intervall'],
      ),
      const _RawSeed(
        id: 'seed_swim_03',
        sport: 'SWIM',
        title: 'Ausdauer-Pyramide 2.200m',
        description:
            'Gleichmäßiges aerobes Ausdauertraining im Grundlagentempo.',
        syntax:
            '300m Z1, 100m Z2, 200m Z2, 300m Z2, 400m Z2, 300m Z2, 200m Z2, 100m Z2, 200m Z1',
        tags: ['Grundlage', 'Ausdauer', 'Pyramide'],
      ),
      const _RawSeed(
        id: 'seed_swim_04',
        sport: 'SWIM',
        title: 'Sprint- und Schnelligkeitsausdauer',
        description:
            'Kurze, intensive Serien für Schnelligkeit und Wasserlage.',
        syntax: '400m Z1, 3x(4x(50m Z5 / 15") / 2\'), 200m Z1',
        tags: ['Sprint', 'Schnelligkeit', 'VO2max'],
      ),
      const _RawSeed(
        id: 'seed_swim_05',
        sport: 'SWIM',
        title: 'CSS-Stufenserie Steigerung',
        description:
            'Stufenweises Herantasten von unterschwellig bis überschwellig.',
        syntax:
            '300m Z1, 4x(100m CSS+4" / 15"), 4x(100m CSS / 15"), 4x(100m CSS-3" / 20"), 200m Z1',
        tags: ['Pacing', 'CSS', 'Steigerung'],
      ),

      // 6-11: RAD
      const _RawSeed(
        id: 'seed_bike_01',
        sport: 'BIKE',
        title: 'Sweet Spot 3x10 min',
        description:
            'Effizientes Training zur Erhöhung der Schwellenleistung bei moderater Ermüdung.',
        syntax:
            '15\' Z2, 3x(10\' 88-92%FTP @90rpm / 4\' Z1), 10\' Z1 [Locker ausrollen]',
        tags: ['Sweet Spot', 'FTP', 'Grundlage'],
      ),
      const _RawSeed(
        id: 'seed_bike_02',
        sport: 'BIKE',
        title: 'Schwellenintervalle 4x4 min',
        description:
            'Klassische VO2max- und Schwellenintervalle an der Funktionsleistungsgrenze.',
        syntax: '15\' Z2, 4x(4\' 102-105%FTP @95rpm / 3\' Z1), 10\' Z1',
        tags: ['Schwelle', 'FTP', 'Intervalle'],
      ),
      const _RawSeed(
        id: 'seed_bike_03',
        sport: 'BIKE',
        title: 'Over-Under Laktat-Clearance',
        description:
            'Wechselnde Belastungen knapp unter und knapp über der anaeroben Schwelle.',
        syntax: '15\' Z2, 3x(3x(2\' 95%FTP / 1\' 105%FTP) / 4\' Z1), 10\' Z1',
        tags: ['Over-Under', 'Schwelle', 'Laktattoleranz'],
      ),
      const _RawSeed(
        id: 'seed_bike_04',
        sport: 'BIKE',
        title: 'VO2max 30/30s Mikro-Intervalle',
        description:
            'Effektive Reize für die maximale Sauerstoffaufnahme bei kurzer Pausendauer.',
        syntax: '15\' Z2, 2x(10x(30" 120%FTP / 30" Z1) / 5\' Z1), 10\' Z1',
        tags: ['VO2max', 'Mikro-Intervalle', 'Sprint'],
      ),
      const _RawSeed(
        id: 'seed_bike_05',
        sport: 'BIKE',
        title: 'Grundlagenausfahrt 90 min',
        description:
            'Stetige Grundlagenausdauer zur Optimierung des Fettstoffwechsels.',
        syntax: '15\' Z1, 60\' Z2 @90rpm, 15\' Z1',
        tags: ['Grundlage', 'GA1', 'Ausdauer'],
      ),
      const _RawSeed(
        id: 'seed_bike_06',
        sport: 'BIKE',
        title: 'Kraftausdauer am Berg 4x5 min',
        description:
            'Niedrige Trittfrequenz zur Kräftigung der radspezifischen Beinmuskulatur.',
        syntax: '15\' Z2, 4x(5\' 85%FTP @60rpm / 4\' Z1 @95rpm), 10\' Z1',
        tags: ['Kraftausdauer', 'Berg', 'Kadenz'],
      ),

      // 12-16: LAUFEN
      const _RawSeed(
        id: 'seed_run_01',
        sport: 'RUN',
        title: '1000m Schwellenintervalle',
        description:
            'Gezielte Intervalle im Schwellenbereich zur Verbesserung der 10km- und Halbmarathonzeit.',
        syntax: '2km Z1, 5x(1000m @4:30/km / 90"), 1.5km Z1',
        tags: ['Intervall', 'Pace', '1000m'],
      ),
      const _RawSeed(
        id: 'seed_run_02',
        sport: 'RUN',
        title: 'Fahrtspiel dynamisch 40 min',
        description:
            'Lockerer Wechsel zwischen Schwellenbelastung und aktiver Trabpause.',
        syntax: '10\' Z1, 6x(3\' Z4 / 2\' Z2), 10\' Z1',
        tags: ['Fahrtspiel', 'Fartlek', 'GA2'],
      ),
      const _RawSeed(
        id: 'seed_run_03',
        sport: 'RUN',
        title: 'Bergsprints Anaerob 8x30s',
        description:
            'Kurze, kraftvolle Bergsprints für Vortriebskraft und Laufökonomie.',
        syntax: '15\' Z2, 8x(30" Z6 / 90" frei [Gehpause]), 10\' Z1',
        tags: ['Bergsprint', 'Schnelligkeit', 'Kraft'],
      ),
      const _RawSeed(
        id: 'seed_run_04',
        sport: 'RUN',
        title: 'Tempodauerlauf 30 min zügig',
        description:
            'Durchgehender Schwellenlauf zur Schulung des Tempogefühls.',
        syntax: '15\' Z1, 30\' Z3, 10\' Z1',
        tags: ['Tempodauerlauf', 'Halbmarathon', 'GA2'],
      ),
      const _RawSeed(
        id: 'seed_run_05',
        sport: 'RUN',
        title: 'Langer Grundlagendauerlauf 75 min',
        description:
            'Ruhiger Dauerlauf im Grundlagenbereich mit Gehpausen bei Bedarf.',
        syntax: '10\' Z1, 55\' Z2, 10\' Z1',
        tags: ['Langer Lauf', 'Grundlage', 'GA1'],
      ),

      // 17-18: KOPPEL / BRICK
      const _RawSeed(
        id: 'seed_brick_01',
        sport: 'BIKE',
        title: 'Koppeleinheit Vorbelastung Rad',
        description:
            'Radteil einer Rennsimulation direkt vor dem Wechsel auf die Laufstrecke.',
        syntax: '45\' Z2, 4x(3\' 95%FTP / 2\' Z1), 10\' Z1',
        tags: ['Koppel', 'Brick', 'Wettkampf'],
      ),
      const _RawSeed(
        id: 'seed_brick_02',
        sport: 'RUN',
        title: 'Koppellauf direkt nach Rad',
        description:
            'Anspruchsvoller Koppellauf mit Intervallen auf vorermüdeten Beinen.',
        syntax: '1km Z1, 4x(1000m @4:30/km / 60"), 1km Z1',
        tags: ['Koppel', 'Brick', 'Lauf nach Rad'],
      ),

      // 19-20: KRAFT & STABILITÄT
      const _RawSeed(
        id: 'seed_str_01',
        sport: 'STRENGTH',
        title: 'Rumpfstabilität Triathlon Circuit',
        description:
            'Kerneinheit für Rumpf, Stabilität und gute Wasserlage / Laufhaltung.',
        syntax:
            '5\' Z1 [Mobilisation], 3x(45" frei [Plank] / 15", 45" frei [Side Plank] / 15", 45" frei [Superman] / 30"), 5\' frei [Stretching]',
        tags: ['Stabi', 'Core', 'Kraft'],
      ),
      const _RawSeed(
        id: 'seed_str_02',
        sport: 'STRENGTH',
        title: 'Hüft- und Beinachsen-Prehab',
        description:
            'Präventives Krafttraining für Knie, Hüfte und Abduktoren.',
        syntax:
            '5\' Z1 [Warmup], 3x(45" frei [Ausfallschritte] / 15", 45" frei [Standwaage] / 15", 45" frei [Glute Bridge] / 30"), 5\' frei [Auslockern]',
        tags: ['Prehab', 'Beine', 'Stabilität'],
      ),
    ];

    return rawList.map((seed) {
      final parser = WorkoutParser(sport: seed.sport);
      final parseResult = parser.parse(seed.syntax);
      final structure = parseResult.structure ??
          WorkoutStructure(sport: seed.sport, blocks: const []);

      return WorkoutTemplate(
        id: seed.id,
        ownerId: currentUserId,
        visibility: 'PUBLIC',
        sport: seed.sport,
        title: seed.title,
        description: seed.description,
        structure: structure,
        tags: seed.tags,
        isFavorite: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }).toList();
  }
}

class _RawSeed {
  final String id;
  final String sport;
  final String title;
  final String description;
  final String syntax;
  final List<String> tags;

  const _RawSeed({
    required this.id,
    required this.sport,
    required this.title,
    required this.description,
    required this.syntax,
    required this.tags,
  });
}
