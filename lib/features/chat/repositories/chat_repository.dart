import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/chat_message.dart';
import '../models/chat_conversation.dart';

/// Repository für Echtzeit-Chat, Nachrichten-Streaming, Soft-Delete und Dateianhänge.
class ChatRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  ChatRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  /// Stream einer einzelnen Konversation.
  Stream<ChatConversation?> watchConversation(String chatId) {
    return _firestore.collection('chats').doc(chatId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ChatConversation.fromDocument(doc);
    });
  }

  /// Stream aller aktiven Konversationen eines Nutzers (für Trainer mit mehreren Athleten).
  Stream<List<ChatConversation>> watchUserConversations(String uid) {
    // Abfrage für Chats, in denen der Nutzer entweder als Trainer oder Athlet eingetragen ist
    return _firestore
        .collection('chats')
        .where('coachId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ChatConversation.fromDocument(doc))
          .toList();
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    });
  }

  /// Stream der neuesten Nachrichten einer Konversation (paginiert, neueste zuerst).
  Stream<List<ChatMessage>> watchMessages(String chatId, {int limit = 40}) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessage.fromDocument(doc, chatId))
          .toList();
    });
  }

  /// Sendet eine neue Nachricht in den Chat.
  Future<ChatMessage> sendMessage({
    required String chatId,
    required String senderId,
    required MessageType type,
    String? text,
    String? mediaUrl,
    String? fileName,
    int? fileSizeBytes,
    ActivityShareSnapshot? activityShare,
  }) async {
    final now = DateTime.now();
    final messageDoc =
        _firestore.collection('chats').doc(chatId).collection('messages').doc();

    final message = ChatMessage(
      id: messageDoc.id,
      chatId: chatId,
      senderId: senderId,
      type: type,
      text: text,
      mediaUrl: mediaUrl,
      fileName: fileName,
      fileSizeBytes: fileSizeBytes,
      activityShare: activityShare,
      status: MessageStatus.sent,
      createdAt: now,
    );

    // Nachricht in Subcollection schreiben
    await messageDoc.set(message.toMap());

    return message;
  }

  /// Führt ein Soft-Delete einer eigenen Nachricht durch.
  /// Entfernt Text- und Anhangsdaten und setzt Status auf 'DELETED'.
  Future<void> softDeleteMessage({
    required String chatId,
    required String messageId,
    required String senderId,
  }) async {
    final docRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId);

    await docRef.update({
      'status': 'DELETED',
      'text': 'Diese Nachricht wurde gelöscht.',
      'mediaUrl': FieldValue.delete(),
      'fileName': FieldValue.delete(),
      'fileSizeBytes': FieldValue.delete(),
      'activityShare': FieldValue.delete(),
      'deletedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Aktualisiert den Gelesen-Status (`chats/{chatId}/state/{uid}`).
  Future<void> markChatAsRead(String chatId, String uid) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('state')
          .doc(uid)
          .set({
        'lastReadAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Offline- oder Berechtigungsfehler tolerant fangen
    }
  }

  /// Lädt einen Bildanhang in Cloud Storage hoch (max. 10 MB).
  Future<String> uploadImage({
    required String chatId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final ref = _storage.ref().child('chats/$chatId/images/$fileName');
    final metadata = SettableMetadata(contentType: 'image/jpeg');
    final uploadTask = await ref.putData(bytes, metadata);
    return await uploadTask.ref.getDownloadURL();
  }

  /// Lädt einen Dateianhang in Cloud Storage hoch (max. 25 MB).
  Future<String> uploadFile({
    required String chatId,
    required Uint8List bytes,
    required String fileName,
    String contentType = 'application/octet-stream',
  }) async {
    final ref = _storage.ref().child('chats/$chatId/files/$fileName');
    final metadata = SettableMetadata(contentType: contentType);
    final uploadTask = await ref.putData(bytes, metadata);
    return await uploadTask.ref.getDownloadURL();
  }
}
