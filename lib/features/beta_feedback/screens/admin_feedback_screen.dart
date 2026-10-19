import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../../auth/providers/user_provider.dart';
import '../models/beta_feedback_report.dart';
import '../widgets/beta_feedback_ticket_card.dart';

/// Admin- & Tester-Inbox für gemeldete Beta-Feedback- & Bug-Tickets (Phase 28.2).
///
/// Zweistufiges DSGVO- & Sicherheitsmodell:
/// - Admins (`isAdmin == true`): Sehen alle Tickets und können den Bearbeitungsstatus
///   (`OPEN`, `IN_PROGRESS`, `RESOLVED`) verwalten.
/// - Normale Beta-Tester: Sehen ausschließlich ihre eigenen eingereichten Tickets
///   (Filter `.where('userId', isEqualTo: uid)`), kein `PERMISSION_DENIED`.
class AdminFeedbackScreen extends ConsumerStatefulWidget {
  final Stream<QuerySnapshot>? streamOverride;
  final bool? isAdminOverride;

  const AdminFeedbackScreen({
    super.key,
    this.streamOverride,
    this.isAdminOverride,
  });

  @override
  ConsumerState<AdminFeedbackScreen> createState() =>
      _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends ConsumerState<AdminFeedbackScreen> {
  String _selectedStatusFilter = 'ALL';
  String _selectedCategoryFilter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final userDoc = ref.watch(userDocumentProvider).valueOrNull;
    String? authEmail;
    String currentUid = '';
    try {
      if (Firebase.apps.isNotEmpty) {
        final authUser = FirebaseAuth.instance.currentUser;
        authEmail = authUser?.email;
        currentUid = authUser?.uid ?? '';
      }
    } catch (_) {}

    final bool isAdmin = widget.isAdminOverride ??
        (userDoc?['isAdmin'] == true ||
            authEmail == 'tim@orbit.training' ||
            authEmail == 'tim.zarges@gmail.com');

    // Zweistufige Query gemäß KORREKTUR 1 (DSGVO):
    Stream<QuerySnapshot>? defaultStream;
    if (widget.streamOverride == null) {
      try {
        if (Firebase.apps.isNotEmpty) {
          defaultStream = isAdmin
              ? FirebaseFirestore.instance
                  .collection('betaFeedback')
                  .orderBy('createdAt', descending: true)
                  .snapshots()
              : FirebaseFirestore.instance
                  .collection('betaFeedback')
                  .where('userId', isEqualTo: currentUid)
                  .snapshots();
        }
      } catch (_) {}
    }

    final Stream<QuerySnapshot> stream =
        widget.streamOverride ?? defaultStream ?? const Stream.empty();

    return Scaffold(
      backgroundColor: AppColors.navy,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        title: Text(
          isAdmin ? 'Beta Feedback-Inbox (Admin)' : 'Meine gemeldeten Tickets',
          style: const TextStyle(
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
          // Filterleiste (Navy-Brand Surface)
          _buildFilterBar(),
          const Divider(color: Color(0xFF00357A), height: 1),

          // Liste der Tickets
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: stream,
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
                    .toList()
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

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
                          isAdmin
                              ? 'Keine Feedback-Tickets vorhanden'
                              : 'Du hast bisher keine Tickets eingereicht',
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
                    final report = filtered[index];
                    return BetaFeedbackTicketCard(
                      report: report,
                      isAdmin: isAdmin,
                      onDetailsPressed: () =>
                          _showTicketDetails(context, report),
                      onStatusSelected: (newStatus) async {
                        await FirebaseFirestore.instance
                            .collection('betaFeedback')
                            .doc(report.id)
                            .update({'status': newStatus});
                      },
                    );
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
      color: const Color(0xFF002A5C),
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
      backgroundColor: const Color(0xFF00357A),
      selectedColor: AppColors.volt,
      side: BorderSide(
        color: selected ? AppColors.volt : const Color(0xFF004D99),
      ),
      labelStyle: TextStyle(
        color: selected ? AppColors.navy : Colors.white,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      onSelected: (_) {
        setState(() => _selectedStatusFilter = value);
      },
    );
  }

  Widget _buildCategoryChip(String value, String label) {
    final selected = _selectedCategoryFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      backgroundColor: const Color(0xFF00357A),
      selectedColor: AppColors.volt,
      side: BorderSide(
        color: selected ? AppColors.volt : const Color(0xFF004D99),
      ),
      labelStyle: TextStyle(
        color: selected ? AppColors.navy : Colors.white,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      onSelected: (_) {
        setState(() => _selectedCategoryFilter = value);
      },
    );
  }

  void _showTicketDetails(BuildContext context, BetaFeedbackReport report) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppColors.navy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF003E80)),
          ),
          title: Text(
            report.ticketId ?? 'Ticket-Details',
            style: const TextStyle(
              color: AppColors.volt,
              fontWeight: FontWeight.bold,
            ),
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
                      color: const Color(0xFF002A5C),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF003E80)),
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
