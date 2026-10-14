import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../models/chat_message.dart';

/// Einzelne Chat-Nachrichtenblase mit Unterstützung für Text, Bilder, Dateien und geteilte Aktivitäten.
class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final VoidCallback? onDelete;
  final ValueChanged<String>? onActivityTap;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onDelete,
    this.onActivityTap,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isDeleted) {
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            'Diese Nachricht wurde gelöscht.',
            style: AppTypography.label.copyWith(
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade500,
            ),
          ),
        ),
      );
    }

    final bubbleColor = isMe ? AppColors.navy : AppColors.techGrey;
    final textColor = isMe ? AppColors.white : AppColors.navy;
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(isMe ? 16 : 4),
      bottomRight: Radius.circular(isMe ? 4 : 16),
    );

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress:
            isMe && onDelete != null ? () => _showContextMenu(context) : null,
        child: Container(
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78),
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: borderRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Content je nach Typ
              if (message.type == MessageType.image)
                _buildImageContent(context),
              if (message.type == MessageType.file)
                _buildFileContent(context, textColor),
              if (message.type == MessageType.activityShare)
                _buildActivityContent(context),
              if (message.text != null &&
                  message.text!.isNotEmpty &&
                  message.type != MessageType.activityShare)
                Text(
                  message.text!,
                  style: AppTypography.body
                      .copyWith(color: textColor, fontSize: 15),
                ),
              const SizedBox(height: 4),

              // Timestamp & Status
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(message.createdAt),
                    style: AppTypography.label.copyWith(
                      fontSize: 10,
                      color: isMe
                          ? AppColors.white.withValues(alpha: 0.7)
                          : Colors.grey.shade600,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    if (message.status == MessageStatus.sending)
                      SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.white.withValues(alpha: 0.7)),
                        ),
                      )
                    else if (message.status == MessageStatus.failed)
                      const Icon(Icons.error_outline,
                          size: 12, color: Color(0xFFEF4444))
                    else
                      Icon(
                        Icons.done_all,
                        size: 13,
                        color: AppColors.volt,
                      ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageContent(BuildContext context) {
    if (message.mediaUrl == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          message.mediaUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (ctx, child, progress) {
            if (progress == null) return child;
            return Container(
              height: 180,
              color: Colors.black12,
              child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2)),
            );
          },
          errorBuilder: (ctx, err, _) => Container(
            height: 100,
            color: Colors.black12,
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image, size: 36, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildFileContent(BuildContext context, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isMe ? Colors.white.withValues(alpha: 0.12) : AppColors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file_outlined,
                size: 24, color: isMe ? AppColors.volt : AppColors.navy),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.fileName ?? 'Datei',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: textColor,
                    ),
                  ),
                  if (message.fileSizeBytes != null)
                    Text(
                      _formatFileSize(message.fileSizeBytes!),
                      style: AppTypography.label.copyWith(
                        fontSize: 11,
                        color: isMe ? Colors.white70 : Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityContent(BuildContext context) {
    final share = message.activityShare;
    if (share == null) return const SizedBox.shrink();

    return InkWell(
      onTap:
          onActivityTap != null ? () => onActivityTap!(share.activityId) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.techGrey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_getSportIcon(share.sport),
                      size: 16, color: AppColors.navy),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        share.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.title
                            .copyWith(fontSize: 14, color: AppColors.navy),
                      ),
                      Text(
                        share.date,
                        style: AppTypography.label.copyWith(
                            fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatItem(label: 'Dauer', value: share.formattedDuration),
                if (share.distanceM > 0)
                  _StatItem(label: 'Distanz', value: share.formattedDistance),
                if (share.avgPowerW != null && share.avgPowerW! > 0)
                  _StatItem(
                      label: 'Ø Watt', value: '${share.avgPowerW!.round()} W'),
                if (share.avgHr != null && share.avgHr! > 0)
                  _StatItem(
                      label: 'Ø HF', value: '${share.avgHr!.round()} bpm'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Details ansehen',
                  style: AppTypography.label.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.navy),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                title: Text(
                  'Nachricht löschen',
                  style: AppTypography.body.copyWith(
                    color: const Color(0xFFEF4444),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text('Wird durch einen Platzhalter ersetzt.'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  onDelete?.call();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getSportIcon(String sport) {
    switch (sport.toUpperCase()) {
      case 'BIKE':
        return Icons.directions_bike;
      case 'RUN':
        return Icons.directions_run;
      case 'SWIM':
        return Icons.pool;
      default:
        return Icons.fitness_center;
    }
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTypography.label
                .copyWith(fontSize: 10, color: Colors.grey.shade500)),
        Text(value,
            style: AppTypography.body.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.navy)),
      ],
    );
  }
}
