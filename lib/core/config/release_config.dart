/// Datei-Header: `lib/core/config/release_config.dart`
/// Zweck: Zentrale Feature-Gate-Konfiguration für den gestuften ORBIT-Rollout
/// (V1.0.0 Core Launch vs. V2.0.0 Coaching/Builder vs. V3.0.0 Telemetrie/Health).
/// Architektur-Einordnung: Core-Konfigurationsschicht (`lib/core/config/`),
/// steuert die Sichtbarkeit von UI-Modulen, ohne bestehenden V2/V3-Code oder
/// die 218 Bestands-Tests zu brechen.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Unveränderlicher Konfigurationszustand für die aktiven Release-Ausbaustufen.
///
/// Warum: Ermöglicht granulare Selektoren (`ref.watch(releaseConfigProvider.select(...))`)
/// gemäß dem Effizienz-Gebot (`AGENTS.md` Regel 10), sodass Widgets nur dann neu
/// gebaut werden, wenn sich tatsächlich ein relevantes Versions-Flag ändert.
class ReleaseScopeState {
  /// Gibt an, ob Funktionen der Ausbaustufe V2.0.0 aktiv sind
  /// (Trainings-Detail-Weiterleitung, Zonen-Rechner, Leistungsdiagnostik,
  /// Visueller Workout-Builder, Vorlagen-Bibliothek und Trainer-Chat).
  final bool isV2Enabled;

  /// Gibt an, ob Funktionen der Ausbaustufe V3.0.0 aktiv sind
  /// (3 Daily Health Ringe, Readiness-Score, Morgen-Check-in, Banister PMC
  /// und erweiterte ML-/Telemetrie-Analysen).
  final bool isV3Enabled;

  /// Erstellt einen neuen [ReleaseScopeState].
  ///
  /// Im V1.0.0-Standardbetrieb sind sowohl [isV2Enabled] als auch [isV3Enabled]
  /// standardmäßig deaktiviert (`false`).
  const ReleaseScopeState({
    this.isV2Enabled = false,
    this.isV3Enabled = false,
  });

  /// Gibt `true` zurück, wenn die App im fokussierten V1.0.0-Core-Modus läuft.
  bool get isStrictV1 => !isV2Enabled && !isV3Enabled;

  /// Erzeugt eine kopierte Instanz mit selektiv überschriebenen Versions-Flags.
  ///
  /// [isV2Enabled]: Optionaler neuer Zustand für V2.0.0-Features.
  /// [isV3Enabled]: Optionaler neuer Zustand für V3.0.0-Features.
  /// Rückgabewert: Neuer [ReleaseScopeState].
  ReleaseScopeState copyWith({
    bool? isV2Enabled,
    bool? isV3Enabled,
  }) {
    // Erstellt unveränderliche Kopie für Riverpod-State-Vergleiche
    return ReleaseScopeState(
      isV2Enabled: isV2Enabled ?? this.isV2Enabled,
      isV3Enabled: isV3Enabled ?? this.isV3Enabled,
    );
  }

  @override
  bool operator ==(Object other) {
    // Wertgleichheit verhindert unnötige Widget-Rebuilds bei identischen Flags
    if (identical(this, other)) return true;
    return other is ReleaseScopeState &&
        other.isV2Enabled == isV2Enabled &&
        other.isV3Enabled == isV3Enabled;
  }

  @override
  int get hashCode => Object.hash(isV2Enabled, isV3Enabled);
}

/// Statische und reaktive Steuerung des aktiven ORBIT-Funktionsumfangs (Phase 41).
///
/// Was: Definiert die produktiven Standardwerte für V1.0.0 (`isV2Enabled = false`,
/// `isV3Enabled = false`) und bietet Test-Overrides für Unit- und Widget-Tests.
/// Warum: Dadurch bleibt der gesamte V2/V3-Code für die 218 Bestands-Tests voll
/// testbar, während die produktive App strikt den schlanken V1.0.0-Scope rendert.
class ReleaseConfig {
  /// Privater Konstruktor zur Verhinderung direkter Instanziierung.
  const ReleaseConfig._();

  /// Internes Überschreibungs-Flag für V2.0.0 in Testumgebungen.
  static bool? _testOverrideV2;

  /// Internes Überschreibungs-Flag für V3.0.0 in Testumgebungen.
  static bool? _testOverrideV3;

  /// Aktueller Status für V2.0.0-Funktionen (Standard im App-Betrieb: `false`).
  ///
  /// Blendet im V1.0.0-Betrieb Trainings-Detail-Weiterleitung, Zonen-Rechner,
  /// Leistungsdiagnostik, Workout-Builder und Chat aus.
  static bool get isV2Enabled => _testOverrideV2 ?? false;

  /// Aktueller Status für V3.0.0-Funktionen (Standard im App-Betrieb: `false`).
  ///
  /// Blendet im V1.0.0-Betrieb die 3 Daily Health Ringe, Readiness-Score,
  /// Morgen-Check-in und ML-/Telemetrie-Analysen aus.
  static bool get isV3Enabled => _testOverrideV3 ?? false;

  /// Liefert den aktuellen Gesamtzustand als [ReleaseScopeState].
  static ReleaseScopeState get currentState => ReleaseScopeState(
        isV2Enabled: isV2Enabled,
        isV3Enabled: isV3Enabled,
      );

  /// Überschreibt die V2/V3-Feature-Flags gezielt für automatisierte Tests.
  ///
  /// [v2]: Optionales Override für `isV2Enabled`.
  /// [v3]: Optionales Override für `isV3Enabled`.
  static void overrideForTesting({bool? v2, bool? v3}) {
    // Setzt statische Test-Overrides für synchrone und Provider-basierte Abfragen
    _testOverrideV2 = v2;
    _testOverrideV3 = v3;
  }

  /// Setzt alle Test-Überschreibungen wieder auf den strikten V1.0.0-Standard zurück.
  static void resetTestingOverrides() {
    // Stellt den produktiven V1.0.0-Default (false / false) wieder her
    _testOverrideV2 = null;
    _testOverrideV3 = null;
  }
}

/// Riverpod-Provider für den aktuellen [ReleaseScopeState].
///
/// Kann in Widget-Tests zusätzlich per `releaseConfigProvider.overrideWithValue(...)`
/// überschrieben werden und nutzt standardmäßig [ReleaseConfig.currentState].
final releaseConfigProvider = Provider<ReleaseScopeState>((ref) {
  // Liest den aktuellen Zustand aus ReleaseConfig (inkl. etwaiger Test-Overrides)
  return ReleaseConfig.currentState;
});
