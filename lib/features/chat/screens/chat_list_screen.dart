import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../providers/chat_providers.dart';

/// Übersicht aller aktiven Konversationen (vor allem für Trainer mit mehreren Athleten).
class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final conversationsAsync = ref.watch(userConversationsProvider(currentUid));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Nachrichten',
          style: AppTypography.headline
              .copyWith(fontSize: 18, color: AppColors.navy),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.navy),
      ),
      body: Column(
        children: [
          // Suchleiste
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Nachrichten durchsuchen...',
                prefixIcon:
                    const Icon(Icons.search, size: 20, color: Colors.grey),
                filled: true,
                fillColor: AppColors.lightBackground,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) =>
                  setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),
          const Divider(height: 1),

          // Liste der Konversationen
          Expanded(
            child: conversationsAsync.when(
              data: (conversations) {
                final filtered = conversations.where((c) {
                  final name = c.otherUserName?.toLowerCase() ?? '';
                  final lastText = c.lastMessageText?.toLowerCase() ?? '';
                  return name.contains(_searchQuery) ||
                      lastText.contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.forum_outlined,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'Keine Chats vorhanden.',
                          style: AppTypography.body
                              .copyWith(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 72),
                  itemBuilder: (context, index) {
                    final conversation = filtered[index];
                    final unread = conversation.unreadFor(currentUid);
                    final displayName = conversation.otherUserName ?? 'Athlet';

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.techGrey,
                            child: Text(
                              displayName.isNotEmpty
                                  ? displayName[0].toUpperCase()
                                  : 'A',
                              style: AppTypography.title.copyWith(
                                  fontSize: 18, color: AppColors.navy),
                            ),
                          ),
                          if (unread > 0)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.volt,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppColors.white, width: 1.5),
                                ),
                                constraints: const BoxConstraints(
                                    minWidth: 16, minHeight: 16),
                                child: Text(
                                  unread > 9 ? '9+' : '$unread',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.label.copyWith(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.navy,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.body.copyWith(
                                fontWeight: unread > 0
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: AppColors.navy,
                              ),
                            ),
                          ),
                          if (conversation.lastMessageTime != null)
                            Text(
                              _formatTime(conversation.lastMessageTime!),
                              style: AppTypography.label.copyWith(
                                fontSize: 11,
                                color: unread > 0
                                    ? AppColors.navy
                                    : Colors.grey.shade500,
                                fontWeight: unread > 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        conversation.lastMessageText ?? 'Keine Nachrichten',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.label.copyWith(
                          color: unread > 0
                              ? AppColors.navy
                              : Colors.grey.shade600,
                          fontWeight:
                              unread > 0 ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      onTap: () {
                        context.push(
                          '/chat/${conversation.id}?athleteId=${conversation.athleteId}&name=$displayName',
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Fehler: $err')),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.';
  }
}
