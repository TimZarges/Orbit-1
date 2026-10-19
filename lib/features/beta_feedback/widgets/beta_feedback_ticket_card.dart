import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/utils/orbit_date_formatter.dart';
import '../models/beta_feedback_report.dart';

/// Visuelle Karte für ein einzelnes Feedback- & Bug-Ticket (Phase 38.4).
///
/// Zeigt die Ticket-ID (`#ORB-xxx`), Kategorie, die detaillierte Beschreibung,
/// das Erstellungsdatum im Format `DD.MM.YYYY • HH:mm Uhr` sowie den aktuellen
/// Bearbeitungsstatus (`🟢 Offen`, `🟡 In Arbeit`, `✅ Gelöst`).
class BetaFeedbackTicketCard extends StatelessWidget {
  /// Das anzuzeigende Ticket.
  final BetaFeedbackReport report;

  /// Ob der aktuelle Nutzer Administrator-Rechte besitzt (Status-Änderungsmenü aktiv).
  final bool isAdmin;

  /// Callback bei Klick auf "Details".
  final VoidCallback? onDetailsPressed;

  /// Callback für Statusänderungen durch Administratoren.
  final ValueChanged<String>? onStatusSelected;

  const BetaFeedbackTicketCard({
    super.key,
    required this.report,
    this.isAdmin = false,
    this.onDetailsPressed,
    this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusLabel;

    switch (report.status) {
      case 'IN_PROGRESS':
        statusColor = const Color(0xFFF59E0B);
        statusLabel = '🟡 In Arbeit';
        break;
      case 'RESOLVED':
        statusColor = const Color(0xFF10B981);
        statusLabel = '✅ Gelöst';
        break;
      case 'OPEN':
      default:
        statusColor = const Color(0xFF10B981);
        statusLabel = '🟢 Offen';
        break;
    }

    return Container(
      key: Key('ticket_card_${report.id}'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF002A5C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF003E80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Ticket-ID, Kategorie, Status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.volt,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  report.ticketId ?? '#ORB-???',
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  report.category.label(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor, width: 0.8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Beschreibung
          Text(
            report.description,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),

          // Metadaten & Aktionen
          Row(
            children: [
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Text(
                      OrbitDateFormatter.formatDateTime(report.createdAt),
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                      ),
                    ),
                    if (report.screenshotPath != null)
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.image_outlined,
                            size: 14,
                            color: AppColors.volt,
                          ),
                          SizedBox(width: 2),
                          Text(
                            'Screenshot',
                            style: TextStyle(
                              color: AppColors.volt,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    if (report.diagnostics != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 14,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            report.diagnostics!.deviceInfo,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              if (onDetailsPressed != null)
                TextButton(
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    minimumSize: const Size(0, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: onDetailsPressed,
                  child: const Text(
                    'Details',
                    style: TextStyle(color: AppColors.volt, fontSize: 12),
                  ),
                ),
              if (isAdmin && onStatusSelected != null)
                PopupMenuButton<String>(
                  tooltip: 'Status ändern',
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.white70,
                    size: 18,
                  ),
                  color: const Color(0xFF002A5C),
                  onSelected: onStatusSelected,
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'OPEN',
                      child: Text('🟢 Auf Offen setzen',
                          style: TextStyle(color: Colors.white)),
                    ),
                    PopupMenuItem(
                      value: 'IN_PROGRESS',
                      child: Text('🟡 Auf In Arbeit setzen',
                          style: TextStyle(color: Colors.white)),
                    ),
                    PopupMenuItem(
                      value: 'RESOLVED',
                      child: Text('✅ Auf Gelöst setzen',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
