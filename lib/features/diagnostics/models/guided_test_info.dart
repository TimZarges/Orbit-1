/// Beschreibung eines geführten Schwellenwert-Feldtests.
class GuidedTestInfo {
  final String id;
  final String sport;
  final String titleDe;
  final String titleEn;
  final String subtitleDe;
  final int durationMinutes;
  final String protocolDe;
  final String protocolEn;
  final String safetyNoteDe;

  const GuidedTestInfo({
    required this.id,
    required this.sport,
    required this.titleDe,
    required this.titleEn,
    required this.subtitleDe,
    required this.durationMinutes,
    required this.protocolDe,
    required this.protocolEn,
    required this.safetyNoteDe,
  });

  static List<GuidedTestInfo> get standardTests => [
        const GuidedTestInfo(
          id: 'bike_ramp_test',
          sport: 'BIKE',
          titleDe: 'Stufentest (Ramp Test)',
          titleEn: 'Ramp Test (MAP & FTP)',
          subtitleDe:
              'Stufenförmige Ausbelastung zur präzisen Bestimmung von MAP und FTP.',
          durationMinutes: 25,
          protocolDe: '1. 5 min lockeres Einfahren bei 100 Watt\n'
              '2. Start bei 100 Watt, Steigerung um +25 Watt alle 30 Sekunden bis zur Erschöpfung\n'
              '3. 10 min lockeres Ausfahren\n\n'
              'Berechnung: MAP = höchste vollendete Stufe. FTP ≈ 0,75 × beste 1-Minuten-Leistung.',
          protocolEn: '1. 5 min easy warmup at 100 W\n'
              '2. Start at 100 W, increase by +25 W every 30 seconds until failure\n'
              '3. 10 min cooldown\n\n'
              'Calculation: MAP = highest completed step. FTP ≈ 0.75 × best 1-minute power.',
          safetyNoteDe:
              'Nur auf dem Smart-Trainer / Ergometer im ERG-Modus durchführen. Bei Schwindel oder Brustschmerzen sofort abbrechen.',
        ),
        const GuidedTestInfo(
          id: 'bike_ftp_20m',
          sport: 'BIKE',
          titleDe: '20-Minuten-FTP-Test',
          titleEn: '20-Minute FTP Test',
          subtitleDe:
              'Klassischer Feldtest zur Ermittlung der funktionellen Schwellenleistung.',
          durationMinutes: 60,
          protocolDe:
              '1. 20 min lockeres Einfahren mit 3x 1 min schneller Trittfrequenz (>100 rpm)\n'
              '2. 5 min ruhiges Rollen\n'
              '3. 20 min maximale gleichmäßige Ausbelastung (All-Out)\n'
              '4. 10–15 min lockeres Ausfahren\n\n'
              'Berechnung: 95 % deiner durchschnittlichen 20-Minuten-Wattleistung.',
          protocolEn:
              '1. 20 min easy warmup with 3x 1 min high cadence bursts\n'
              '2. 5 min easy spinning\n'
              '3. 20 min all-out steady pacing\n'
              '4. 10–15 min cooldown\n\n'
              'Calculation: 95% of your 20-minute average power.',
          safetyNoteDe:
              'Wichtiger Sicherheitshinweis: Führe diesen Test nur bei voller Gesundheit und auf einer sicheren, kreuzungsfreien Strecke oder auf der Rolle durch. Dies ist kein ärztlicher Belastungstest.',
        ),
        const GuidedTestInfo(
          id: 'run_5min_all_out',
          sport: 'RUN',
          titleDe: '5-Minuten-All-Out-Test',
          titleEn: '5-Minute All-Out Test (vVO2max)',
          subtitleDe:
              'Maximaltest zur Ermittlung von vVO2max und Schwellenpace.',
          durationMinutes: 30,
          protocolDe: '1. 15 min lockeres Einlaufen mit 3 Steigerungsläufen\n'
              '2. 5 min maximale Distanz auf flacher Strecke oder 400m-Bahn (All-Out)\n'
              '3. 10 min lockeres Auslaufen\n\n'
              'Berechnung: Durchschnittsgeschwindigkeit = vVO2max. Schwellenpace ≈ Renntempo über 5 min / 0,85.',
          protocolEn: '1. 15 min warmup with strides\n'
              '2. 5 min maximal distance (all-out)\n'
              '3. 10 min cooldown\n\n'
              'Calculation: Average speed = vVO2max. Threshold pace derived from 5-min pace.',
          safetyNoteDe:
              'Vollständiges Aufwärmen ist zwingend erforderlich, um Muskelzerrungen zu vermeiden.',
        ),
        const GuidedTestInfo(
          id: 'run_lthr_30m',
          sport: 'RUN',
          titleDe: '30-Minuten-Lauftest',
          titleEn: '30-Minute Run Threshold Test',
          subtitleDe:
              'Ermittelt deine Schwellen-Herzfrequenz (LTHR) und Schwellenpace.',
          durationMinutes: 55,
          protocolDe: '1. 15 min lockeres Einlaufen mit 3 Steigerungsläufen\n'
              '2. 30 min maximales, gleichmäßiges Lauftempo (flache Strecke oder Bahn)\n'
              '3. 10 min Auslaufen\n\n'
              'Berechnung: Durchschnittspuls der letzten 20 Minuten = LTHR. Durchschnittstempo über 30 min = Schwellenpace.',
          protocolEn: '1. 15 min easy warmup with 3 strides\n'
              '2. 30 min all-out steady tempo\n'
              '3. 10 min cooldown\n\n'
              'Calculation: Average heart rate of the final 20 minutes = LTHR. Average pace = Threshold Pace.',
          safetyNoteDe:
              'Wichtiger Sicherheitshinweis: Bei Schmerzen, Schwindel oder Vorerkrankungen sofort abbrechen. Nur bei schmerzfreiem Bewegungsapparat durchführen.',
        ),
        const GuidedTestInfo(
          id: 'swim_css_test',
          sport: 'SWIM',
          titleDe: '400m / 200m CSS-Test',
          titleEn: '400m / 200m Critical Swim Speed Test',
          subtitleDe:
              'Der Goldstandard zur Berechnung der anaeroben Schwimmschwelle.',
          durationMinutes: 45,
          protocolDe:
              '1. 400 m lockeres Einschwimmen (inkl. 4x 50 m Steigerung)\n'
              '2. 400 m All-Out auf Zeit (Zeit exakt stoppen)\n'
              '3. 10–15 min lockeres Ausschwimmen / aktive Pause\n'
              '4. 200 m All-Out auf Zeit (Zeit exakt stoppen)\n\n'
              'Formel: CSS = (400 - 200) / (T400 - T200) m/s.',
          protocolEn: '1. 400 m easy warmup\n'
              '2. 400 m time trial all-out\n'
              '3. 10–15 min active recovery\n'
              '4. 200 m time trial all-out\n\n'
              'Formula: CSS = (400 - 200) / (T400 - T200) m/s.',
          safetyNoteDe:
              'Nur unter Aufsicht oder im regulären Schwimmbadbetrieb durchführen.',
        ),
      ];
}
