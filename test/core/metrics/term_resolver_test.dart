import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/core/metrics/term_resolver.dart';

void main() {
  group('TermResolver', () {
    test('resolves DE correctly for beginner', () {
      expect(TermResolver.resolve(MetricTerm.ctl, ExperienceLevel.beginner),
          'Fitness');
      expect(TermResolver.resolve(MetricTerm.atl, ExperienceLevel.beginner),
          'Ermüdung');
    });

    test('resolves DE correctly for advanced', () {
      expect(TermResolver.resolve(MetricTerm.ctl, ExperienceLevel.advanced),
          'Fitness (CTL)');
    });

    test('resolves DE correctly for expert', () {
      expect(
          TermResolver.resolve(MetricTerm.ctl, ExperienceLevel.expert), 'CTL');
    });

    test('resolves EN correctly', () {
      expect(TermResolver.resolveEn(MetricTerm.tsb, ExperienceLevel.beginner),
          'Form');
      expect(TermResolver.resolveEn(MetricTerm.tss, ExperienceLevel.advanced),
          'Load (TSS)');
    });
  });
}
