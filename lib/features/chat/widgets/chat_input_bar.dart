import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../models/chat_message.dart';
import 'activity_share_picker_sheet.dart';

/// Eingabeleiste für den Chat mit Textfeld, Anhängen und Aktivitäts-Sharing.
class ChatInputBar extends StatefulWidget {
  final String athleteId;
  final bool isRevoked;
  final ValueChanged<String> onSendText;
  final ValueChanged<ActivityShareSnapshot> onShareActivity;
  final VoidCallback? onAttachImage;
  final VoidCallback? onAttachFile;

  const ChatInputBar({
    super.key,
    required this.athleteId,
    this.isRevoked = false,
    required this.onSendText,
    required this.onShareActivity,
    this.onAttachImage,
    this.onAttachFile,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final can = _controller.text.trim().isNotEmpty;
      if (can != _canSend) {
        setState(() => _canSend = can);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSendText(text);
    _controller.clear();
  }

  void _showAttachmentOptions() {
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
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.techGrey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.share, color: AppColors.navy, size: 20),
                ),
                title: Text(
                  'Aktivität teilen',
                  style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.bold, color: AppColors.navy),
                ),
                subtitle: const Text(
                    'Momentaufnahme einer absolvierten Einheit senden.'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final snapshot = await ActivitySharePickerSheet.show(
                      context, widget.athleteId);
                  if (snapshot != null) {
                    widget.onShareActivity(snapshot);
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.techGrey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.image_outlined,
                      color: AppColors.navy, size: 20),
                ),
                title: Text(
                  'Bild senden',
                  style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.bold, color: AppColors.navy),
                ),
                subtitle: const Text('Aus Galerie oder Kamera (max. 10 MB).'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  widget.onAttachImage?.call();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.techGrey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      Icon(Icons.attach_file, color: AppColors.navy, size: 20),
                ),
                title: Text(
                  'Datei anhängen',
                  style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.bold, color: AppColors.navy),
                ),
                subtitle: const Text('FIT-Datei oder Dokument (max. 25 MB).'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  widget.onAttachFile?.call();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isRevoked) {
      return Container(
        color: AppColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Verknüpfung beendet – Der Chat ist archiviert und kann nicht mehr fortgeführt werden.',
                    style: AppTypography.label
                        .copyWith(color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Anhang-Button
            IconButton(
              icon: Icon(Icons.add_circle_outline,
                  color: AppColors.navy, size: 26),
              onPressed: _showAttachmentOptions,
            ),
            const SizedBox(width: 4),

            // Text-Eingabefeld
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                child: TextField(
                  controller: _controller,
                  maxLines: 5,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Nachricht eingeben...',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  style: AppTypography.body
                      .copyWith(fontSize: 15, color: AppColors.navy),
                ),
              ),
            ),
            const SizedBox(width: 6),

            // Senden-Button (Volt-Hintergrund, Navy-Icon)
            Container(
              decoration: BoxDecoration(
                color: _canSend ? AppColors.volt : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_upward,
                  color: _canSend ? AppColors.navy : Colors.grey.shade500,
                  size: 20,
                ),
                onPressed: _canSend ? _handleSend : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
