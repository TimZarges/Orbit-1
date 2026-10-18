import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../models/coach_dashboard_athlete.dart';
import '../models/coach_view_preference.dart';
import '../models/coach_global_mode.dart';
import '../providers/coach_dashboard_provider.dart';
import '../providers/coach_global_mode_provider.dart';

/// Konfigurierbare, performante Daten-Tabelle für den Trainer-Kader.
class CoachAthletesTable extends ConsumerWidget {
  final List<CoachDashboardAthlete> athletes;
  final Function(String athleteId, String name) onAthleteOpen;
  final Function(CoachDashboardAthlete athlete) onCreateProposal;

  const CoachAthletesTable({
    super.key,
    required this.athletes,
    required this.onAthleteOpen,
    required this.onCreateProposal,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIds = ref.watch(coachSelectedAthleteIdsProvider);
    final activePref = ref.watch(coachActivePreferenceProvider);

    if (athletes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.people_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                'Keine Athleten entsprechen den aktuellen Filtern.',
                style: AppTypography.title
                    .copyWith(fontSize: 16, color: AppColors.navy),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  ref.read(coachActivePreferenceProvider.notifier).state =
                      CoachViewPreference.defaultView;
                  ref.read(coachAthleteSearchQueryProvider.notifier).state = '';
                },
                child: const Text('Filter zurücksetzen'),
              ),
            ],
          ),
        ),
      );
    }

    final globalMode = ref.watch(coachGlobalModeProvider);
    final isSimpleMode = globalMode == CoachGlobalMode.simpleDownload;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 920),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.techGrey),
          dataRowMinHeight: 52,
          dataRowMaxHeight: 64,
          horizontalMargin: 16,
          columnSpacing: 20,
          showCheckboxColumn: true,
          columns: isSimpleMode
              ? [
                  DataColumn(
                    label: const Text('Name',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    onSort: (columnIndex, ascending) {
                      ref.read(coachActivePreferenceProvider.notifier).state =
                          activePref.copyWith(
                        sortField: 'name',
                        sortAscending: ascending,
                      );
                    },
                  ),
                  const DataColumn(
                    label: Text('Sport',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const DataColumn(
                    label: Text('Letzte Einheit',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const DataColumn(
                    label: Text('Dauer & Distanz',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const DataColumn(
                    label: Text('Ø Puls & Watt',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const DataColumn(
                    label: Text('Originaldatei (.FIT / .TCX)',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const DataColumn(
                    label: Text('Aktion',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ]
              : [
                  // Name
                  DataColumn(
                    label: const Text('Name',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    onSort: (columnIndex, ascending) {
                      ref.read(coachActivePreferenceProvider.notifier).state =
                          activePref.copyWith(
                        sortField: 'name',
                        sortAscending: ascending,
                      );
                    },
                  ),
                  // Sport
                  const DataColumn(
                    label: Text('Sport',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  // Form
                  const DataColumn(
                    label: Text('Form',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  // Erholung (Art. 9 DSGVO)
                  const DataColumn(
                    label: Text('Erholung (Art. 9)',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  // Compliance 7d
                  DataColumn(
                    label: const Text('Soll/Ist (7T)',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    onSort: (columnIndex, ascending) {
                      ref.read(coachActivePreferenceProvider.notifier).state =
                          activePref.copyWith(
                        sortField: 'compliance7d',
                        sortAscending: ascending,
                      );
                    },
                  ),
                  // Belastung 7d
                  const DataColumn(
                    label: Text('Last 7T',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  // Saisonziel
                  DataColumn(
                    label: const Text('Saisonziel',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    onSort: (columnIndex, ascending) {
                      ref.read(coachActivePreferenceProvider.notifier).state =
                          activePref.copyWith(
                        sortField: 'daysRemaining',
                        sortAscending: ascending,
                      );
                    },
                  ),
                  // Auffälligkeiten / Alerts
                  const DataColumn(
                    label: Text('Status / Alerts',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  // Aktionen
                  const DataColumn(
                    label: Text('Aktion',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
          rows: athletes.map((athlete) {
            final isSelected = selectedIds.contains(athlete.athleteId);

            return DataRow(
              selected: isSelected,
              onSelectChanged: (selected) {
                final current = Set<String>.from(selectedIds);
                if (selected == true) {
                  current.add(athlete.athleteId);
                } else {
                  current.remove(athlete.athleteId);
                }
                ref.read(coachSelectedAthleteIdsProvider.notifier).state =
                    current;
              },
              cells: isSimpleMode
                  ? [
                      // 1. Name
                      _buildNameCell(athlete),
                      // 2. Sport
                      DataCell(
                        Text(athlete.sport,
                            style: AppTypography.label.copyWith(fontSize: 12)),
                      ),
                      // 3. Letzte Einheit
                      DataCell(
                        Text(
                          athlete.latestActivity != null
                              ? '${athlete.latestActivity!['title'] ?? 'Training'}'
                              : '–',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      // 4. Dauer & Distanz
                      DataCell(
                        Builder(builder: (_) {
                          if (athlete.latestActivity == null) {
                            return const Text('–');
                          }
                          final dur = athlete.latestActivity!['durationSec']
                                  as num? ??
                              3600;
                          final dist = athlete.latestActivity!['distanceM']
                                  as num? ??
                              0;
                          final durStr =
                              '${(dur ~/ 3600)}h ${(dur % 3600 ~/ 60).toString().padLeft(2, '0')}m';
                          final distStr = dist > 0
                              ? ' · ${(dist / 1000).toStringAsFixed(1)} km'
                              : '';
                          return Text('$durStr$distStr',
                              style: const TextStyle(fontSize: 12));
                        }),
                      ),
                      // 5. Ø Puls & Watt
                      DataCell(
                        Builder(builder: (_) {
                          if (athlete.latestActivity == null) {
                            return const Text('–');
                          }
                          final hr = athlete.latestActivity!['avgHr'] as num?;
                          final w =
                              athlete.latestActivity!['avgPowerW'] as num?;
                          final hrStr =
                              hr != null ? '${hr.round()} bpm' : '–';
                          final wStr = w != null ? ' · ${w.round()} W' : '';
                          return Text('$hrStr$wStr',
                              style: const TextStyle(fontSize: 12));
                        }),
                      ),
                      // 6. Originaldatei Download (.FIT)
                      DataCell(
                        ElevatedButton.icon(
                          icon: const Icon(Icons.file_download_outlined,
                              size: 15, color: AppColors.navy),
                          label: const Text('.FIT Download',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.navy)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.volt,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            final rawPath = athlete
                                    .latestActivity?['rawFilePath'] ??
                                'users/${athlete.athleteId}/rawActivities/latest_${athlete.athleteId}.fit';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.download_done,
                                        color: AppColors.volt),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                          'Download für WKO5/GoldenCheetah bereitgestellt: $rawPath'),
                                    ),
                                  ],
                                ),
                                backgroundColor: AppColors.navy,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ),
                      // 7. Aktion (Kalender)
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.calendar_month,
                              size: 18, color: AppColors.navy),
                          tooltip: 'Kalender öffnen',
                          onPressed: () =>
                              onAthleteOpen(athlete.athleteId, athlete.name),
                        ),
                      ),
                    ]
                  : [
                      // Name
                      _buildNameCell(athlete),
                // Sport
                DataCell(
                  Text(athlete.sport,
                      style: AppTypography.label.copyWith(fontSize: 12)),
                ),
                // Form
                DataCell(
                  _buildFormBadge(athlete.formStatus, athlete.tsb),
                ),
                // Erholung (Art. 9 DSGVO Gate)
                DataCell(
                  _buildHealthRecoveryCell(athlete),
                ),
                // Compliance
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 50,
                        child: LinearProgressIndicator(
                          value: (athlete.compliance7d / 100).clamp(0.0, 1.0),
                          backgroundColor: Colors.grey.shade200,
                          color: athlete.compliance7d < 70
                              ? Colors.orange
                              : const Color(0xFF10B981),
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${athlete.compliance7d}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: athlete.compliance7d < 70
                              ? Colors.orange.shade800
                              : AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                ),
                // Belastung 7d
                DataCell(
                  Text(
                    '${athlete.actualLoad7d} / ${athlete.plannedLoad7d} TSS',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                // Saisonziel
                DataCell(
                  athlete.raceGoal != null
                      ? Text(
                          '${athlete.raceGoal!['title']} (${athlete.raceGoal!['daysRemaining']}T)',
                          style: const TextStyle(fontSize: 12),
                        )
                      : const Text('–', style: TextStyle(color: Colors.grey)),
                ),
                // Alerts
                DataCell(
                  athlete.alert != null
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade400),
                          ),
                          child: Text(
                            athlete.alertLabelDe ?? athlete.alert!,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900),
                          ),
                        )
                      : const Text('Normal',
                          style: TextStyle(fontSize: 12, color: Colors.green)),
                ),
                // Aktionen
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.auto_awesome,
                            size: 18, color: AppColors.navy),
                        tooltip: 'Schwellenwert vorschlagen',
                        onPressed: () => onCreateProposal(athlete),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_month,
                            size: 18, color: AppColors.navy),
                        tooltip: 'Kalender öffnen',
                        onPressed: () =>
                            onAthleteOpen(athlete.athleteId, athlete.name),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  DataCell _buildNameCell(CoachDashboardAthlete athlete) {
    return DataCell(
      InkWell(
        onTap: () => onAthleteOpen(athlete.athleteId, athlete.name),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.navy.withValues(alpha: 0.1),
              child: Text(
                athlete.name.isNotEmpty ? athlete.name[0] : 'A',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              athlete.name,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: AppColors.navy),
            ),
            if (athlete.unreadMessagesCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.volt,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${athlete.unreadMessagesCount}',
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFormBadge(CoachAthleteFormStatus status, int tsb) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case CoachAthleteFormStatus.optimal:
        bg = AppColors.volt.withValues(alpha: 0.25);
        fg = AppColors.navy;
        label = 'Optimal';
        break;
      case CoachAthleteFormStatus.wellLoaded:
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade800;
        label = 'Belastet';
        break;
      case CoachAthleteFormStatus.caution:
        bg = Colors.red.shade50;
        fg = Colors.red.shade800;
        label = 'Achtung';
        break;
      case CoachAthleteFormStatus.fresh:
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        label = 'Frisch';
        break;
      case CoachAthleteFormStatus.building:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade800;
        label = 'Aufbau';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label (${tsb >= 0 ? "+$tsb" : tsb})',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  /// Rendert die Trainer-Erholungsampel unter strikter Einhaltung von Art. 9 DSGVO.
  ///
  /// Wird nur angezeigt, wenn [athlete.hasHealthPermission] wahr ist und der Status
  /// der Verknüpfung aktiv ist. Andernfalls wird ein gesperrtes Schloss-Symbol angezeigt.
  Widget _buildHealthRecoveryCell(CoachDashboardAthlete athlete) {
    if (!athlete.hasHealthPermission || athlete.coachLinkStatus != 'ACTIVE') {
      return Tooltip(
        message: 'Gesundheitsdaten nicht freigegeben (Art. 9 DSGVO)',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 14, color: Colors.grey.shade500),
            const SizedBox(width: 4),
            Text(
              'Gesperrt (Art. 9)',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    final score = athlete.recoveryScore ?? 65;
    final trafficLight = athlete.recoveryTrafficLight ?? 'GREEN';
    final Color badgeColor;
    final Color textColor;
    if (trafficLight == 'GREEN') {
      badgeColor = AppColors.emerald.withValues(alpha: 0.15);
      textColor = AppColors.emerald;
    } else if (trafficLight == 'RED') {
      badgeColor = AppColors.coral.withValues(alpha: 0.15);
      textColor = AppColors.coral;
    } else {
      badgeColor = AppColors.amber.withValues(alpha: 0.15);
      textColor = AppColors.amber;
    }

    final hrvTrendIcon = athlete.hrvTrend == 'DOWN'
        ? Icons.trending_down
        : (athlete.hrvTrend == 'UP' ? Icons.trending_up : Icons.trending_flat);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: textColor.withValues(alpha: 0.5)),
          ),
          child: Text(
            '$score %',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
        if (athlete.hrvTrend != null) ...[
          const SizedBox(width: 4),
          Icon(hrvTrendIcon, size: 14, color: textColor),
        ],
      ],
    );
  }
}
