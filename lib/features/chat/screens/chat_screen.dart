import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../models/chat_message.dart';
import '../providers/chat_providers.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input_bar.dart';

/// Haupt-Bildschirm für eine 1:1 Konversation zwischen Athlet und Trainer.
class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String? athleteId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.chatId,
    this.athleteId,
    this.otherUserName = 'Coach',
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Als gelesen markieren
    _markRead();
  }

  void _markRead() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      ref.read(chatRepositoryProvider).markChatAsRead(widget.chatId, uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final conversationAsync = ref.watch(conversationProvider(widget.chatId));
    final messagesAsync = ref.watch(messagesProvider(widget.chatId));

    final isRevoked = conversationAsync.asData?.value?.isActive == false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 1,
        shadowColor: Colors.black12,
        iconTheme: const IconThemeData(color: AppColors.navy),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.techGrey,
              child: Text(
                widget.otherUserName.isNotEmpty
                    ? widget.otherUserName[0].toUpperCase()
                    : 'C',
                style: AppTypography.title
                    .copyWith(fontSize: 16, color: AppColors.navy),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: AppTypography.title
                        .copyWith(fontSize: 16, color: AppColors.navy),
                  ),
                  Text(
                    isRevoked ? 'Verbindung beendet' : 'Verbunden',
                    style: AppTypography.label.copyWith(
                      fontSize: 11,
                      color: isRevoked
                          ? Colors.red.shade400
                          : const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Nachrichtenliste
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'Noch keine Nachrichten.',
                          style: AppTypography.body
                              .copyWith(color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Schreibe deinem Coach oder teile eine Einheit.',
                          style: AppTypography.label
                              .copyWith(color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUid;

                    // Datumstrenner prüfen
                    bool showDateHeader = false;
                    if (index == messages.length - 1) {
                      showDateHeader = true;
                    } else {
                      final prevMessage = messages[index + 1];
                      if (!_isSameDay(
                          message.createdAt, prevMessage.createdAt)) {
                        showDateHeader = true;
                      }
                    }

                    return Column(
                      children: [
                        if (showDateHeader) _buildDateHeader(message.createdAt),
                        ChatBubble(
                          message: message,
                          isMe: isMe,
                          onDelete: () => _handleDeleteMessage(message),
                          onActivityTap: (actId) => _openActivityDetail(actId),
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Fehler beim Laden: $err')),
            ),
          ),

          // Eingabeleiste
          ChatInputBar(
            athleteId: widget.athleteId ?? currentUid,
            isRevoked: isRevoked,
            onSendText: (text) => _handleSendText(text),
            onShareActivity: (snap) => _handleShareActivity(snap),
          ),
        ],
      ),
    );
  }

  void _handleSendText(String text) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    ref.read(chatRepositoryProvider).sendMessage(
          chatId: widget.chatId,
          senderId: currentUid,
          type: MessageType.text,
          text: text,
        );
  }

  void _handleShareActivity(ActivityShareSnapshot snapshot) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    ref.read(chatRepositoryProvider).sendMessage(
          chatId: widget.chatId,
          senderId: currentUid,
          type: MessageType.activityShare,
          activityShare: snapshot,
        );
  }

  void _handleDeleteMessage(ChatMessage message) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    ref.read(chatRepositoryProvider).softDeleteMessage(
          chatId: widget.chatId,
          messageId: message.id,
          senderId: currentUid,
        );
  }

  void _openActivityDetail(String activityId) {
    context.push('/activities/$activityId');
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    String label;
    if (_isSameDay(date, now)) {
      label = 'Heute';
    } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      label = 'Gestern';
    } else {
      label =
          '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: AppTypography.label
                .copyWith(fontSize: 11, color: Colors.grey.shade600),
          ),
        ),
      ),
    );
  }
}
