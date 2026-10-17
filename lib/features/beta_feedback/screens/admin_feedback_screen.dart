import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../models/beta_feedback_report.dart';

/// Admin-Inbox für gemeldete Beta-Feedback- & Bug-Tickets (Phase 28.2).
///
/// Ermöglicht dem Admin das Filtern, Einsehen der Diagnose-Metadaten
/// und das Setzen des Bearbeitungsstatus (OPEN, IN_PROGRESS, RESOLVED).
class AdminFeedbackScreen extends StatefulWidget {
  final Stream<QuerySnapshot>? streamOverride;

  const AdminFeedbackScreen({super.key, this.streamOverride});

  @override
  State<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends State<AdminFeedbackScreen> {
  String _selectedStatusFilter = 'ALL';
  String _selectedCategoryFilter = 'ALL';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF001F47),
        elevation: 0,
        title: const Text(
          'Beta Feedback-Inbox',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.volt),
            tooltip: 'Aktualisieren',
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filterleiste
          _buildFilterBar(),
          const Divider(color: Color(0xFF1E293B), height: 1),

          // Liste der Tickets
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: widget.streamOverride ??
                  FirebaseFirestore.instance
                      .collection('betaFeedback')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Fehler beim Laden: ${snapshot.error}',
                        style: const TextStyle(color: Colors.redAccent),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.volt),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                final allReports = docs
                    .map((d) => BetaFeedbackReport.fromFirestore(d))
                    .toList();

                // Filtern nach Status & Kategorie
                final filtered = allReports.where((r) {
                  if (_selectedStatusFilter != 'ALL' &&
                      r.status != _selectedStatusFilter) {
                    return false;
                  }
                  if (_selectedCategoryFilter != 'ALL' &&
                      r.category.wireValue != _selectedCategoryFilter) {
                    return false;
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Keine Feedback-Tickets vorhanden',
                          style: AppTypography.title.copyWith(
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildTicketCard(filtered[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: const Color(0xFF001F47),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          // Status-Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusChip('ALL', 'Alle Status'),
                const SizedBox(width: 8),
                _buildStatusChip('OPEN', '🔴 Offen'),
                const SizedBox(width: 8),
                _buildStatusChip('IN_PROGRESS', '🟡 In Arbeit'),
                const SizedBox(width: 8),
                _buildStatusChip('RESOLVED', '🟢 Behoben'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Kategorie-Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip('ALL', 'Alle Kategorien'),
                const SizedBox(width: 8),
                _buildCategoryChip('BUG_CRASH', '🐛 Bugs'),
                const SizedBox(width: 8),
                _buildCategoryChip('FEATURE_IDEA', '💡 Ideen'),
                const SizedBox(width: 8),
                _buildCategoryChip('SUPPORT_QUESTION', '❓ Support'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String value, String label) {
    final selected = _selectedStatusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      backgroundColor: const Color(0xFF1E293B),
      selectedColor: AppColors.volt,
      labelStyle: TextStyle(
        color: selected ? AppColors.navy : Colors.white70,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      onSelected: (_) => setState(() => _selectedStatusFilter = value),
    );
  }

  Widget _buildCategoryChip(String value, String label) {
    final selected = _selectedCategoryFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      backgroundColor: const Color(0xFF1E293B),
      selectedColor: AppColors.volt,
      labelStyle: TextStyle(
        color: selected ? AppColors.navy : Colors.white70,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      onSelected: (_) => setState(() => _selectedCategoryFilter = value),
    );
  }

  Widget _buildTicketCard(BetaFeedbackReport report) {
    final ticketId = report.ticketId ?? '#ORB-${report.id.substring(0, 4)}';

    Color statusColor;
    String statusText;
    switch (report.status) {
      case 'RESOLVED':
        statusColor = AppColors.green;
        statusText = 'Behoben';
        break;
      case 'IN_PROGRESS':
        statusColor = AppColors.amber;
        statusText = 'In Arbeit';
        break;
      default:
        statusColor = Colors.redAccent;
        statusText = 'Offen';
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Ticket-ID, Kategorie, Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.volt.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.volt, width: 1),
                    ),
                    child: Text(
                      ticketId,
                      style: const TextStyle(
                        color: AppColors.volt,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      report.category.label(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor, width: 1),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Beschreibung
          Text(
            report.description,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),

          // Metadaten-Zeile
          Row(
            children: [
              Icon(Icons.access_time, size: 13, color: Colors.white54),
              const SizedBox(width: 4),
              Text(
                '${report.createdAt.day.toString().padLeft(2, '0')}.${report.createdAt.month.toString().padLeft(2, '0')}. ${report.createdAt.hour.toString().padLeft(2, '0')}:${report.createdAt.minute.toString().padLeft(2, '0')} Uhr',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
              if (report.diagnostics != null) ...[
                const SizedBox(width: 12),
                Icon(Icons.phone_android, size: 13, color: Colors.white54),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    report.diagnostics!.deviceInfo,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),

          // Details anzeigen & Status ändern
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _showTicketDetails(context, report),
                child: const Text(
                  'Details ansehen',
                  style: TextStyle(color: AppColors.volt, fontSize: 12),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Status ändern',
                icon: const Icon(Icons.more_vert,
                    color: Colors.white70, size: 18),
                color: const Color(0xFF0F172A),
                onSelected: (newStatus) async {
                  await FirebaseFirestore.instance
                      .collection('betaFeedback')
                      .doc(report.id)
                      .update({'status': newStatus});
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'OPEN',
                    child: Text('🔴 Auf Offen setzen',
                        style: TextStyle(color: Colors.white)),
                  ),
                  const PopupMenuItem(
                    value: 'IN_PROGRESS',
                    child: Text('🟡 Auf In Arbeit setzen',
                        style: TextStyle(color: Colors.white)),
                  ),
                  const PopupMenuItem(
                    value: 'RESOLVED',
                    child: Text('🟢 Als Behoben markieren',
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

  void _showTicketDetails(BuildContext context, BetaFeedbackReport report) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          title: Text(
            report.ticketId ?? 'Ticket-Details',
            style: const TextStyle(
                color: AppColors.volt, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Kategorie: ${report.category.label()}',
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 6),
                Text('Status: ${report.status}',
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 6),
                Text('User-ID: ${report.userId}',
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 11)),
                const SizedBox(height: 12),
                const Text('Beschreibung:',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(report.description,
                    style: const TextStyle(color: Colors.white)),
                if (report.diagnostics != null) ...[
                  const SizedBox(height: 14),
                  const Text('Diagnose-Metadaten:',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Screen: ${report.diagnostics!.route}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11)),
                        Text('Version: ${report.diagnostics!.appVersion}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11)),
                        Text('Gerät: ${report.diagnostics!.deviceInfo}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11)),
                        if (report.diagnostics!.recentLogs.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          const Text('Logs:',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 10)),
                          ...report.diagnostics!.recentLogs.take(5).map(
                                (l) => Text(l,
                                    style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 9,
                                        fontFamily: 'monospace')),
                              ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Schließen',
                  style: TextStyle(color: AppColors.volt)),
            ),
          ],
        );
      },
    );
  }
}
