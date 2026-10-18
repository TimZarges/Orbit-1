import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/coach_global_mode.dart';

/// Zentraler StateProvider für den globalen Ansichtsmodus des Coaches.
///
/// Gilt app-weit für alle Athleten und Ansichten des Trainers:
/// - [CoachGlobalMode.simpleDownload]: Schlanke Übersicht mit direktem Datei-Download
/// - [CoachGlobalMode.fullAnalysis]: Volles Cockpit mit allen Leistungs- und Gesundheitsdaten
final coachGlobalModeProvider = StateProvider<CoachGlobalMode>((ref) {
  return CoachGlobalMode.fullAnalysis;
});
