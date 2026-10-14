import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/threshold_proposal.dart';
import '../models/threshold_entry.dart';

/// Repository zur Verwaltung von Schwellenwert-Vorschlägen und Historie.
class DiagnosticsRepository {
  final FirebaseFirestore _firestore;

  DiagnosticsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Lädt alle offenen Schwellenwert-Vorschläge eines Athleten.
  Stream<List<ThresholdProposal>> watchPendingProposals(String athleteId) {
    return _firestore
        .collection('users')
        .doc(athleteId)
        .collection('thresholdProposals')
        .where('status', isEqualTo: 'PENDING')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ThresholdProposal.fromDocument(doc))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Lädt einmalig offene Schwellenwert-Vorschläge.
  Future<List<ThresholdProposal>> getPendingProposals(String athleteId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(athleteId)
          .collection('thresholdProposals')
          .where('status', isEqualTo: 'PENDING')
          .get();

      final list = snapshot.docs
          .map((doc) => ThresholdProposal.fromDocument(doc))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      return [];
    }
  }

  /// Lädt die vollständige Schwellenwert-Historie chronologisch aufsteigend.
  Stream<List<ThresholdEntry>> watchThresholdHistory(String athleteId) {
    return _firestore
        .collection('users')
        .doc(athleteId)
        .collection('thresholdHistory')
        .orderBy('effectiveFrom', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ThresholdEntry.fromDocument(doc))
          .toList();
    });
  }

  /// Lädt den aktuell gültigen Schwellenwert-Stand.
  Future<ThresholdEntry?> getLatestThresholds(String athleteId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(athleteId)
          .collection('thresholdHistory')
          .orderBy('effectiveFrom', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return ThresholdEntry.fromDocument(snapshot.docs.first);
    } catch (e) {
      return null;
    }
  }

  /// Nimmt einen Vorschlag an:
  /// 1. Aktualisiert den Status des Vorschlags auf 'ACCEPTED'.
  /// 2. Schreibt einen neuen Eintrag in `thresholdHistory` mit `effectiveFrom = heute`.
  /// Die bisherige Historie bleibt unverändert!
  Future<void> acceptProposal({
    required String athleteId,
    required ThresholdProposal proposal,
    required bool triggerRecompute,
  }) async {
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // 1. Neuesten Schwellenwert-Stand laden, um bestehende andere Werte beizubehalten
    final latest = await getLatestThresholds(athleteId);

    double? newFtp = latest?.ftpW;
    double? newLthr = latest?.thresholdHrBpm;
    double? newMaxHr = latest?.maxHrBpm;
    double? newRestingHr = latest?.restingHrBpm;
    double? newRunPace = latest?.runThresholdPaceSecPerKm;
    double? newSwimCss = latest?.swimCssSecPer100m;

    switch (proposal.type) {
      case ThresholdType.ftp:
        newFtp = proposal.proposedValue;
        break;
      case ThresholdType.lthr:
        newLthr = proposal.proposedValue;
        break;
      case ThresholdType.thresholdPace:
        newRunPace = proposal.proposedValue;
        break;
      case ThresholdType.css:
        newSwimCss = proposal.proposedValue;
        break;
    }

    final newEntry = ThresholdEntry(
      id: 'th_${now.millisecondsSinceEpoch}',
      effectiveFrom: todayStr,
      ftpW: newFtp,
      thresholdHrBpm: newLthr,
      maxHrBpm: newMaxHr,
      restingHrBpm: newRestingHr,
      runThresholdPaceSecPerKm: newRunPace,
      swimCssSecPer100m: newSwimCss,
      source: 'ESTIMATED',
      createdAt: now,
    );

    final batch = _firestore.batch();

    // Vorschlag als angenommen markieren (nur status-Feld, gemäß Firestore Security Rules!)
    final proposalRef = _firestore
        .collection('users')
        .doc(athleteId)
        .collection('thresholdProposals')
        .doc(proposal.id);
    batch.update(proposalRef, {'status': 'ACCEPTED'});

    // Neuen Schwellenwerteintrag mit effectiveFrom = heute anlegen
    final historyRef = _firestore
        .collection('users')
        .doc(athleteId)
        .collection('thresholdHistory')
        .doc(newEntry.id);
    batch.set(historyRef, newEntry.toMap());

    await batch.commit();

    // 3. Wenn Neuberechnung gewünscht: Cloud Function oder Request anlegen
    if (triggerRecompute) {
      await _triggerHistoricalRecompute(athleteId, todayStr);
    }
  }

  /// Weist einen Vorschlag ab:
  /// Ändert ausschließlich den Status auf 'REJECTED' (gemäß Security Rules).
  Future<void> rejectProposal({
    required String athleteId,
    required String proposalId,
  }) async {
    final proposalRef = _firestore
        .collection('users')
        .doc(athleteId)
        .collection('thresholdProposals')
        .doc(proposalId);

    await proposalRef.update({'status': 'REJECTED'});
  }

  /// Triggert die serverseitige Neuberechnung für vergangene Einheiten (Phase 05).
  Future<void> _triggerHistoricalRecompute(
      String athleteId, String fromDate) async {
    try {
      // Protokollierung / Trigger-Dokument für den Worker
      await _firestore
          .collection('users')
          .doc(athleteId)
          .collection('recomputeRequests')
          .add({
        'athleteId': athleteId,
        'requestedAt': FieldValue.serverTimestamp(),
        'fromDate': fromDate,
        'status': 'PENDING',
        'reason': 'THRESHOLD_UPDATE_RECOMPUTE',
      });
    } catch (_) {
      // Fehler beim Recompute fangen
    }
  }
}
