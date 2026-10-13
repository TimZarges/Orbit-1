import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/features/chat/models/chat_message.dart';
import 'package:orbit/features/chat/models/chat_conversation.dart';

void main() {
  group('ChatMessage Model Tests', () {
    test('serialisiert Text-Nachricht korrekt', () {
      final msg = ChatMessage(
        id: 'msg_1',
        chatId: 'ath1_coach1',
        senderId: 'ath1',
        type: MessageType.text,
        text: 'Hallo Coach, wie war mein Intervall-Training?',
        createdAt: DateTime(2026, 10, 13, 15, 30),
      );

      final map = msg.toMap();
      expect(map['senderId'], 'ath1');
      expect(map['type'], 'TEXT');
      expect(map['text'], 'Hallo Coach, wie war mein Intervall-Training?');
      expect(map['status'], 'SENT');
      expect(msg.isDeleted, isFalse);
    });

    test('serialisiert ActivityShareSnapshot korrekt', () {
      const share = ActivityShareSnapshot(
        activityId: 'act_123',
        title: '4x4min Schwellenintervalle',
        sport: 'BIKE',
        date: '2026-10-13',
        durationSec: 3600,
        distanceM: 32500,
        avgPowerW: 275,
        avgHr: 165,
      );

      final msg = ChatMessage(
        id: 'msg_2',
        chatId: 'ath1_coach1',
        senderId: 'ath1',
        type: MessageType.activityShare,
        activityShare: share,
        createdAt: DateTime(2026, 10, 13, 16, 0),
      );

      final map = msg.toMap();
      expect(map['type'], 'ACTIVITY_SHARE');
      expect(map['activityShare']['activityId'], 'act_123');
      expect(map['activityShare']['avgPowerW'], 275);
      expect(share.formattedDuration, '1:00:00 h');
      expect(share.formattedDistance, '32.5 km');
    });

    test('Soft-Delete Markierung funktioniert', () {
      final msg = ChatMessage(
        id: 'msg_3',
        chatId: 'ath1_coach1',
        senderId: 'ath1',
        type: MessageType.text,
        text: 'Diese Nachricht wurde gelöscht.',
        status: MessageStatus.deleted,
        createdAt: DateTime(2026, 10, 13, 16, 0),
        deletedAt: DateTime(2026, 10, 13, 16, 5),
      );

      expect(msg.isDeleted, isTrue);
      expect(msg.status, MessageStatus.deleted);
      expect(msg.toMap()['status'], 'DELETED');
    });
  });

  group('ChatConversation Model Tests', () {
    test('ermittelt ungelesene Nachrichten und Teilnehmer', () {
      final conv = ChatConversation(
        id: 'ath1_coach1',
        athleteId: 'ath1',
        coachId: 'coach1',
        status: 'ACTIVE',
        lastMessageText: 'Super gefahren!',
        unreadCounts: {'ath1': 0, 'coach1': 3},
        updatedAt: DateTime(2026, 10, 13, 16, 0),
      );

      expect(conv.isActive, isTrue);
      expect(conv.unreadFor('coach1'), 3);
      expect(conv.unreadFor('ath1'), 0);
      expect(conv.getOtherParticipantId('ath1'), 'coach1');
      expect(conv.getOtherParticipantId('coach1'), 'ath1');
    });
  });
}
