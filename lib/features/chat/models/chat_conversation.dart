import 'package:cloud_firestore/cloud_firestore.dart';

/// Modell für eine Chat-Konversation (`chats/{chatId}`).
class ChatConversation {
  final String id;
  final String athleteId;
  final String coachId;
  final String status; // "ACTIVE" | "REVOKED"
  final String? lastMessageText;
  final DateTime? lastMessageTime;
  final String? lastMessageSenderId;
  final String? lastMessageType;
  final Map<String, int> unreadCounts;
  final DateTime updatedAt;

  // UI Helper
  final String? otherUserName;
  final String? otherUserRole;

  const ChatConversation({
    required this.id,
    required this.athleteId,
    required this.coachId,
    this.status = 'ACTIVE',
    this.lastMessageText,
    this.lastMessageTime,
    this.lastMessageSenderId,
    this.lastMessageType,
    this.unreadCounts = const {},
    required this.updatedAt,
    this.otherUserName,
    this.otherUserRole,
  });

  factory ChatConversation.fromDocument(DocumentSnapshot doc,
      {String? currentUid}) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};

    final athleteId = data['athleteId'] as String? ?? '';
    final coachId = data['coachId'] as String? ?? '';

    final lastMsg = data['lastMessage'] as Map<String, dynamic>? ?? {};
    final unreadMap = (data['unreadCount'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, (v as num).toInt()),
        ) ??
        {};

    return ChatConversation(
      id: doc.id,
      athleteId: athleteId,
      coachId: coachId,
      status: data['status'] as String? ?? 'ACTIVE',
      lastMessageText: lastMsg['text'] as String?,
      lastMessageTime: (lastMsg['sentAt'] as Timestamp?)?.toDate(),
      lastMessageSenderId: lastMsg['senderId'] as String?,
      lastMessageType: lastMsg['type'] as String?,
      unreadCounts: unreadMap,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      otherUserName: data['otherUserName'] as String?,
      otherUserRole: data['otherUserRole'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'athleteId': athleteId,
      'coachId': coachId,
      'status': status,
      if (lastMessageText != null)
        'lastMessage': {
          'text': lastMessageText,
          'senderId': lastMessageSenderId,
          if (lastMessageTime != null)
            'sentAt': Timestamp.fromDate(lastMessageTime!),
          'type': lastMessageType ?? 'TEXT',
        },
      'unreadCount': unreadCounts,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  bool get isActive => status == 'ACTIVE';

  int unreadFor(String uid) => unreadCounts[uid] ?? 0;

  String getOtherParticipantId(String currentUid) {
    return currentUid == athleteId ? coachId : athleteId;
  }
}
