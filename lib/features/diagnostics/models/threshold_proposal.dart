import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum ThresholdType {
  ftp,
  lthr,
  thresholdPace,
  css,
}

enum ConfidenceLevel {
  high,
  medium,
  low,
}

enum ProposalStatus {
  pending,
  accepted,
  rejected,
  expired,
}

/// Modell für einen automatischen Schwellenwert-Vorschlag (`users/{uid}/thresholdProposals/{id}`).
class ThresholdProposal {
  final String id;
  final String athleteId;
  final String sport;
  final ThresholdType type;
  final double proposedValue;
  final double? currentValue;
  final double delta;
  final double deltaPercent;
  final ConfidenceLevel confidence;
  final List<String> basis;
  final String explanationDe;
  final String explanationEn;
  final ProposalStatus status;
  final DateTime createdAt;
  final DateTime? expiresAt;

  const ThresholdProposal({
    required this.id,
    required this.athleteId,
    required this.sport,
    required this.type,
    required this.proposedValue,
    this.currentValue,
    required this.delta,
    required this.deltaPercent,
    required this.confidence,
    required this.basis,
    required this.explanationDe,
    required this.explanationEn,
    this.status = ProposalStatus.pending,
    required this.createdAt,
    this.expiresAt,
  });

  factory ThresholdProposal.fromDocument(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};

    final typeStr = data['type'] as String? ?? 'FTP';
    final ThresholdType type;
    switch (typeStr.toUpperCase()) {
      case 'LTHR':
        type = ThresholdType.lthr;
        break;
      case 'THRESHOLD_PACE':
        type = ThresholdType.thresholdPace;
        break;
      case 'CSS':
        type = ThresholdType.css;
        break;
      case 'FTP':
      default:
        type = ThresholdType.ftp;
        break;
    }

    final confStr = data['confidence'] as String? ?? 'MEDIUM';
    final ConfidenceLevel confidence;
    switch (confStr.toUpperCase()) {
      case 'HIGH':
        confidence = ConfidenceLevel.high;
        break;
      case 'LOW':
        confidence = ConfidenceLevel.low;
        break;
      case 'MEDIUM':
      default:
        confidence = ConfidenceLevel.medium;
        break;
    }

    final statusStr = data['status'] as String? ?? 'PENDING';
    final ProposalStatus status;
    switch (statusStr.toUpperCase()) {
      case 'ACCEPTED':
        status = ProposalStatus.accepted;
        break;
      case 'REJECTED':
        status = ProposalStatus.rejected;
        break;
      case 'EXPIRED':
        status = ProposalStatus.expired;
        break;
      case 'PENDING':
      default:
        status = ProposalStatus.pending;
        break;
    }

    final basisList =
        (data['basis'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
            [];

    return ThresholdProposal(
      id: doc.id,
      athleteId: data['athleteId'] as String? ?? '',
      sport: data['sport'] as String? ?? 'BIKE',
      type: type,
      proposedValue: (data['proposedValue'] as num?)?.toDouble() ?? 0.0,
      currentValue: (data['currentValue'] as num?)?.toDouble(),
      delta: (data['delta'] as num?)?.toDouble() ?? 0.0,
      deltaPercent: (data['deltaPercent'] as num?)?.toDouble() ?? 0.0,
      confidence: confidence,
      basis: basisList,
      explanationDe: data['explanationDe'] as String? ?? '',
      explanationEn: data['explanationEn'] as String? ?? '',
      status: status,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'athleteId': athleteId,
      'sport': sport,
      'type': type.name.toUpperCase(),
      'proposedValue': proposedValue,
      'currentValue': currentValue,
      'delta': delta,
      'deltaPercent': deltaPercent,
      'confidence': confidence.name.toUpperCase(),
      'basis': basis,
      'explanationDe': explanationDe,
      'explanationEn': explanationEn,
      'status': status.name.toUpperCase(),
      'createdAt': Timestamp.fromDate(createdAt),
      if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
    };
  }

  String get typeLabelDe {
    switch (type) {
      case ThresholdType.ftp:
        return 'Rad FTP';
      case ThresholdType.lthr:
        return 'Schwellen-HF (LTHR)';
      case ThresholdType.thresholdPace:
        return 'Schwellen-Pace';
      case ThresholdType.css:
        return 'Schwimm-CSS';
    }
  }

  String get unit {
    switch (type) {
      case ThresholdType.ftp:
        return 'W';
      case ThresholdType.lthr:
        return 'bpm';
      case ThresholdType.thresholdPace:
        return '/km';
      case ThresholdType.css:
        return '/100m';
    }
  }

  String get formattedProposedValue {
    switch (type) {
      case ThresholdType.ftp:
      case ThresholdType.lthr:
        return '${proposedValue.round()} $unit';
      case ThresholdType.thresholdPace:
        final m = proposedValue.toInt() ~/ 60;
        final s = (proposedValue % 60).round();
        return '$m:${s.toString().padLeft(2, '0')} $unit';
      case ThresholdType.css:
        final m = proposedValue.toInt() ~/ 60;
        final s = (proposedValue % 60).round();
        return '$m:${s.toString().padLeft(2, '0')} $unit';
    }
  }

  String get formattedDelta {
    final sign = delta >= 0 ? '+' : '';
    final pctSign = deltaPercent >= 0 ? '+' : '';
    if (type == ThresholdType.ftp || type == ThresholdType.lthr) {
      return '$sign${delta.round()} $unit ($pctSign${deltaPercent.toStringAsFixed(1)} %)';
    }
    return '$pctSign${deltaPercent.toStringAsFixed(1)} %';
  }

  Color get confidenceColor {
    switch (confidence) {
      case ConfidenceLevel.high:
        return const Color(0xFF10B981); // Grün
      case ConfidenceLevel.medium:
        return const Color(0xFFF59E0B); // Amber
      case ConfidenceLevel.low:
        return const Color(0xFF94A3B8); // Slate
    }
  }

  String get confidenceLabelDe {
    switch (confidence) {
      case ConfidenceLevel.high:
        return 'Hohe Konfidenz';
      case ConfidenceLevel.medium:
        return 'Mittlere Konfidenz';
      case ConfidenceLevel.low:
        return 'Niedrige Konfidenz';
    }
  }
}
