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
          equals('Gewichtete Leistung'));
      expect(TermResolver.resolve(MetricTerm.ifactor, ExperienceLevel.beginner),
          equals('Intensität'));
    });

    test('Ebene Advanced verbindet Begriff mit Fachkürzel', () {
      expect(TermResolver.resolve(MetricTerm.ctl, ExperienceLevel.advanced),
          equals('Fitness (CTL)'));
      expect(TermResolver.resolve(MetricTerm.atl, ExperienceLevel.advanced),
          equals('Ermüdung (ATL)'));
      expect(TermResolver.resolve(MetricTerm.tsb, ExperienceLevel.advanced),
          equals('Frische (TSB)'));
      expect(TermResolver.resolve(MetricTerm.tss, ExperienceLevel.advanced),
          equals('Belastung (TSS)'));
      expect(TermResolver.resolve(MetricTerm.np, ExperienceLevel.advanced),
          equals('Gewichtete Leistung (NP)'));
      expect(TermResolver.resolve(MetricTerm.ifactor, ExperienceLevel.advanced),
          equals('Intensität (IF)'));
    });

    test('Ebene Expert nutzt reine Fachkürzel', () {
      expect(TermResolver.resolve(MetricTerm.ctl, ExperienceLevel.expert),
          equals('CTL'));
      expect(TermResolver.resolve(MetricTerm.atl, ExperienceLevel.expert),
          equals('ATL'));
      expect(TermResolver.resolve(MetricTerm.tsb, ExperienceLevel.expert),
          equals('TSB'));
      expect(TermResolver.resolve(MetricTerm.tss, ExperienceLevel.expert),
          equals('TSS'));
      expect(TermResolver.resolve(MetricTerm.np, ExperienceLevel.expert),
          equals('NP'));
      expect(TermResolver.resolve(MetricTerm.ifactor, ExperienceLevel.expert),
          equals('IF'));
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
