import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  image,
  file,
  activityShare,
}

enum MessageStatus {
  sending,
  sent,
  failed,
  deleted,
}

/// Momentaufnahme einer geteilten Trainingseinheit im Chat.
/// Das Teilen gewährt KEINEN zusätzlichen Datenzugriff, sondern zeigt nur diesen Snapshot.
class ActivityShareSnapshot {
  final String activityId;
  final String title;
  final String sport;
  final String date;
  final int durationSec;
  final double distanceM;
  final double? avgPowerW;
  final double? avgHr;
  final double? orbitScore;

  const ActivityShareSnapshot({
    required this.activityId,
    required this.title,
    required this.sport,
    required this.date,
    required this.durationSec,
    required this.distanceM,
    this.avgPowerW,
    this.avgHr,
    this.orbitScore,
  });

  factory ActivityShareSnapshot.fromMap(Map<String, dynamic> map) {
    return ActivityShareSnapshot(
      activityId: map['activityId'] as String? ?? '',
      title: map['title'] as String? ?? 'Training',
      sport: map['sport'] as String? ?? 'OTHER',
      date: map['date'] as String? ?? '',
      durationSec: (map['durationSec'] as num?)?.toInt() ?? 0,
      distanceM: (map['distanceM'] as num?)?.toDouble() ?? 0.0,
      avgPowerW: (map['avgPowerW'] as num?)?.toDouble(),
      avgHr: (map['avgHr'] as num?)?.toDouble(),
      orbitScore: (map['orbitScore'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'activityId': activityId,
      'title': title,
      'sport': sport,
      'date': date,
      'durationSec': durationSec,
      'distanceM': distanceM,
      if (avgPowerW != null) 'avgPowerW': avgPowerW,
      if (avgHr != null) 'avgHr': avgHr,
      if (orbitScore != null) 'orbitScore': orbitScore,
    };
  }

  String get formattedDuration {
    final h = durationSec ~/ 3600;
    final m = (durationSec % 3600) ~/ 60;
    final s = durationSec % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')} h';
    }
    return '$m:${s.toString().padLeft(2, '0')} min';
  }

  String get formattedDistance {
    if (distanceM <= 0) return '';
    if (sport.toUpperCase() == 'SWIM') {
      return '${distanceM.round()} m';
    }
    return '${(distanceM / 1000).toStringAsFixed(1)} km';
  }
}

/// Modell für eine Chat-Nachricht (`chats/{chatId}/messages/{messageId}`).
class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final MessageType type;
  final String? text;
  final String? mediaUrl;
  final String? fileName;
  final int? fileSizeBytes;
  final ActivityShareSnapshot? activityShare;
  final MessageStatus status;
  final DateTime createdAt;
  final DateTime? deletedAt;

  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.type,
    this.text,
    this.mediaUrl,
    this.fileName,
    this.fileSizeBytes,
    this.activityShare,
    this.status = MessageStatus.sent,
    required this.createdAt,
    this.deletedAt,
  });

  factory ChatMessage.fromDocument(DocumentSnapshot doc, String chatId) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};

    final typeStr = data['type'] as String? ?? 'TEXT';
    final MessageType type;
    switch (typeStr.toUpperCase()) {
      case 'IMAGE':
        type = MessageType.image;
        break;
      case 'FILE':
        type = MessageType.file;
        break;
      case 'ACTIVITY_SHARE':
        type = MessageType.activityShare;
        break;
      case 'TEXT':
      default:
        type = MessageType.text;
        break;
    }

    final statusStr = data['status'] as String? ?? 'SENT';
    final MessageStatus status;
    switch (statusStr.toUpperCase()) {
      case 'DELETED':
        status = MessageStatus.deleted;
        break;
      case 'SENDING':
        status = MessageStatus.sending;
        break;
      case 'FAILED':
        status = MessageStatus.failed;
        break;
      case 'SENT':
      default:
        status = MessageStatus.sent;
        break;
    }

    ActivityShareSnapshot? share;
    if (data['activityShare'] != null && data['activityShare'] is Map) {
      share = ActivityShareSnapshot.fromMap(
          Map<String, dynamic>.from(data['activityShare'] as Map));
    }

    return ChatMessage(
      id: doc.id,
      chatId: chatId,
      senderId: data['senderId'] as String? ?? '',
      type: type,
      text: data['text'] as String?,
      mediaUrl: data['mediaUrl'] as String?,
      fileName: data['fileName'] as String?,
      fileSizeBytes: (data['fileSizeBytes'] as num?)?.toInt(),
      activityShare: share,
      status: status,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deletedAt: (data['deletedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    final String typeStr;
    switch (type) {
      case MessageType.text:
        typeStr = 'TEXT';
        break;
      case MessageType.image:
        typeStr = 'IMAGE';
        break;
      case MessageType.file:
        typeStr = 'FILE';
        break;
      case MessageType.activityShare:
        typeStr = 'ACTIVITY_SHARE';
        break;
    }

    return {
      'senderId': senderId,
      'type': typeStr,
      if (text != null) 'text': text,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
      if (fileName != null) 'fileName': fileName,
      if (fileSizeBytes != null) 'fileSizeBytes': fileSizeBytes,
      if (activityShare != null) 'activityShare': activityShare!.toMap(),
      'status': status.name.toUpperCase(),
      'createdAt': Timestamp.fromDate(createdAt),
      if (deletedAt != null) 'deletedAt': Timestamp.fromDate(deletedAt!),
    };
  }

  bool get isDeleted => status == MessageStatus.deleted;

  ChatMessage copyWith({
    String? id,
    String? chatId,
    String? senderId,
    MessageType? type,
    String? text,
    String? mediaUrl,
    String? fileName,
    int? fileSizeBytes,
    ActivityShareSnapshot? activityShare,
    MessageStatus? status,
    DateTime? createdAt,
    DateTime? deletedAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      type: type ?? this.type,
      text: text ?? this.text,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      fileName: fileName ?? this.fileName,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      activityShare: activityShare ?? this.activityShare,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
