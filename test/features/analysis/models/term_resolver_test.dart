import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/core/metrics/term_resolver.dart';

void main() {
  group('TermResolver Tests (§7a DESIGN.md)', () {
    test('Ebene Beginner nutzt alltagstaugliche Begriffe', () {
      expect(TermResolver.resolve(MetricTerm.ctl, ExperienceLevel.beginner),
          equals('Fitness'));
      expect(TermResolver.resolve(MetricTerm.atl, ExperienceLevel.beginner),
          equals('Ermüdung'));
      expect(TermResolver.resolve(MetricTerm.tsb, ExperienceLevel.beginner),
          equals('Frische'));
      expect(TermResolver.resolve(MetricTerm.tss, ExperienceLevel.beginner),
          equals('Belastung'));
      expect(TermResolver.resolve(MetricTerm.np, ExperienceLevel.beginner),
          equals('Normalisierte Leistung'));
      expect(TermResolver.resolve(MetricTerm.ifactor, ExperienceLevel.beginner),
          equals('Intensität'));
    });

    test('Ebene Advanced verbindet Begriff mit Fachkürzel bzw. ORBIT Begriff',
        () {
      expect(TermResolver.resolve(MetricTerm.ctl, ExperienceLevel.advanced),
          equals('Fitness (CTL)'));
      expect(TermResolver.resolve(MetricTerm.atl, ExperienceLevel.advanced),
          equals('Ermüdung (ATL)'));
      expect(TermResolver.resolve(MetricTerm.tsb, ExperienceLevel.advanced),
          equals('Frische (TSB)'));
      expect(TermResolver.resolve(MetricTerm.tss, ExperienceLevel.advanced),
          equals('ORBIT Belastung'));
      expect(TermResolver.resolve(MetricTerm.np, ExperienceLevel.advanced),
          equals('Normalisierte Leistung'));
      expect(TermResolver.resolve(MetricTerm.ifactor, ExperienceLevel.advanced),
          equals('Intensitäts-Faktor'));
    });

    test('Ebene Expert nutzt ORBIT Begrifflichkeiten', () {
      expect(TermResolver.resolve(MetricTerm.ctl, ExperienceLevel.expert),
          equals('CTL'));
      expect(TermResolver.resolve(MetricTerm.atl, ExperienceLevel.expert),
          equals('ATL'));
      expect(TermResolver.resolve(MetricTerm.tsb, ExperienceLevel.expert),
          equals('TSB'));
      expect(TermResolver.resolve(MetricTerm.tss, ExperienceLevel.expert),
          equals('ORBIT Load'));
      expect(TermResolver.resolve(MetricTerm.np, ExperienceLevel.expert),
          equals('Iso-Power'));
      expect(TermResolver.resolve(MetricTerm.ifactor, ExperienceLevel.expert),
          equals('Intensitäts-Faktor'));
    });

    test('Englische Übersetzung matcht Design-System', () {
      expect(TermResolver.resolveEn(MetricTerm.ctl, ExperienceLevel.beginner),
          equals('Fitness'));
      expect(TermResolver.resolveEn(MetricTerm.atl, ExperienceLevel.beginner),
          equals('Fatigue'));
      expect(TermResolver.resolveEn(MetricTerm.tsb, ExperienceLevel.beginner),
          equals('Form'));
      expect(TermResolver.resolveEn(MetricTerm.tss, ExperienceLevel.beginner),
          equals('Load'));
    });
  });
}
