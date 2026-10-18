import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../models/chat_conversation.dart';
import '../repositories/chat_repository.dart';

/// Provider für den Zugriff auf das [ChatRepository].
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

/// Stream-Provider für eine einzelne Chat-Konversation identifiziert durch [chatId].
final conversationProvider =
    StreamProvider.family<ChatConversation?, String>((ref, chatId) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.watchConversation(chatId);
});

/// Stream-Provider für alle aktiven Chat-Konversationen eines Nutzers [uid].
final userConversationsProvider =
    StreamProvider.family<List<ChatConversation>, String>((ref, uid) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.watchUserConversations(uid);
});

/// Stream-Provider für den chronologischen Nachrichtenverlauf eines Chats [chatId].
final messagesProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, chatId) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.watchMessages(chatId);
});
