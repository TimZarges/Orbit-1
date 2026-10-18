enum ExperienceLevel { beginner, advanced, expert }

enum MetricTerm {
  ctl,
  atl,
  tsb,
  tss,
  np,
  ifactor,
}

class TermResolver {
  /// Liefert die korrekte Bezeichnung basierend auf der Erfahrungsstufe.
  static String resolve(MetricTerm term, ExperienceLevel level) {
    switch (term) {
      case MetricTerm.ctl:
        if (level == ExperienceLevel.beginner) return 'Fitness';
        if (level == ExperienceLevel.advanced) return 'Fitness (CTL)';
        return 'CTL';
      case MetricTerm.atl:
        if (level == ExperienceLevel.beginner) return 'Ermüdung';
        if (level == ExperienceLevel.advanced) return 'Ermüdung (ATL)';
        return 'ATL';
      case MetricTerm.tsb:
        if (level == ExperienceLevel.beginner) return 'Frische';
        if (level == ExperienceLevel.advanced) return 'Frische (TSB)';
        return 'TSB';
      case MetricTerm.tss:
        if (level == ExperienceLevel.beginner) return 'Belastung';
        if (level == ExperienceLevel.advanced) return 'ORBIT Belastung';
        return 'ORBIT Load';
      case MetricTerm.np:
        if (level == ExperienceLevel.beginner) return 'Normalisierte Leistung';
        if (level == ExperienceLevel.advanced) return 'Normalisierte Leistung';
        return 'Iso-Power';
      case MetricTerm.ifactor:
        if (level == ExperienceLevel.beginner) return 'Intensität';
        if (level == ExperienceLevel.advanced) return 'Intensitäts-Faktor';
        return 'Intensitäts-Faktor';
    }
  }

  /// Liefert den englischen Fallback für Tests oder späteres i18n
  static String resolveEn(MetricTerm term, ExperienceLevel level) {
    switch (term) {
      case MetricTerm.ctl:
        if (level == ExperienceLevel.beginner) return 'Fitness';
        if (level == ExperienceLevel.advanced) return 'Fitness (CTL)';
        return 'CTL';
      case MetricTerm.atl:
        if (level == ExperienceLevel.beginner) return 'Fatigue';
        if (level == ExperienceLevel.advanced) return 'Fatigue (ATL)';
        return 'ATL';
      case MetricTerm.tsb:
        if (level == ExperienceLevel.beginner) return 'Form';
        if (level == ExperienceLevel.advanced) return 'Form (TSB)';
        return 'TSB';
      case MetricTerm.tss:
        if (level == ExperienceLevel.beginner) return 'Load';
        if (level == ExperienceLevel.advanced) return 'ORBIT Load';
        return 'ORBIT Load';
      case MetricTerm.np:
        if (level == ExperienceLevel.beginner) return 'Normalized Power';
        if (level == ExperienceLevel.advanced) return 'Normalized Power';
        return 'Iso-Power';
      case MetricTerm.ifactor:
        if (level == ExperienceLevel.beginner) return 'Intensity';
        if (level == ExperienceLevel.advanced) return 'Intensity Factor';
        return 'Intensity Factor';
    }
  }
}
