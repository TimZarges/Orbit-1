import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../models/chat_conversation.dart';
import '../repositories/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

final conversationProvider = StreamProvider.family<ChatConversation?, String>((ref, chatId) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.watchConversation(chatId);
});

final userConversationsProvider = StreamProvider.family<List<ChatConversation>, String>((ref, uid) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.watchUserConversations(uid);
});

final messagesProvider = StreamProvider.family<List<ChatMessage>, String>((ref, chatId) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.watchMessages(chatId);
});
