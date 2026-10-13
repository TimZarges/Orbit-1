import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/metrics/term_resolver.dart';

/// Bottom Sheet zur barrierefreien Erklärung von Trainingsmetriken und Formeln.
class AnalysisInfoSheet extends StatelessWidget {
  final MetricTerm? term;
  final String? customTitle;
  final String? customDescription;
  final String? formula;
  final ExperienceLevel level;

  const AnalysisInfoSheet({
    super.key,
    this.term,
    this.customTitle,
    this.customDescription,
    this.formula,
    this.level = ExperienceLevel.beginner,
  });

  /// Öffnet das Erklärungs-Sheet für einen Standard-Fachbegriff.
  static void showTerm(
    BuildContext context, {
    required MetricTerm term,
    ExperienceLevel level = ExperienceLevel.beginner,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AnalysisInfoSheet(term: term, level: level),
    );
  }

  /// Öffnet das Erklärungs-Sheet für die Form-Ampel.
  static void showFormTrafficLight(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const AnalysisInfoSheet(
        customTitle: 'Form-Ampel (Physiologische Einordnung)',
        customDescription:
            'Die Form-Ampel bewertet deinen aktuellen Zustand anhand des individuellen Verhältnisses von Frische zu Grundfitness (TSB / CTL).\n\n'
            '• Sehr müde (TSB/CTL < -0,30): Körper absorbiert hohe Belastungsreize.\n'
            '• Gut belastet (-0,30 bis -0,10): Optimaler Korridor für nachhaltigen Trainingsaufbau.\n'
            '• Ausgeglichen (-0,10 bis +0,15): Belastung und Erholung halten sich die Waage.\n'
            '• Frisch (> +0,15): Hohe Frische nach Erholung oder Tapering.\n\n'
            'Für eine verlässliche Aussage sind mindestens 21 Tage kontinuierliche Trainingsdaten erforderlich.',
        formula: 'TSB_Ratio = (CTL - ATL) / CTL',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = customTitle ?? (term != null ? TermResolver.resolve(term!, level) : 'Information');
    final desc = customDescription ?? _getDescription(term);
    final form = formula ?? _getFormula(term);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(title, style: AppTypography.headline),
            const SizedBox(height: 12),
            Text(
              desc,
              style: AppTypography.body.copyWith(color: AppColors.navy, height: 1.4),
            ),
            if (form != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.techGrey,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Formel / Berechnung:', style: AppTypography.label.copyWith(color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    Text(form, style: AppTypography.bodySmall.copyWith(fontFamily: 'monospace')),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Verstanden'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDescription(MetricTerm? term) {
    switch (term) {
      case MetricTerm.ctl:
        return 'Chronische Trainingsbelastung (Fitness). Exponentiell gewichteter Durchschnitt deiner Trainingsbelastung über die letzten 42 Tage. Spiegelt deine langfristige Ausdauerbasis wider.';
      case MetricTerm.atl:
        return 'Akute Trainingsbelastung (Ermüdung). Exponentiell gewichteter Durchschnitt deiner Belastung über die letzten 7 Tage. Zeigt die kurzfristige Erschöpfung durch aktuelle Einheiten.';
      case MetricTerm.tsb:
        return 'Trainingsstress-Balance (Frische). Differenz aus Fitness und Ermüdung (CTL - ATL). Ein positiver Wert signalisiert Frische, ein negativer akute Belastung.';
      case MetricTerm.tss:
        return 'Trainingsbelastung (Training Stress Score). Einheitsmaß für die Gesamtschwere eines Trainings basierend auf Dauer und Intensität im Verhältnis zu deinen individuellen Schwellenwerten.';
      case MetricTerm.np:
        return 'Gewichtete Leistung (Normalized Power). Berechnet die physiologischen Kosten ungleichmäßiger Wattleistungen unter Berücksichtigung von Leistungsspitzen.';
      case MetricTerm.ifactor:
        return 'Intensitätsfaktor (Intensity Factor). Verhältnis deiner gewichteten Leistung zu deiner funktionellen Schwellenleistung (FTP).';
      default:
        return 'Erklärung für diesen Wert folgt in Kürze.';
    }
  }

  String? _getFormula(MetricTerm? term) {
    switch (term) {
      case MetricTerm.ctl:
        return 'CTL_heute = TSS * (1 - e^(-1/42)) + CTL_gestern * e^(-1/42)';
      case MetricTerm.atl:
        return 'ATL_heute = TSS * (1 - e^(-1/7)) + ATL_gestern * e^(-1/7)';
      case MetricTerm.tsb:
        return 'TSB = CTL - ATL';
      case MetricTerm.tss:
        return 'TSS = (Dauer_s * NP * IF) / (FTP * 3600) * 100';
      case MetricTerm.np:
        return 'NP = (Mittelwert(Gleitender30sMittelwert^4))^(1/4)';
      case MetricTerm.ifactor:
        return 'IF = NP / FTP';
      default:
        return null;
    }
  }
}
